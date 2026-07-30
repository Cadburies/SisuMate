import 'dart:async';

import 'package:bonsoir/bonsoir.dart';

import 'lan_engine.dart';
import 'lan_message.dart';

const String _kChannel = 'game';

/// How long the host keeps a mid-game seat reserved after a disconnect so the
/// same player can rejoin under the same peer id (LT7). After this, the seat
/// is released and [playerLeaves] fires for game notifiers.
const Duration kMidGameReconnectGrace = Duration(seconds: 15);

abstract class _T {
  static const join = 'join';
  static const welcome = 'welcome'; // host → joining client: confirms their peer id
  static const lobby = 'lobby';
  static const start = 'start';
  static const state = 'state';
  static const move = 'move';
}

/// A player slot visible in the pre-game lobby.
class LobbyPlayer {
  final String id;
  final String name;
  final bool isAI;

  const LobbyPlayer({required this.id, required this.name, this.isAI = false});

  factory LobbyPlayer.fromJson(Map<String, dynamic> json) => LobbyPlayer(
        id: json['id'] as String,
        name: json['name'] as String,
        isAI: json['isAI'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'isAI': isAI};
}

/// Game-specific protocol layer on top of [LanEngine].
///
/// HOST flow:
///   1. [hostGame] — starts the mDNS broadcast and WebSocket server.
///   2. Listen to [playerJoins] to update the lobby UI.
///   3. [startGame] — signals all clients to enter the game screen.
///   4. After every game state change call [broadcastState] with the JSON map.
///   5. Listen to [incomingMoves] for client actions; apply them and broadcast.
///
/// CLIENT flow:
///   1. [scanForGames] — begins mDNS discovery; watch [discoveredGames].
///   2. [joinGame] — connects and sends the join handshake.
///   3. After the welcome arrives, [myAssignedId] holds the peer id the host
///      assigned; use it to populate [localPlayerIdProvider].
///   4. Listen to [remoteStates] to update the rendered game state.
///   5. [sendMove] — sends the local player's action to the host.
///   6. Listen to [gameStarted] to know when to leave the lobby.
///
/// LT7 mid-game rejoin: if a client drops after [startGame], the host keeps
/// their lobby seat for [kMidGameReconnectGrace]. A reconnecting client that
/// re-sends [join] under the same name is rebound to the **same peer id**,
/// gets the last broadcast state, and game notifiers never see a leave/join
/// churn — so roster seats and [localPlayerIdProvider] stay valid.
class GameLanService {
  final LanEngine _engine;
  bool _isHost = false;
  String? _myAssignedId;
  bool _gameInProgress = false;
  Map<String, dynamic>? _lastBroadcastState;

  /// peerId → LobbyPlayer for seats that disconnected mid-game and are still
  /// within the reconnect grace window.
  final Map<String, LobbyPlayer> _pendingReconnectByPeerId = {};
  final Map<String, Timer> _graceTimers = {};

  final _remoteStateCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _moveCtrl = StreamController<
      ({String peerId, String action, Map<String, dynamic> data})>.broadcast();
  final _joinCtrl = StreamController<LobbyPlayer>.broadcast();
  final _leaveCtrl = StreamController<String>.broadcast();
  final _startCtrl = StreamController<void>.broadcast();
  final _rejoinCtrl = StreamController<LobbyPlayer>.broadcast();

  /// State snapshots pushed by the host; clients replace their local state
  /// with each value received here.
  Stream<Map<String, dynamic>> get remoteStates => _remoteStateCtrl.stream;

  /// Move commands sent by remote players; host listens and applies them.
  Stream<({String peerId, String action, Map<String, dynamic> data})>
      get incomingMoves => _moveCtrl.stream;

  /// Emits whenever a player joins the lobby.
  Stream<LobbyPlayer> get playerJoins => _joinCtrl.stream;

  /// Emits the peer-id of a player who disconnected mid-lobby or whose
  /// mid-game reconnect grace expired.
  Stream<String> get playerLeaves => _leaveCtrl.stream;

  /// Host-side: a previously-connected seat re-bound after mid-game rejoin.
  /// Games usually do not need this (state is rebroadcast); exposed for tests.
  Stream<LobbyPlayer> get playerRejoins => _rejoinCtrl.stream;

  /// Emits once when the host fires [startGame].
  Stream<void> get gameStarted => _startCtrl.stream;

  /// Mirrors [LanEngine.discoveredServices].
  Stream<List<BonsoirService>> get discoveredGames =>
      _engine.discoveredServices;

  bool get isHost => _isHost;

  /// Whether [startGame] has been called and the session has not ended.
  bool get gameInProgress => _gameInProgress;

  /// The peer id the host assigned to this client after a successful join.
  /// Null on the host device, or before the welcome message arrives.
  String? get myAssignedId => _myAssignedId;

  final List<LobbyPlayer> _lobbyPlayers = [];

  /// Current snapshot of the lobby player list (authoritative on host,
  /// mirrored from host on clients).
  List<LobbyPlayer> get lobbyPlayers => List.unmodifiable(_lobbyPlayers);

  /// Peer ids currently waiting for mid-game rejoin (host diagnostics / tests).
  Set<String> get pendingReconnectPeerIds =>
      Set.unmodifiable(_pendingReconnectByPeerId.keys);

  GameLanService(this._engine) {
    _engine.incoming.listen(_dispatch);
    _engine.peerLeaves.listen(_onPeerLeave);
  }

  // ── Host ───────────────────────────────────────────────────────────────────

  /// Start hosting a game named [gameName]; add the host themselves as the
  /// first lobby player under [hostPlayerName].
  Future<void> hostGame({
    required String gameName,
    required String hostPlayerName,
  }) async {
    _isHost = true;
    _gameInProgress = false;
    _lastBroadcastState = null;
    _clearGraceState();
    _lobbyPlayers
      ..clear()
      ..add(LobbyPlayer(id: 'host', name: hostPlayerName));
    await _engine.startHost(gameName);
  }

  /// Tell all clients the game is starting.  Navigating to the game screen
  /// is the caller's responsibility (listen to [gameStarted] on clients).
  void startGame() {
    assert(_isHost, 'Only the host can start the game');
    _gameInProgress = true;
    _engine.broadcast(LanMessage(
      channel: _kChannel,
      type: _T.start,
      payload: {},
    ));
    _startCtrl.add(null);
  }

  /// Adds a host-local seat (an AI bot) to the lobby — no network connection
  /// involved, unlike a real join. Re-broadcasts the authoritative lobby list
  /// so already-connected clients' lobby views pick it up too.
  void addLocalPlayer(LobbyPlayer player) {
    assert(_isHost, 'Only the host can add a local player');
    _lobbyPlayers.add(player);
    _broadcastLobby();
  }

  /// Removes a host-local seat (an AI bot) added via [addLocalPlayer].
  void removeLocalPlayer(String id) {
    assert(_isHost, 'Only the host can remove a local player');
    _lobbyPlayers.removeWhere((p) => p.id == id);
    _broadcastLobby();
  }

  /// Push an updated game state JSON to every connected client.
  void broadcastState(Map<String, dynamic> stateJson) {
    assert(_isHost, 'Only the host can broadcast state');
    _lastBroadcastState = Map<String, dynamic>.from(stateJson);
    _engine.broadcast(LanMessage(
      channel: _kChannel,
      type: _T.state,
      payload: stateJson,
    ));
  }

  // ── Client ─────────────────────────────────────────────────────────────────

  /// Begin scanning for hosted games on the local network.
  Future<void> scanForGames() => _engine.startDiscovery();

  /// Connect to [service] and announce [playerName] to the host.
  Future<void> joinGame({
    required BonsoirService service,
    required String playerName,
  }) async {
    _isHost = false;
    _myPlayerName = playerName;
    await _engine.connectToService(service);
    _engine.sendToHost(LanMessage(
      channel: _kChannel,
      type: _T.join,
      payload: {'name': playerName},
    ));
  }

  String? _myPlayerName;

  /// This client's own player name, remembered from [joinGame] so a dropped
  /// connection can re-announce itself to the host without the caller having
  /// to keep track of it separately.
  String? get myPlayerName => _myPlayerName;

  /// Client-side: retries the WebSocket connection to the same host this
  /// client was last connected to, and re-sends the join handshake under the
  /// same player name if the socket comes back. Returns false if there's no
  /// prior connection to retry, or the retry itself fails.
  ///
  /// On success the host rebinds this client to their **previous peer id**
  /// when the game is in progress (LT7); [myAssignedId] is updated via the
  /// welcome message.
  Future<bool> reconnect() async {
    final name = _myPlayerName;
    if (name == null) return false;
    final ok = await _engine.reconnectToLastHost();
    if (!ok) return false;
    _engine.sendToHost(LanMessage(
      channel: _kChannel,
      type: _T.join,
      payload: {
        'name': name,
        // Hint for hosts that support preferred-id rejoin (same as last welcome).
        if (_myAssignedId != null) 'preferredId': _myAssignedId,
      },
    ));
    return true;
  }

  /// Send a game-specific action to the host.
  /// [action] is a string key (e.g. `'finalizeRoll'`, `'declareBid'`).
  /// [data] carries the action's parameters as a JSON-serialisable map.
  void sendMove(String action, Map<String, dynamic> data) {
    _engine.sendToHost(LanMessage(
      channel: _kChannel,
      type: _T.move,
      payload: {'action': action, 'data': data},
    ));
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  Future<void> endSession() async {
    _lobbyPlayers.clear();
    _isHost = false;
    _myAssignedId = null;
    _myPlayerName = null;
    _gameInProgress = false;
    _lastBroadcastState = null;
    _clearGraceState();
    await _engine.dispose();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _clearGraceState() {
    for (final t in _graceTimers.values) {
      t.cancel();
    }
    _graceTimers.clear();
    _pendingReconnectByPeerId.clear();
  }

  void _broadcastLobby() {
    _engine.broadcast(LanMessage(
      channel: _kChannel,
      type: _T.lobby,
      payload: {
        'players': _lobbyPlayers.map((p) => p.toJson()).toList(),
      },
    ));
  }

  void _onPeerLeave(String peerId) {
    if (!_isHost) {
      // Client-side: engine reports 'host' when the host socket drops.
      _leaveCtrl.add(peerId);
      return;
    }

    // AI seats are not socket-backed.
    if (peerId.startsWith('ai_')) return;

    final existing = _lobbyPlayers.where((p) => p.id == peerId).firstOrNull;
    if (existing == null) {
      // Unknown / already cleaned up.
      return;
    }

    if (!_gameInProgress) {
      // Pre-game lobby: drop immediately (previous behaviour).
      _lobbyPlayers.removeWhere((p) => p.id == peerId);
      _leaveCtrl.add(peerId);
      _broadcastLobby();
      return;
    }

    // Mid-game: reserve the seat so the same player can rejoin (LT7).
    _pendingReconnectByPeerId[peerId] = existing;
    _graceTimers[peerId]?.cancel();
    _graceTimers[peerId] = Timer(kMidGameReconnectGrace, () {
      _finalizeDisconnectedSeat(peerId);
    });
    // Do NOT emit playerLeaves yet — game state keeps the seat.
  }

  void _finalizeDisconnectedSeat(String peerId) {
    _graceTimers.remove(peerId)?.cancel();
    final pending = _pendingReconnectByPeerId.remove(peerId);
    if (pending == null) return;
    _lobbyPlayers.removeWhere((p) => p.id == peerId);
    _leaveCtrl.add(peerId);
    if (_isHost) _broadcastLobby();
  }

  /// Host-only join handling with LT7 same-seat rebind.
  void _handleHostJoin(String ephemeralPeerId, Map<String, dynamic> payload) {
    final name = payload['name'] as String? ?? 'Player';
    final preferredId = payload['preferredId'] as String?;

    // Prefer explicit preferredId (reconnect path), else match by name among
    // seats waiting to rejoin.
    LobbyPlayer? seat;
    if (preferredId != null &&
        _pendingReconnectByPeerId.containsKey(preferredId)) {
      seat = _pendingReconnectByPeerId[preferredId];
    }
    seat ??= _pendingReconnectByPeerId.values
        .where((p) => p.name == name)
        .firstOrNull;

    // Also allow rejoin if the seat is still listed but the socket was
    // replaced (edge: grace cancelled incorrectly).
    if (seat == null && _gameInProgress) {
      seat = _lobbyPlayers
          .where((p) =>
              p.name == name &&
              p.id != 'host' &&
              !p.isAI &&
              p.id != ephemeralPeerId)
          .firstOrNull;
    }

    if (seat != null && _gameInProgress) {
      final stableId = seat.id;
      _graceTimers.remove(stableId)?.cancel();
      _pendingReconnectByPeerId.remove(stableId);

      // Re-key the live socket onto the original peer id.
      final rebound = _engine.rebindPeerId(ephemeralPeerId, stableId);
      final idForWelcome = rebound ? stableId : ephemeralPeerId;

      _engine.sendTo(
        idForWelcome,
        LanMessage(
          channel: _kChannel,
          type: _T.welcome,
          payload: {'yourId': idForWelcome},
        ),
      );

      // Push last known game state so the client resyncs without a full deal.
      final last = _lastBroadcastState;
      if (last != null) {
        _engine.sendTo(
          idForWelcome,
          LanMessage(
            channel: _kChannel,
            type: _T.state,
            payload: last,
          ),
        );
      }

      _rejoinCtrl.add(seat);
      return;
    }

    // Mid-game brand-new joiners are not admitted (would desync roster games).
    if (_gameInProgress) {
      // Politely ignore — no lobby seat, no welcome that would add them.
      return;
    }

    // Pre-game: normal new seat.
    final player = LobbyPlayer(id: ephemeralPeerId, name: name);
    _lobbyPlayers.add(player);
    _joinCtrl.add(player);
    _engine.sendTo(
      ephemeralPeerId,
      LanMessage(
        channel: _kChannel,
        type: _T.welcome,
        payload: {'yourId': ephemeralPeerId},
      ),
    );
    _broadcastLobby();
  }

  void _dispatch(({String peerId, LanMessage message}) record) {
    final peerId = record.peerId;
    final msg = record.message;
    if (msg.channel != _kChannel) return;

    switch (msg.type) {
      case _T.join:
        if (_isHost) {
          _handleHostJoin(peerId, msg.payload);
        }

      case _T.welcome:
        if (!_isHost) {
          _myAssignedId = msg.payload['yourId'] as String?;
        }

      case _T.lobby:
        if (!_isHost) {
          final raw = msg.payload['players'] as List? ?? [];
          _lobbyPlayers
            ..clear()
            ..addAll(
              raw.map((e) => LobbyPlayer.fromJson(e as Map<String, dynamic>)),
            );
          for (final p in _lobbyPlayers) {
            _joinCtrl.add(p);
          }
        }

      case _T.state:
        _remoteStateCtrl.add(msg.payload);

      case _T.move:
        if (_isHost) {
          final action = msg.payload['action'] as String? ?? '';
          final data = msg.payload['data'] as Map<String, dynamic>? ?? {};
          _moveCtrl.add((peerId: peerId, action: action, data: data));
        }

      case _T.start:
        if (!_isHost) {
          _gameInProgress = true;
          _startCtrl.add(null);
        }
    }
  }
}
