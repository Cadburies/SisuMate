import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:sisu_mate/services/lan/lan_engine.dart';
import 'package:sisu_mate/services/lan/lan_message.dart';

/// In-memory [LanEngine] double for host+client(s) LAN multiplayer tests.
///
/// Supports **multiple clients** (TEST7): the host keeps a map of peer id →
/// client engine; [broadcast] fans out to every client; [sendTo] routes by
/// peer id; clients [sendToHost] tag messages with their assigned peer id.
///
/// One-client tests keep using [connectClient] exactly as before.
class FakeLanEngine extends LanEngine {
  final _incomingCtrl =
      StreamController<({String peerId, LanMessage message})>.broadcast();
  final _peerLeaveCtrl = StreamController<String>.broadcast();

  @override
  Stream<({String peerId, LanMessage message})> get incoming =>
      _incomingCtrl.stream;

  @override
  Stream<String> get peerLeaves => _peerLeaveCtrl.stream;

  /// Host → connected clients (peerId → engine).
  final Map<String, FakeLanEngine> _clients = {};

  /// Client → host engine (null when this instance is the host).
  FakeLanEngine? _host;

  /// How the host labels this client connection (`peer_1`, …).
  String? _myPeerIdOnHost;

  /// Wires [client] to this (the host) engine.
  /// [clientPeerId] is the ephemeral id the host assigns the connection.
  void connectClient(FakeLanEngine client, {String clientPeerId = 'peer_1'}) {
    _clients[clientPeerId] = client;
    client._host = this;
    client._myPeerIdOnHost = clientPeerId;
    client._clients.clear();
  }

  /// Number of client sockets currently attached (host diagnostics / tests).
  int get connectedClientCount => _clients.length;

  void _deliverToClient(FakeLanEngine client, LanMessage message) {
    client._incomingCtrl.add((peerId: 'host', message: message));
  }

  @override
  void sendTo(String peerId, LanMessage message) {
    final client = _clients[peerId];
    if (client != null) {
      _deliverToClient(client, message);
      return;
    }
    // Client accidentally calling sendTo — ignore.
  }

  @override
  void broadcast(LanMessage message) {
    for (final client in _clients.values) {
      _deliverToClient(client, message);
    }
  }

  @override
  void sendToHost(LanMessage message) {
    final host = _host;
    final id = _myPeerIdOnHost;
    if (host == null || id == null) return;
    host._incomingCtrl.add((peerId: id, message: message));
  }

  /// Simulates this connection dropping.
  ///
  /// - Client: notifies host [peerLeaves] with this client's peer id.
  /// - Host with clients: disconnects all clients (fires leave on each).
  void disconnect() {
    final host = _host;
    final myId = _myPeerIdOnHost;
    if (host != null && myId != null) {
      // Client disconnecting from host.
      host._clients.remove(myId);
      host._peerLeaveCtrl.add(myId);
      _host = null;
      _myPeerIdOnHost = null;
      return;
    }
    // Host shutting down sockets.
    final clients = Map<String, FakeLanEngine>.from(_clients);
    _clients.clear();
    for (final entry in clients.entries) {
      entry.value._host = null;
      entry.value._myPeerIdOnHost = null;
      entry.value._peerLeaveCtrl.add('host');
      _peerLeaveCtrl.add(entry.key);
    }
  }

  /// Host-only: drop one client by peer id (TEST7 partial disconnect).
  void disconnectClient(String peerId) {
    final client = _clients.remove(peerId);
    if (client == null) return;
    client._host = null;
    client._myPeerIdOnHost = null;
    _peerLeaveCtrl.add(peerId);
  }

  @override
  Future<void> startHost(String serviceName) async {}

  @override
  Future<void> connectToService(BonsoirService service) async {}

  @override
  Future<bool> reconnectToLastHost() async => _host != null;

  @override
  bool rebindPeerId(String fromId, String toId) {
    final client = _clients.remove(fromId);
    if (client == null) return false;
    _clients[toId] = client;
    client._myPeerIdOnHost = toId;
    return true;
  }
}
