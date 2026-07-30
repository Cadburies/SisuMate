import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/game_lan_service.dart';
import '../../../../services/lan/lan_providers.dart';

final _rng = Random();

enum UnoColor { red, yellow, green, blue, wild }
enum UnoValue { zero, one, two, three, four, five, six, seven, eight, nine, skip, reverse, drawTwo, wild, wildDrawFour }

const colorLabel = {
  UnoColor.red: 'Red', UnoColor.yellow: 'Yellow',
  UnoColor.green: 'Green', UnoColor.blue: 'Blue', UnoColor.wild: 'Wild',
};

const valueLabel = {
  UnoValue.zero: '0', UnoValue.one: '1', UnoValue.two: '2', UnoValue.three: '3',
  UnoValue.four: '4', UnoValue.five: '5', UnoValue.six: '6', UnoValue.seven: '7',
  UnoValue.eight: '8', UnoValue.nine: '9', UnoValue.skip: 'Skip',
  UnoValue.reverse: 'Reverse', UnoValue.drawTwo: '+2',
  UnoValue.wild: 'Wild', UnoValue.wildDrawFour: 'Wild +4',
};

class UnoCard {
  final UnoColor color;
  final UnoValue value;
  const UnoCard(this.color, this.value);

  bool get isWild => color == UnoColor.wild;
  bool get isAction => value == UnoValue.skip || value == UnoValue.reverse ||
      value == UnoValue.drawTwo || value == UnoValue.wild || value == UnoValue.wildDrawFour;

  bool canPlayOn(UnoColor topColor, UnoValue topValue) {
    if (isWild) return true;
    if (color == topColor) return true;
    if (value == topValue) return true;
    return false;
  }

  @override
  String toString() => '${colorLabel[color]} ${valueLabel[value]}';

  Map<String, dynamic> toJson() => {'color': color.name, 'value': value.name};

  factory UnoCard.fromJson(Map<String, dynamic> j) => UnoCard(
        UnoColor.values.byName(j['color'] as String),
        UnoValue.values.byName(j['value'] as String),
      );
}

List<UnoCard> _buildDeck() {
  final deck = <UnoCard>[];
  for (final c in [UnoColor.red, UnoColor.yellow, UnoColor.green, UnoColor.blue]) {
    deck.add(UnoCard(c, UnoValue.zero));
    for (final v in UnoValue.values) {
      if (v == UnoValue.zero || v == UnoValue.wild || v == UnoValue.wildDrawFour) continue;
      deck.add(UnoCard(c, v));
      deck.add(UnoCard(c, v)); // two of each non-zero
    }
  }
  for (int i = 0; i < 4; i++) {
    deck.add(const UnoCard(UnoColor.wild, UnoValue.wild));
    deck.add(const UnoCard(UnoColor.wild, UnoValue.wildDrawFour));
  }
  return deck..shuffle(_rng);
}

enum UnoPhase { playing, choosingColor, gameOver }

class UnoState {
  final List<UnoCard> deck;
  final List<UnoCard> playerHand;
  final List<UnoCard> aiHand;
  final List<UnoCard> discardPile;
  final UnoColor currentColor;
  final UnoValue currentValue;
  final bool isPlayerTurn;
  final UnoPhase phase;
  final String message;
  final String? winner;
  final int? selectedCardIndex; // active role's selected card index
  // GAME1: absolute host/guest model, same shape as checkers/yatzy/backgammon
  // — the host is always the "player" role (isPlayerTurn: true means host's
  // turn), the opponent always the "ai" role, whether that's the local AI
  // (solo, isOpponentAI: true) or a real remote guest (multiplayer,
  // isOpponentAI: false).
  final bool isMultiplayer;
  final bool isOpponentAI;

  const UnoState({
    required this.deck,
    required this.playerHand,
    required this.aiHand,
    required this.discardPile,
    required this.currentColor,
    required this.currentValue,
    required this.isPlayerTurn,
    required this.phase,
    required this.message,
    this.winner,
    this.selectedCardIndex,
    this.isMultiplayer = false,
    this.isOpponentAI = true,
  });

  UnoState copyWith({
    List<UnoCard>? deck,
    List<UnoCard>? playerHand,
    List<UnoCard>? aiHand,
    List<UnoCard>? discardPile,
    UnoColor? currentColor,
    UnoValue? currentValue,
    bool? isPlayerTurn,
    UnoPhase? phase,
    String? message,
    String? Function()? winner,
    int? Function()? selectedCardIndex,
    bool? isMultiplayer,
    bool? isOpponentAI,
  }) =>
      UnoState(
        deck: deck ?? this.deck,
        playerHand: playerHand ?? this.playerHand,
        aiHand: aiHand ?? this.aiHand,
        discardPile: discardPile ?? this.discardPile,
        currentColor: currentColor ?? this.currentColor,
        currentValue: currentValue ?? this.currentValue,
        isPlayerTurn: isPlayerTurn ?? this.isPlayerTurn,
        phase: phase ?? this.phase,
        message: message ?? this.message,
        winner: winner != null ? winner() : this.winner,
        selectedCardIndex: selectedCardIndex != null ? selectedCardIndex() : this.selectedCardIndex,
        isMultiplayer: isMultiplayer ?? this.isMultiplayer,
        isOpponentAI: isOpponentAI ?? this.isOpponentAI,
      );

  Map<String, dynamic> toJson() => {
        'deck': deck.map((c) => c.toJson()).toList(),
        'playerHand': playerHand.map((c) => c.toJson()).toList(),
        'aiHand': aiHand.map((c) => c.toJson()).toList(),
        'discardPile': discardPile.map((c) => c.toJson()).toList(),
        'currentColor': currentColor.name,
        'currentValue': currentValue.name,
        'isPlayerTurn': isPlayerTurn,
        'phase': phase.name,
        'message': message,
        'winner': winner,
        'selectedCardIndex': selectedCardIndex,
        'isMultiplayer': isMultiplayer,
        'isOpponentAI': isOpponentAI,
      };

  factory UnoState.fromJson(Map<String, dynamic> j) => UnoState(
        deck: (j['deck'] as List)
            .map((e) => UnoCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        playerHand: (j['playerHand'] as List)
            .map((e) => UnoCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        aiHand: (j['aiHand'] as List)
            .map((e) => UnoCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        discardPile: (j['discardPile'] as List)
            .map((e) => UnoCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentColor: UnoColor.values.byName(j['currentColor'] as String),
        currentValue: UnoValue.values.byName(j['currentValue'] as String),
        isPlayerTurn: j['isPlayerTurn'] as bool,
        phase: UnoPhase.values.byName(j['phase'] as String),
        message: j['message'] as String,
        winner: j['winner'] as String?,
        selectedCardIndex: j['selectedCardIndex'] as int?,
        isMultiplayer: j['isMultiplayer'] as bool? ?? false,
        isOpponentAI: j['isOpponentAI'] as bool? ?? true,
      );
}

class UnoNotifier extends Notifier<UnoState> {
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
  UnoState build() {
    ref.onDispose(() {
      _remoteSub?.cancel();
      _moveSub?.cancel();
      _leaveSub?.cancel();
    });
    return _dealGame();
  }

  // ── Multiplayer setup (mirrors checkers/backgammon/cribbage's absolute
  // host/guest model — Uno is strictly 2-role, no player-id roster needed) ──

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
    state = _dealGame(
      isMultiplayer: true,
      isOpponentAI: opponent?.isAI ?? true,
    );
    // No separate startGame()/determineStarter() step to naturally
    // re-broadcast a couple of seconds later (same gap found live in
    // Yatzy/Checkers/Backgammon/Cribbage) — delay briefly so the guest's
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
      state = UnoState.fromJson(json);
    });
    _leaveSub = lan.playerLeaves.listen((peerId) {
      if (peerId == 'host') _handleHostDisconnect(generation);
    });

    state = UnoState(
      deck: const [],
      playerHand: const [],
      aiHand: const [],
      discardPile: const [],
      currentColor: UnoColor.wild,
      currentValue: UnoValue.wild,
      isPlayerTurn: true,
      phase: UnoPhase.playing,
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
      phase: UnoPhase.gameOver,
      message: 'Connection to host lost. Game ended.',
    );
  }

  // ── Host-side remote move handler ─────────────────────────────────────────

  void _applyRemoteMove(
      ({String peerId, String action, Map<String, dynamic> data}) move) {
    switch (move.action) {
      case 'selectCard':
        selectCard(move.data['index'] as int);
      case 'playSelected':
        playSelected();
      case 'chooseColor':
        chooseColor(UnoColor.values.byName(move.data['color'] as String));
      case 'drawCard':
        drawCard();
    }
  }

  void _broadcastIfHost() {
    if (_isHostMode) {
      ref.read(gameLanServiceProvider).broadcastState(state.toJson());
    }
  }

  // ── Disconnect handling ───────────────────────────────────────────────────
  //
  // Uno has no player-id roster (fixed 2-role model) — any disconnect while
  // hosting can only be the one real guest, so it simply ends the game.
  void _handleDisconnect(String peerId) {
    state = state.copyWith(
      phase: UnoPhase.gameOver,
      message: 'Opponent disconnected. Game ended.',
    );
    _broadcastIfHost();
  }

  UnoState _dealGame({bool isMultiplayer = false, bool isOpponentAI = true}) {
    var deck = _buildDeck();
    final playerHand = deck.sublist(0, 7);
    final aiHand = deck.sublist(7, 14);
    deck = deck.sublist(14);
    // Find first non-wild card for discard pile
    int startIdx = deck.indexWhere((c) => !c.isWild);
    if (startIdx == -1) startIdx = 0;
    final startCard = deck[startIdx];
    deck.removeAt(startIdx);
    return UnoState(
      deck: deck,
      playerHand: playerHand,
      aiHand: aiHand,
      discardPile: [startCard],
      currentColor: startCard.color,
      currentValue: startCard.value,
      isPlayerTurn: true,
      phase: UnoPhase.playing,
      message: 'Your turn! Play a card or draw.',
      isMultiplayer: isMultiplayer,
      isOpponentAI: isOpponentAI,
    );
  }

  // Acts on behalf of whichever role's turn it currently is
  // (state.isPlayerTurn), not hardcoded "the human" — in solo mode the AI's
  // turn never reaches these methods (it goes through _aiTurn instead), but
  // in multiplayer the guest's forwarded taps run through here too while
  // isPlayerTurn is false. Same fix shape as checkers/backgammon/cribbage.

  void selectCard(int index) {
    if (state.phase != UnoPhase.playing) return;
    final isHostRole = state.isPlayerTurn;
    final hand = isHostRole ? state.playerHand : state.aiHand;
    if (index < 0 || index >= hand.length) return;
    final card = hand[index];
    if (!card.canPlayOn(state.currentColor, state.currentValue)) {
      state = state.copyWith(
        selectedCardIndex: () => null,
        message: 'That card can\'t be played. Draw or pick another.',
      );
      _broadcastIfHost();
      return;
    }
    state = state.copyWith(selectedCardIndex: () => index);
    _broadcastIfHost();
  }

  void playSelected() {
    final idx = state.selectedCardIndex;
    if (idx == null) return;
    final isHostRole = state.isPlayerTurn;
    final hand = isHostRole ? state.playerHand : state.aiHand;
    if (idx < 0 || idx >= hand.length) return;
    final card = hand[idx];
    if (!card.canPlayOn(state.currentColor, state.currentValue)) return;

    final newHand = [...hand]..removeAt(idx);
    if (newHand.isEmpty) {
      final newDiscard = [...state.discardPile, card];
      state = state.copyWith(
        playerHand: isHostRole ? newHand : state.playerHand,
        aiHand: isHostRole ? state.aiHand : newHand,
        discardPile: newDiscard,
        phase: UnoPhase.gameOver,
        message: isHostRole ? 'UNO! You win! 🎉' : 'UNO! Opponent wins!',
        winner: () => isHostRole ? 'You' : 'AI',
        selectedCardIndex: () => null,
      );
      _broadcastIfHost();
      return;
    }

    if (card.isWild) {
      state = state.copyWith(
        playerHand: isHostRole ? newHand : state.playerHand,
        aiHand: isHostRole ? state.aiHand : newHand,
        discardPile: [...state.discardPile, card],
        currentValue: card.value,
        phase: UnoPhase.choosingColor,
        message: 'Choose a color!',
        selectedCardIndex: () => null,
      );
      _broadcastIfHost();
      return;
    }

    _applyCard(card, newHand, isHostRole);
  }

  void _applyCard(UnoCard card, List<UnoCard> newHand, bool isHostRole) {
    var deck = [...state.deck];
    var otherHand = isHostRole ? [...state.aiHand] : [...state.playerHand];
    var discard = [...state.discardPile, card];

    String msg;
    bool otherGetsSkipped = false;

    switch (card.value) {
      case UnoValue.skip:
        msg = 'Opponent is skipped!';
        otherGetsSkipped = true;
      case UnoValue.reverse:
        msg = 'Reversed! (Opponent skipped in 2-player)';
        otherGetsSkipped = true;
      case UnoValue.drawTwo:
        for (int i = 0; i < 2; i++) {
          if (deck.isEmpty) { deck = discard.sublist(0, discard.length - 1)..shuffle(_rng); discard = [discard.last]; }
          if (deck.isNotEmpty) otherHand.add(deck.removeAt(0));
        }
        msg = 'Opponent draws 2 and is skipped!';
        otherGetsSkipped = true;
      default:
        msg = newHand.length == 1 ? 'UNO! Opponent\'s turn.' : 'Opponent\'s turn.';
    }

    state = state.copyWith(
      playerHand: isHostRole ? newHand : otherHand,
      aiHand: isHostRole ? otherHand : newHand,
      deck: deck,
      discardPile: discard,
      currentColor: card.color,
      currentValue: card.value,
      isPlayerTurn: !isHostRole,
      message: msg,
      selectedCardIndex: () => null,
    );
    _broadcastIfHost();

    if (otherGetsSkipped) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (state.phase == UnoPhase.gameOver) return;
        state = state.copyWith(isPlayerTurn: isHostRole, message: 'Your turn!');
        _broadcastIfHost();
      });
    } else {
      final isLocalAiTurn =
          !state.isPlayerTurn && (!state.isMultiplayer || state.isOpponentAI);
      if (isLocalAiTurn) {
        Future.delayed(const Duration(milliseconds: 700), _aiTurn);
      }
    }
  }

  void chooseColor(UnoColor color) {
    if (state.phase != UnoPhase.choosingColor) return;
    // The role choosing the color is whoever played the wild — playSelected's
    // wild branch didn't touch isPlayerTurn, so it's preserved from before.
    final isHostRole = state.isPlayerTurn;
    final isWildDraw4 = state.discardPile.last.value == UnoValue.wildDrawFour;
    var deck = [...state.deck];
    var otherHand = isHostRole ? [...state.aiHand] : [...state.playerHand];
    var discard = [...state.discardPile];
    bool otherGetsSkipped = false;

    if (isWildDraw4) {
      for (int i = 0; i < 4; i++) {
        if (deck.isEmpty) { deck = discard.sublist(0, discard.length - 1)..shuffle(_rng); discard = [discard.last]; }
        if (deck.isNotEmpty) otherHand.add(deck.removeAt(0));
      }
      otherGetsSkipped = true;
    }

    state = state.copyWith(
      deck: deck,
      playerHand: isHostRole ? state.playerHand : otherHand,
      aiHand: isHostRole ? otherHand : state.aiHand,
      discardPile: discard,
      currentColor: color,
      phase: UnoPhase.playing,
      isPlayerTurn: !isHostRole,
      message: isWildDraw4
          ? 'Opponent draws 4! ${colorLabel[color]} chosen.'
          : '${colorLabel[color]} chosen. Opponent\'s turn.',
    );
    _broadcastIfHost();

    if (otherGetsSkipped) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (state.phase == UnoPhase.gameOver) return;
        state = state.copyWith(isPlayerTurn: isHostRole, message: 'Your turn!');
        _broadcastIfHost();
      });
    } else {
      final isLocalAiTurn =
          !state.isPlayerTurn && (!state.isMultiplayer || state.isOpponentAI);
      if (isLocalAiTurn) {
        Future.delayed(const Duration(milliseconds: 700), _aiTurn);
      }
    }
  }

  void drawCard() {
    if (state.phase != UnoPhase.playing) return;
    final isHostRole = state.isPlayerTurn;
    var deck = [...state.deck];
    var discard = [...state.discardPile];
    if (deck.isEmpty) {
      deck = discard.sublist(0, discard.length - 1)..shuffle(_rng);
      discard = [discard.last];
    }
    if (deck.isEmpty) return;
    final drawn = deck.removeAt(0);
    final hand = isHostRole ? state.playerHand : state.aiHand;
    final newHand = [...hand, drawn];
    // Auto-play if drawable card matches
    if (drawn.canPlayOn(state.currentColor, state.currentValue)) {
      state = state.copyWith(
        deck: deck,
        discardPile: discard,
        playerHand: isHostRole ? newHand : state.playerHand,
        aiHand: isHostRole ? state.aiHand : newHand,
        message: isHostRole
            ? 'Drew ${drawn.toString()} — tap to play it or pass.'
            : 'Opponent drew a card.',
        selectedCardIndex: () => isHostRole ? newHand.length - 1 : null,
      );
      _broadcastIfHost();
    } else {
      state = state.copyWith(
        deck: deck,
        discardPile: discard,
        playerHand: isHostRole ? newHand : state.playerHand,
        aiHand: isHostRole ? state.aiHand : newHand,
        isPlayerTurn: !isHostRole,
        message: isHostRole
            ? 'Drew ${drawn.toString()}. Opponent\'s turn.'
            : 'Opponent drew. Your turn!',
      );
      _broadcastIfHost();
      final isLocalAiTurn =
          !state.isPlayerTurn && (!state.isMultiplayer || state.isOpponentAI);
      if (isLocalAiTurn) {
        Future.delayed(const Duration(milliseconds: 700), _aiTurn);
      }
    }
  }

  void _aiTurn() {
    if (state.phase == UnoPhase.gameOver || state.isPlayerTurn) return;
    var deck = [...state.deck];
    var aiHand = [...state.aiHand];
    var discard = [...state.discardPile];

    // Find a playable card
    final playable = aiHand.where(
        (c) => c.canPlayOn(state.currentColor, state.currentValue)).toList();

    if (playable.isEmpty) {
      // Draw
      if (deck.isEmpty) {
        deck = discard.sublist(0, discard.length - 1)..shuffle(_rng);
        discard = [discard.last];
      }
      if (deck.isNotEmpty) aiHand.add(deck.removeAt(0));
      state = state.copyWith(
        deck: deck,
        aiHand: aiHand,
        discardPile: discard,
        isPlayerTurn: true,
        message: 'AI drew a card. Your turn!',
      );
      _broadcastIfHost();
      return;
    }

    // Prefer action cards, then wild last
    playable.sort((a, b) {
      if (a.isWild && !b.isWild) return 1;
      if (!a.isWild && b.isWild) return -1;
      if (a.isAction && !b.isAction) return -1;
      if (!a.isAction && b.isAction) return 1;
      return 0;
    });

    final card = playable.first;
    aiHand.remove(card);

    if (aiHand.isEmpty) {
      state = state.copyWith(
        aiHand: aiHand,
        discardPile: [...discard, card],
        phase: UnoPhase.gameOver,
        message: 'AI plays ${card.toString()}. UNO! AI wins!',
        winner: () => 'AI',
      );
      _broadcastIfHost();
      return;
    }

    // Wild: AI picks most frequent color in hand
    UnoColor newColor = card.color;
    if (card.isWild) {
      final colorCount = <UnoColor, int>{};
      for (final c in aiHand) {
        if (!c.isWild) colorCount[c.color] = (colorCount[c.color] ?? 0) + 1;
      }
      if (colorCount.isNotEmpty) {
        newColor = colorCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      } else {
        newColor = UnoColor.values[_rng.nextInt(4)];
      }
    }

    bool playerGetsSkipped = false;
    String msg = aiHand.length == 1 ? 'AI plays ${card.toString()} — UNO!' : 'AI plays ${card.toString()}.';

    switch (card.value) {
      case UnoValue.skip:
      case UnoValue.reverse:
        msg += ' You are skipped!';
        playerGetsSkipped = true;
      case UnoValue.drawTwo:
        for (int i = 0; i < 2; i++) {
          if (deck.isEmpty) { deck = discard.sublist(0, discard.length - 1)..shuffle(_rng); discard = [discard.last]; }
          if (deck.isNotEmpty) state.playerHand; // draw happens below
        }
        final newPlayerHand = [...state.playerHand];
        for (int i = 0; i < 2; i++) {
          if (deck.isEmpty) break;
          newPlayerHand.add(deck.removeAt(0));
        }
        state = state.copyWith(
          deck: deck, aiHand: aiHand, discardPile: [...discard, card],
          playerHand: newPlayerHand,
          currentColor: card.color, currentValue: card.value,
          isPlayerTurn: false,
          message: 'AI plays +2! You draw 2. AI\'s turn again.',
        );
        _broadcastIfHost();
        Future.delayed(const Duration(milliseconds: 700), _aiTurn);
        return;
      case UnoValue.wildDrawFour:
        final newPlayerHand = [...state.playerHand];
        for (int i = 0; i < 4; i++) {
          if (deck.isEmpty) break;
          newPlayerHand.add(deck.removeAt(0));
        }
        msg = 'AI plays Wild +4! You draw 4. AI chooses ${colorLabel[newColor]}.';
        state = state.copyWith(
          deck: deck, aiHand: aiHand, discardPile: [...discard, card],
          playerHand: newPlayerHand,
          currentColor: newColor, currentValue: card.value,
          isPlayerTurn: false,
          message: '$msg AI\'s turn again.',
        );
        _broadcastIfHost();
        Future.delayed(const Duration(milliseconds: 700), _aiTurn);
        return;
      default:
        break;
    }

    if (card.isWild) {
      msg += ' Chooses ${colorLabel[newColor]}.';
    }

    state = state.copyWith(
      deck: deck, aiHand: aiHand, discardPile: [...discard, card],
      currentColor: newColor, currentValue: card.value,
      isPlayerTurn: !playerGetsSkipped,
      message: playerGetsSkipped ? '$msg Your turn (after skip).' : '$msg Your turn!',
    );
    _broadcastIfHost();

    if (playerGetsSkipped) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (state.phase == UnoPhase.gameOver) return;
        state = state.copyWith(isPlayerTurn: false, message: 'AI\'s turn again.');
        _broadcastIfHost();
        Future.delayed(const Duration(milliseconds: 700), _aiTurn);
      });
    }
  }

  void newGame() {
    exitMultiplayerMode();
    state = _dealGame();
  }
}

final unoStateProvider = NotifierProvider<UnoNotifier, UnoState>(UnoNotifier.new);
