import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';

import 'lan_message.dart';

const String _kServiceType = '_sisumate._tcp';

/// Mutable peer slot so [rebindPeerId] can change the id that inbound
/// messages report without tearing down the WebSocket (LT7 same-seat rejoin).
class _PeerSlot {
  String id;
  final WebSocket socket;
  _PeerSlot({required this.id, required this.socket});
}

/// Low-level LAN transport: mDNS broadcast/discovery + WebSocket host/client.
///
/// HOST mode  — call [startHost]: binds a WebSocket server on a dynamic port,
///              then broadcasts an mDNS service so clients can find it.
/// CLIENT mode — call [startDiscovery], watch [discoveredServices], then call
///              [connectToService] with the chosen service.
///
/// All inbound messages arrive on [incoming]. Use [broadcast] (host) or
/// [sendToHost] (client) to send messages.
class LanEngine {
  HttpServer? _server;
  WebSocket? _hostSocket;
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;

  int _peerCounter = 0;
  final Map<String, _PeerSlot> _peers = {};
  final Map<String, BonsoirService> _resolvedServices = {};

  /// Client-side only: remembers which host [connectToService] last
  /// connected to, so a dropped connection can be retried against the same
  /// address without re-running mDNS discovery from scratch.
  BonsoirService? _lastConnectedService;

  final _incomingCtrl =
      StreamController<({String peerId, LanMessage message})>.broadcast();
  final _peerJoinCtrl = StreamController<String>.broadcast();
  final _peerLeaveCtrl = StreamController<String>.broadcast();
  final _servicesCtrl = StreamController<List<BonsoirService>>.broadcast();

  Stream<({String peerId, LanMessage message})> get incoming =>
      _incomingCtrl.stream;
  Stream<String> get peerJoins => _peerJoinCtrl.stream;
  Stream<String> get peerLeaves => _peerLeaveCtrl.stream;

  /// Emits the current list of discovered (resolved) services whenever it changes.
  /// A resolved service has a non-null [BonsoirService.host].
  Stream<List<BonsoirService>> get discoveredServices => _servicesCtrl.stream;
  List<BonsoirService> get currentServices =>
      List.unmodifiable(_resolvedServices.values);

  /// Currently connected peer ids (host-side). Exposed for tests / diagnostics.
  Set<String> get connectedPeerIds => _peers.keys.toSet();

  /// Bound host port, or null when not hosting. Used by LAN integration tests.
  int? get hostPort => _server?.port;

  // ── Host mode ──────────────────────────────────────────────────────────────

  /// Binds a WebSocket server on an OS-assigned port and registers an mDNS
  /// service named [serviceName] so clients can discover it.
  Future<void> startHost(String serviceName) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final port = _server!.port;

    _server!.listen((request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        final id = 'peer_${++_peerCounter}';
        _attach(id, socket);
      }
    });

    final service = BonsoirService(
      name: serviceName,
      type: _kServiceType,
      port: port,
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.initialize();
    await _broadcast!.start();
  }

  // ── Client mode ────────────────────────────────────────────────────────────

  /// Scans the local network for mDNS services of the Sisu Mate type.
  /// Resolved services (with a valid host) emit on [discoveredServices].
  Future<void> startDiscovery() async {
    _discovery = BonsoirDiscovery(type: _kServiceType);
    await _discovery!.initialize();

    _discovery!.eventStream?.listen((event) {
      switch (event) {
        case BonsoirDiscoveryServiceFoundEvent():
          event.service.resolve(_discovery!.serviceResolver);
        case BonsoirDiscoveryServiceResolvedEvent():
          final svc = event.service;
          if (svc.host != null) {
            _resolvedServices[svc.name] = svc;
            _servicesCtrl.add(_resolvedServices.values.toList());
          }
        case BonsoirDiscoveryServiceLostEvent():
          _resolvedServices.remove(event.service.name);
          _servicesCtrl.add(_resolvedServices.values.toList());
        default:
          break;
      }
    });

    await _discovery!.start();
  }

  /// Connects to [service] (a resolved mDNS service with a non-null host).
  Future<void> connectToService(BonsoirService service) async {
    final host = service.host ?? '';
    final port = service.port;
    _hostSocket = await WebSocket.connect('ws://$host:$port');
    _attach('host', _hostSocket!);
    _lastConnectedService = service;
  }

  /// Re-attempts the WebSocket connection to the last host this engine
  /// connected to (client mode only). Returns false if there's no
  /// previously-connected host to retry, or the attempt itself fails (e.g.
  /// the host is genuinely gone, not just a transient drop).
  Future<bool> reconnectToLastHost() async {
    final service = _lastConnectedService;
    if (service == null) return false;
    try {
      await connectToService(service);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Host-side: re-key an ephemeral peer id (from a fresh WebSocket) onto a
  /// stable seat id so mid-game rejoin keeps the same player identity (LT7).
  ///
  /// Inbound messages after rebind report [stableId]. Returns false if
  /// [ephemeralId] is not currently connected.
  bool rebindPeerId(String ephemeralId, String stableId) {
    if (ephemeralId == stableId) return _peers.containsKey(stableId);
    final slot = _peers.remove(ephemeralId);
    if (slot == null) return false;
    // Drop any stale mapping for the stable id (socket already gone).
    _peers.remove(stableId);
    slot.id = stableId;
    _peers[stableId] = slot;
    return true;
  }

  // ── Messaging ──────────────────────────────────────────────────────────────

  /// Send [message] to a specific connected peer (host-side use).
  void sendTo(String peerId, LanMessage message) {
    _peers[peerId]?.socket.add(message.encode());
  }

  /// Broadcast [message] to every connected peer (host-side use).
  void broadcast(LanMessage message) {
    final encoded = message.encode();
    for (final slot in _peers.values) {
      slot.socket.add(encoded);
    }
  }

  /// Send [message] to the host (client-side use).
  void sendToHost(LanMessage message) {
    _hostSocket?.add(message.encode());
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _attach(String peerId, WebSocket socket) {
    final slot = _PeerSlot(id: peerId, socket: socket);
    _peers[peerId] = slot;
    _peerJoinCtrl.add(peerId);

    socket.listen(
      (data) {
        if (data is String) {
          try {
            // Read slot.id live so LT7 rebind is reflected on subsequent msgs.
            _incomingCtrl
                .add((peerId: slot.id, message: LanMessage.decode(data)));
          } catch (_) {}
        }
      },
      onDone: () {
        // Remove by current id (may have been rebound after attach).
        final id = slot.id;
        if (_peers[id] == slot) {
          _peers.remove(id);
        }
        _peerLeaveCtrl.add(id);
      },
      cancelOnError: false,
    );
  }

  Future<void> dispose() async {
    for (final slot in _peers.values) {
      try {
        await slot.socket.close();
      } catch (_) {}
    }
    _peers.clear();
    try {
      await _hostSocket?.close();
    } catch (_) {}
    try {
      await _server?.close(force: true);
    } catch (_) {}
    // Bonsoir platform channels may throw when no Flutter binding is
    // available (unit tests) or when the OS mDNS stack is already torn down.
    try {
      await _broadcast?.stop();
    } catch (_) {}
    try {
      await _discovery?.stop();
    } catch (_) {}
    _resolvedServices.clear();
    _peerCounter = 0;
    _hostSocket = null;
    _server = null;
    _broadcast = null;
    _discovery = null;
    _lastConnectedService = null;
  }
}
