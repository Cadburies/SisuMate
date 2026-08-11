import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'nmea_sentence_parser.dart';
import 'predictwind_datahub_service.dart';

/// #263 — Yacht Devices YDWG-02 (or equivalent) NMEA 0183 over TCP.
///
/// Factory default server port is **1456**. Connects, reads a short window of
/// sentences, and maps them into [PredictWindBoatData]. No data within the
/// listen window → null (caller falls through failover).
///
/// Injectable [socketFactory] is the test seam (no real network in unit tests).
class YdwgNmeaService {
  const YdwgNmeaService({
    required this.host,
    this.port = defaultNmeaPort,
    this.listenWindow = const Duration(seconds: 4),
    this.socketFactory,
  });

  final String host;
  final int port;
  final Duration listenWindow;
  final Future<Socket> Function(String host, int port)? socketFactory;

  /// Yacht Devices YDWG-02 factory default TCP/UDP NMEA port.
  static const defaultNmeaPort = 1456;

  static const defaultPortEnv =
      String.fromEnvironment('YDWG_NMEA_PORT', defaultValue: '1456');

  static int get defaultPortResolved {
    final p = int.tryParse(defaultPortEnv);
    return (p != null && p > 0) ? p : defaultNmeaPort;
  }

  /// Host from a base URL (`http://192.168.10.30`) or bare IP.
  static String? hostFromUrl(String? urlOrHost) {
    if (urlOrHost == null) return null;
    final t = urlOrHost.trim();
    if (t.isEmpty) return null;
    try {
      if (t.contains('://')) {
        final h = Uri.parse(t).host;
        return h.isEmpty ? null : h;
      }
      // bare host or host:port
      final hostPart = t.split('/').first.split(':').first;
      return hostPart.isEmpty ? null : hostPart;
    } catch (_) {
      return null;
    }
  }

  Future<PredictWindBoatData?> fetchBoatData() async {
    final factory = socketFactory ??
        ((h, p) => Socket.connect(h, p, timeout: const Duration(seconds: 3)));
    Socket? socket;
    try {
      socket = await factory(host, port);
      final parser = NmeaSentenceParser();
      final completer = Completer<void>();
      late StreamSubscription<List<int>> sub;
      final timer = Timer(listenWindow, () {
        if (!completer.isCompleted) completer.complete();
      });

      sub = socket.listen(
        (data) {
          parser.feedLines(utf8.decode(data, allowMalformed: true));
          // Good enough once we have a position.
          if (parser.fix.hasPosition && !completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );

      await completer.future;
      await sub.cancel();
      timer.cancel();

      final f = parser.fix;
      if (!f.hasPosition) return null;
      return PredictWindBoatData(
        latitude: f.latitude,
        longitude: f.longitude,
        windSpeedKt: f.windSpeedKt,
        windDirectionDeg: f.windDirectionDeg,
        depthMeters: f.depthMeters,
        sogKt: f.sogKt,
        stwKt: f.stwKt,
        cogDeg: f.cogDeg,
        enginePortRpm: f.enginePortRpm,
        engineStbdRpm: f.engineStbdRpm,
        airTempC: f.airTempC,
        waterTempC: f.waterTempC,
        viaLocalNetwork: true,
        sourceLabel: 'YDWG-02 (NMEA local)',
        observedAt: f.observedAt ?? DateTime.now().toUtc(),
      );
    } catch (_) {
      return null;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }
}
