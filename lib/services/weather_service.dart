import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Open-Meteo forecast (free, no API key) with local cache for offline (S3).
class WeatherService {
  static const _cacheKey = 'weather_cache_v1';
  static const _cacheMaxAge = Duration(hours: 3);

  /// Fetch forecast for [lat]/[lon]. Uses network when available; falls back
  /// to a still-fresh cache. Throws if neither works.
  Future<WeatherBundle> fetch({
    required double lat,
    required double lon,
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
            'temperature_2m,wind_speed_10m,wind_direction_10m,precipitation_probability',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,wind_speed_10m_max,precipitation_sum',
        'wind_speed_unit': 'kn',
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
        c.get(uri).timeout(const Duration(seconds: 12)),
        c.get(marineUri).timeout(const Duration(seconds: 12)),
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

      final bundle = WeatherBundle.fromJson(
        forecast: forecast,
        marine: marine,
        lat: lat,
        lon: lon,
        fetchedAt: DateTime.now(),
        fromCache: false,
      );
      await _saveCache(bundle);
      return bundle;
    } catch (e) {
      final cached = await loadCache();
      if (cached != null &&
          DateTime.now().difference(cached.fetchedAt) < _cacheMaxAge) {
        return cached.copyWith(fromCache: true);
      }
      if (e is WeatherException) rethrow;
      throw WeatherException('Could not load weather: $e');
    } finally {
      if (client == null) c.close();
    }
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
    } catch (_) {
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
  final double? windKn;
  final double? windDirDeg;
  final int? weatherCode;
  final double? humidity;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;
  final List<HourlyMarine> marine;

  const WeatherBundle({
    required this.lat,
    required this.lon,
    required this.fetchedAt,
    required this.fromCache,
    this.tempC,
    this.windKn,
    this.windDirDeg,
    this.weatherCode,
    this.humidity,
    this.hourly = const [],
    this.daily = const [],
    this.marine = const [],
  });

  WeatherBundle copyWith({bool? fromCache}) => WeatherBundle(
        lat: lat,
        lon: lon,
        fetchedAt: fetchedAt,
        fromCache: fromCache ?? this.fromCache,
        tempC: tempC,
        windKn: windKn,
        windDirDeg: windDirDeg,
        weatherCode: weatherCode,
        humidity: humidity,
        hourly: hourly,
        daily: daily,
        marine: marine,
      );

  factory WeatherBundle.fromJson({
    required Map<String, dynamic> forecast,
    Map<String, dynamic>? marine,
    required double lat,
    required double lon,
    required DateTime fetchedAt,
    required bool fromCache,
  }) {
    final current = forecast['current'] as Map<String, dynamic>? ?? {};
    final hourly = forecast['hourly'] as Map<String, dynamic>? ?? {};
    final daily = forecast['daily'] as Map<String, dynamic>? ?? {};

    final hTimes = (hourly['time'] as List? ?? const []).cast<String>();
    final hTemp = (hourly['temperature_2m'] as List? ?? const []);
    final hWind = (hourly['wind_speed_10m'] as List? ?? const []);
    final hDir = (hourly['wind_direction_10m'] as List? ?? const []);
    final hPop = (hourly['precipitation_probability'] as List? ?? const []);

    final hourlyOut = <HourlyWeather>[];
    final limit = hTimes.length.clamp(0, 24);
    for (var i = 0; i < limit; i++) {
      hourlyOut.add(HourlyWeather(
        time: DateTime.tryParse(hTimes[i]) ?? DateTime.now(),
        tempC: _num(hTemp, i),
        windKn: _num(hWind, i),
        windDirDeg: _num(hDir, i),
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
        maxWindKn: _num(dWind, i),
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
      windKn: (current['wind_speed_10m'] as num?)?.toDouble(),
      windDirDeg: (current['wind_direction_10m'] as num?)?.toDouble(),
      weatherCode: (current['weather_code'] as num?)?.toInt(),
      humidity: (current['relative_humidity_2m'] as num?)?.toDouble(),
      hourly: hourlyOut,
      daily: dailyOut,
      marine: marineOut,
    );
  }

  factory WeatherBundle.fromStorage(Map<String, dynamic> j) {
    return WeatherBundle(
      lat: (j['lat'] as num).toDouble(),
      lon: (j['lon'] as num).toDouble(),
      fetchedAt: DateTime.parse(j['fetchedAt'] as String),
      fromCache: true,
      tempC: (j['tempC'] as num?)?.toDouble(),
      windKn: (j['windKn'] as num?)?.toDouble(),
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
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'fetchedAt': fetchedAt.toIso8601String(),
        'tempC': tempC,
        'windKn': windKn,
        'windDirDeg': windDirDeg,
        'weatherCode': weatherCode,
        'humidity': humidity,
        'hourly': hourly.map((e) => e.toJson()).toList(),
        'daily': daily.map((e) => e.toJson()).toList(),
        'marine': marine.map((e) => e.toJson()).toList(),
      };

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
  final double? windKn;
  final double? windDirDeg;
  final double? precipProb;

  const HourlyWeather({
    required this.time,
    this.tempC,
    this.windKn,
    this.windDirDeg,
    this.precipProb,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> j) => HourlyWeather(
        time: DateTime.parse(j['time'] as String),
        tempC: (j['tempC'] as num?)?.toDouble(),
        windKn: (j['windKn'] as num?)?.toDouble(),
        windDirDeg: (j['windDirDeg'] as num?)?.toDouble(),
        precipProb: (j['precipProb'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'tempC': tempC,
        'windKn': windKn,
        'windDirDeg': windDirDeg,
        'precipProb': precipProb,
      };
}

class DailyWeather {
  final DateTime date;
  final double? maxC;
  final double? minC;
  final double? maxWindKn;
  final int? weatherCode;
  final double? precipMm;

  const DailyWeather({
    required this.date,
    this.maxC,
    this.minC,
    this.maxWindKn,
    this.weatherCode,
    this.precipMm,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> j) => DailyWeather(
        date: DateTime.parse(j['date'] as String),
        maxC: (j['maxC'] as num?)?.toDouble(),
        minC: (j['minC'] as num?)?.toDouble(),
        maxWindKn: (j['maxWindKn'] as num?)?.toDouble(),
        weatherCode: (j['weatherCode'] as num?)?.toInt(),
        precipMm: (j['precipMm'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'maxC': maxC,
        'minC': minC,
        'maxWindKn': maxWindKn,
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
