import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/units.dart';
import 'error_log_service.dart';

/// A saved or search-result place (SUG3 named locations).
class WeatherPlace {
  final String name;
  final double lat;
  final double lon;
  final String? admin1;
  final String? country;

  const WeatherPlace({
    required this.name,
    required this.lat,
    required this.lon,
    this.admin1,
    this.country,
  });

  String get label {
    final parts = <String>[
      name,
      if (admin1 != null && admin1!.isNotEmpty) admin1!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': lat,
        'lon': lon,
        if (admin1 != null) 'admin1': admin1,
        if (country != null) 'country': country,
      };

  factory WeatherPlace.fromJson(Map<String, dynamic> j) => WeatherPlace(
        name: j['name'] as String? ?? 'Place',
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        admin1: j['admin1'] as String?,
        country: j['country'] as String?,
      );
}

/// Open-Meteo forecast (free, no API key) with local cache for offline (S3).
/// SUG3: place search, GEBCO water depth, named favorites.
///
/// TEST26: all network calls use short timeouts; offline falls back to any
/// cached bundle (fresh preferred, then stale) so fetch never hangs and rarely
/// hard-fails when the user has previously loaded weather.
class WeatherService {
  /// v2: wind stored as m/s (metric), not knots.
  static const _cacheKey = 'weather_cache_v2';
  /// How long a cache is considered "fresh" (preferred over re-fetch success).
  static const cacheMaxAge = Duration(hours: 3);
  static const _favoritesKey = 'weather_named_locations_v1';
  /// Per-request network timeout (TEST26 — no multi-minute hangs).
  static const networkTimeout = Duration(seconds: 12);

  /// True when [fetchedAt] is within [cacheMaxAge] of [now].
  static bool isCacheFresh(DateTime fetchedAt, {DateTime? now}) {
    final at = now ?? DateTime.now();
    return at.difference(fetchedAt) < cacheMaxAge;
  }

  /// Fetch forecast for [lat]/[lon]. Uses network when available; falls back
  /// to local cache offline (fresh first, then any stale cache). Throws only
  /// when network fails **and** there is no usable cache.
  ///
  /// Optionally enriches with [placeName] / GEBCO [waterDepthM] (best-effort).
  Future<WeatherBundle> fetch({
    required double lat,
    required double lon,
    String? placeName,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toStringAsFixed(4),
        'longitude': lon.toStringAsFixed(4),
        'current':
            'temperature_2m,wind_speed_10m,wind_direction_10m,weather_code,relative_humidity_2m',
        'hourly':
            'temperature_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation_probability',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,wind_speed_10m_max,precipitation_sum',
        // #242: Open-Meteo's actual default is km/h — must request m/s
        // explicitly, since windMs (and every UnitConverter.formatSpeedFromMs
        // caller) treats the stored value as true m/s.
        'windspeed_unit': 'ms',
        'timezone': 'auto',
        'forecast_days': '3',
      });
      final marineUri = Uri.https('marine-api.open-meteo.com', '/v1/marine', {
        'latitude': lat.toStringAsFixed(4),
        'longitude': lon.toStringAsFixed(4),
        'hourly': 'wave_height,wave_direction,wave_period',
        'timezone': 'auto',
        'forecast_days': '3',
      });

      final responses = await Future.wait([
        c.get(uri).timeout(networkTimeout),
        c.get(marineUri).timeout(networkTimeout),
      ]);

      if (responses[0].statusCode != 200) {
        throw WeatherException(
          'Weather request failed (${responses[0].statusCode})',
        );
      }
      final forecast = jsonDecode(responses[0].body) as Map<String, dynamic>;
      Map<String, dynamic>? marine;
      if (responses[1].statusCode == 200) {
        marine = jsonDecode(responses[1].body) as Map<String, dynamic>;
      }

      // Best-effort place name + charted depth (do not fail the forecast).
      String? resolvedName = placeName;
      double? depthM;
      try {
        final nameFut = (placeName == null || placeName.isEmpty)
            ? reverseGeocode(lat: lat, lon: lon, client: c)
            : Future<String?>.value(placeName);
        final depthFut = fetchWaterDepthM(lat: lat, lon: lon, client: c);
        final extras = await Future.wait<Object?>([nameFut, depthFut]);
        resolvedName = extras[0] as String?;
        depthM = extras[1] as double?;
      } catch (e) {
        unawaited(ErrorLogService().logWarning(
          'place name / charted depth enrichment failed: $e',
          context: 'weather_service: getWeather enrichment',
        ));
      }

      final bundle = WeatherBundle.fromJson(
        forecast: forecast,
        marine: marine,
        lat: lat,
        lon: lon,
        fetchedAt: DateTime.now(),
        fromCache: false,
        placeName: resolvedName,
        waterDepthM: depthM,
      );
      await _saveCache(bundle);
      return bundle;
    } catch (e) {
      // TEST26: never hang; prefer any cache over hard failure when offline.
      unawaited(ErrorLogService()
          .logWarning('live fetch failed: $e', context: 'weather_service: getWeather'));
      final cached = await loadCache();
      if (cached != null) {
        return cached.copyWith(fromCache: true);
      }
      if (e is WeatherException) rethrow;
      throw WeatherException('Could not load weather: $e');
    } finally {
      if (client == null) c.close();
    }
  }

  /// Forward geocode via Open-Meteo (free, no key).
  Future<List<WeatherPlace>> searchPlaces(
    String query, {
    http.Client? client,
    int count = 6,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final c = client ?? http.Client();
    try {
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': q,
        'count': '$count',
        'language': 'en',
        'format': 'json',
      });
      final res = await c.get(uri).timeout(networkTimeout);
      if (res.statusCode != 200) return const [];
      return parsePlaceSearchJson(res.body);
    } catch (e) {
      unawaited(ErrorLogService()
          .logWarning('place search failed: $e', context: 'weather_service: searchPlaces'));
      return const [];
    } finally {
      if (client == null) c.close();
    }
  }

  /// Reverse geocode via Nominatim (OSM). Best-effort; may return null.
  Future<String?> reverseGeocode({
    required double lat,
    required double lon,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': lat.toStringAsFixed(5),
        'lon': lon.toStringAsFixed(5),
        'format': 'json',
        'zoom': '10',
      });
      final res = await c.get(
        uri,
        headers: {'User-Agent': 'SisuMate/1.0 (weather; offline-first sailor app)'},
      ).timeout(networkTimeout);
      if (res.statusCode != 200) return null;
      return parseNominatimReverseJson(res.body);
    } catch (e) {
      unawaited(ErrorLogService()
          .logWarning('reverse geocode failed: $e', context: 'weather_service: reverseGeocode'));
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  /// Charted depth/elevation via OpenTopoData GEBCO (meters; negative = water).
  Future<double?> fetchWaterDepthM({
    required double lat,
    required double lon,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final uri = Uri.https('api.opentopodata.org', '/v1/gebco2020', {
        'locations': '${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}',
      });
      final res = await c.get(uri).timeout(networkTimeout);
      if (res.statusCode != 200) return null;
      return parseGebcoElevationJson(res.body);
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'charted depth lookup failed: $e',
        context: 'weather_service: fetchWaterDepthM',
      ));
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  Future<List<WeatherPlace>> loadNamedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoritesKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => WeatherPlace.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'stored favorite locations failed to parse: $e',
        context: 'weather_service: loadNamedLocations',
      ));
      return const [];
    }
  }

  Future<void> saveNamedLocations(List<WeatherPlace> places) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _favoritesKey,
      jsonEncode(places.map((p) => p.toJson()).toList()),
    );
  }

  Future<List<WeatherPlace>> addNamedLocation(WeatherPlace place) async {
    final list = [...await loadNamedLocations()];
    list.removeWhere(
      (p) =>
          (p.lat - place.lat).abs() < 0.0001 &&
          (p.lon - place.lon).abs() < 0.0001,
    );
    list.insert(0, place);
    if (list.length > 12) list.removeRange(12, list.length);
    await saveNamedLocations(list);
    return list;
  }

  Future<List<WeatherPlace>> removeNamedLocation(WeatherPlace place) async {
    final list = [...await loadNamedLocations()];
    list.removeWhere(
      (p) =>
          p.name == place.name &&
          (p.lat - place.lat).abs() < 0.0001 &&
          (p.lon - place.lon).abs() < 0.0001,
    );
    await saveNamedLocations(list);
    return list;
  }

  Future<void> _saveCache(WeatherBundle b) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(b.toJson()));
  }

  Future<WeatherBundle?> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return WeatherBundle.fromStorage(map);
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'stored weather cache failed to parse: $e',
        context: 'weather_service: loadCache',
      ));
      return null;
    }
  }
}

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);
  @override
  String toString() => message;
}

class WeatherBundle {
  final double lat;
  final double lon;
  final DateTime fetchedAt;
  final bool fromCache;
  final double? tempC;
  final double? windMs;
  final double? windDirDeg;
  final int? weatherCode;
  final double? humidity;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;
  final List<HourlyMarine> marine;
  /// Human place name (SUG3).
  final String? placeName;
  /// GEBCO elevation meters: negative => water depth (absolute value).
  final double? waterDepthM;

  const WeatherBundle({
    required this.lat,
    required this.lon,
    required this.fetchedAt,
    required this.fromCache,
    this.tempC,
    this.windMs,
    this.windDirDeg,
    this.weatherCode,
    this.humidity,
    this.hourly = const [],
    this.daily = const [],
    this.marine = const [],
    this.placeName,
    this.waterDepthM,
  });

  WeatherBundle copyWith({
    bool? fromCache,
    String? placeName,
    double? waterDepthM,
  }) =>
      WeatherBundle(
        lat: lat,
        lon: lon,
        fetchedAt: fetchedAt,
        fromCache: fromCache ?? this.fromCache,
        tempC: tempC,
        windMs: windMs,
        windDirDeg: windDirDeg,
        weatherCode: weatherCode,
        humidity: humidity,
        hourly: hourly,
        daily: daily,
        marine: marine,
        placeName: placeName ?? this.placeName,
        waterDepthM: waterDepthM ?? this.waterDepthM,
      );

  factory WeatherBundle.fromJson({
    required Map<String, dynamic> forecast,
    Map<String, dynamic>? marine,
    required double lat,
    required double lon,
    required DateTime fetchedAt,
    required bool fromCache,
    String? placeName,
    double? waterDepthM,
  }) {
    final current = forecast['current'] as Map<String, dynamic>? ?? {};
    final hourly = forecast['hourly'] as Map<String, dynamic>? ?? {};
    final daily = forecast['daily'] as Map<String, dynamic>? ?? {};

    final hTimes = (hourly['time'] as List? ?? const []).cast<String>();
    final hTemp = (hourly['temperature_2m'] as List? ?? const []);
    final hWind = (hourly['wind_speed_10m'] as List? ?? const []);
    final hDir = (hourly['wind_direction_10m'] as List? ?? const []);
    final hGust = (hourly['wind_gusts_10m'] as List? ?? const []);
    final hPop = (hourly['precipitation_probability'] as List? ?? const []);

    final hourlyOut = <HourlyWeather>[];
    final limit = hTimes.length.clamp(0, 24);
    for (var i = 0; i < limit; i++) {
      hourlyOut.add(HourlyWeather(
        time: DateTime.tryParse(hTimes[i]) ?? DateTime.now(),
        tempC: _num(hTemp, i),
        windMs: _num(hWind, i),
        windDirDeg: _num(hDir, i),
        windGustMs: _num(hGust, i),
        precipProb: _num(hPop, i),
      ));
    }

    final dTimes = (daily['time'] as List? ?? const []).cast<String>();
    final dMax = (daily['temperature_2m_max'] as List? ?? const []);
    final dMin = (daily['temperature_2m_min'] as List? ?? const []);
    final dWind = (daily['wind_speed_10m_max'] as List? ?? const []);
    final dCode = (daily['weather_code'] as List? ?? const []);
    final dPrecip = (daily['precipitation_sum'] as List? ?? const []);
    final dailyOut = <DailyWeather>[];
    for (var i = 0; i < dTimes.length; i++) {
      dailyOut.add(DailyWeather(
        date: DateTime.tryParse(dTimes[i]) ?? DateTime.now(),
        maxC: _num(dMax, i),
        minC: _num(dMin, i),
        maxWindMs: _num(dWind, i),
        weatherCode: _int(dCode, i),
        precipMm: _num(dPrecip, i),
      ));
    }

    final marineOut = <HourlyMarine>[];
    if (marine != null) {
      final mh = marine['hourly'] as Map<String, dynamic>? ?? {};
      final mTimes = (mh['time'] as List? ?? const []).cast<String>();
      final mH = (mh['wave_height'] as List? ?? const []);
      final mD = (mh['wave_direction'] as List? ?? const []);
      final mP = (mh['wave_period'] as List? ?? const []);
      final mLimit = mTimes.length.clamp(0, 24);
      for (var i = 0; i < mLimit; i++) {
        marineOut.add(HourlyMarine(
          time: DateTime.tryParse(mTimes[i]) ?? DateTime.now(),
          waveHeightM: _num(mH, i),
          waveDirDeg: _num(mD, i),
          wavePeriodS: _num(mP, i),
        ));
      }
    }

    return WeatherBundle(
      lat: lat,
      lon: lon,
      fetchedAt: fetchedAt,
      fromCache: fromCache,
      tempC: (current['temperature_2m'] as num?)?.toDouble(),
      windMs: (current['wind_speed_10m'] as num?)?.toDouble(),
      windDirDeg: (current['wind_direction_10m'] as num?)?.toDouble(),
      weatherCode: (current['weather_code'] as num?)?.toInt(),
      humidity: (current['relative_humidity_2m'] as num?)?.toDouble(),
      hourly: hourlyOut,
      daily: dailyOut,
      marine: marineOut,
      placeName: placeName,
      waterDepthM: waterDepthM,
    );
  }

  factory WeatherBundle.fromStorage(Map<String, dynamic> j) {
    return WeatherBundle(
      lat: (j['lat'] as num).toDouble(),
      lon: (j['lon'] as num).toDouble(),
      fetchedAt: DateTime.parse(j['fetchedAt'] as String),
      fromCache: true,
      tempC: (j['tempC'] as num?)?.toDouble(),
      windMs: (j['windMs'] as num?)?.toDouble(),
      windDirDeg: (j['windDirDeg'] as num?)?.toDouble(),
      weatherCode: (j['weatherCode'] as num?)?.toInt(),
      humidity: (j['humidity'] as num?)?.toDouble(),
      hourly: (j['hourly'] as List? ?? const [])
          .map((e) => HourlyWeather.fromJson(e as Map<String, dynamic>))
          .toList(),
      daily: (j['daily'] as List? ?? const [])
          .map((e) => DailyWeather.fromJson(e as Map<String, dynamic>))
          .toList(),
      marine: (j['marine'] as List? ?? const [])
          .map((e) => HourlyMarine.fromJson(e as Map<String, dynamic>))
          .toList(),
      placeName: j['placeName'] as String?,
      waterDepthM: (j['waterDepthM'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'fetchedAt': fetchedAt.toIso8601String(),
        'tempC': tempC,
        'windMs': windMs,
        'windDirDeg': windDirDeg,
        'weatherCode': weatherCode,
        'humidity': humidity,
        'hourly': hourly.map((e) => e.toJson()).toList(),
        'daily': daily.map((e) => e.toJson()).toList(),
        'marine': marine.map((e) => e.toJson()).toList(),
        if (placeName != null) 'placeName': placeName,
        if (waterDepthM != null) 'waterDepthM': waterDepthM,
      };

  /// Human depth/elevation line for UI. Source is always meters (GEBCO).
  String? depthLabel([
    UnitSystem system = UnitSystem.metric,
    DepthUnitPref? depth,
  ]) =>
      UnitConverter.formatChartDepthM(waterDepthM, system, depth: depth);

  static double? _num(List list, int i) {
    if (i >= list.length) return null;
    final v = list[i];
    if (v is num) return v.toDouble();
    return null;
  }

  static int? _int(List list, int i) {
    if (i >= list.length) return null;
    final v = list[i];
    if (v is num) return v.toInt();
    return null;
  }

  static String weatherCodeLabel(int? code) {
    if (code == null) return 'Unknown';
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Fog';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Showers';
    if (code <= 86) return 'Snow showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Code $code';
  }
}

class HourlyWeather {
  final DateTime time;
  final double? tempC;
  final double? windMs;
  final double? windDirDeg;
  final double? windGustMs;
  final double? precipProb;

  const HourlyWeather({
    required this.time,
    this.tempC,
    this.windMs,
    this.windDirDeg,
    this.windGustMs,
    this.precipProb,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> j) => HourlyWeather(
        time: DateTime.parse(j['time'] as String),
        tempC: (j['tempC'] as num?)?.toDouble(),
        windMs: (j['windMs'] as num?)?.toDouble(),
        windDirDeg: (j['windDirDeg'] as num?)?.toDouble(),
        windGustMs: (j['windGustMs'] as num?)?.toDouble(),
        precipProb: (j['precipProb'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'tempC': tempC,
        'windMs': windMs,
        'windDirDeg': windDirDeg,
        'windGustMs': windGustMs,
        'precipProb': precipProb,
      };
}

class DailyWeather {
  final DateTime date;
  final double? maxC;
  final double? minC;
  final double? maxWindMs;
  final int? weatherCode;
  final double? precipMm;

  const DailyWeather({
    required this.date,
    this.maxC,
    this.minC,
    this.maxWindMs,
    this.weatherCode,
    this.precipMm,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> j) => DailyWeather(
        date: DateTime.parse(j['date'] as String),
        maxC: (j['maxC'] as num?)?.toDouble(),
        minC: (j['minC'] as num?)?.toDouble(),
        maxWindMs: (j['maxWindMs'] as num?)?.toDouble(),
        weatherCode: (j['weatherCode'] as num?)?.toInt(),
        precipMm: (j['precipMm'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'maxC': maxC,
        'minC': minC,
        'maxWindMs': maxWindMs,
        'weatherCode': weatherCode,
        'precipMm': precipMm,
      };
}

class HourlyMarine {
  final DateTime time;
  final double? waveHeightM;
  final double? waveDirDeg;
  final double? wavePeriodS;

  const HourlyMarine({
    required this.time,
    this.waveHeightM,
    this.waveDirDeg,
    this.wavePeriodS,
  });

  factory HourlyMarine.fromJson(Map<String, dynamic> j) => HourlyMarine(
        time: DateTime.parse(j['time'] as String),
        waveHeightM: (j['waveHeightM'] as num?)?.toDouble(),
        waveDirDeg: (j['waveDirDeg'] as num?)?.toDouble(),
        wavePeriodS: (j['wavePeriodS'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'waveHeightM': waveHeightM,
        'waveDirDeg': waveDirDeg,
        'wavePeriodS': wavePeriodS,
      };
}

/// Great-circle distance in nautical miles (S3 passage planning).
double haversineNm(double lat1, double lon1, double lat2, double lon2) {
  const rNm = 3440.065;
  double rad(double d) => d * math.pi / 180.0;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return rNm * c;
}

/// Passage summary: total NM, hours at [speedKn], fuel at [litersPerHour].
({double nm, double hours, double liters}) planPassage({
  required List<({double lat, double lon})> waypoints,
  required double speedKn,
  required double litersPerHour,
}) {
  var nm = 0.0;
  for (var i = 1; i < waypoints.length; i++) {
    nm += haversineNm(
      waypoints[i - 1].lat,
      waypoints[i - 1].lon,
      waypoints[i].lat,
      waypoints[i].lon,
    );
  }
  final speed = speedKn <= 0 ? 1.0 : speedKn;
  final hours = nm / speed;
  final liters = hours * (litersPerHour < 0 ? 0 : litersPerHour);
  return (nm: nm, hours: hours, liters: liters);
}

// ── SUG3 pure JSON parsers (unit-tested without network) ─────────────────────

List<WeatherPlace> parsePlaceSearchJson(String body) {
  final map = jsonDecode(body) as Map<String, dynamic>;
  final results = map['results'] as List? ?? const [];
  return results.map((e) {
    final m = e as Map<String, dynamic>;
    return WeatherPlace(
      name: m['name'] as String? ?? 'Place',
      lat: (m['latitude'] as num).toDouble(),
      lon: (m['longitude'] as num).toDouble(),
      admin1: m['admin1'] as String?,
      country: m['country'] as String?,
    );
  }).toList();
}

String? parseNominatimReverseJson(String body) {
  final map = jsonDecode(body) as Map<String, dynamic>;
  final display = map['display_name'] as String?;
  if (display != null && display.isNotEmpty) {
    // Keep first 2-3 comma parts for a short place label.
    final parts = display.split(',').map((s) => s.trim()).toList();
    if (parts.length <= 2) return parts.join(', ');
    return '${parts[0]}, ${parts[1]}';
  }
  final addr = map['address'] as Map<String, dynamic>?;
  if (addr == null) return null;
  final name = addr['city'] ??
      addr['town'] ??
      addr['village'] ??
      addr['municipality'] ??
      addr['county'] ??
      addr['state'];
  final country = addr['country'];
  if (name == null) return country as String?;
  if (country == null) return '$name';
  return '$name, $country';
}

/// GEBCO elevation meters (negative = below sea level).
double? parseGebcoElevationJson(String body) {
  final map = jsonDecode(body) as Map<String, dynamic>;
  final results = map['results'] as List? ?? const [];
  if (results.isEmpty) return null;
  final elev = (results.first as Map<String, dynamic>)['elevation'];
  if (elev is num) return elev.toDouble();
  return null;
}
