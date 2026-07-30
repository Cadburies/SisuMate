import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:sisu_mate/services/lan/lan_engine.dart';
import 'package:sisu_mate/services/lan/lan_message.dart';

/// In-memory [LanEngine] double for host+client LAN multiplayer tests.
///
/// Bypasses real mDNS/WebSocket entirely: two instances are wired together
/// with [connectClient], after which [sendTo]/[broadcast]/[sendToHost] push
/// straight into the paired engine's [incoming] stream. This lets
/// [GameLanService] (Liar's Dice / Dudo's transport layer) be exercised
/// end-to-end — join handshake, state broadcast, moves, disconnects —
/// deterministically and without a real network.
class FakeLanEngine extends LanEngine {
  final _incomingCtrl =
      StreamController<({String peerId, LanMessage message})>.broadcast();
  final _peerLeaveCtrl = StreamController<String>.broadcast();

  @override
  Stream<({String peerId, LanMessage message})> get incoming =>
      _incomingCtrl.stream;

  @override
  Stream<String> get peerLeaves => _peerLeaveCtrl.stream;

  FakeLanEngine? _peer;

  /// How *this* engine refers to its one peer connection when a message
  /// arrives — mirrors the real engine's local per-connection labelling
  /// (`'host'` on the client side; a host-assigned `'peer_N'` on the host
  /// side). Used to tag inbound messages, not outbound ones.
  String _remoteLabel = '';

  /// Wires [client] to this (the host) engine, standing in for what a real
  /// `startHost` + `connectToService` + join handshake would set up.
  /// [clientPeerId] is the ephemeral id the host would have assigned this
  /// connection (e.g. `'peer_1'`).
  void connectClient(FakeLanEngine client, {String clientPeerId = 'peer_1'}) {
    _peer = client;
    _remoteLabel = clientPeerId;
    client._peer = this;
    client._remoteLabel = 'host';
  }

  void _deliver(LanMessage message) {
    final peer = _peer;
    if (peer == null) return;
    peer._incomingCtrl.add((peerId: peer._remoteLabel, message: message));
  }

  @override
  void sendTo(String peerId, LanMessage message) => _deliver(message);

  @override
  void broadcast(LanMessage message) => _deliver(message);

  @override
  void sendToHost(LanMessage message) => _deliver(message);

  /// Simulates this connection dropping — fires [peerLeaves] on the *other*
  /// side, mirroring the real socket's `onDone` callback.
  void disconnect() {
    final peer = _peer;
    if (peer == null) return;
    peer._peerLeaveCtrl.add(peer._remoteLabel);
    _peer = null;
    peer._peer = null;
  }

  @override
  Future<void> startHost(String serviceName) async {}

  @override
  Future<void> connectToService(BonsoirService service) async {}
}
