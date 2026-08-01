import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/game_lan_service.dart';
import '../../../../services/lan/lan_providers.dart';

final _rng = Random();

// Card: 0-51. suit = c ~/ 13 (0=♣ 1=♦ 2=♥ 3=♠), rank = c % 13 (0=A 1=2 … 12=K)
int suitOf(int c) => c ~/ 13;
int rankOf(int c) => c % 13;
int faceValue(int c) => min(rankOf(c) + 1, 10); // Ace=1, 2-10=face, J/Q/K=10
int pipValue(int c) => rankOf(c) + 1; // for sequences: A=1, 2=2 … K=13

const _rankLabels = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
const _suitSymbols = ['♣','♦','♥','♠'];
String cardLabel(int c) => '${_rankLabels[rankOf(c)]}${_suitSymbols[suitOf(c)]}';
bool isRed(int c) => suitOf(c) == 1 || suitOf(c) == 2;

// ── Scoring helpers ───────────────────────────────────────────────────────────

int _countFifteens(List<int> cards) {
  int score = 0;
  final n = cards.length;
  for (int mask = 1; mask < (1 << n); mask++) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
      if (mask & (1 << i) != 0) sum += faceValue(cards[i]);
    }
    if (sum == 15) score += 2;
  }
  return score;
}

int _countPairs(List<int> cards) {
  int score = 0;
  for (int i = 0; i < cards.length; i++) {
    for (int j = i + 1; j < cards.length; j++) {
      if (rankOf(cards[i]) == rankOf(cards[j])) score += 2;
    }
  }
  return score;
}

int _countRuns(List<int> cards) {
  final ranks = cards.map(pipValue).toList()..sort();
  int score = 0;
  // Find longest runs of 3+
  for (int len = cards.length; len >= 3; len--) {
    for (int start = 0; start <= ranks.length - len; start++) {
      final slice = ranks.sublist(start, start + len);
      bool isRun = true;
      for (int i = 1; i < slice.length; i++) {
        if (slice[i] != slice[i - 1] + 1) { isRun = false; break; }
      }
      if (isRun) {
        score += len;
        return score; // simplified: count first longest run × its multiplicity
      }
    }
  }
  return score;
}

int _countFlush(List<int> hand, int? starter, bool isCrib) {
  final s = suitOf(hand[0]);
  if (hand.every((c) => suitOf(c) == s)) {
    if (starter != null && suitOf(starter) == s) return 5;
    if (!isCrib) return 4;
  }
  return 0;
}

int _countNobs(List<int> hand, int starter) {
  for (final c in hand) {
    if (rankOf(c) == 10 && suitOf(c) == suitOf(starter)) return 1; // J same suit
  }
  return 0;
}

int scoreHand(List<int> hand, int starter, {bool isCrib = false}) {
  final all = [...hand, starter];
  return _countFifteens(all) +
      _countPairs(all) +
      _countRuns(all) +
      _countFlush(hand, starter, isCrib) +
      _countNobs(hand, starter);
}

// Pegging scoring: score for playing [card] after [table]
int scorePegging(List<int> table, int card) {
  final played = [...table, card];
  final count = played.fold(0, (s, c) => s + faceValue(c));
  int score = 0;
  if (count == 15) score += 2;
  if (count == 31) score += 2;
  // Pairs/trips/quads of last N equal ranks
  final ranks = played.map(rankOf).toList().reversed.toList();
  int pairLen = 1;
  while (pairLen < ranks.length && ranks[pairLen] == ranks[0]) { pairLen++; }
  if (pairLen == 2) score += 2;
  if (pairLen == 3) score += 6;
  if (pairLen == 4) score += 12;
  // Runs
  for (int len = played.length; len >= 3; len--) {
    final tail = played.sublist(played.length - len).map(pipValue).toList()..sort();
    bool isRun = true;
    for (int i = 1; i < tail.length; i++) {
      if (tail[i] != tail[i - 1] + 1) { isRun = false; break; }
    }
    if (tail.toSet().length == len && isRun) {
      score += len;
      break;
    }
  }
  return score;
}

// ── Game state ────────────────────────────────────────────────────────────────

enum CribbagePhase { discarding, pegging, counting, gameOver }

class CribbageState {
  final List<int> deck;
  final List<int> playerFullHand; // 6 cards dealt
  final List<int> playerHand;     // 4 kept
  final List<int> aiHand;         // 4 kept
  final List<int> crib;
  final int? starter;
  final List<int> pegTable;       // cards played this pegging round
  final List<int> playerPegging;  // cards left for pegging
  final List<int> aiPegging;
  final int pegCount;
  final int playerScore;
  final int aiScore;
  final bool isPlayerDealer;
  final bool isPlayerPegging;     // whose pegging turn
  final CribbagePhase phase;
  final Set<int> selectedDiscard; // indices of player's 6-card hand to discard
  final String message;
  final String? winner;
  // Who most recently added a card to pegTable (not a "Go" pass, which adds
  // nothing) — null until the first card of a pegging series is played.
  // Drives both the Go/last-card point attribution and who leads the next
  // series after a reset, since turn alternation alone can't reliably infer
  // this (see GB12/GB13 fix).
  final bool? lastToPlayWasHuman;
  // GAME1: absolute host/guest model, same shape as checkers/yatzy/backgammon
  // — the host is always the "player" role, the opponent always the "ai"
  // role, whether that's the local AI (solo, isOpponentAI: true) or a real
  // remote guest (multiplayer, isOpponentAI: false).
  final bool isMultiplayer;
  final bool isOpponentAI;
  // Unlike the other titles, Cribbage's discard phase is simultaneous, not
  // turn-based: both sides pick 2 cards independently and the round can't
  // proceed to cutting the starter until BOTH have confirmed. In solo mode
  // (or an AI-filled multiplayer seat) the AI side auto-confirms immediately
  // in _dealRound, same as before — aiFullHand stays empty and
  // guestDiscardConfirmed starts true. In real multiplayer, aiFullHand holds
  // the guest's own 6 cards until they confirm via confirmAiDiscard/
  // toggleAiDiscard (their own mirror of playerFullHand/selectedDiscard).
  final List<int> aiFullHand;
  final Set<int> selectedAiDiscard;
  final bool hostDiscardConfirmed;
  final bool guestDiscardConfirmed;

  const CribbageState({
    required this.deck,
    required this.playerFullHand,
    required this.playerHand,
    required this.aiHand,
    required this.crib,
    required this.starter,
    required this.pegTable,
    required this.playerPegging,
    required this.aiPegging,
    required this.pegCount,
    required this.playerScore,
    required this.aiScore,
    required this.isPlayerDealer,
    required this.isPlayerPegging,
    required this.phase,
    required this.selectedDiscard,
    required this.message,
    this.winner,
    this.lastToPlayWasHuman,
    this.isMultiplayer = false,
    this.isOpponentAI = true,
    this.aiFullHand = const [],
    this.selectedAiDiscard = const {},
    this.hostDiscardConfirmed = false,
    this.guestDiscardConfirmed = false,
  });

  CribbageState copyWith({
    List<int>? deck,
    List<int>? playerFullHand,
    List<int>? playerHand,
    List<int>? aiHand,
    List<int>? crib,
    int? Function()? starter,
    List<int>? pegTable,
    List<int>? playerPegging,
    List<int>? aiPegging,
    int? pegCount,
    int? playerScore,
    int? aiScore,
    bool? isPlayerDealer,
    bool? isPlayerPegging,
    CribbagePhase? phase,
    Set<int>? selectedDiscard,
    String? message,
    String? Function()? winner,
    bool? lastToPlayWasHuman,
    bool? isMultiplayer,
    bool? isOpponentAI,
    List<int>? aiFullHand,
    Set<int>? selectedAiDiscard,
    bool? hostDiscardConfirmed,
    bool? guestDiscardConfirmed,
  }) =>
      CribbageState(
        deck: deck ?? this.deck,
        playerFullHand: playerFullHand ?? this.playerFullHand,
        playerHand: playerHand ?? this.playerHand,
        aiHand: aiHand ?? this.aiHand,
        crib: crib ?? this.crib,
        starter: starter != null ? starter() : this.starter,
        pegTable: pegTable ?? this.pegTable,
        playerPegging: playerPegging ?? this.playerPegging,
        aiPegging: aiPegging ?? this.aiPegging,
        pegCount: pegCount ?? this.pegCount,
        playerScore: playerScore ?? this.playerScore,
        aiScore: aiScore ?? this.aiScore,
        isPlayerDealer: isPlayerDealer ?? this.isPlayerDealer,
        isPlayerPegging: isPlayerPegging ?? this.isPlayerPegging,
        phase: phase ?? this.phase,
        selectedDiscard: selectedDiscard ?? this.selectedDiscard,
        message: message ?? this.message,
        winner: winner != null ? winner() : this.winner,
        lastToPlayWasHuman: lastToPlayWasHuman ?? this.lastToPlayWasHuman,
        isMultiplayer: isMultiplayer ?? this.isMultiplayer,
        isOpponentAI: isOpponentAI ?? this.isOpponentAI,
        aiFullHand: aiFullHand ?? this.aiFullHand,
        selectedAiDiscard: selectedAiDiscard ?? this.selectedAiDiscard,
        hostDiscardConfirmed: hostDiscardConfirmed ?? this.hostDiscardConfirmed,
        guestDiscardConfirmed: guestDiscardConfirmed ?? this.guestDiscardConfirmed,
      );

  Map<String, dynamic> toJson() => {
        'deck': deck,
        'playerFullHand': playerFullHand,
        'playerHand': playerHand,
        'aiHand': aiHand,
        'crib': crib,
        'starter': starter,
        'pegTable': pegTable,
        'playerPegging': playerPegging,
        'aiPegging': aiPegging,
        'pegCount': pegCount,
        'playerScore': playerScore,
        'aiScore': aiScore,
        'isPlayerDealer': isPlayerDealer,
        'isPlayerPegging': isPlayerPegging,
        'phase': phase.name,
        'selectedDiscard': selectedDiscard.toList(),
        'message': message,
        'winner': winner,
        'lastToPlayWasHuman': lastToPlayWasHuman,
        'isMultiplayer': isMultiplayer,
        'isOpponentAI': isOpponentAI,
        'aiFullHand': aiFullHand,
        'selectedAiDiscard': selectedAiDiscard.toList(),
        'hostDiscardConfirmed': hostDiscardConfirmed,
        'guestDiscardConfirmed': guestDiscardConfirmed,
      };

  factory CribbageState.fromJson(Map<String, dynamic> j) => CribbageState(
        deck: (j['deck'] as List).cast<int>(),
        playerFullHand: (j['playerFullHand'] as List).cast<int>(),
        playerHand: (j['playerHand'] as List).cast<int>(),
        aiHand: (j['aiHand'] as List).cast<int>(),
        crib: (j['crib'] as List).cast<int>(),
        starter: j['starter'] as int?,
        pegTable: (j['pegTable'] as List).cast<int>(),
        playerPegging: (j['playerPegging'] as List).cast<int>(),
        aiPegging: (j['aiPegging'] as List).cast<int>(),
        pegCount: j['pegCount'] as int,
        playerScore: j['playerScore'] as int,
        aiScore: j['aiScore'] as int,
        isPlayerDealer: j['isPlayerDealer'] as bool,
        isPlayerPegging: j['isPlayerPegging'] as bool,
        phase: CribbagePhase.values.byName(j['phase'] as String),
        selectedDiscard: (j['selectedDiscard'] as List).cast<int>().toSet(),
        message: j['message'] as String,
        winner: j['winner'] as String?,
        lastToPlayWasHuman: j['lastToPlayWasHuman'] as bool?,
        isMultiplayer: j['isMultiplayer'] as bool? ?? false,
        isOpponentAI: j['isOpponentAI'] as bool? ?? true,
        aiFullHand: (j['aiFullHand'] as List?)?.cast<int>() ?? const [],
        selectedAiDiscard:
            (j['selectedAiDiscard'] as List?)?.cast<int>().toSet() ?? const {},
        hostDiscardConfirmed: j['hostDiscardConfirmed'] as bool? ?? false,
        guestDiscardConfirmed: j['guestDiscardConfirmed'] as bool? ?? false,
      );
}

class CribbageNotifier extends Notifier<CribbageState> {
  bool _isHostMode = false;
  bool _isClientMode = false;

  bool get isClientMode => _isClientMode;

  StreamSubscription<Map<String, dynamic>>? _remoteSub;
  StreamSubscription<({String peerId, String action, Map<String, dynamic> data})>?
      _moveSub;
  StreamSubscription<String>? _leaveSub;

  // Bumped on every initClientMode()/exitMultiplayerMode() call so an
  // in-flight reconnect retry loop from a previous session can tell it's
  // stale and stop touching state after the notifier has moved on.
  int _sessionGeneration = 0;

  @override
  CribbageState build() {
    ref.onDispose(() {
      _remoteSub?.cancel();
      _moveSub?.cancel();
      _leaveSub?.cancel();
    });
    return _dealRound(playerScore: 0, aiScore: 0, playerDealer: true);
  }

  // ── Multiplayer setup (mirrors checkers/backgammon's absolute host/guest
  // model — Cribbage is strictly 2-role, no player-id roster needed) ────────
  //
  // Unlike those titles, the discard phase is simultaneous rather than
  // turn-based (see CribbageState's doc comment on aiFullHand/
  // hostDiscardConfirmed/guestDiscardConfirmed) — _dealRound branches on
  // whether the opponent is a real remote guest to decide whether to wait.

  void initHostMode(List<LobbyPlayer> lobbyPlayers) {
    _isHostMode = true;
    _isClientMode = false;
    _sessionGeneration++;
    _remoteSub?.cancel();
    _moveSub?.cancel();
    _leaveSub?.cancel();

    final lan = ref.read(gameLanServiceProvider);
    _moveSub = lan.incomingMoves.listen(_applyRemoteMove);
    _leaveSub = lan.playerLeaves.listen(_handleDisconnect);

    final opponent = lobbyPlayers.length > 1 ? lobbyPlayers[1] : null;
    state = _dealRound(
      playerScore: 0,
      aiScore: 0,
      playerDealer: true,
      isMultiplayer: true,
      isOpponentAI: opponent?.isAI ?? true,
    );
    // No separate startGame()/determineStarter() step to naturally
    // re-broadcast a couple of seconds later (same gap found live in
    // Yatzy/Checkers/Backgammon) — delay briefly so the guest's
    // initClientMode() subscription has attached before this fires.
    Timer(const Duration(seconds: 1), _broadcastIfHost);
  }

  void initClientMode() {
    _isClientMode = true;
    _isHostMode = false;
    _moveSub?.cancel();
    _leaveSub?.cancel();
    final generation = ++_sessionGeneration;

    final lan = ref.read(gameLanServiceProvider);
    _remoteSub = lan.remoteStates.listen((json) {
      state = CribbageState.fromJson(json);
    });
    _leaveSub = lan.playerLeaves.listen((peerId) {
      if (peerId == 'host') _handleHostDisconnect(generation);
    });

    state = const CribbageState(
      deck: [],
      playerFullHand: [],
      playerHand: [],
      aiHand: [],
      crib: [],
      starter: null,
      pegTable: [],
      playerPegging: [],
      aiPegging: [],
      pegCount: 0,
      playerScore: 0,
      aiScore: 0,
      isPlayerDealer: true,
      isPlayerPegging: false,
      phase: CribbagePhase.discarding,
      selectedDiscard: {},
      message: 'Waiting for host...',
      isMultiplayer: true,
      isOpponentAI: false,
    );
  }

  void exitMultiplayerMode() {
    _isHostMode = false;
    _isClientMode = false;
    _sessionGeneration++;
    _remoteSub?.cancel();
    _moveSub?.cancel();
    _leaveSub?.cancel();
  }

  /// Client-side: the connection to the host dropped. Surfaces a message and
  /// tries a few quick reconnects before giving up cleanly.
  Future<void> _handleHostDisconnect(int generation) async {
    if (generation != _sessionGeneration) return;
    state = state.copyWith(message: 'Connection lost. Reconnecting…');

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      await Future.delayed(const Duration(seconds: 2));
      if (generation != _sessionGeneration) return;

      final reconnected = await ref.read(gameLanServiceProvider).reconnect();
      if (generation != _sessionGeneration) return;

      if (reconnected) {
        state = state.copyWith(message: 'Reconnected!');
        return;
      }
    }

    state = state.copyWith(
      phase: CribbagePhase.gameOver,
      message: 'Connection to host lost. Game ended.',
    );
  }

  // ── Host-side remote move handler ─────────────────────────────────────────
  //
  // Only the actions a guest would ever send appear here — 'toggleDiscard'/
  // 'confirmDiscard' are the host's own hand and are only ever called
  // locally on the host's device.
  void _applyRemoteMove(
      ({String peerId, String action, Map<String, dynamic> data}) move) {
    switch (move.action) {
      case 'toggleAiDiscard':
        toggleAiDiscard(move.data['idx'] as int);
      case 'confirmAiDiscard':
        confirmAiDiscard();
      case 'playPegCard':
        playPegCard(move.data['handIdx'] as int);
      case 'sayGo':
        sayGo();
      case 'nextRound':
        nextRound();
    }
  }

  void _broadcastIfHost() {
    if (_isHostMode) {
      ref.read(gameLanServiceProvider).broadcastState(state.toJson());
    }
  }

  // ── Disconnect handling ───────────────────────────────────────────────────
  //
  // Cribbage has no player-id roster (fixed 2-role model) — any disconnect
  // while hosting can only be the one real guest, so it simply ends the game.
  void _handleDisconnect(String peerId) {
    state = state.copyWith(
      phase: CribbagePhase.gameOver,
      message: 'Opponent disconnected. Game ended.',
    );
    _broadcastIfHost();
  }

  CribbageState _dealRound({
    required int playerScore,
    required int aiScore,
    required bool playerDealer,
    bool isMultiplayer = false,
    bool isOpponentAI = true,
  }) {
    final deck = List.generate(52, (i) => i)..shuffle(_rng);
    final playerFull = deck.sublist(0, 6);
    final aiFullHand = deck.sublist(6, 12);
    final dealMessage = playerDealer
        ? 'You deal. Choose 2 cards for your crib.'
        : 'AI deals. Choose 2 cards for the crib.';

    if (!isMultiplayer || isOpponentAI) {
      // Local AI (solo, or an AI-filled multiplayer seat) auto-discards
      // immediately, same as before — nothing to wait for.
      final aiKeep = _aiSelectDiscard(aiFullHand, playerDealer);
      final aiDiscard = aiFullHand.where((c) => !aiKeep.contains(c)).toList();
      return CribbageState(
        deck: deck.sublist(12),
        playerFullHand: playerFull,
        playerHand: const [],
        aiHand: aiKeep,
        crib: aiDiscard,
        starter: null,
        pegTable: const [],
        playerPegging: const [],
        aiPegging: const [],
        pegCount: 0,
        playerScore: playerScore,
        aiScore: aiScore,
        isPlayerDealer: playerDealer,
        isPlayerPegging: !playerDealer, // non-dealer pegs first
        phase: CribbagePhase.discarding,
        selectedDiscard: const {},
        message: dealMessage,
        isMultiplayer: isMultiplayer,
        isOpponentAI: isOpponentAI,
        hostDiscardConfirmed: false,
        guestDiscardConfirmed: true,
      );
    }

    // Real remote guest — both sides discard independently; the round can't
    // proceed until _maybeFinishDiscarding sees both confirmed.
    return CribbageState(
      deck: deck.sublist(12),
      playerFullHand: playerFull,
      playerHand: const [],
      aiHand: const [],
      aiFullHand: aiFullHand,
      crib: const [],
      starter: null,
      pegTable: const [],
      playerPegging: const [],
      aiPegging: const [],
      pegCount: 0,
      playerScore: playerScore,
      aiScore: aiScore,
      isPlayerDealer: playerDealer,
      isPlayerPegging: !playerDealer,
      phase: CribbagePhase.discarding,
      selectedDiscard: const {},
      message: dealMessage,
      isMultiplayer: true,
      isOpponentAI: false,
      hostDiscardConfirmed: false,
      guestDiscardConfirmed: false,
    );
  }

  void toggleDiscard(int idx) {
    if (state.phase != CribbagePhase.discarding) return;
    if (state.hostDiscardConfirmed) return;
    final s = {...state.selectedDiscard};
    if (s.contains(idx)) {
      s.remove(idx);
    } else if (s.length < 2) {
      s.add(idx);
    }
    state = state.copyWith(selectedDiscard: s);
    _broadcastIfHost();
  }

  void confirmDiscard() {
    if (state.phase != CribbagePhase.discarding) return;
    if (state.hostDiscardConfirmed) return;
    if (state.selectedDiscard.length != 2) return;

    final hand = state.playerFullHand;
    final discardList = state.selectedDiscard.toList();
    final discard = discardList.map((i) => hand[i]).toList();
    final kept = [
      for (int i = 0; i < hand.length; i++)
        if (!state.selectedDiscard.contains(i)) hand[i]
    ];

    state = state.copyWith(
      playerHand: kept,
      crib: [...state.crib, ...discard],
      selectedDiscard: {},
      hostDiscardConfirmed: true,
    );
    _broadcastIfHost();
    _maybeFinishDiscarding();
  }

  // Guest's own mirror of toggleDiscard/confirmDiscard — see CribbageState's
  // doc comment on aiFullHand for why this can't just reuse the same method.
  void toggleAiDiscard(int idx) {
    if (state.phase != CribbagePhase.discarding) return;
    if (state.guestDiscardConfirmed) return;
    final s = {...state.selectedAiDiscard};
    if (s.contains(idx)) {
      s.remove(idx);
    } else if (s.length < 2) {
      s.add(idx);
    }
    state = state.copyWith(selectedAiDiscard: s);
    _broadcastIfHost();
  }

  void confirmAiDiscard() {
    if (state.phase != CribbagePhase.discarding) return;
    if (state.guestDiscardConfirmed) return;
    if (state.selectedAiDiscard.length != 2) return;

    final hand = state.aiFullHand;
    final discardList = state.selectedAiDiscard.toList();
    final discard = discardList.map((i) => hand[i]).toList();
    final kept = [
      for (int i = 0; i < hand.length; i++)
        if (!state.selectedAiDiscard.contains(i)) hand[i]
    ];

    state = state.copyWith(
      aiHand: kept,
      crib: [...state.crib, ...discard],
      selectedAiDiscard: {},
      guestDiscardConfirmed: true,
    );
    _broadcastIfHost();
    _maybeFinishDiscarding();
  }

  // Cuts the starter, checks nibs, and moves to pegging — but only once
  // BOTH sides have confirmed their discard. Safe to call from either
  // confirmDiscard (host) or confirmAiDiscard (guest, via _applyRemoteMove)
  // regardless of which side confirms first, since it no-ops until both are
  // true and everything after runs once on whichever call satisfies both.
  void _maybeFinishDiscarding() {
    if (!state.hostDiscardConfirmed || !state.guestDiscardConfirmed) return;

    final deckCopy = [...state.deck];
    final starterCard = deckCopy.removeAt(_rng.nextInt(deckCopy.length));

    // Heels: if starter is Jack, dealer gets 2
    int pScore = state.playerScore;
    int aScore = state.aiScore;
    String nibsMsg = '';
    if (rankOf(starterCard) == 10) {
      if (state.isPlayerDealer) {
        pScore += 2;
        nibsMsg = ' Nibs! You get 2 points.';
      } else {
        aScore += 2;
        nibsMsg = ' Nibs! AI gets 2 points.';
      }
    }

    if (pScore >= 121) {
      state = state.copyWith(
        starter: () => starterCard,
        playerScore: pScore, aiScore: aScore,
        phase: CribbagePhase.gameOver,
        message: 'You win with nibs!', winner: () => 'You',
      );
      _broadcastIfHost();
      return;
    }
    if (aScore >= 121) {
      state = state.copyWith(
        starter: () => starterCard,
        playerScore: pScore, aiScore: aScore,
        phase: CribbagePhase.gameOver,
        message: 'AI wins with nibs!', winner: () => 'AI',
      );
      _broadcastIfHost();
      return;
    }

    state = state.copyWith(
      deck: deckCopy,
      starter: () => starterCard,
      playerScore: pScore,
      aiScore: aScore,
      playerPegging: [...state.playerHand],
      aiPegging: [...state.aiHand],
      phase: CribbagePhase.pegging,
      message: 'Starter: ${cardLabel(starterCard)}.$nibsMsg'
          ' ${!state.isPlayerDealer ? "Your" : "AI's"} turn to peg.',
    );
    _broadcastIfHost();

    final isLocalAiTurn =
        !state.isPlayerPegging && (!state.isMultiplayer || state.isOpponentAI);
    if (isLocalAiTurn) {
      Future.delayed(const Duration(milliseconds: 600), _aiPegTurn);
    }
  }

  // Acts on behalf of whichever role's peg turn it currently is
  // (state.isPlayerPegging), not hardcoded "the human" — in solo mode the
  // AI's turn never reaches this (it goes through _aiPegTurn instead), but
  // in multiplayer the guest's forwarded plays run through here too while
  // isPlayerPegging is false. Same fix shape as checkers/backgammon.
  void playPegCard(int handIdx) {
    if (state.phase != CribbagePhase.pegging) return;
    final isHostRole = state.isPlayerPegging;
    final hand = isHostRole ? state.playerPegging : state.aiPegging;
    if (handIdx < 0 || handIdx >= hand.length) return;
    final card = hand[handIdx];
    if (faceValue(card) + state.pegCount > 31) return;

    final pts = scorePegging(state.pegTable, card);
    final newTable = [...state.pegTable, card];
    final newHand = [...hand]..removeAt(handIdx);
    final newCount = state.pegCount + faceValue(card);

    int pScore = state.playerScore + (isHostRole ? pts : 0);
    int aScore = state.aiScore + (isHostRole ? 0 : pts);
    final newPlayerPegging = isHostRole ? newHand : state.playerPegging;
    final newAiPegging = isHostRole ? state.aiPegging : newHand;

    String msg = pts > 0
        ? (isHostRole ? 'You score $pts pegging. ' : 'Opponent scores $pts pegging. ')
        : '';

    if (pScore >= 121) {
      state = state.copyWith(
        pegTable: newTable, playerPegging: newPlayerPegging, aiPegging: newAiPegging,
        pegCount: newCount, playerScore: pScore,
        phase: CribbagePhase.gameOver,
        message: 'You win with $pScore points!', winner: () => 'You',
      );
      _broadcastIfHost();
      return;
    }
    if (aScore >= 121) {
      state = state.copyWith(
        pegTable: newTable, playerPegging: newPlayerPegging, aiPegging: newAiPegging,
        pegCount: newCount, aiScore: aScore,
        phase: CribbagePhase.gameOver,
        message: 'AI wins with $aScore points!', winner: () => 'AI',
      );
      _broadcastIfHost();
      return;
    }

    // Check if count hits 31
    if (newCount == 31) {
      if (isHostRole) { pScore += 2; } else { aScore += 2; }
      state = state.copyWith(
        pegTable: [], playerPegging: newPlayerPegging, aiPegging: newAiPegging,
        pegCount: 0, playerScore: pScore, aiScore: aScore,
        isPlayerPegging: !isHostRole,
        lastToPlayWasHuman: isHostRole,
        message: isHostRole
            ? '${msg}31! You score 2. Count resets.'
            : '${msg}31! Opponent +2. Count resets.',
      );
      _broadcastIfHost();
      final nextIsLocalAi = !state.isPlayerPegging &&
          (!state.isMultiplayer || state.isOpponentAI);
      if (nextIsLocalAi) {
        Future.delayed(const Duration(milliseconds: 600), _aiPegTurn);
      }
      return;
    }

    // Check if the other side can play — if not, and this hand is out of
    // cards, this is a stoppage: this side gets the last-card point and the
    // count resets here rather than deferring detection to _aiPegTurn/the
    // other side's next play, which would otherwise independently
    // rediscover "neither side can play" and double-award the point (GB12).
    final otherHand = isHostRole ? newAiPegging : newPlayerPegging;
    final otherCanPlay = otherHand.any((c) => faceValue(c) + newCount <= 31);
    final stoppage = !otherCanPlay && newHand.isEmpty;
    if (stoppage) {
      if (isHostRole) { pScore += 1; } else { aScore += 1; }
      msg += isHostRole
          ? 'Last card +1. Count resets.'
          : 'Last card. Opponent +1. Count resets.';
    }

    state = state.copyWith(
      pegTable: stoppage ? [] : newTable,
      playerPegging: newPlayerPegging,
      aiPegging: newAiPegging,
      pegCount: stoppage ? 0 : newCount,
      playerScore: pScore,
      aiScore: aScore,
      isPlayerPegging: !isHostRole,
      lastToPlayWasHuman: isHostRole,
      message: stoppage
          ? msg
          : (isHostRole
              ? '${msg}Count: $newCount. AI\'s peg turn.'
              : '${msg}Count: $newCount. Your peg turn.'),
    );
    _broadcastIfHost();

    if (newPlayerPegging.isEmpty && newAiPegging.isEmpty) {
      Future.delayed(const Duration(milliseconds: 400), _startCounting);
    } else {
      final nextIsLocalAi = !state.isPlayerPegging &&
          (!state.isMultiplayer || state.isOpponentAI);
      if (nextIsLocalAi) {
        Future.delayed(const Duration(milliseconds: 600), _aiPegTurn);
      }
    }
  }

  void _aiPegTurn() {
    if (state.isPlayerPegging || state.phase != CribbagePhase.pegging) return;

    final playable = state.aiPegging
        .where((c) => faceValue(c) + state.pegCount <= 31)
        .toList();

    if (playable.isEmpty) {
      // AI says "go"
      if (state.playerPegging.any((c) => faceValue(c) + state.pegCount <= 31)) {
        state = state.copyWith(
          isPlayerPegging: true,
          message: 'AI says Go! Your turn. Count: ${state.pegCount}.',
        );
        _broadcastIfHost();
        return;
      }
      // Both can't play — resolve the stoppage.
      _resolveGoStoppage();
      return;
    }

    // Play card that scores most, else highest
    playable.sort((a, b) {
      final sa = scorePegging(state.pegTable, a);
      final sb = scorePegging(state.pegTable, b);
      if (sb != sa) return sb.compareTo(sa);
      return faceValue(b).compareTo(faceValue(a));
    });

    final card = playable.first;
    final pts = scorePegging(state.pegTable, card);
    int aScore = state.aiScore + pts;
    final newTable = [...state.pegTable, card];
    final newAiPegging = [...state.aiPegging]..remove(card);
    final newCount = state.pegCount + faceValue(card);

    String msg = 'AI plays ${cardLabel(card)}.';
    if (pts > 0) msg += ' AI scores $pts.';

    if (aScore >= 121) {
      state = state.copyWith(
        pegTable: newTable, aiPegging: newAiPegging,
        pegCount: newCount, aiScore: aScore,
        phase: CribbagePhase.gameOver,
        message: 'AI wins with $aScore points!', winner: () => 'AI',
      );
      _broadcastIfHost();
      return;
    }

    if (newCount == 31) {
      aScore += 2;
      state = state.copyWith(
        pegTable: [], aiPegging: newAiPegging,
        pegCount: 0, aiScore: aScore,
        isPlayerPegging: true, // you lead the next series — AI just played
        lastToPlayWasHuman: false,
        message: '$msg 31! AI +2. Count resets.',
      );
      _broadcastIfHost();
      return;
    }

    // Mirror of the human-side stoppage above (GB12): if you can't follow
    // and AI is now out of cards, resolve the point/reset here rather than
    // letting your next Go tap independently rediscover the same stoppage.
    final playerCanPlay = state.playerPegging.any((c) => faceValue(c) + newCount <= 31);
    final aiStoppage = !playerCanPlay && newAiPegging.isEmpty;
    if (aiStoppage) aScore += 1;

    state = state.copyWith(
      pegTable: aiStoppage ? [] : newTable,
      aiPegging: newAiPegging,
      pegCount: aiStoppage ? 0 : newCount,
      aiScore: aScore,
      isPlayerPegging: true,
      lastToPlayWasHuman: false,
      message: aiStoppage
          ? '$msg Count resets. Your peg turn.'
          : '$msg Count: $newCount. Your peg turn.',
    );
    _broadcastIfHost();

    if (newAiPegging.isEmpty && state.playerPegging.isEmpty) {
      Future.delayed(const Duration(milliseconds: 400), _startCounting);
    }
  }

  // Resolves a mutual "neither side can play" stoppage — reached either
  // from _aiPegTurn (AI just discovered it) or from sayGo() (you just
  // discovered it). The point goes to whoever played the table's last
  // card, tracked via lastToPlayWasHuman rather than inferred from which
  // side is calling this, since that inference is unreliable (GB12/GB13).
  void _resolveGoStoppage() {
    final humanPlayedLast = state.lastToPlayWasHuman ?? false;
    int pScore = state.playerScore;
    int aScore = state.aiScore;
    final String msg;
    if (humanPlayedLast) {
      pScore += 1;
      msg = 'Last card. You +1. Count resets.';
    } else {
      aScore += 1;
      msg = 'Last card. AI +1. Count resets.';
    }

    if (pScore >= 121) {
      state = state.copyWith(
        playerScore: pScore, aiScore: aScore,
        phase: CribbagePhase.gameOver,
        message: 'You win with $pScore points!', winner: () => 'You',
      );
      _broadcastIfHost();
      return;
    }
    if (aScore >= 121) {
      state = state.copyWith(
        playerScore: pScore, aiScore: aScore,
        phase: CribbagePhase.gameOver,
        message: 'AI wins with $aScore points!', winner: () => 'AI',
      );
      _broadcastIfHost();
      return;
    }

    state = state.copyWith(
      playerScore: pScore,
      aiScore: aScore,
      pegTable: [],
      pegCount: 0,
      isPlayerPegging: !humanPlayedLast,
      message: msg,
    );
    _broadcastIfHost();
    if (state.playerPegging.isEmpty && state.aiPegging.isEmpty) {
      Future.delayed(const Duration(milliseconds: 400), _startCounting);
    } else {
      final nextIsLocalAi = !state.isPlayerPegging &&
          (!state.isMultiplayer || state.isOpponentAI);
      if (nextIsLocalAi) {
        Future.delayed(const Duration(milliseconds: 600), _aiPegTurn);
      }
    }
  }

  // GB11: the human side of "AI says Go" — previously only the AI could
  // pass when unable to play; a human with no legal card had no affordance
  // at all, silently stalling pegging. Now role-aware (see playPegCard) so
  // a guest's own "no legal play" is handled the same way.
  void sayGo() {
    if (state.phase != CribbagePhase.pegging) return;
    final isHostRole = state.isPlayerPegging;
    final hand = isHostRole ? state.playerPegging : state.aiPegging;
    final canPlay = hand.any((c) => faceValue(c) + state.pegCount <= 31);
    if (canPlay) return; // must play a legal card if one exists

    final otherHand = isHostRole ? state.aiPegging : state.playerPegging;
    final otherCanPlay = otherHand.any((c) => faceValue(c) + state.pegCount <= 31);
    if (otherCanPlay) {
      state = state.copyWith(
        isPlayerPegging: !isHostRole,
        message: isHostRole
            ? 'You say Go! AI\'s turn. Count: ${state.pegCount}.'
            : 'Opponent says Go! Your turn. Count: ${state.pegCount}.',
      );
      _broadcastIfHost();
      final nextIsLocalAi = !state.isPlayerPegging &&
          (!state.isMultiplayer || state.isOpponentAI);
      if (nextIsLocalAi) {
        Future.delayed(const Duration(milliseconds: 600), _aiPegTurn);
      }
      return;
    }

    _resolveGoStoppage();
  }

  void _startCounting() {
    if (state.phase != CribbagePhase.pegging) return;
    final st = state.starter!;
    // Non-dealer hand first, then dealer, then crib
    final nonDealerHand = state.isPlayerDealer ? state.aiHand : state.playerHand;
    final dealerHand = state.isPlayerDealer ? state.playerHand : state.aiHand;

    final nonDealerPts = scoreHand(nonDealerHand, st);
    final dealerPts = scoreHand(dealerHand, st);
    final cribPts = scoreHand(state.crib, st, isCrib: true);

    int pScore = state.playerScore;
    int aScore = state.aiScore;
    String summary = '';

    if (state.isPlayerDealer) {
      aScore += nonDealerPts;
      summary += 'AI hand: $nonDealerPts. ';
      pScore += dealerPts + cribPts;
      summary += 'Your hand+crib: ${dealerPts + cribPts}.';
    } else {
      pScore += nonDealerPts;
      summary += 'Your hand: $nonDealerPts. ';
      aScore += dealerPts + cribPts;
      summary += 'AI hand+crib: ${dealerPts + cribPts}.';
    }

    if (pScore >= 121) {
      state = state.copyWith(
        playerScore: pScore, aiScore: aScore,
        phase: CribbagePhase.gameOver,
        message: 'You win! $summary Final: You $pScore – AI $aScore',
        winner: () => 'You',
      );
      _broadcastIfHost();
      return;
    }
    if (aScore >= 121) {
      state = state.copyWith(
        playerScore: pScore, aiScore: aScore,
        phase: CribbagePhase.gameOver,
        message: 'AI wins! $summary Final: You $pScore – AI $aScore',
        winner: () => 'AI',
      );
      _broadcastIfHost();
      return;
    }

    state = state.copyWith(
      playerScore: pScore,
      aiScore: aScore,
      phase: CribbagePhase.counting,
      message: '$summary You: $pScore – AI: $aScore. Next round.',
    );
    _broadcastIfHost();
  }

  void nextRound() {
    if (state.phase != CribbagePhase.counting) return;
    state = _dealRound(
      playerScore: state.playerScore,
      aiScore: state.aiScore,
      playerDealer: !state.isPlayerDealer,
      isMultiplayer: state.isMultiplayer,
      isOpponentAI: state.isOpponentAI,
    );
    _broadcastIfHost();
  }

  void newGame() {
    exitMultiplayerMode();
    state = build();
  }

  List<int> _aiSelectDiscard(List<int> hand, bool playerDealer) =>
      cribbageAiSelectKeep(hand, playerDealer: playerDealer);
}

/// TEST28 / GAI: pure crib-discard keep set (no RNG) — same hand ⇒ same keep.
///
/// Returns the 4 cards the AI keeps (not the two discarded).
List<int> cribbageAiSelectKeep(List<int> hand, {bool playerDealer = false}) {
  // Try all combinations of 4-keep, pick highest scoring hand.
  // [playerDealer] reserved for future dealer-aware crib strategy.
  List<int> bestKeep = hand.sublist(0, 4);
  int bestScore = -1;
  for (int i = 0; i < hand.length; i++) {
    for (int j = i + 1; j < hand.length; j++) {
      final keep = [
        for (int k = 0; k < hand.length; k++)
          if (k != i && k != j) hand[k]
      ];
      // Use a dummy starter for evaluation
      int score = 0;
      for (int s = 0; s < 52; s++) {
        if (!hand.contains(s)) {
          score += scoreHand(keep, s);
          break; // just one estimate for speed
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestKeep = keep;
      }
    }
  }
  return bestKeep;
}

final cribbageStateProvider =
    NotifierProvider<CribbageNotifier, CribbageState>(CribbageNotifier.new);
