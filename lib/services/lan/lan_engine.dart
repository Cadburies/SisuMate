import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bonsoir/bonsoir.dart';

import 'lan_message.dart';

const String _kServiceType = '_sisumate._tcp';

/// Engine-level handshake channel (#435). Never reaches service handlers.
const String kLanAccessChannel = '_access';
const String _kHello = 'hello';
const String _kDenied = 'denied';

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
  /// Largest text frame accepted from a peer; bigger ones close the socket.
  static const maxFrameChars = 256 * 1024;

  /// Wrong codes allowed per remote address before it is refused outright.
  static const maxFailedAttemptsPerAddress = 5;

  /// Admitted peers per host session (bots aren't sockets, so not counted).
  static const maxPeers = 12;

  /// A connection that hasn't presented the code by then is dropped.
  static const helloTimeout = Duration(seconds: 10);

  static final _secureRandom = Random.secure();

  HttpServer? _server;
  WebSocket? _hostSocket;
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;

  int _peerCounter = 0;
  final Map<String, _PeerSlot> _peers = {};
  final Map<String, BonsoirService> _resolvedServices = {};

  /// Host-side: the code a peer must present before anything else (#435).
  /// Shown on the host's screen and typed on the joining device, so it never
  /// travels in the mDNS advert where anyone on the Wi-Fi could read it.
  String? _accessCode;
  String? get accessCode => _accessCode;
  final Map<String, int> _failedByAddress = {};

  /// Client-side: code used for [connectToService], replayed on reconnect.
  String? _clientAccessCode;
  final _accessDeniedCtrl = StreamController<void>.broadcast();

  /// Client-side: the host rejected this device's access code.
  Stream<void> get accessDenied => _accessDeniedCtrl.stream;

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
    _accessCode = _newAccessCode();
    _failedByAddress.clear();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final port = _server!.port;

    _server!.listen((request) async {
      final address = request.connectionInfo?.remoteAddress.address ?? '?';
      if ((_failedByAddress[address] ?? 0) >= maxFailedAttemptsPerAddress) {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
        return;
      }
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _awaitHello(socket, address);
      } else {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
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
  /// [accessCode] is the code shown on the host's screen; it is sent before
  /// any other message. A wrong code fires [accessDenied] and the host closes.
  Future<void> connectToService(BonsoirService service,
      {required String accessCode}) async {
    final host = service.host ?? '';
    final port = service.port;
    _hostSocket = await WebSocket.connect('ws://$host:$port');
    _clientAccessCode = accessCode;
    _hostSocket!.add(LanMessage(
      channel: kLanAccessChannel,
      type: _kHello,
      payload: {'code': accessCode},
    ).encode());
    _attach('host', _hostSocket!);
    _lastConnectedService = service;
  }

  /// Re-attempts the WebSocket connection to the last host this engine
  /// connected to (client mode only). Returns false if there's no
  /// previously-connected host to retry, or the attempt itself fails (e.g.
  /// the host is genuinely gone, not just a transient drop).
  Future<bool> reconnectToLastHost() async {
    final service = _lastConnectedService;
    final code = _clientAccessCode;
    if (service == null || code == null) return false;
    try {
      await connectToService(service, accessCode: code);
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

  static String _newAccessCode() =>
      _secureRandom.nextInt(1000000).toString().padLeft(6, '0');

  /// Host-side gate: the first frame must be a hello with the access code.
  /// Until then the socket is not a peer: no join event, nothing on [incoming].
  /// A WebSocket allows one listener, so this one serves both phases.
  void _awaitHello(WebSocket socket, String address) {
    _PeerSlot? slot;
    final timer = Timer(helloTimeout, () {
      if (slot == null) socket.close(WebSocketStatus.policyViolation);
    });

    socket.listen(
      (data) {
        final admitted = slot;
        if (admitted != null) {
          _onFrame(admitted, data);
          return;
        }
        LanMessage? msg;
        if (data is String && data.length <= maxFrameChars) {
          try {
            msg = LanMessage.decode(data);
          } catch (_) {
            // Not a LanMessage: treated as a failed hello below.
          }
        }
        final ok = msg != null &&
            msg.channel == kLanAccessChannel &&
            msg.type == _kHello &&
            _accessCode != null &&
            msg.payload['code'] == _accessCode;
        timer.cancel();
        if (!ok || _peers.length >= maxPeers) {
          if (!ok) {
            _failedByAddress[address] = (_failedByAddress[address] ?? 0) + 1;
          }
          socket.add(const LanMessage(
                  channel: kLanAccessChannel, type: _kDenied, payload: {})
              .encode());
          socket.close(WebSocketStatus.policyViolation);
          return;
        }
        slot = _admit('peer_${++_peerCounter}', socket);
      },
      onDone: () {
        timer.cancel();
        final admitted = slot;
        if (admitted != null) _onDone(admitted);
      },
      cancelOnError: false,
    );
  }

  /// Client-side: the host connection is trusted once connected.
  void _attach(String peerId, WebSocket socket) {
    final slot = _admit(peerId, socket);
    socket.listen(
      (data) => _onFrame(slot, data),
      onDone: () => _onDone(slot),
      cancelOnError: false,
    );
  }

  _PeerSlot _admit(String peerId, WebSocket socket) {
    final slot = _PeerSlot(id: peerId, socket: socket);
    _peers[peerId] = slot;
    _peerJoinCtrl.add(peerId);
    return slot;
  }

  void _onFrame(_PeerSlot slot, dynamic data) {
    if (data is! String) return;
    if (data.length > maxFrameChars) {
      // Oversized: a misbehaving or hostile peer. Drop it (#435).
      slot.socket.close(WebSocketStatus.messageTooBig);
      return;
    }
    final LanMessage msg;
    try {
      msg = LanMessage.decode(data);
    } catch (_) {
      return; // Malformed frame from a peer: ignore, keep the socket.
    }
    if (msg.channel == kLanAccessChannel) {
      if (msg.type == _kDenied && slot.id == 'host') {
        _accessDeniedCtrl.add(null);
      }
      return; // Handshake traffic never reaches the services.
    }
    // Read slot.id live so LT7 rebind is reflected on subsequent msgs.
    _incomingCtrl.add((peerId: slot.id, message: msg));
  }

  void _onDone(_PeerSlot slot) {
    // Remove by current id (may have been rebound after attach).
    final id = slot.id;
    if (_peers[id] == slot) {
      _peers.remove(id);
    }
    _peerLeaveCtrl.add(id);
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
    _accessCode = null;
    _failedByAddress.clear();
    _clientAccessCode = null;
    _hostSocket = null;
    _server = null;
    _broadcast = null;
    _discovery = null;
    _lastConnectedService = null;
  }
}
