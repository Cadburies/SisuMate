import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/game_lan_service.dart';
import '../../../../services/lan/lan_providers.dart';

final _rng = Random();

// Card: 0-51.  suit = c ~/ 13 (0=♣ 1=♦ 2=♥ 3=♠)  rank = c % 13 (0=2 … 12=A)
// Note: rank 0=2, rank 12=Ace  (so Ace is high)
int suitOf(int c) => c ~/ 13;
int rankOf(int c) => c % 13; // 0=2,1=3,…,8=10,9=J,10=Q,11=K,12=A
bool isRed(int c) => suitOf(c) == 1 || suitOf(c) == 2;

const _rankLabels = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
const _suitSymbols = ['♣', '♦', '♥', '♠'];
String cardLabel(int c) => '${_rankLabels[rankOf(c)]}${_suitSymbols[suitOf(c)]}';

// ── Hand evaluation ───────────────────────────────────────────────────────────

enum HandRank {
  highCard,
  onePair,
  twoPair,
  threeOfAKind,
  straight,
  flush,
  fullHouse,
  fourOfAKind,
  straightFlush,
  royalFlush,
}

const handRankLabel = {
  HandRank.highCard: 'High Card',
  HandRank.onePair: 'One Pair',
  HandRank.twoPair: 'Two Pair',
  HandRank.threeOfAKind: 'Three of a Kind',
  HandRank.straight: 'Straight',
  HandRank.flush: 'Flush',
  HandRank.fullHouse: 'Full House',
  HandRank.fourOfAKind: 'Four of a Kind',
  HandRank.straightFlush: 'Straight Flush',
  HandRank.royalFlush: 'Royal Flush',
};

class HandResult implements Comparable<HandResult> {
  final HandRank rank;
  final List<int> tiebreakers; // sorted descending for comparison
  const HandResult(this.rank, this.tiebreakers);

  @override
  int compareTo(HandResult other) {
    final rc = rank.index.compareTo(other.rank.index);
    if (rc != 0) return rc;
    for (int i = 0; i < tiebreakers.length && i < other.tiebreakers.length; i++) {
      final c = tiebreakers[i].compareTo(other.tiebreakers[i]);
      if (c != 0) return c;
    }
    return 0;
  }
}

HandResult evaluateHand(List<int> hand) {
  assert(hand.length == 5);
  final ranks = hand.map(rankOf).toList()..sort((a, b) => b.compareTo(a));
  final suits = hand.map(suitOf).toList();
  final cnt = <int, int>{};
  for (final r in ranks) {
    cnt[r] = (cnt[r] ?? 0) + 1;
  }
  final groups = cnt.entries.toList()
    ..sort((a, b) {
      final byCnt = b.value.compareTo(a.value);
      return byCnt != 0 ? byCnt : b.key.compareTo(a.key);
    });
  final isFlush = suits.toSet().length == 1;
  // Straight detection (also A-2-3-4-5 wheel)
  final uniqueRanks = ranks.toSet().toList()..sort((a, b) => b.compareTo(a));
  bool isStraight =
      uniqueRanks.length == 5 && uniqueRanks.first - uniqueRanks.last == 4;
  bool isWheel = false;
  if (!isStraight && uniqueRanks.toSet().containsAll([12, 0, 1, 2, 3])) {
    isStraight = true;
    isWheel = true; // A-2-3-4-5 — Ace plays low, so this is the lowest straight
  }

  final tieRanks = groups.map((e) => e.key).toList();
  // A wheel's tiebreak must compare as a 5-high straight, not Ace-high —
  // otherwise groups' raw key ordering (which sorts the Ace's rank index,
  // 12, first) would let it wrongly beat/tie a King-high straight instead
  // of ranking below every other straight (GB4).
  final straightTieRanks = isWheel ? const [3, 2, 1, 0, -1] : tieRanks;

  if (isFlush && isStraight) {
    final isRoyal = ranks.contains(12) &&
        ranks.contains(11) &&
        ranks.contains(10) &&
        ranks.contains(9) &&
        ranks.contains(8);
    return HandResult(
        isRoyal ? HandRank.royalFlush : HandRank.straightFlush, straightTieRanks);
  }
  if (groups.first.value == 4) return HandResult(HandRank.fourOfAKind, tieRanks);
  if (groups.first.value == 3 && groups[1].value == 2) {
    return HandResult(HandRank.fullHouse, tieRanks);
  }
  if (isFlush) return HandResult(HandRank.flush, ranks);
  if (isStraight) return HandResult(HandRank.straight, straightTieRanks);
  if (groups.first.value == 3) return HandResult(HandRank.threeOfAKind, tieRanks);
  if (groups.first.value == 2 && groups[1].value == 2) {
    return HandResult(HandRank.twoPair, tieRanks);
  }
  if (groups.first.value == 2) return HandResult(HandRank.onePair, tieRanks);
  return HandResult(HandRank.highCard, ranks);
}

// ── Game state ────────────────────────────────────────────────────────────────

enum PokerPhase { betting1, draw, betting2, showdown, roundOver, gameOver }

class PokerState {
  final List<int> deck;
  final List<int> playerHand;
  final List<int> aiHand;
  final Set<int> selectedDiscard; // indices in playerHand (host role)
  final Set<int> selectedAiDiscard; // indices in aiHand (guest role)
  final int playerChips;
  final int aiChips;
  final int pot;
  final int playerCurrentBet;
  final int aiCurrentBet;
  final PokerPhase phase;
  final String message;
  final String? outcome; // null until showdown/fold; host-centric wording
  // GAME1: absolute host/guest model (same shape as uno/yatzy/checkers) —
  // host is always the "player" role, opponent always the "ai" role (local AI
  // or real remote guest). isPlayerTurn true = host role's action expected.
  final bool isPlayerTurn;
  final bool isMultiplayer;
  final bool isOpponentAI;
  final bool hostDrawConfirmed;
  final bool guestDrawConfirmed;

  const PokerState({
    required this.deck,
    required this.playerHand,
    required this.aiHand,
    required this.selectedDiscard,
    this.selectedAiDiscard = const {},
    required this.playerChips,
    required this.aiChips,
    required this.pot,
    required this.playerCurrentBet,
    required this.aiCurrentBet,
    required this.phase,
    required this.message,
    this.outcome,
    this.isPlayerTurn = true,
    this.isMultiplayer = false,
    this.isOpponentAI = true,
    this.hostDrawConfirmed = false,
    this.guestDrawConfirmed = false,
  });

  PokerState copyWith({
    List<int>? deck,
    List<int>? playerHand,
    List<int>? aiHand,
    Set<int>? selectedDiscard,
    Set<int>? selectedAiDiscard,
    int? playerChips,
    int? aiChips,
    int? pot,
    int? playerCurrentBet,
    int? aiCurrentBet,
    PokerPhase? phase,
    String? message,
    String? Function()? outcome,
    bool? isPlayerTurn,
    bool? isMultiplayer,
    bool? isOpponentAI,
    bool? hostDrawConfirmed,
    bool? guestDrawConfirmed,
  }) =>
      PokerState(
        deck: deck ?? this.deck,
        playerHand: playerHand ?? this.playerHand,
        aiHand: aiHand ?? this.aiHand,
        selectedDiscard: selectedDiscard ?? this.selectedDiscard,
        selectedAiDiscard: selectedAiDiscard ?? this.selectedAiDiscard,
        playerChips: playerChips ?? this.playerChips,
        aiChips: aiChips ?? this.aiChips,
        pot: pot ?? this.pot,
        playerCurrentBet: playerCurrentBet ?? this.playerCurrentBet,
        aiCurrentBet: aiCurrentBet ?? this.aiCurrentBet,
        phase: phase ?? this.phase,
        message: message ?? this.message,
        outcome: outcome != null ? outcome() : this.outcome,
        isPlayerTurn: isPlayerTurn ?? this.isPlayerTurn,
        isMultiplayer: isMultiplayer ?? this.isMultiplayer,
        isOpponentAI: isOpponentAI ?? this.isOpponentAI,
        hostDrawConfirmed: hostDrawConfirmed ?? this.hostDrawConfirmed,
        guestDrawConfirmed: guestDrawConfirmed ?? this.guestDrawConfirmed,
      );

  Map<String, dynamic> toJson() => {
        'deck': deck,
        'playerHand': playerHand,
        'aiHand': aiHand,
        'selectedDiscard': selectedDiscard.toList(),
        'selectedAiDiscard': selectedAiDiscard.toList(),
        'playerChips': playerChips,
        'aiChips': aiChips,
        'pot': pot,
        'playerCurrentBet': playerCurrentBet,
        'aiCurrentBet': aiCurrentBet,
        'phase': phase.name,
        'message': message,
        'outcome': outcome,
        'isPlayerTurn': isPlayerTurn,
        'isMultiplayer': isMultiplayer,
        'isOpponentAI': isOpponentAI,
        'hostDrawConfirmed': hostDrawConfirmed,
        'guestDrawConfirmed': guestDrawConfirmed,
      };

  factory PokerState.fromJson(Map<String, dynamic> j) => PokerState(
        deck: (j['deck'] as List).map((e) => e as int).toList(),
        playerHand: (j['playerHand'] as List).map((e) => e as int).toList(),
        aiHand: (j['aiHand'] as List).map((e) => e as int).toList(),
        selectedDiscard:
            (j['selectedDiscard'] as List? ?? const []).map((e) => e as int).toSet(),
        selectedAiDiscard:
            (j['selectedAiDiscard'] as List? ?? const []).map((e) => e as int).toSet(),
        playerChips: j['playerChips'] as int,
        aiChips: j['aiChips'] as int,
        pot: j['pot'] as int,
        playerCurrentBet: j['playerCurrentBet'] as int,
        aiCurrentBet: j['aiCurrentBet'] as int,
        phase: PokerPhase.values.byName(j['phase'] as String),
        message: j['message'] as String,
        outcome: j['outcome'] as String?,
        isPlayerTurn: j['isPlayerTurn'] as bool? ?? true,
        isMultiplayer: j['isMultiplayer'] as bool? ?? false,
        isOpponentAI: j['isOpponentAI'] as bool? ?? true,
        hostDrawConfirmed: j['hostDrawConfirmed'] as bool? ?? false,
        guestDrawConfirmed: j['guestDrawConfirmed'] as bool? ?? false,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PokerNotifier extends Notifier<PokerState> {
  static const _ante = 10;
  static const _betAmount = 20;

  bool _isHostMode = false;
  bool _isClientMode = false;

  bool get isClientMode => _isClientMode;

  StreamSubscription<Map<String, dynamic>>? _remoteSub;
  StreamSubscription<({String peerId, String action, Map<String, dynamic> data})>?
      _moveSub;
  StreamSubscription<String>? _leaveSub;

  int _sessionGeneration = 0;

  @override
  PokerState build() {
    ref.onDispose(() {
      _remoteSub?.cancel();
      _moveSub?.cancel();
      _leaveSub?.cancel();
    });
    return _startRound(
      playerChips: 500,
      aiChips: 500,
      isMultiplayer: false,
      isOpponentAI: true,
    );
  }

  // ── Multiplayer setup ─────────────────────────────────────────────────────

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
    state = _startRound(
      playerChips: 500,
      aiChips: 500,
      isMultiplayer: true,
      isOpponentAI: opponent?.isAI ?? true,
    );
    // No starter-determination step — delay so guest's initClientMode() has
    // attached its remoteStates subscription (same gap as Yatzy/Uno).
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
      state = PokerState.fromJson(json);
    });
    _leaveSub = lan.playerLeaves.listen((peerId) {
      if (peerId == 'host') _handleHostDisconnect(generation);
    });

    state = PokerState(
      deck: const [],
      playerHand: const [],
      aiHand: const [],
      selectedDiscard: const {},
      playerChips: 500,
      aiChips: 500,
      pot: 0,
      playerCurrentBet: 0,
      aiCurrentBet: 0,
      phase: PokerPhase.betting1,
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
      phase: PokerPhase.gameOver,
      message: 'Connection to host lost. Game ended.',
      outcome: () => null, // clear any prior round outcome
    );
  }

  void _applyRemoteMove(
      ({String peerId, String action, Map<String, dynamic> data}) move) {
    switch (move.action) {
      case 'bet':
        playerBet();
      case 'check':
        playerCheck();
      case 'call':
        playerCall();
      case 'fold':
        playerFold();
      case 'toggleDiscard':
        toggleDiscard(move.data['idx'] as int);
      case 'confirmDraw':
        confirmDraw();
      case 'toggleAiDiscard':
        toggleAiDiscard(move.data['idx'] as int);
      case 'confirmAiDraw':
        confirmAiDraw();
      case 'nextRound':
        nextRound();
    }
  }

  void _broadcastIfHost() {
    if (_isHostMode) {
      ref.read(gameLanServiceProvider).broadcastState(state.toJson());
    }
  }

  void _handleDisconnect(String peerId) {
    state = state.copyWith(
      phase: PokerPhase.gameOver,
      message: 'Opponent disconnected. Game ended.',
      outcome: () => null,
    );
    _broadcastIfHost();
  }

  bool get _humanOpponent => state.isMultiplayer && !state.isOpponentAI;

  PokerState _startRound({
    required int playerChips,
    required int aiChips,
    required bool isMultiplayer,
    required bool isOpponentAI,
  }) {
    final mp = isMultiplayer;
    final oppAi = isOpponentAI;

    if (playerChips <= 0) {
      return PokerState(
        deck: [],
        playerHand: [],
        aiHand: [],
        selectedDiscard: {},
        playerChips: 0,
        aiChips: aiChips,
        pot: 0,
        playerCurrentBet: 0,
        aiCurrentBet: 0,
        phase: PokerPhase.gameOver,
        message: 'You\'re out of chips! Opponent wins.',
        outcome: 'AI wins',
        isMultiplayer: mp,
        isOpponentAI: oppAi,
      );
    }
    if (aiChips <= 0) {
      return PokerState(
        deck: [],
        playerHand: [],
        aiHand: [],
        selectedDiscard: {},
        playerChips: playerChips,
        aiChips: 0,
        pot: 0,
        playerCurrentBet: 0,
        aiCurrentBet: 0,
        phase: PokerPhase.gameOver,
        message: 'Opponent is out of chips! You win!',
        outcome: 'You win',
        isMultiplayer: mp,
        isOpponentAI: oppAi,
      );
    }
    final deck = List.generate(52, (i) => i)..shuffle(_rng);
    final ante = _ante.clamp(0, playerChips.clamp(0, aiChips));
    final playerHand = deck.sublist(0, 5);
    final aiHand = deck.sublist(5, 10);
    return PokerState(
      deck: deck.sublist(10),
      playerHand: playerHand,
      aiHand: aiHand,
      selectedDiscard: {},
      selectedAiDiscard: {},
      playerChips: playerChips - ante,
      aiChips: aiChips - ante,
      pot: ante * 2,
      playerCurrentBet: ante,
      aiCurrentBet: ante,
      phase: PokerPhase.betting1,
      message: 'Ante: \$$ante each. Bet, check, or fold?',
      isPlayerTurn: true,
      isMultiplayer: mp,
      isOpponentAI: oppAi,
      hostDrawConfirmed: false,
      guestDrawConfirmed: false,
    );
  }

  // ── Discard selection ─────────────────────────────────────────────────────

  void toggleDiscard(int idx) {
    if (state.phase != PokerPhase.draw) return;
    if (state.hostDrawConfirmed) return;
    final newSet = Set<int>.from(state.selectedDiscard);
    if (newSet.contains(idx)) {
      newSet.remove(idx);
    } else {
      newSet.add(idx);
    }
    state = state.copyWith(selectedDiscard: newSet);
    _broadcastIfHost();
  }

  void toggleAiDiscard(int idx) {
    if (state.phase != PokerPhase.draw) return;
    if (state.guestDrawConfirmed) return;
    final newSet = Set<int>.from(state.selectedAiDiscard);
    if (newSet.contains(idx)) {
      newSet.remove(idx);
    } else {
      newSet.add(idx);
    }
    state = state.copyWith(selectedAiDiscard: newSet);
    _broadcastIfHost();
  }

  // ── Betting — role-aware via isPlayerTurn (host role when true) ────────────

  void playerBet() {
    if (state.phase != PokerPhase.betting1 && state.phase != PokerPhase.betting2) {
      return;
    }
    final isHostRole = state.isPlayerTurn;
    final myChips = isHostRole ? state.playerChips : state.aiChips;
    final amount = _betAmount.clamp(0, myChips);
    if (amount == 0) {
      playerCheck();
      return;
    }

    if (isHostRole) {
      state = state.copyWith(
        playerChips: state.playerChips - amount,
        pot: state.pot + amount,
        playerCurrentBet: state.playerCurrentBet + amount,
      );
    } else {
      state = state.copyWith(
        aiChips: state.aiChips - amount,
        pot: state.pot + amount,
        aiCurrentBet: state.aiCurrentBet + amount,
      );
    }

    if (_humanOpponent) {
      // Hand off for call/fold — do not auto-match.
      state = state.copyWith(
        isPlayerTurn: !isHostRole,
        message: isHostRole
            ? 'You bet \$$amount. Waiting for opponent…'
            : 'Opponent bets \$$amount. Call or fold?',
      );
      _broadcastIfHost();
      return;
    }

    // Solo / AI seat: AI always calls (capped at actual bet, GB3).
    final aiCall = amount.clamp(0, state.aiChips);
    state = state.copyWith(
      aiChips: state.aiChips - aiCall,
      pot: state.pot + aiCall,
      aiCurrentBet: state.aiCurrentBet + aiCall,
      phase: state.phase == PokerPhase.betting1 ? PokerPhase.draw : PokerPhase.showdown,
      message: state.phase == PokerPhase.betting1
          ? 'You bet \$$amount. AI calls. Select cards to discard.'
          : 'You bet \$$amount. AI calls. Showdown!',
      isPlayerTurn: true,
    );
    _broadcastIfHost();
    if (state.phase == PokerPhase.showdown) {
      Future.delayed(const Duration(milliseconds: 400), _showdown);
    }
  }

  void playerCheck() {
    if (state.phase != PokerPhase.betting1 && state.phase != PokerPhase.betting2) {
      return;
    }
    final isHostRole = state.isPlayerTurn;
    final myBet = isHostRole ? state.playerCurrentBet : state.aiCurrentBet;
    final oppBet = isHostRole ? state.aiCurrentBet : state.playerCurrentBet;
    if (oppBet > myBet) return; // must call or fold

    if (_humanOpponent) {
      if (isHostRole) {
        // Host checks first → guest acts.
        state = state.copyWith(
          isPlayerTurn: false,
          message: 'You check. Opponent\'s action…',
        );
        _broadcastIfHost();
      } else {
        // Guest checks back → both checked.
        _advanceAfterEqualBets('Both check.');
      }
      return;
    }

    // Solo: AI may bet or check.
    final aiWillBet = _rng.nextInt(3) == 0; // 33% AI bets back
    if (aiWillBet && state.aiChips >= _betAmount) {
      final aiAmount = _betAmount.clamp(0, state.aiChips);
      state = state.copyWith(
        aiChips: state.aiChips - aiAmount,
        pot: state.pot + aiAmount,
        aiCurrentBet: state.aiCurrentBet + aiAmount,
        message: 'AI bets \$$aiAmount. Call or fold?',
        isPlayerTurn: true,
      );
      _broadcastIfHost();
    } else {
      _advanceAfterEqualBets('Both check.');
    }
  }

  void playerCall() {
    if (state.phase != PokerPhase.betting1 && state.phase != PokerPhase.betting2) {
      return;
    }
    final isHostRole = state.isPlayerTurn;
    final myBet = isHostRole ? state.playerCurrentBet : state.aiCurrentBet;
    final oppBet = isHostRole ? state.aiCurrentBet : state.playerCurrentBet;
    final needed = oppBet - myBet;
    if (needed <= 0) return;

    final myChips = isHostRole ? state.playerChips : state.aiChips;
    final diff = needed.clamp(0, myChips);
    final uncalled = needed - diff;

    if (isHostRole) {
      // Host calls guest's (or AI's) bet — uncalled portion returns to AI stack.
      state = state.copyWith(
        playerChips: state.playerChips - diff,
        aiChips: state.aiChips + uncalled,
        pot: state.pot + diff - uncalled,
        playerCurrentBet: state.playerCurrentBet + diff,
      );
    } else {
      // Guest calls host's bet — uncalled portion returns to host stack.
      state = state.copyWith(
        aiChips: state.aiChips - diff,
        playerChips: state.playerChips + uncalled,
        pot: state.pot + diff - uncalled,
        aiCurrentBet: state.aiCurrentBet + diff,
      );
    }

    final intoDraw = state.phase == PokerPhase.betting1;
    state = state.copyWith(
      phase: intoDraw ? PokerPhase.draw : PokerPhase.showdown,
      message: intoDraw ? 'Call. Select cards to discard.' : 'Call. Showdown!',
      isPlayerTurn: true,
      hostDrawConfirmed: false,
      guestDrawConfirmed: false,
      selectedDiscard: {},
      selectedAiDiscard: {},
    );
    _broadcastIfHost();
    if (state.phase == PokerPhase.showdown) {
      Future.delayed(const Duration(milliseconds: 400), _showdown);
    } else if (intoDraw && !_humanOpponent) {
      // Solo draw: nothing further until player confirms.
    }
  }

  void playerFold() {
    if (state.phase != PokerPhase.betting1 && state.phase != PokerPhase.betting2) {
      return;
    }
    final isHostRole = state.isPlayerTurn;
    final pot = state.pot;
    if (isHostRole) {
      // Host folds → opponent wins pot.
      state = state.copyWith(
        aiChips: state.aiChips + pot,
        pot: 0,
        phase: PokerPhase.roundOver,
        message: 'You fold. Opponent wins \$$pot.',
        outcome: () => 'AI wins',
        isPlayerTurn: true,
      );
    } else {
      // Guest folds → host wins pot.
      state = state.copyWith(
        playerChips: state.playerChips + pot,
        pot: 0,
        phase: PokerPhase.roundOver,
        message: 'Opponent folds. You win \$$pot.',
        outcome: () => 'You win',
        isPlayerTurn: true,
      );
    }
    _broadcastIfHost();
  }

  void _advanceAfterEqualBets(String prefix) {
    final intoDraw = state.phase == PokerPhase.betting1;
    state = state.copyWith(
      phase: intoDraw ? PokerPhase.draw : PokerPhase.showdown,
      message: intoDraw
          ? '$prefix Select cards to discard.'
          : '$prefix Showdown!',
      isPlayerTurn: true,
      hostDrawConfirmed: false,
      guestDrawConfirmed: false,
      selectedDiscard: {},
      selectedAiDiscard: {},
    );
    _broadcastIfHost();
    if (state.phase == PokerPhase.showdown) {
      Future.delayed(const Duration(milliseconds: 400), _showdown);
    }
  }

  // ── Draw ──────────────────────────────────────────────────────────────────

  void confirmDraw() {
    if (state.phase != PokerPhase.draw) return;
    if (state.hostDrawConfirmed) return;

    if (_humanOpponent) {
      state = state.copyWith(hostDrawConfirmed: true);
      if (state.guestDrawConfirmed) {
        _applyBothDraws();
      } else {
        state = state.copyWith(message: 'Waiting for opponent to discard…');
        _broadcastIfHost();
      }
      return;
    }

    // Solo / AI opponent: player draw + AI auto-draw.
    final newDeck = [...state.deck];
    final newHand = [...state.playerHand];
    for (final i in state.selectedDiscard.toList()..sort()) {
      if (newDeck.isNotEmpty) newHand[i] = newDeck.removeAt(0);
    }
    final aiDiscard = _aiDiscardIndices(state.aiHand);
    final newAiHand = [...state.aiHand];
    for (final i in aiDiscard) {
      if (newDeck.isNotEmpty) newAiHand[i] = newDeck.removeAt(0);
    }
    state = state.copyWith(
      deck: newDeck,
      playerHand: newHand,
      aiHand: newAiHand,
      selectedDiscard: {},
      selectedAiDiscard: {},
      phase: PokerPhase.betting2,
      message:
          'You drew ${state.selectedDiscard.length}, AI drew ${aiDiscard.length}. Bet, check, or fold?',
      isPlayerTurn: true,
      hostDrawConfirmed: false,
      guestDrawConfirmed: false,
    );
    _broadcastIfHost();
  }

  void confirmAiDraw() {
    if (state.phase != PokerPhase.draw) return;
    if (state.guestDrawConfirmed) return;
    if (!_humanOpponent) return;

    state = state.copyWith(guestDrawConfirmed: true);
    if (state.hostDrawConfirmed) {
      _applyBothDraws();
    } else {
      state = state.copyWith(message: 'Opponent discarded. Waiting for you…');
      _broadcastIfHost();
    }
  }

  void _applyBothDraws() {
    final newDeck = [...state.deck];
    final newHand = [...state.playerHand];
    final hostCount = state.selectedDiscard.length;
    for (final i in state.selectedDiscard.toList()..sort()) {
      if (newDeck.isNotEmpty) newHand[i] = newDeck.removeAt(0);
    }
    final newAiHand = [...state.aiHand];
    final guestCount = state.selectedAiDiscard.length;
    for (final i in state.selectedAiDiscard.toList()..sort()) {
      if (newDeck.isNotEmpty) newAiHand[i] = newDeck.removeAt(0);
    }
    state = state.copyWith(
      deck: newDeck,
      playerHand: newHand,
      aiHand: newAiHand,
      selectedDiscard: {},
      selectedAiDiscard: {},
      phase: PokerPhase.betting2,
      message:
          'Drew $hostCount / $guestCount cards. Bet, check, or fold?',
      isPlayerTurn: true,
      hostDrawConfirmed: false,
      guestDrawConfirmed: false,
    );
    _broadcastIfHost();
  }

  List<int> _aiDiscardIndices(List<int> hand) {
    final result = evaluateHand(hand);
    if (result.rank.index >= HandRank.onePair.index) {
      final ranks = hand.map(rankOf).toList();
      final cnt = <int, int>{};
      for (final r in ranks) {
        cnt[r] = (cnt[r] ?? 0) + 1;
      }
      final keepRanks =
          cnt.entries.where((e) => e.value >= 2).map((e) => e.key).toSet();
      if (keepRanks.isEmpty) return [];
      return [
        for (int i = 0; i < hand.length; i++)
          if (!keepRanks.contains(rankOf(hand[i]))) i
      ];
    }
    final sorted = List.generate(5, (i) => i)
      ..sort((a, b) => rankOf(hand[a]).compareTo(rankOf(hand[b])));
    return sorted.sublist(0, 2);
  }

  void _showdown() {
    if (state.phase != PokerPhase.showdown) return;
    final pResult = evaluateHand(state.playerHand);
    final aResult = evaluateHand(state.aiHand);
    final cmp = pResult.compareTo(aResult);
    String outcome;
    int newPlayerChips = state.playerChips;
    int newAiChips = state.aiChips;
    if (cmp > 0) {
      outcome =
          'You win! ${handRankLabel[pResult.rank]} beats ${handRankLabel[aResult.rank]}';
      newPlayerChips += state.pot;
    } else if (cmp < 0) {
      outcome = 'Opponent wins with ${handRankLabel[aResult.rank]}!';
      newAiChips += state.pot;
    } else {
      outcome = 'Tie! Split pot.';
      final half = state.pot ~/ 2;
      newPlayerChips += half;
      newAiChips += state.pot - half;
    }
    state = state.copyWith(
      playerChips: newPlayerChips,
      aiChips: newAiChips,
      pot: 0,
      phase: PokerPhase.roundOver,
      message: outcome,
      outcome: () => outcome,
    );
    _broadcastIfHost();
  }

  void nextRound() {
    state = _startRound(
      playerChips: state.playerChips,
      aiChips: state.aiChips,
      isMultiplayer: state.isMultiplayer,
      isOpponentAI: state.isOpponentAI,
    );
    _broadcastIfHost();
  }

  void newGame() {
    exitMultiplayerMode();
    state = _startRound(
      playerChips: 500,
      aiChips: 500,
      isMultiplayer: false,
      isOpponentAI: true,
    );
  }
}

final pokerStateProvider =
    NotifierProvider<PokerNotifier, PokerState>(PokerNotifier.new);
