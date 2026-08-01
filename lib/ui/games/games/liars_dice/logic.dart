import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/game_ai/game_ai_difficulty.dart';
import '../../../../services/game_ai/game_ai_persona.dart';
import '../../../../services/lan/game_lan_service.dart';
import '../../../../services/lan/lan_providers.dart';
import 'helpers.dart';

final _rng = Random();

enum GameStateEnum {
  start,
  determineStarter,
  rollDice,
  declareHand,
  acceptChallenge,
  acceptReveal,       // brief dice reveal after opponent accepts — no counter lost
  resolveChallenge,
  determineGameOver,
  gameOver,
}

enum DiceRank {
  fiveOfAKind,
  fourOfAKind,
  fullHouse,
  straightHigh,
  straightLow,
  threeOfAKind,
  twoPair,
  onePair,
  highCard,
}

class Player {
  final String id;
  final String name;
  final bool isAI;
  final List<int> dice;
  final int counters;
  final bool isConnected;
  /// GAI1: seat skill (meaningful when [isAI]).
  final GameAiDifficulty aiDifficulty;
  /// GAI5: seat style (meaningful when [isAI]).
  final GameAiPersona aiPersona;

  const Player({
    required this.id,
    required this.name,
    required this.isAI,
    this.dice = const [1, 1, 1, 1, 1],
    this.counters = 10,
    this.isConnected = true,
    this.aiDifficulty = GameAiDifficulty.normal,
    this.aiPersona = GameAiPersona.balanced,
  });

  Player copyWith({
    String? id,
    String? name,
    bool? isAI,
    List<int>? dice,
    int? counters,
    bool? isConnected,
    GameAiDifficulty? aiDifficulty,
    GameAiPersona? aiPersona,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      isAI: isAI ?? this.isAI,
      dice: dice ?? this.dice,
      counters: counters ?? this.counters,
      isConnected: isConnected ?? this.isConnected,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      aiPersona: aiPersona ?? this.aiPersona,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isAI': isAI,
        'dice': dice,
        'counters': counters,
        'isConnected': isConnected,
        if (isAI) 'aiDifficulty': aiDifficulty.wire,
        if (isAI) 'aiPersona': aiPersona.wire,
      };

  factory Player.fromJson(Map<String, dynamic> j) => Player(
        id: j['id'] as String,
        name: j['name'] as String,
        isAI: j['isAI'] as bool,
        dice: (j['dice'] as List).cast<int>(),
        counters: j['counters'] as int,
        isConnected: j['isConnected'] as bool? ?? true,
        aiDifficulty: GameAiDifficulty.fromWire(j['aiDifficulty'] as String?),
        aiPersona: GameAiPersona.fromWire(j['aiPersona'] as String?),
      );
}

class Bid {
  final DiceRank rank;
  final int face;

  const Bid(this.rank, this.face);

  Map<String, dynamic> toJson() => {'rank': rank.name, 'face': face};

  factory Bid.fromJson(Map<String, dynamic> j) =>
      Bid(DiceRank.values.byName(j['rank'] as String), j['face'] as int);
}

class GameState {
  final GameStateEnum currentState;
  final List<Player> players;
  final int currentTurn;
  final int oppositionPlayer;
  final List<Bid> bidHistory;
  final Bid? lastDeclaredBid;
  final bool isMultiplayer;
  final String? gameMessage;
  final List<String> rerollingPlayerIds;

  const GameState({
    required this.currentState,
    required this.players,
    this.currentTurn = 0,
    this.oppositionPlayer = 1,
    this.bidHistory = const [],
    this.lastDeclaredBid,
    this.isMultiplayer = false,
    this.gameMessage,
    this.rerollingPlayerIds = const [],
  });

  GameState copyWith({
    GameStateEnum? currentState,
    List<Player>? players,
    int? currentTurn,
    int? oppositionPlayer,
    List<Bid>? bidHistory,
    Bid? Function()? lastDeclaredBid,
    bool? isMultiplayer,
    String? gameMessage,
    List<String>? rerollingPlayerIds,
  }) {
    return GameState(
      currentState: currentState ?? this.currentState,
      players: players ?? this.players,
      currentTurn: currentTurn ?? this.currentTurn,
      oppositionPlayer: oppositionPlayer ?? this.oppositionPlayer,
      bidHistory: bidHistory ?? this.bidHistory,
      lastDeclaredBid: lastDeclaredBid != null ? lastDeclaredBid() : this.lastDeclaredBid,
      isMultiplayer: isMultiplayer ?? this.isMultiplayer,
      gameMessage: gameMessage ?? this.gameMessage,
      rerollingPlayerIds: rerollingPlayerIds ?? this.rerollingPlayerIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentState': currentState.name,
        'players': players.map((p) => p.toJson()).toList(),
        'currentTurn': currentTurn,
        'oppositionPlayer': oppositionPlayer,
        'bidHistory': bidHistory.map((b) => b.toJson()).toList(),
        'lastDeclaredBid': lastDeclaredBid?.toJson(),
        'isMultiplayer': isMultiplayer,
        'gameMessage': gameMessage,
        'rerollingPlayerIds': rerollingPlayerIds,
      };

  factory GameState.fromJson(Map<String, dynamic> j) => GameState(
        currentState:
            GameStateEnum.values.byName(j['currentState'] as String),
        players: (j['players'] as List)
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentTurn: j['currentTurn'] as int? ?? 0,
        oppositionPlayer: j['oppositionPlayer'] as int? ?? 1,
        bidHistory: (j['bidHistory'] as List? ?? [])
            .map((e) => Bid.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastDeclaredBid: j['lastDeclaredBid'] != null
            ? Bid.fromJson(j['lastDeclaredBid'] as Map<String, dynamic>)
            : null,
        isMultiplayer: j['isMultiplayer'] as bool? ?? false,
        gameMessage: j['gameMessage'] as String?,
        rerollingPlayerIds:
            (j['rerollingPlayerIds'] as List? ?? []).cast<String>(),
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class GameStateNotifier extends Notifier<GameState> {
  bool _isHostMode = false;
  bool _isClientMode = false;
  GameAiDifficulty _aiDifficulty = GameAiDifficulty.normal;

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
  GameState build() {
    ref.onDispose(() {
      _remoteSub?.cancel();
      _moveSub?.cancel();
      _leaveSub?.cancel();
    });
    return const GameState(currentState: GameStateEnum.start, players: []);
  }

  // ── Multiplayer setup ─────────────────────────────────────────────────────

  void initHostMode(List<LobbyPlayer> lobbyPlayers) {
    _isHostMode = true;
    _isClientMode = false;
    _aiDifficulty = maxAiDifficulty(lobbyPlayers);
    _sessionGeneration++;
    _remoteSub?.cancel();
    _moveSub?.cancel();
    _leaveSub?.cancel();

    final lan = ref.read(gameLanServiceProvider);
    _moveSub = lan.incomingMoves.listen(_applyRemoteMove);
    _leaveSub = lan.playerLeaves.listen(_handleDisconnect);

    final players = lobbyPlayers
        .map((lp) => Player(
              id: lp.id,
              name: lp.name,
              isAI: lp.isAI,
              aiDifficulty: lp.aiDifficulty,
              aiPersona: lp.aiPersona,
            ))
        .toList();
    state = GameState(
      currentState: GameStateEnum.start,
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
      state = GameState.fromJson(json);
    });
    _leaveSub = lan.playerLeaves.listen((peerId) {
      if (peerId == 'host') _handleHostDisconnect(generation);
    });

    state = const GameState(
      currentState: GameStateEnum.start,
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

  /// Client-side: the connection to the host dropped (WiFi blip, host closed
  /// the app, etc.) — previously this was entirely silent, leaving the
  /// screen frozen on the last-known state with no indication anything was
  /// wrong. Now it surfaces a message and tries a few quick reconnects
  /// before giving up cleanly.
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
      currentState: GameStateEnum.gameOver,
      gameMessage: 'Connection to host lost. Game ended.',
    );
  }

  // ── Host-side remote move handler ─────────────────────────────────────────

  void _applyRemoteMove(
      ({String peerId, String action, Map<String, dynamic> data}) move) {
    switch (move.action) {
      case 'finalizeRoll':
        finalizeRoll((move.data['dice'] as List).cast<int>());
      case 'declareBid':
        declareBid(Bid.fromJson(move.data));
      case 'acceptChallenge':
        acceptChallenge(move.data['accept'] as bool);
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
        currentState: GameStateEnum.gameOver,
        gameMessage: '$name disconnected. Game ended.',
      );
      _broadcastIfHost();
      return;
    }

    // Clamp indices to the new player list size.
    final newTurn = state.currentTurn.clamp(0, remaining.length - 1);
    final newOpp = (newTurn + 1) % remaining.length;

    state = state.copyWith(
      players: remaining,
      currentTurn: newTurn,
      oppositionPlayer: newOpp,
      currentState: GameStateEnum.rollDice,
      bidHistory: [],
      lastDeclaredBid: () => null,
      gameMessage: '$name disconnected. Continuing with ${remaining.length} players…',
    );
    _broadcastIfHost();
  }

  // ── Game logic ────────────────────────────────────────────────────────────

  void addPlayer(Player player) {
    state = state.copyWith(players: [...state.players, player]);
  }

  void removePlayer(String id) {
    state = state.copyWith(
      players: state.players.where((p) => p.id != id).toList(),
    );
  }

  void startGame() {
    if (state.players.length >= 2) {
      final updatedPlayers =
          state.players.map((p) => p.copyWith(dice: rollDice())).toList();
      state = state.copyWith(
        currentState: GameStateEnum.determineStarter,
        players: updatedPlayers,
        gameMessage: 'Rolling to determine first player…',
      );
      _broadcastIfHost();
      Timer(const Duration(seconds: 2), determineStarter);
    }
  }

  void determineStarter() {
    final handRanks =
        state.players.map((p) => evaluateHand(p.dice).index).toList();
    final best = handRanks.reduce((a, b) => a < b ? a : b);
    final tied = [
      for (int i = 0; i < handRanks.length; i++)
        if (handRanks[i] == best) i,
    ];

    if (tied.length == 1) {
      final starterIndex = tied.first;
      state = state.copyWith(
        currentState: GameStateEnum.rollDice,
        currentTurn: starterIndex,
        oppositionPlayer: (starterIndex + 1) % state.players.length,
        gameMessage: '${state.players[starterIndex].name} starts!',
        rerollingPlayerIds: const [],
      );
      _broadcastIfHost();
    } else {
      // Re-roll only the tied players and repeat.
      final names = tied.map((i) => state.players[i].name).join(' and ');
      final tiedIds = tied.map((i) => state.players[i].id).toList();
      final updatedPlayers = [...state.players];
      for (final i in tied) {
        updatedPlayers[i] = updatedPlayers[i].copyWith(dice: rollDice());
      }
      state = state.copyWith(
        players: updatedPlayers,
        gameMessage: 'Tie between $names! Re-rolling…',
        rerollingPlayerIds: tiedIds,
      );
      _broadcastIfHost();
      Timer(const Duration(seconds: 2), determineStarter);
    }
  }

  void finalizeRoll(List<int> finalDice) {
    final updated = [...state.players];
    updated[state.currentTurn] =
        updated[state.currentTurn].copyWith(dice: finalDice);
    state = state.copyWith(
      players: updated,
      currentState: GameStateEnum.declareHand,
      gameMessage:
          '${state.players[state.currentTurn].name}, declare your hand',
    );
    _broadcastIfHost();
  }

  void declareBid(Bid bid) {
    if (isValidBid(bid, state.lastDeclaredBid)) {
      state = state.copyWith(
        bidHistory: [...state.bidHistory, bid],
        lastDeclaredBid: () => bid,
        currentState: GameStateEnum.acceptChallenge,
        gameMessage:
            '${state.players[state.oppositionPlayer].name}, accept or challenge?',
      );
    } else {
      state = state.copyWith(
        gameMessage:
            'Invalid bid! Must beat ${rankToString(state.lastDeclaredBid!.rank)} '
            'of ${faceToString(state.lastDeclaredBid!.face)}.',
      );
    }
    _broadcastIfHost();
  }

  void acceptChallenge(bool accept) {
    if (accept) {
      // Show the declarer's dice briefly before moving to the next round.
      state = state.copyWith(
        currentState: GameStateEnum.acceptReveal,
        gameMessage:
            '${state.players[state.oppositionPlayer].name} accepts! '
            "Revealing ${state.players[state.currentTurn].name}'s hand…",
      );
    } else {
      state = state.copyWith(
        currentState: GameStateEnum.resolveChallenge,
        gameMessage:
            'Challenging ${state.players[state.currentTurn].name}…',
      );
    }
    _broadcastIfHost();
  }

  /// Called after the accept-reveal display timer expires (host/SP only).
  /// One-box rule: the shared dice pass to the new declarer so they can hold
  /// and re-roll from the same set rather than starting with fresh dice.
  void advanceFromAcceptReveal() {
    final sharedDice = state.players[state.currentTurn].dice;
    final newDeclarer = state.oppositionPlayer;
    final newOpponent = (newDeclarer + 1) % state.players.length;
    final updatedPlayers = [...state.players];
    updatedPlayers[newDeclarer] =
        updatedPlayers[newDeclarer].copyWith(dice: sharedDice);
    state = state.copyWith(
      players: updatedPlayers,
      currentTurn: newDeclarer,
      oppositionPlayer: newOpponent,
      lastDeclaredBid: () => null,
      bidHistory: [],
      currentState: GameStateEnum.rollDice,
      gameMessage: '${state.players[newDeclarer].name}, roll your dice',
    );
    _broadcastIfHost();
  }

  void resolveChallenge() {
    final declarer = state.players[state.currentTurn];
    final declared = state.lastDeclaredBid!;
    final actualBid = Bid(evaluateHand(declarer.dice), declared.face);

    // Penalty is for OVERCLAIMING (declared better than actual).
    // declared <= actual → honest/conservative → challenge fails → challenger loses.
    // declared >  actual → overclaim/bluff     → challenge wins  → declarer loses.
    final bluffFailed = compareBids(declared, actualBid) <= 0;
    final loserIndex =
        bluffFailed ? state.oppositionPlayer : state.currentTurn;

    final updatedPlayers = [...state.players];
    updatedPlayers[loserIndex] = updatedPlayers[loserIndex]
        .copyWith(counters: updatedPlayers[loserIndex].counters - 1);

    final message = bluffFailed
        ? '${state.players[state.oppositionPlayer].name} failed the challenge!'
        : '${state.players[state.currentTurn].name} was bluffing!';

    // "Common Hand" rule: the challenger always starts the next round,
    // regardless of whether the challenge succeeded or failed.
    final challenger = state.oppositionPlayer;
    state = state.copyWith(
      players: updatedPlayers,
      currentTurn: challenger,
      oppositionPlayer: (challenger + 1) % state.players.length,
      currentState: GameStateEnum.determineGameOver,
      gameMessage: message,
    );
    _broadcastIfHost();
  }

  void determineGameOver() {
    final isGameOver = state.players.any((p) => p.counters <= 0);
    if (isGameOver) {
      int winnerIndex = state.players.indexWhere((p) => p.counters > 0);
      if (winnerIndex == -1) winnerIndex = 0;
      state = state.copyWith(
        currentState: GameStateEnum.gameOver,
        gameMessage: '${state.players[winnerIndex].name} wins the game!',
      );
    } else {
      final resetPlayers =
          state.players.map((p) => p.copyWith(dice: rollDice())).toList();
      state = state.copyWith(
        currentState: GameStateEnum.rollDice,
        players: resetPlayers,
        bidHistory: [],
        lastDeclaredBid: () => null,
        gameMessage:
            '${state.players[state.currentTurn].name}, roll your dice',
      );
    }
    _broadcastIfHost();
  }

  // ── AI helpers (GAI4 pure logic lives in helpers.dart) ────────────────────

  GameAiDifficulty _difficultyFor(int playerIndex) {
    final p = state.players[playerIndex];
    if (p.isAI) return p.aiDifficulty;
    return _aiDifficulty;
  }

  GameAiPersona _personaFor(int playerIndex) {
    final p = state.players[playerIndex];
    if (p.isAI) return p.aiPersona;
    return GameAiPersona.balanced;
  }

  /// Bid based on the AI's actual hand; forced bluffs prefer higher-prior ranks.
  Bid getAIBid() {
    final seat = state.players[state.currentTurn];
    return computeLiarDiceAiBid(
      seat.dice,
      state.lastDeclaredBid,
      difficulty: _difficultyFor(state.currentTurn),
      persona: _personaFor(state.currentTurn),
      rng: _rng,
    );
  }

  /// Accept or challenge using rank priors + bid-history escalation (GAI4).
  bool getAIAccept() {
    final declared = state.lastDeclaredBid;
    if (declared == null) return true;
    final seat = state.players[state.oppositionPlayer];
    return computeLiarDiceAiAccept(
      declared: declared,
      myDice: seat.dice,
      bidHistory: state.bidHistory,
      rng: _rng,
      difficulty: _difficultyFor(state.oppositionPlayer),
      persona: _personaFor(state.oppositionPlayer),
    );
  }

  void resetGame() {
    exitMultiplayerMode();
    final resetPlayers = state.players
        .map((p) => p.copyWith(counters: 10, dice: [1, 1, 1, 1, 1]))
        .toList();
    state = state.copyWith(
      currentState: GameStateEnum.start,
      players: resetPlayers,
      currentTurn: 0,
      oppositionPlayer: 1,
      bidHistory: [],
      lastDeclaredBid: () => null,
      isMultiplayer: false,
      gameMessage: 'Game reset. Add players to start again.',
    );
  }
}

final gameStateProvider =
    NotifierProvider<GameStateNotifier, GameState>(GameStateNotifier.new);

// ── Local UI state providers ──────────────────────────────────────────────────

class _DiceListNotifier extends Notifier<List<int>> {
  final List<int> _initial;
  _DiceListNotifier(this._initial);
  @override
  List<int> build() => _initial;
  void set(List<int> value) => state = value;
}

class _BoolListNotifier extends Notifier<List<bool>> {
  @override
  List<bool> build() => [false, false, false, false, false];
  void set(List<bool> value) => state = value;
}

class _NullableRankNotifier extends Notifier<DiceRank?> {
  @override
  DiceRank? build() => null;
  void set(DiceRank? value) => state = value;
}

class _NullableIntNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void set(int? value) => state = value;
}

class _BoolNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final myDiceProvider = NotifierProvider<_DiceListNotifier, List<int>>(
    () => _DiceListNotifier([1, 1, 1, 1, 1]));
final diceHoldsProvider =
    NotifierProvider<_BoolListNotifier, List<bool>>(_BoolListNotifier.new);
final selectedRankProvider =
    NotifierProvider<_NullableRankNotifier, DiceRank?>(_NullableRankNotifier.new);
final selectedFaceProvider =
    NotifierProvider<_NullableIntNotifier, int?>(_NullableIntNotifier.new);
final hasRolledProvider =
    NotifierProvider<_BoolNotifier, bool>(_BoolNotifier.new);

// gameLanServiceProvider + localPlayerIdProvider are declared in
// lan_providers.dart (imported above) — shared across every multiplayer game.
