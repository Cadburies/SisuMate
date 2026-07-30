import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/game_lan_service.dart';
import '../../../../services/lan/lan_providers.dart';
import 'helpers.dart';

enum DudoStateEnum {
  start,
  determineStarter,
  rollAll,
  bidding,
  resolveChallenge,
  resolveSpotOn,
  determineRoundOver,
  gameOver,
}

// ── Data models ───────────────────────────────────────────────────────────────

class DudoPlayer {
  final String id;
  final String name;
  final bool isAI;
  final List<int> dice;
  final int diceCount;
  final bool isConnected;

  const DudoPlayer({
    required this.id,
    required this.name,
    required this.isAI,
    this.dice = const [1, 1, 1, 1, 1],
    this.diceCount = 5,
    this.isConnected = true,
  });

  bool get isEliminated => diceCount <= 0;

  DudoPlayer copyWith({
    String? id,
    String? name,
    bool? isAI,
    List<int>? dice,
    int? diceCount,
    bool? isConnected,
  }) {
    return DudoPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isAI: isAI ?? this.isAI,
      dice: dice ?? this.dice,
      diceCount: diceCount ?? this.diceCount,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isAI': isAI,
        'dice': dice,
        'diceCount': diceCount,
        'isConnected': isConnected,
      };

  factory DudoPlayer.fromJson(Map<String, dynamic> j) => DudoPlayer(
        id: j['id'] as String,
        name: j['name'] as String,
        isAI: j['isAI'] as bool,
        dice: (j['dice'] as List).cast<int>(),
        diceCount: j['diceCount'] as int,
        isConnected: j['isConnected'] as bool? ?? true,
      );
}

class DudoBid {
  final int quantity;
  final int face; // 1 = aces, 2–6 = pips

  const DudoBid(this.quantity, this.face);

  Map<String, dynamic> toJson() => {'quantity': quantity, 'face': face};

  factory DudoBid.fromJson(Map<String, dynamic> j) =>
      DudoBid(j['quantity'] as int, j['face'] as int);
}

class DudoGameState {
  final DudoStateEnum currentState;
  final List<DudoPlayer> players;
  final int activePlayer;   // whose turn it is to act
  final int lastBidder;     // who placed currentBid (opponent in Dudo)
  final DudoBid? currentBid;
  final bool allDiceRevealed;
  final String? gameMessage;
  final bool isMultiplayer;
  // GB5: true for a round where any non-eliminated player holds exactly 1
  // die — the real Perudo "palafico" variant (aces stop being wild, raises
  // restricted to same-face quantity+1). Recomputed at the start of each
  // round in beginRound().
  final bool isPalaficoRound;

  const DudoGameState({
    required this.currentState,
    required this.players,
    this.activePlayer = 0,
    this.lastBidder = 0,
    this.currentBid,
    this.allDiceRevealed = false,
    this.gameMessage,
    this.isMultiplayer = false,
    this.isPalaficoRound = false,
  });

  DudoGameState copyWith({
    DudoStateEnum? currentState,
    List<DudoPlayer>? players,
    int? activePlayer,
    int? lastBidder,
    DudoBid? Function()? currentBid,
    bool? allDiceRevealed,
    String? gameMessage,
    bool? isMultiplayer,
    bool? isPalaficoRound,
  }) {
    return DudoGameState(
      currentState: currentState ?? this.currentState,
      players: players ?? this.players,
      activePlayer: activePlayer ?? this.activePlayer,
      lastBidder: lastBidder ?? this.lastBidder,
      currentBid: currentBid != null ? currentBid() : this.currentBid,
      allDiceRevealed: allDiceRevealed ?? this.allDiceRevealed,
      gameMessage: gameMessage ?? this.gameMessage,
      isMultiplayer: isMultiplayer ?? this.isMultiplayer,
      isPalaficoRound: isPalaficoRound ?? this.isPalaficoRound,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentState': currentState.name,
        'players': players.map((p) => p.toJson()).toList(),
        'activePlayer': activePlayer,
        'lastBidder': lastBidder,
        'currentBid': currentBid?.toJson(),
        'allDiceRevealed': allDiceRevealed,
        'gameMessage': gameMessage,
        'isMultiplayer': isMultiplayer,
        'isPalaficoRound': isPalaficoRound,
      };

  factory DudoGameState.fromJson(Map<String, dynamic> j) => DudoGameState(
        currentState: DudoStateEnum.values.byName(j['currentState'] as String),
        players: (j['players'] as List)
            .map((e) => DudoPlayer.fromJson(e as Map<String, dynamic>))
            .toList(),
        activePlayer: j['activePlayer'] as int? ?? 0,
        lastBidder: j['lastBidder'] as int? ?? 0,
        currentBid: j['currentBid'] != null
            ? DudoBid.fromJson(j['currentBid'] as Map<String, dynamic>)
            : null,
        allDiceRevealed: j['allDiceRevealed'] as bool? ?? false,
        gameMessage: j['gameMessage'] as String?,
        isMultiplayer: j['isMultiplayer'] as bool? ?? false,
        isPalaficoRound: j['isPalaficoRound'] as bool? ?? false,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class DudoGameNotifier extends Notifier<DudoGameState> {
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
  DudoGameState build() {
    ref.onDispose(() {
      _remoteSub?.cancel();
      _moveSub?.cancel();
      _leaveSub?.cancel();
    });
    return const DudoGameState(currentState: DudoStateEnum.start, players: []);
  }

  // ── Multiplayer setup (mirrors liars_dice/logic.dart's GameStateNotifier)──

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

    final players = lobbyPlayers
        .map((lp) => DudoPlayer(id: lp.id, name: lp.name, isAI: lp.isAI))
        .toList();
    state = DudoGameState(
      currentState: DudoStateEnum.start,
      players: players,
      isMultiplayer: true,
      gameMessage: 'Game ready. Starting...',
    );
  }

  void initClientMode() {
    _isClientMode = true;
    _isHostMode = false;
    _moveSub?.cancel();
    _leaveSub?.cancel();
    final generation = ++_sessionGeneration;

    final lan = ref.read(gameLanServiceProvider);
    _remoteSub = lan.remoteStates.listen((json) {
      state = DudoGameState.fromJson(json);
    });
    _leaveSub = lan.playerLeaves.listen((peerId) {
      if (peerId == 'host') _handleHostDisconnect(generation);
    });

    state = const DudoGameState(
      currentState: DudoStateEnum.start,
      players: [],
      isMultiplayer: true,
      gameMessage: 'Waiting for host...',
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
    state = state.copyWith(gameMessage: 'Connection lost. Reconnecting…');

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      await Future.delayed(const Duration(seconds: 2));
      if (generation != _sessionGeneration) return; // session moved on

      final lan = ref.read(gameLanServiceProvider);
      final reconnected = await lan.reconnect();
      if (generation != _sessionGeneration) return;

      if (reconnected) {
        // LT7: host rebinds the same peer id; refresh provider in case welcome
        // re-confirmed (or corrected) the assignment.
        final id = lan.myAssignedId;
        if (id != null) {
          ref.read(localPlayerIdProvider.notifier).set(id);
        }
        state = state.copyWith(gameMessage: 'Reconnected!');
        return;
      }
    }

    state = state.copyWith(
      currentState: DudoStateEnum.gameOver,
      gameMessage: 'Connection to host lost. Game ended.',
    );
  }

  // ── Host-side remote move handler ─────────────────────────────────────────

  void _applyRemoteMove(
      ({String peerId, String action, Map<String, dynamic> data}) move) {
    switch (move.action) {
      case 'placeBid':
        placeBid(DudoBid.fromJson(move.data));
      case 'callDudo':
        callDudo();
      case 'callSpotOn':
        callSpotOn();
    }
  }

  void _broadcastIfHost() {
    if (_isHostMode) {
      ref.read(gameLanServiceProvider).broadcastState(state.toJson());
    }
  }

  // ── Disconnect handling ───────────────────────────────────────────────────

  void _handleDisconnect(String peerId) {
    final idx = state.players.indexWhere((p) => p.id == peerId);
    if (idx == -1) return;

    final name = state.players[idx].name;
    final remaining = [...state.players]..removeAt(idx);

    if (remaining.length < 2) {
      state = state.copyWith(
        players: remaining,
        currentState: DudoStateEnum.gameOver,
        gameMessage: '$name disconnected. Game ended.',
      );
      _broadcastIfHost();
      return;
    }

    // Clamp indices to the new player list size.
    final newActive = state.activePlayer.clamp(0, remaining.length - 1);

    state = state.copyWith(
      players: remaining,
      activePlayer: newActive,
      lastBidder: newActive,
      currentState: DudoStateEnum.rollAll,
      currentBid: () => null,
      gameMessage:
          '$name disconnected. Continuing with ${remaining.length} players…',
    );
    Timer(const Duration(seconds: 1), beginRound);
    _broadcastIfHost();
  }

  // ── Player management ─────────────────────────────────────────────────────

  void addPlayer(DudoPlayer player) {
    state = state.copyWith(players: [...state.players, player]);
  }

  void removePlayer(String id) {
    state = state.copyWith(
      players: state.players.where((p) => p.id != id).toList(),
    );
  }

  // ── Game start ────────────────────────────────────────────────────────────

  void startGame() {
    if (state.players.length < 2) return;
    // Roll one die per player to determine starter.
    final updated = state.players
        .map((p) => p.copyWith(dice: rollDice(1), diceCount: 5))
        .toList();
    state = state.copyWith(
      currentState: DudoStateEnum.determineStarter,
      players: updated,
      gameMessage: 'Rolling to determine first player…',
    );
    _broadcastIfHost();
    Timer(const Duration(seconds: 2), determineStarter);
  }

  void determineStarter() {
    final rolls = state.players.map((p) => p.dice.first).toList();
    final best = rolls.reduce((a, b) => a > b ? a : b);
    final tied = [
      for (int i = 0; i < rolls.length; i++)
        if (rolls[i] == best) i,
    ];

    if (tied.length == 1) {
      final winner = tied.first;
      state = state.copyWith(
        activePlayer: winner,
        lastBidder: winner,
        gameMessage: '${state.players[winner].name} starts!',
      );
      _broadcastIfHost();
      Timer(const Duration(seconds: 1), beginRound);
    } else {
      final names = tied.map((i) => state.players[i].name).join(' & ');
      final updated = [...state.players];
      for (final i in tied) {
        updated[i] = updated[i].copyWith(dice: rollDice(1));
      }
      state = state.copyWith(
        players: updated,
        gameMessage: 'Tie between $names! Re-rolling…',
      );
      _broadcastIfHost();
      Timer(const Duration(seconds: 2), determineStarter);
    }
  }

  // ── Round ─────────────────────────────────────────────────────────────────

  void beginRound() {
    final updated = state.players.map((p) {
      if (p.isEliminated) return p;
      return p.copyWith(dice: rollDice(p.diceCount));
    }).toList();
    // GB5: palafico — any non-eliminated player down to their last die
    // makes this a special round for everyone (aces not wild, raises
    // restricted to same-face quantity+1).
    final isPalafico = updated.any((p) => !p.isEliminated && p.diceCount == 1);
    state = state.copyWith(
      currentState: DudoStateEnum.rollAll,
      players: updated,
      currentBid: () => null,
      allDiceRevealed: false,
      isPalaficoRound: isPalafico,
      gameMessage: isPalafico
          ? 'Palafico! Aces aren\'t wild — raises must match the face, +1 quantity. ${state.players[state.activePlayer].name} bids first.'
          : 'Dice rolled! ${state.players[state.activePlayer].name} bids first.',
    );
    _broadcastIfHost();
    Timer(const Duration(seconds: 2), startBidding);
  }

  void startBidding() {
    state = state.copyWith(
      currentState: DudoStateEnum.bidding,
      gameMessage: '${state.players[state.activePlayer].name}, make your bid.',
    );
    _broadcastIfHost();
  }

  // ── Player actions ────────────────────────────────────────────────────────

  void placeBid(DudoBid bid) {
    final player = state.players[state.activePlayer];
    if (!isValidRaise(bid, state.currentBid,
        playerDiceCount: player.diceCount, isPalafico: state.isPalaficoRound)) {
      state = state.copyWith(
        gameMessage: state.currentBid == null
            ? 'Invalid bid. Choose quantity ≥ 1.'
            : state.isPalaficoRound
                ? 'Palafico! Must bid ${bidToString(DudoBid(state.currentBid!.quantity + 1, state.currentBid!.face))}.'
                : 'Invalid raise! Must beat: ${bidToString(state.currentBid!)}.',
      );
      _broadcastIfHost();
      return;
    }
    final next = nextPlayer(state.players, state.activePlayer);
    state = state.copyWith(
      currentBid: () => bid,
      lastBidder: state.activePlayer,
      activePlayer: next,
      gameMessage:
          '${player.name} bids ${bidToString(bid)}. ${state.players[next].name}, your turn.',
    );
    _broadcastIfHost();
  }

  void callDudo() {
    final caller = state.players[state.activePlayer];
    state = state.copyWith(
      allDiceRevealed: true,
      currentState: DudoStateEnum.resolveChallenge,
      gameMessage: '${caller.name} calls Dudo! Revealing all dice…',
    );
    _broadcastIfHost();
  }

  void callSpotOn() {
    final caller = state.players[state.activePlayer];
    state = state.copyWith(
      allDiceRevealed: true,
      currentState: DudoStateEnum.resolveSpotOn,
      gameMessage: '${caller.name} calls Spot On! Revealing all dice…',
    );
    _broadcastIfHost();
  }

  // ── Resolution ────────────────────────────────────────────────────────────

  void resolveChallenge() {
    final bid = state.currentBid!;
    final actual = countBid(state.players, bid, isPalafico: state.isPalaficoRound);
    final bidderIndex = state.lastBidder;
    final callerIndex = state.activePlayer;

    final bidCorrect = actual >= bid.quantity;
    // bid correct → caller (Dudo-caller) loses 1 die
    // bid wrong   → bidder loses 1 die
    final loserIndex = bidCorrect ? callerIndex : bidderIndex;

    final updated = [...state.players];
    final loser = updated[loserIndex];
    final newDiceCount = (loser.diceCount - 1).clamp(0, 5);
    updated[loserIndex] = loser.copyWith(
      diceCount: newDiceCount,
      dice: newDiceCount > 0
          ? loser.dice.sublist(0, newDiceCount)
          : [],
    );

    final loserName = state.players[loserIndex].name;
    final msg = bidCorrect
        ? 'Bid correct! $actual × ${bid.face}s found. $loserName loses a die.'
        : 'Bid wrong! Only $actual × ${bid.face}s. $loserName loses a die.';

    state = state.copyWith(
      players: updated,
      activePlayer: loserIndex,
      currentState: DudoStateEnum.determineRoundOver,
      gameMessage: msg,
    );
    _broadcastIfHost();
  }

  void resolveSpotOn() {
    final bid = state.currentBid!;
    final actual = countBid(state.players, bid, isPalafico: state.isPalaficoRound);
    final callerIndex = state.activePlayer;

    final updated = [...state.players];
    final caller = updated[callerIndex];
    String msg;

    if (actual == bid.quantity) {
      // Exact! Caller gains 1 die (max 5).
      final newCount = (caller.diceCount + 1).clamp(0, 5);
      updated[callerIndex] = caller.copyWith(diceCount: newCount);
      msg = 'Spot On! Exactly $actual × ${bid.face}s. ${caller.name} gains a die!';
    } else {
      // Wrong. Caller loses 1 die.
      final newCount = (caller.diceCount - 1).clamp(0, 5);
      updated[callerIndex] = caller.copyWith(
        diceCount: newCount,
        dice: newCount > 0 ? caller.dice.sublist(0, newCount) : [],
      );
      msg = 'Wrong! $actual × ${bid.face}s found. ${caller.name} loses a die.';
    }

    state = state.copyWith(
      players: updated,
      currentState: DudoStateEnum.determineRoundOver,
      gameMessage: msg,
    );
    _broadcastIfHost();
  }

  void determineRoundOver() {
    final active = state.players
        .where((p) => !p.isEliminated)
        .toList();

    if (active.length <= 1) {
      final winner = active.isNotEmpty
          ? active.first.name
          : state.players.first.name;
      state = state.copyWith(
        currentState: DudoStateEnum.gameOver,
        gameMessage: '$winner wins the game!',
      );
      _broadcastIfHost();
      return;
    }

    // resolveChallenge()/resolveSpotOn() set activePlayer to the round's loser
    // (or the correct Spot On caller). They start the next round if still in
    // the game, else it passes to their next active neighbor.
    int nextStarter = state.activePlayer;
    if (state.players[nextStarter].isEliminated) {
      nextStarter = nextPlayer(state.players, nextStarter);
    }

    state = state.copyWith(
      currentState: DudoStateEnum.rollAll,
      activePlayer: nextStarter,
      lastBidder: nextStarter,
    );
    _broadcastIfHost();
    Timer(const Duration(milliseconds: 500), beginRound);
  }

  void resetGame() {
    exitMultiplayerMode();
    final reset = state.players
        .map((p) => p.copyWith(diceCount: 5, dice: [1, 1, 1, 1, 1]))
        .toList();
    state = DudoGameState(
      currentState: DudoStateEnum.start,
      players: reset,
      gameMessage: 'Game reset.',
    );
  }

  // ── AI helpers ────────────────────────────────────────────────────────────

  DudoBid computeAIBid() => getAIBid(
      state.players, state.activePlayer, state.currentBid,
      isPalafico: state.isPalaficoRound);

  bool shouldAIDudo() => getAIShouldDudo(
      state.players, state.activePlayer, state.currentBid!,
      isPalafico: state.isPalaficoRound);

  bool shouldAISpotOn() => getAIShouldSpotOn(
      state.players, state.activePlayer, state.currentBid!,
      isPalafico: state.isPalaficoRound);
}

final dudoGameProvider =
    NotifierProvider<DudoGameNotifier, DudoGameState>(DudoGameNotifier.new);

// gameLanServiceProvider + localPlayerIdProvider are declared in
// lan_providers.dart (imported above) — shared across every multiplayer game.
