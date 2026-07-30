import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/game_lan_service.dart';
import '../../../../services/lan/lan_providers.dart';

final _rng = Random();

// Board: indices 0–23 = points 1–24.
// Human (white) moves point 24→1, i.e. index 23→0. Home board: indices 0–5.
// AI (black) moves point 1→24, i.e. index 0→23. Home board: indices 18–23.
// board[i] > 0 : human pieces on point i+1
// board[i] < 0 : AI pieces on point i+1

List<int> _initialBoard() {
  final b = List.filled(24, 0);
  // Human (white)
  b[23] = 2;   // point 24
  b[12] = 5;   // point 13
  b[7] = 3;    // point 8
  b[5] = 5;    // point 6
  // AI (black)
  b[0] = -2;   // point 1
  b[11] = -5;  // point 12
  b[16] = -3;  // point 17
  b[18] = -5;  // point 19
  return b;
}

enum BgPhase { rolling, moving, gameOver, doubleOffered }

class BackgammonState {
  final List<int> board;       // 24 points
  final int humanBar;
  final int aiBar;
  final int humanBornOff;
  final int aiBornOff;
  final List<int> dice;        // current roll (may have duplicates for doubles)
  final List<int> movesLeft;   // remaining die values to use this turn
  final bool isHumanTurn;
  final int? selectedPoint;    // -1 = bar, 0–23 = point index, null = none
  final BgPhase phase;
  final String message;
  // GAME1: absolute host/guest model, same shape as checkers/yatzy — the
  // host is always the human/white role (isHumanTurn: true means host's
  // turn), the opponent is always the AI/black role, whether that's the
  // local AI (solo, isOpponentAI: true) or a real remote guest (multiplayer,
  // isOpponentAI: false).
  final bool isMultiplayer;
  final bool isOpponentAI;
  // GB7 doubling cube — stake multiplies on accept; owner may redouble.
  final int cubeValue; // 1,2,4,8,16,32,64
  final bool? cubeOwnerIsHuman; // null = centered (either may double)
  final bool? doubleOfferedByHuman; // set while phase == doubleOffered

  const BackgammonState({
    required this.board,
    required this.humanBar,
    required this.aiBar,
    required this.humanBornOff,
    required this.aiBornOff,
    required this.dice,
    required this.movesLeft,
    required this.isHumanTurn,
    required this.selectedPoint,
    required this.phase,
    required this.message,
    this.isMultiplayer = false,
    this.isOpponentAI = true,
    this.cubeValue = 1,
    this.cubeOwnerIsHuman,
    this.doubleOfferedByHuman,
  });

  /// Whether the role whose turn it is may offer a double (before rolling).
  bool get canOfferDouble {
    if (phase != BgPhase.rolling) return false;
    if (cubeValue >= 64) return false;
    // Centered: either player. Owned: only the owner may redouble.
    if (cubeOwnerIsHuman == null) return true;
    return cubeOwnerIsHuman == isHumanTurn;
  }

  BackgammonState copyWith({
    List<int>? board,
    int? humanBar,
    int? aiBar,
    int? humanBornOff,
    int? aiBornOff,
    List<int>? dice,
    List<int>? movesLeft,
    bool? isHumanTurn,
    int? Function()? selectedPoint,
    BgPhase? phase,
    String? message,
    bool? isMultiplayer,
    bool? isOpponentAI,
    int? cubeValue,
    bool? Function()? cubeOwnerIsHuman,
    bool? Function()? doubleOfferedByHuman,
  }) =>
      BackgammonState(
        board: board ?? this.board,
        humanBar: humanBar ?? this.humanBar,
        aiBar: aiBar ?? this.aiBar,
        humanBornOff: humanBornOff ?? this.humanBornOff,
        aiBornOff: aiBornOff ?? this.aiBornOff,
        dice: dice ?? this.dice,
        movesLeft: movesLeft ?? this.movesLeft,
        isHumanTurn: isHumanTurn ?? this.isHumanTurn,
        selectedPoint: selectedPoint != null ? selectedPoint() : this.selectedPoint,
        phase: phase ?? this.phase,
        message: message ?? this.message,
        isMultiplayer: isMultiplayer ?? this.isMultiplayer,
        isOpponentAI: isOpponentAI ?? this.isOpponentAI,
        cubeValue: cubeValue ?? this.cubeValue,
        cubeOwnerIsHuman: cubeOwnerIsHuman != null
            ? cubeOwnerIsHuman()
            : this.cubeOwnerIsHuman,
        doubleOfferedByHuman: doubleOfferedByHuman != null
            ? doubleOfferedByHuman()
            : this.doubleOfferedByHuman,
      );

  Map<String, dynamic> toJson() => {
        'board': board,
        'humanBar': humanBar,
        'aiBar': aiBar,
        'humanBornOff': humanBornOff,
        'aiBornOff': aiBornOff,
        'dice': dice,
        'movesLeft': movesLeft,
        'isHumanTurn': isHumanTurn,
        'selectedPoint': selectedPoint,
        'phase': phase.name,
        'message': message,
        'isMultiplayer': isMultiplayer,
        'isOpponentAI': isOpponentAI,
        'cubeValue': cubeValue,
        'cubeOwnerIsHuman': cubeOwnerIsHuman,
        'doubleOfferedByHuman': doubleOfferedByHuman,
      };

  factory BackgammonState.fromJson(Map<String, dynamic> j) => BackgammonState(
        board: (j['board'] as List).cast<int>(),
        humanBar: j['humanBar'] as int,
        aiBar: j['aiBar'] as int,
        humanBornOff: j['humanBornOff'] as int,
        aiBornOff: j['aiBornOff'] as int,
        dice: (j['dice'] as List).cast<int>(),
        movesLeft: (j['movesLeft'] as List).cast<int>(),
        isHumanTurn: j['isHumanTurn'] as bool,
        selectedPoint: j['selectedPoint'] as int?,
        phase: BgPhase.values.byName(j['phase'] as String),
        message: j['message'] as String,
        isMultiplayer: j['isMultiplayer'] as bool? ?? false,
        isOpponentAI: j['isOpponentAI'] as bool? ?? true,
        cubeValue: j['cubeValue'] as int? ?? 1,
        cubeOwnerIsHuman: j['cubeOwnerIsHuman'] as bool?,
        doubleOfferedByHuman: j['doubleOfferedByHuman'] as bool?,
      );

  bool humanAllHome() {
    for (int i = 6; i < 24; i++) {
      if (board[i] > 0) return false;
    }
    return humanBar == 0;
  }

  bool aiAllHome() {
    for (int i = 0; i < 18; i++) {
      if (board[i] < 0) return false;
    }
    return aiBar == 0;
  }
}

// ── Move validation helpers ───────────────────────────────────────────────────

/// Returns list of valid destination indices for human moving from [from].
/// [from] == -1 means coming off the bar.
List<int> validHumanMoves(BackgammonState s, int from, int die) {
  if (s.movesLeft.isEmpty || !s.movesLeft.contains(die)) return [];
  final board = s.board;

  if (s.humanBar > 0 && from != -1) return []; // must enter from bar first

  if (from == -1) {
    // Entering from bar: land on point (25 - die) = index (24 - die)
    final dest = 24 - die;
    if (dest < 0 || dest > 23) return [];
    if (board[dest] <= -2) return []; // blocked by AI
    return [dest];
  }

  final dest = from - die;
  if (s.humanAllHome() && dest < 0) {
    // Exact bear-off (dest == -1) is always allowed. An overshoot
    // (dest < -1, i.e. die > exact needed) is only allowed when no checker
    // remains on a higher point — otherwise that checker must move/bear off
    // first (GB8: this used to accept any overshoot unconditionally).
    if (dest < -1) {
      for (int i = from + 1; i <= 5; i++) {
        if (board[i] > 0) return [];
      }
    }
    return [-2]; // -2 = bear off
  }
  if (dest < 0) return [];
  if (board[dest] <= -2) return []; // blocked
  return [dest];
}

List<int> validAiMoves(BackgammonState s, int from, int die) {
  if (s.movesLeft.isEmpty || !s.movesLeft.contains(die)) return [];
  final board = s.board;

  if (s.aiBar > 0 && from != -1) return [];

  if (from == -1) {
    final dest = die - 1; // entering: point die = index die-1
    if (dest < 0 || dest > 23) return [];
    if (board[dest] >= 2) return [];
    return [dest];
  }

  final dest = from + die;
  if (s.aiAllHome() && dest > 23) {
    // Exact bear-off (dest == 24) is always allowed. An overshoot
    // (dest > 24) is only allowed when no checker remains further back
    // (lower index within the home board) — mirrors the human check above.
    if (dest > 24) {
      for (int i = 18; i < from; i++) {
        if (board[i] < 0) return [];
      }
    }
    return [-2]; // bear off
  }
  if (dest > 23) return [];
  if (board[dest] >= 2) return [];
  return [dest];
}

class BackgammonNotifier extends Notifier<BackgammonState> {
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
  BackgammonState build() {
    ref.onDispose(() {
      _remoteSub?.cancel();
      _moveSub?.cancel();
      _leaveSub?.cancel();
    });
    return BackgammonState(
      board: _initialBoard(),
      humanBar: 0,
      aiBar: 0,
      humanBornOff: 0,
      aiBornOff: 0,
      dice: [],
      movesLeft: [],
      isHumanTurn: true,
      selectedPoint: null,
      phase: BgPhase.rolling,
      message: 'Tap "Roll" to start your turn.',
    );
  }

  // ── Multiplayer setup (mirrors checkers/logic.dart's absolute host/guest
  // model — Backgammon is strictly 2-role, no player-id roster needed) ──────

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
    state = BackgammonState(
      board: _initialBoard(),
      humanBar: 0,
      aiBar: 0,
      humanBornOff: 0,
      aiBornOff: 0,
      dice: [],
      movesLeft: [],
      isHumanTurn: true,
      selectedPoint: null,
      phase: BgPhase.rolling,
      message: 'Game ready. Starting...',
      isMultiplayer: true,
      isOpponentAI: opponent?.isAI ?? true,
    );
    // No startGame()/determineStarter() step to naturally re-broadcast a
    // couple of seconds later (same gap found live in Yatzy/Checkers) — delay
    // briefly so the guest's initClientMode() subscription has attached
    // before this fires, instead of it being stuck on its own default forever.
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
      state = BackgammonState.fromJson(json);
    });
    _leaveSub = lan.playerLeaves.listen((peerId) {
      if (peerId == 'host') _handleHostDisconnect(generation);
    });

    state = BackgammonState(
      board: _initialBoard(),
      humanBar: 0,
      aiBar: 0,
      humanBornOff: 0,
      aiBornOff: 0,
      dice: [],
      movesLeft: [],
      isHumanTurn: true,
      selectedPoint: null,
      phase: BgPhase.rolling,
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
      phase: BgPhase.gameOver,
      message: 'Connection to host lost. Game ended.',
    );
  }

  // ── Host-side remote move handler ─────────────────────────────────────────

  void _applyRemoteMove(
      ({String peerId, String action, Map<String, dynamic> data}) move) {
    switch (move.action) {
      case 'roll':
        roll();
      case 'selectPoint':
        selectPoint(move.data['pointIdx'] as int);
      case 'bearOff':
        bearOff();
      case 'passTurn':
        passTurn();
      case 'offerDouble':
        offerDouble();
      case 'acceptDouble':
        acceptDouble();
      case 'declineDouble':
        declineDouble();
    }
  }

  void _broadcastIfHost() {
    if (_isHostMode) {
      ref.read(gameLanServiceProvider).broadcastState(state.toJson());
    }
  }

  // ── Disconnect handling ───────────────────────────────────────────────────
  //
  // Backgammon has no player-id roster (fixed 2-role model) — any disconnect
  // while hosting can only be the one real guest, so it simply ends the game.
  void _handleDisconnect(String peerId) {
    state = state.copyWith(
      phase: BgPhase.gameOver,
      message: 'Opponent disconnected. Game ended.',
    );
    _broadcastIfHost();
  }

  // ── Game actions ────────────────────────────────────────────────────────────
  //
  // All of these act on behalf of whichever role's turn it currently is
  // (state.isHumanTurn), not hardcoded "the human" — in solo mode those are
  // always the same thing (the AI's turn never reaches these methods, it
  // goes through _aiMove instead), but in multiplayer the guest's actions are
  // forwarded here too via _applyRemoteMove while isHumanTurn is false. This
  // mirrors the fix found live in checkers/logic.dart's selectCell/
  // _executeMove — same bug class, same shape (single shared entry point
  // serving both roles), applied here proactively before shipping.

  // ── GB7 doubling cube ─────────────────────────────────────────────────────

  void offerDouble() {
    if (!state.canOfferDouble) return;
    final isHumanRole = state.isHumanTurn;
    state = state.copyWith(
      phase: BgPhase.doubleOffered,
      doubleOfferedByHuman: () => isHumanRole,
      message: isHumanRole
          ? 'Double offered (${state.cubeValue}→${state.cubeValue * 2}). Waiting…'
          : 'Opponent offers double to ${state.cubeValue * 2}. Accept or decline?',
    );
    _broadcastIfHost();

    // Local AI responds when a human offered against AI.
    final aiMustRespond = isHumanRole &&
        (!state.isMultiplayer || state.isOpponentAI);
    if (aiMustRespond) {
      Future.delayed(const Duration(milliseconds: 700), _aiRespondToDouble);
    }
  }

  void acceptDouble() {
    if (state.phase != BgPhase.doubleOffered) return;
    final offeredByHuman = state.doubleOfferedByHuman ?? true;
    // Acceptor becomes owner and may redouble later.
    final newOwnerIsHuman = !offeredByHuman;
    final newValue = (state.cubeValue * 2).clamp(1, 64);
    state = state.copyWith(
      cubeValue: newValue,
      cubeOwnerIsHuman: () => newOwnerIsHuman,
      doubleOfferedByHuman: () => null,
      phase: BgPhase.rolling,
      // Offerer's turn continues — they still need to roll.
      isHumanTurn: offeredByHuman,
      message: 'Double accepted — cube is $newValue. Roll dice.',
    );
    _broadcastIfHost();

    final isLocalAiTurn =
        !state.isHumanTurn && (!state.isMultiplayer || state.isOpponentAI);
    if (isLocalAiTurn) {
      Future.delayed(const Duration(milliseconds: 400), roll);
    }
  }

  void declineDouble() {
    if (state.phase != BgPhase.doubleOffered) return;
    final offeredByHuman = state.doubleOfferedByHuman ?? true;
    final stake = state.cubeValue;
    state = state.copyWith(
      phase: BgPhase.gameOver,
      doubleOfferedByHuman: () => null,
      // Mark winner via born-off for overlay: set offerer to 15.
      humanBornOff: offeredByHuman ? 15 : state.humanBornOff,
      aiBornOff: offeredByHuman ? state.aiBornOff : 15,
      message: offeredByHuman
          ? 'Opponent declined the double. You win ($stake pt)!'
          : 'You declined. Opponent wins ($stake pt).',
    );
    _broadcastIfHost();
  }

  void _aiRespondToDouble() {
    if (state.phase != BgPhase.doubleOffered) return;
    // Accept unless the human is clearly ahead on bearing off.
    final humanLead = state.humanBornOff - state.aiBornOff;
    if (humanLead >= 6) {
      declineDouble();
    } else {
      acceptDouble();
    }
  }

  void _maybeAiOfferDouble() {
    if (!state.canOfferDouble) return;
    if (state.isHumanTurn) return;
    if (state.isMultiplayer && !state.isOpponentAI) return;
    final aiLead = state.aiBornOff - state.humanBornOff;
    // Offer when ahead by a few borne-off checkers (~20% of the time).
    if (aiLead >= 3 && _rng.nextInt(5) == 0) {
      offerDouble();
    }
  }

  void roll() {
    if (state.phase != BgPhase.rolling) return;
    // Solo AI may offer a double before rolling.
    if (!state.isHumanTurn &&
        (!state.isMultiplayer || state.isOpponentAI) &&
        state.canOfferDouble) {
      _maybeAiOfferDouble();
      if (state.phase == BgPhase.doubleOffered) return;
    }

    final d1 = _rng.nextInt(6) + 1;
    final d2 = _rng.nextInt(6) + 1;
    final dice = [d1, d2];
    final moves = d1 == d2 ? [d1, d1, d1, d1] : [d1, d2];
    final isHumanRole = state.isHumanTurn;
    state = state.copyWith(
      dice: dice,
      movesLeft: moves,
      phase: BgPhase.moving,
      message: isHumanRole
          ? 'Rolled $d1, $d2. Select a piece to move.'
          : 'AI rolled $d1, $d2.',
    );
    _broadcastIfHost();

    // A remote human opponent plays its own turn via its own device's taps —
    // only fire the local AI when there's no such opponent to wait for
    // (solo, or a multiplayer seat deliberately filled with a local AI).
    final isLocalAiTurn =
        !isHumanRole && (!state.isMultiplayer || state.isOpponentAI);
    if (isLocalAiTurn) {
      Future.delayed(const Duration(milliseconds: 600), _aiMove);
      return;
    }

    // Whoever's turn it actually is (host or a real guest) — if they have no
    // valid move at all for this roll, auto-pass after a short beat.
    if (!_hasAnyMove(state, isHumanRole)) {
      state = state.copyWith(
        message: isHumanRole
            ? 'No valid moves for this roll — passing.'
            : 'Opponent has no valid moves — passing.',
      );
      _broadcastIfHost();
      Future.delayed(const Duration(milliseconds: 1200), () {
        state = state.copyWith(
          movesLeft: [],
          selectedPoint: () => null,
          isHumanTurn: !isHumanRole,
          phase: BgPhase.rolling,
          message: isHumanRole ? "Opponent's turn." : 'Your turn. Tap Roll.',
        );
        _broadcastIfHost();
        final nextIsLocalAi = !state.isHumanTurn &&
            (!state.isMultiplayer || state.isOpponentAI);
        if (nextIsLocalAi) {
          Future.delayed(const Duration(milliseconds: 300), roll);
        }
      });
    }
  }

  void bearOff() {
    if (state.phase != BgPhase.moving) return;
    final isHumanRole = state.isHumanTurn;
    final from = state.selectedPoint;
    if (from == null || from < 0) return;
    for (final die in [...state.movesLeft]) {
      final dests = isHumanRole
          ? validHumanMoves(state, from, die)
          : validAiMoves(state, from, die);
      if (dests.contains(-2)) {
        _executeMove(from, -2, die, isHumanRole);
        return;
      }
    }
  }

  void passTurn() {
    if (state.phase != BgPhase.moving) return;
    final wasHumanTurn = state.isHumanTurn;
    state = state.copyWith(
      movesLeft: [],
      selectedPoint: () => null,
      isHumanTurn: !wasHumanTurn,
      phase: BgPhase.rolling,
      message: wasHumanTurn ? "Opponent's turn." : 'Your turn. Tap Roll.',
    );
    _broadcastIfHost();
    final nextIsLocalAi =
        !state.isHumanTurn && (!state.isMultiplayer || state.isOpponentAI);
    if (nextIsLocalAi) {
      Future.delayed(const Duration(milliseconds: 300), roll);
    }
  }

  void selectPoint(int pointIdx) {
    // pointIdx: -1 = bar, 0–23 = board index
    if (state.phase != BgPhase.moving) return;
    final isHumanRole = state.isHumanTurn;
    final board = state.board;
    final hasSelected = state.selectedPoint != null;
    final barCount = isHumanRole ? state.humanBar : state.aiBar;

    if (!hasSelected) {
      // Selecting a source
      if (barCount > 0) {
        if (pointIdx == -1) {
          state = state.copyWith(
              selectedPoint: () => -1, message: 'Bar selected. Choose destination.');
          _broadcastIfHost();
        }
        return;
      }
      final owns = isHumanRole ? board[pointIdx] > 0 : board[pointIdx] < 0;
      if (pointIdx < 0 || pointIdx > 23 || !owns) return;
      state = state.copyWith(
          selectedPoint: () => pointIdx, message: 'Piece selected. Tap destination.');
      _broadcastIfHost();
      return;
    }

    final from = state.selectedPoint!;
    // Try each remaining die
    for (final die in [...state.movesLeft]) {
      final dests = isHumanRole
          ? validHumanMoves(state, from, die)
          : validAiMoves(state, from, die);
      if (dests.contains(pointIdx) || (pointIdx == -1 && dests.contains(-2))) {
        _executeMove(from, pointIdx == -1 ? -2 : pointIdx, die, isHumanRole);
        return;
      }
    }
    // Tapped invalid dest — try reselect
    final ownsTapped = pointIdx >= 0 &&
        pointIdx <= 23 &&
        (isHumanRole ? board[pointIdx] > 0 : board[pointIdx] < 0);
    if (ownsTapped) {
      state = state.copyWith(selectedPoint: () => pointIdx);
    } else {
      state = state.copyWith(selectedPoint: () => null, message: 'Invalid move. Select a piece.');
    }
    _broadcastIfHost();
  }

  void _executeMove(int from, int to, int die, bool isHumanRole) {
    final board = [...state.board];
    int humanBar = state.humanBar;
    int aiBar = state.aiBar;
    int humanBornOff = state.humanBornOff;
    int aiBornOff = state.aiBornOff;

    if (isHumanRole) {
      // Remove from source
      if (from == -1) {
        humanBar--;
      } else {
        board[from]--;
      }
      if (to == -2) {
        humanBornOff++;
      } else {
        // Hit check
        if (board[to] == -1) {
          board[to] = 0;
          aiBar++;
        }
        board[to]++;
      }
    } else {
      if (from == -1) {
        aiBar--;
      } else {
        board[from]++;
      }
      if (to == -2) {
        aiBornOff++;
      } else {
        if (board[to] == 1) {
          board[to] = 0;
          humanBar++;
        }
        board[to]--;
      }
    }

    final newMovesLeft = [...state.movesLeft];
    newMovesLeft.remove(die);

    if (isHumanRole && humanBornOff == 15) {
      final stake = state.cubeValue;
      state = state.copyWith(
        board: board, humanBar: humanBar, humanBornOff: humanBornOff,
        aiBar: aiBar, aiBornOff: aiBornOff, movesLeft: newMovesLeft,
        selectedPoint: () => null,
        phase: BgPhase.gameOver,
        message: 'You win! All pieces borne off ($stake pt).',
      );
      _broadcastIfHost();
      return;
    }
    if (!isHumanRole && aiBornOff == 15) {
      final stake = state.cubeValue;
      state = state.copyWith(
        board: board, humanBar: humanBar, humanBornOff: humanBornOff,
        aiBar: aiBar, aiBornOff: aiBornOff, movesLeft: newMovesLeft,
        selectedPoint: () => null,
        phase: BgPhase.gameOver,
        message: 'AI wins! All pieces borne off ($stake pt).',
      );
      _broadcastIfHost();
      return;
    }

    final stillHasMove = newMovesLeft.isNotEmpty &&
        _hasAnyMove(
          state.copyWith(
              board: board, humanBar: humanBar, aiBar: aiBar, movesLeft: newMovesLeft),
          isHumanRole,
        );

    if (!stillHasMove) {
      state = state.copyWith(
        board: board, humanBar: humanBar, humanBornOff: humanBornOff,
        aiBar: aiBar, aiBornOff: aiBornOff, movesLeft: [],
        selectedPoint: () => null,
        isHumanTurn: !isHumanRole,
        phase: BgPhase.rolling,
        message: isHumanRole ? "Opponent's turn." : 'Your turn. Tap Roll.',
      );
      _broadcastIfHost();
      final nextIsLocalAi = !state.isHumanTurn &&
          (!state.isMultiplayer || state.isOpponentAI);
      if (nextIsLocalAi) {
        Future.delayed(const Duration(milliseconds: 300), roll);
      }
      return;
    }

    state = state.copyWith(
      board: board, humanBar: humanBar, humanBornOff: humanBornOff,
      aiBar: aiBar, aiBornOff: aiBornOff, movesLeft: newMovesLeft,
      selectedPoint: () => null,
      message: 'Move again (${newMovesLeft.join(", ")} left).',
    );
    _broadcastIfHost();
  }

  bool _hasAnyMove(BackgammonState s, bool isHumanRole) {
    for (final die in s.movesLeft.toSet()) {
      final barCount = isHumanRole ? s.humanBar : s.aiBar;
      if (barCount > 0) {
        final dests =
            isHumanRole ? validHumanMoves(s, -1, die) : validAiMoves(s, -1, die);
        if (dests.isNotEmpty) return true;
      } else {
        for (int i = 0; i < 24; i++) {
          final owns = isHumanRole ? s.board[i] > 0 : s.board[i] < 0;
          if (owns) {
            final dests = isHumanRole
                ? validHumanMoves(s, i, die)
                : validAiMoves(s, i, die);
            if (dests.isNotEmpty) return true;
          }
        }
      }
    }
    return false;
  }

  void _aiMove() {
    if (state.isHumanTurn || state.phase == BgPhase.gameOver) return;
    final s = state;
    var board = [...s.board];
    int aiBar = s.aiBar;
    int aiBornOff = s.aiBornOff;
    int humanBar = s.humanBar;
    var movesLeft = [...s.movesLeft];

    bool madeMove = true;
    while (movesLeft.isNotEmpty && madeMove) {
      madeMove = false;
      for (final die in [...movesLeft.toSet()]) {
        final move = _bestAiMove(BackgammonState(
          board: board, humanBar: humanBar, aiBar: aiBar,
          humanBornOff: s.humanBornOff, aiBornOff: aiBornOff,
          dice: s.dice, movesLeft: movesLeft,
          isHumanTurn: false, selectedPoint: null,
          phase: BgPhase.moving, message: '',
        ), die);
        if (move != null) {
          final from = move.$1;
          final to = move.$2;
          if (from == -1) {
            aiBar--;
          } else {
            board[from]++;
          }
          if (to == -2) {
            aiBornOff++;
          } else {
            if (board[to] == 1) {
              board[to] = 0;
              humanBar++;
            }
            board[to]--;
          }
          movesLeft.remove(die);
          madeMove = true;
          break;
        }
      }
    }

    if (aiBornOff == 15) {
      final stake = state.cubeValue;
      state = state.copyWith(
        board: board, aiBar: aiBar, aiBornOff: aiBornOff,
        humanBar: humanBar, movesLeft: [],
        phase: BgPhase.gameOver,
        message: 'AI wins! All pieces borne off ($stake pt).',
      );
      _broadcastIfHost();
      return;
    }

    state = state.copyWith(
      board: board, aiBar: aiBar, aiBornOff: aiBornOff,
      humanBar: humanBar, movesLeft: [],
      isHumanTurn: true,
      phase: BgPhase.rolling,
      message: 'Your turn. Tap Roll.',
    );
    _broadcastIfHost();
  }

  (int, int)? _bestAiMove(BackgammonState s, int die) {
    final moves = <(int, int)>[];
    if (s.aiBar > 0) {
      for (final dest in validAiMoves(s, -1, die)) {
        moves.add((-1, dest));
      }
    } else {
      for (int i = 0; i < 24; i++) {
        if (s.board[i] >= 0) continue; // no AI piece
        for (final dest in validAiMoves(s, i, die)) {
          moves.add((i, dest));
        }
      }
    }
    if (moves.isEmpty) return null;
    // Prefer: hitting blots > bearing off > advancing home > moving any
    moves.sort((a, b) {
      int scoreA = _aiMoveScore(s, a);
      int scoreB = _aiMoveScore(s, b);
      return scoreB.compareTo(scoreA);
    });
    return moves.first;
  }

  int _aiMoveScore(BackgammonState s, (int, int) move) {
    final to = move.$2;
    if (to == -2) return 10; // bear off
    if (to >= 0 && s.board[to] == 1) return 8; // hit blot
    if (to >= 18) return 5; // advance into home
    return to; // prefer advancing
  }

  void newGame() {
    exitMultiplayerMode();
    state = build();
  }
}

final backgammonStateProvider =
    NotifierProvider<BackgammonNotifier, BackgammonState>(BackgammonNotifier.new);
