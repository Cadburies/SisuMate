import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'error_log_service.dart';
import 'weather_service.dart' show haversineNm;

/// #234: tide/current predictions. NOAA CO-OPS (api.tidesandcurrents.noaa.gov)
/// chosen after live research against the issue's candidate list — free, no
/// API key, matching this app's existing provider pattern, and covers both
/// tide height and current speed/direction predictions from one source
/// (confirmed live before implementing: `/mdapi/prod/webapi/stations.json`
/// for station metadata, `/api/prod/datagetter` for predictions). US/
/// territories coverage only — the model below (TideStation/CurrentStation
/// as plain id/name/lat/lon, not NOAA-specific fields) is written so a
/// second region's provider could plug in later without a model rework, per
/// this issue's own design note.
class TideStation {
  final String id;
  final String name;
  final double lat;
  final double lon;

  const TideStation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
  });

  factory TideStation.fromJson(Map<String, dynamic> j) => TideStation(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lon: (j['lon'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lon': lon,
      };
}

class TidePrediction {
  final DateTime time;
  final double heightFt;

  /// 'H' (high) or 'L' (low).
  final String type;

  const TidePrediction({
    required this.time,
    required this.heightFt,
    required this.type,
  });
}

class CurrentPrediction {
  final DateTime time;

  /// 'slack', 'ebb', or 'flood'.
  final String type;
  final double velocityKt;
  final double? meanFloodDirDeg;
  final double? meanEbbDirDeg;

  const CurrentPrediction({
    required this.time,
    required this.type,
    required this.velocityKt,
    this.meanFloodDirDeg,
    this.meanEbbDirDeg,
  });
}

/// Parses the NOAA mdapi `stations.json` response (works for both
/// `type=tidepredictions` and `type=currentpredictions`).
List<TideStation> parseStationsJson(String body) {
  final map = jsonDecode(body) as Map<String, dynamic>;
  final list = map['stations'] as List? ?? const [];
  return list.map((e) {
    final m = e as Map<String, dynamic>;
    return TideStation(
      id: m['id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      lat: (m['lat'] as num?)?.toDouble() ?? 0,
      lon: (m['lng'] as num?)?.toDouble() ?? 0,
    );
  }).toList();
}

/// Parses a `product=predictions&interval=hilo` datagetter response. An
/// error response (`{"error": {...}}`, e.g. an invalid station) has no
/// `predictions` key and degrades to an empty list, not a crash.
List<TidePrediction> parseTidePredictionsJson(String body) {
  final map = jsonDecode(body) as Map<String, dynamic>;
  final list = map['predictions'] as List? ?? const [];
  return list.map((e) {
    final m = e as Map<String, dynamic>;
    return TidePrediction(
      time: DateTime.parse((m['t'] as String).replaceFirst(' ', 'T')),
      heightFt: double.tryParse(m['v'] as String? ?? '') ?? 0,
      type: m['type'] as String? ?? '',
    );
  }).toList();
}

/// Parses a `product=currents_predictions&interval=MAX_SLACK` response.
List<CurrentPrediction> parseCurrentPredictionsJson(String body) {
  final map = jsonDecode(body) as Map<String, dynamic>;
  final cp = (map['current_predictions'] as Map<String, dynamic>?)?['cp']
          as List? ??
      const [];
  return cp.map((e) {
    final m = e as Map<String, dynamic>;
    return CurrentPrediction(
      time: DateTime.parse((m['Time'] as String).replaceFirst(' ', 'T')),
      type: m['Type'] as String? ?? '',
      velocityKt: (m['Velocity_Major'] as num?)?.toDouble() ?? 0,
      meanFloodDirDeg: (m['meanFloodDir'] as num?)?.toDouble(),
      meanEbbDirDeg: (m['meanEbbDir'] as num?)?.toDouble(),
    );
  }).toList();
}

/// Nearest station to (lat, lon) within [maxNm] — beyond that is "no
/// coverage" (acceptance: degrade gracefully, not an error).
TideStation? nearestStation(
  List<TideStation> stations,
  double lat,
  double lon, {
  double maxNm = 100,
}) {
  TideStation? best;
  double? bestDist;
  for (final s in stations) {
    final d = haversineNm(lat, lon, s.lat, s.lon);
    if (bestDist == null || d < bestDist) {
      bestDist = d;
      best = s;
    }
  }
  if (best == null || bestDist! > maxNm) return null;
  return best;
}

class TideService {
  static const _tideStationsCacheKey = 'tide_stations_v1';
  static const _currentStationsCacheKey = 'current_stations_v1';
  // Station locations essentially never change — a long TTL avoids
  // re-fetching a multi-MB list on every use.
  static const stationsCacheMaxAge = Duration(days: 30);
  static const networkTimeout = Duration(seconds: 15);

  Future<List<TideStation>> fetchTideStations({http.Client? client}) =>
      _fetchStations(
        cacheKey: _tideStationsCacheKey,
        type: 'tidepredictions',
        client: client,
      );

  Future<List<TideStation>> fetchCurrentStations({http.Client? client}) =>
      _fetchStations(
        cacheKey: _currentStationsCacheKey,
        type: 'currentpredictions',
        client: client,
      );

  Future<List<TideStation>> _fetchStations({
    required String cacheKey,
    required String type,
    http.Client? client,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = _loadStationCache(prefs, cacheKey);
    if (cached != null && !cached.stale) return cached.stations;

    final c = client ?? http.Client();
    try {
      final uri = Uri.https(
        'api.tidesandcurrents.noaa.gov',
        '/mdapi/prod/webapi/stations.json',
        {'type': type},
      );
      final res = await c.get(uri).timeout(networkTimeout);
      if (res.statusCode != 200) return cached?.stations ?? const [];
      final stations = parseStationsJson(res.body);
      await prefs.setString(
        cacheKey,
        jsonEncode({
          'fetchedAt': DateTime.now().toIso8601String(),
          'stations': stations.map((s) => s.toJson()).toList(),
        }),
      );
      return stations;
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'station list fetch failed: $e',
        context: 'tide_service: _fetchStations($type)',
      ));
      return cached?.stations ?? const [];
    } finally {
      if (client == null) c.close();
    }
  }

  ({List<TideStation> stations, bool stale})? _loadStationCache(
    SharedPreferences prefs,
    String cacheKey,
  ) {
    final raw = prefs.getString(cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final fetchedAt = DateTime.parse(map['fetchedAt'] as String);
      final stations = (map['stations'] as List? ?? const [])
          .map((e) => TideStation.fromJson(e as Map<String, dynamic>))
          .toList();
      final stale =
          DateTime.now().difference(fetchedAt) > stationsCacheMaxAge;
      return (stations: stations, stale: stale);
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'stored station list failed to parse: $e',
        context: 'tide_service: _loadStationCache',
      ));
      return null;
    }
  }

  /// Best-effort: a fetch/parse failure returns an empty list rather than
  /// throwing — matches the acceptance criterion that missing coverage/data
  /// degrades gracefully, not as an error.
  Future<List<TidePrediction>> fetchTidePredictions({
    required String stationId,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final uri = Uri.https(
        'api.tidesandcurrents.noaa.gov',
        '/api/prod/datagetter',
        {
          'product': 'predictions',
          'application': 'SisuMate',
          'station': stationId,
          'begin_date': _formatDate(DateTime.now()),
          'range': '48',
          'datum': 'MLLW',
          'units': 'english',
          'time_zone': 'lst_ldt',
          'format': 'json',
          'interval': 'hilo',
        },
      );
      final res = await c.get(uri).timeout(networkTimeout);
      if (res.statusCode != 200) return const [];
      return parseTidePredictionsJson(res.body);
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'tide predictions fetch failed: $e',
        context: 'tide_service: fetchTidePredictions',
      ));
      return const [];
    } finally {
      if (client == null) c.close();
    }
  }

  Future<List<CurrentPrediction>> fetchCurrentPredictions({
    required String stationId,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final uri = Uri.https(
        'api.tidesandcurrents.noaa.gov',
        '/api/prod/datagetter',
        {
          'product': 'currents_predictions',
          'application': 'SisuMate',
          'station': stationId,
          'begin_date': _formatDate(DateTime.now()),
          'range': '48',
          'units': 'english',
          'time_zone': 'lst_ldt',
          'format': 'json',
          'interval': 'MAX_SLACK',
        },
      );
      final res = await c.get(uri).timeout(networkTimeout);
      if (res.statusCode != 200) return const [];
      return parseCurrentPredictionsJson(res.body);
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'current predictions fetch failed: $e',
        context: 'tide_service: fetchCurrentPredictions',
      ));
      return const [];
    } finally {
      if (client == null) c.close();
    }
  }

  static String _formatDate(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}
