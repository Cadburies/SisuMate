import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/core/units.dart';
import 'package:sisu_mate/services/weather_service.dart';

WeatherBundle _sampleBundle({
  required DateTime fetchedAt,
  bool fromCache = false,
  double tempC = 18,
}) =>
    WeatherBundle(
      lat: 32.7,
      lon: -117.2,
      fetchedAt: fetchedAt,
      fromCache: fromCache,
      tempC: tempC,
      windMs: 5,
      weatherCode: 0,
    );

void main() {
  group('SUG3 place / depth parsers', () {
    test('parsePlaceSearchJson maps Open-Meteo geocoding hits', () {
      const body = '''
{
  "results": [
    {"name": "San Diego", "latitude": 32.7157, "longitude": -117.1611,
     "admin1": "California", "country": "United States"}
  ]
}''';
      final places = parsePlaceSearchJson(body);
      expect(places, hasLength(1));
      expect(places.first.name, 'San Diego');
      expect(places.first.lat, closeTo(32.7157, 0.0001));
      expect(places.first.label, contains('California'));
    });

    test('parseNominatimReverseJson shortens display_name', () {
      const body = '''
{
  "display_name": "Point Loma, San Diego, California, United States"
}''';
      expect(
        parseNominatimReverseJson(body),
        'Point Loma, San Diego',
      );
    });

    test('parseGebcoElevationJson reads elevation meters', () {
      const body = '''
{"results":[{"elevation":-42.5,"location":{"lat":32.7,"lng":-117.2}}]}''';
      expect(parseGebcoElevationJson(body), closeTo(-42.5, 0.01));
    });

    test('depthLabel formats water depth metric and imperial', () {
      final b = WeatherBundle(
        lat: 1,
        lon: 2,
        fetchedAt: DateTime(2026, 1, 1),
        fromCache: false,
        waterDepthM: -30,
      );
      expect(b.depthLabel(UnitSystem.metric), 'Charted depth ~30 m');
      expect(
        b.depthLabel(UnitSystem.imperial, DepthUnitPref.feet),
        contains('ft'),
      );
      expect(
        b.depthLabel(UnitSystem.imperial, DepthUnitPref.feet),
        isNot(contains(' m')),
      );
    });

    test('depthLabel formats land elevation when positive', () {
      final b = WeatherBundle(
        lat: 1,
        lon: 2,
        fetchedAt: DateTime(2026, 1, 1),
        fromCache: false,
        waterDepthM: 120,
      );
      expect(b.depthLabel(UnitSystem.metric), 'Land elev. ~120 m');
    });
  });

  group('haversineNm / planPassage (S3)', () {
    test('distance between nearby points is positive and small', () {
      // ~60 NM is roughly 1° latitude
      final nm = haversineNm(0, 0, 1, 0);
      expect(nm, greaterThan(59));
      expect(nm, lessThan(61));
    });

    test('zero-length route when single waypoint', () {
      final p = planPassage(
        waypoints: [(lat: 10.0, lon: 20.0)],
        speedKn: 6,
        litersPerHour: 3,
      );
      expect(p.nm, 0);
      expect(p.hours, 0);
      expect(p.liters, 0);
    });

    test('plan scales with speed and burn', () {
      final wps = [
        (lat: 0.0, lon: 0.0),
        (lat: 1.0, lon: 0.0),
      ];
      final slow = planPassage(
        waypoints: wps,
        speedKn: 5,
        litersPerHour: 2,
      );
      final fast = planPassage(
        waypoints: wps,
        speedKn: 10,
        litersPerHour: 2,
      );
      expect(slow.nm, closeTo(fast.nm, 0.01));
      expect(slow.hours, closeTo(fast.hours * 2, 0.1));
      expect(slow.liters, greaterThan(fast.liters));
    });
  });

  group('WeatherBundle parsing', () {
    test('fromJson maps current + hourly', () {
      final b = WeatherBundle.fromJson(
        forecast: {
          'current': {
            'temperature_2m': 22.5,
            'wind_speed_10m': 12,
            'wind_direction_10m': 180,
            'weather_code': 0,
            'relative_humidity_2m': 55,
          },
          'hourly': {
            'time': ['2026-07-09T12:00', '2026-07-09T13:00'],
            'temperature_2m': [22.0, 23.0],
            'wind_speed_10m': [10.0, 11.0],
            'wind_direction_10m': [170.0, 180.0],
            'precipitation_probability': [10, 20],
          },
          'daily': {
            'time': ['2026-07-09'],
            'temperature_2m_max': [28.0],
            'temperature_2m_min': [18.0],
            'wind_speed_10m_max': [15.0],
            'weather_code': [1],
            'precipitation_sum': [0.0],
          },
        },
        marine: {
          'hourly': {
            'time': ['2026-07-09T12:00'],
            'wave_height': [1.2],
            'wave_direction': [90.0],
            'wave_period': [6.0],
          },
        },
        lat: 1,
        lon: 2,
        fetchedAt: DateTime(2026, 7, 9),
        fromCache: false,
      );
      expect(b.tempC, 22.5);
      expect(b.windMs, 12);
      expect(b.hourly, hasLength(2));
      expect(b.daily, hasLength(1));
      expect(b.marine.single.waveHeightM, 1.2);
      expect(WeatherBundle.weatherCodeLabel(0), 'Clear');

      final roundTrip = WeatherBundle.fromStorage(b.toJson());
      expect(roundTrip.tempC, 22.5);
      expect(roundTrip.hourly, hasLength(2));
    });

    // #231: wind gusts alongside sustained wind.
    test('fromJson maps wind_gusts_10m onto HourlyWeather.windGustMs', () {
      final b = WeatherBundle.fromJson(
        forecast: {
          'hourly': {
            'time': ['2026-07-09T12:00', '2026-07-09T13:00'],
            'wind_speed_10m': [10.0, 11.0],
            'wind_gusts_10m': [14.0, 18.5],
          },
        },
        lat: 1,
        lon: 2,
        fetchedAt: DateTime(2026, 7, 9),
        fromCache: false,
      );
      expect(b.hourly[0].windMs, 10.0);
      expect(b.hourly[0].windGustMs, 14.0);
      expect(b.hourly[1].windGustMs, 18.5);
    });

    test('fromJson leaves windGustMs null when the response has no gust '
        'field (older cache / provider response)', () {
      final b = WeatherBundle.fromJson(
        forecast: {
          'hourly': {
            'time': ['2026-07-09T12:00'],
            'wind_speed_10m': [10.0],
          },
        },
        lat: 1,
        lon: 2,
        fetchedAt: DateTime(2026, 7, 9),
        fromCache: false,
      );
      expect(b.hourly.single.windMs, 10.0);
      expect(b.hourly.single.windGustMs, isNull);
    });

    test('toJson/fromStorage round-trips windGustMs, and fromStorage on '
        'pre-#231 cached JSON (no windGustMs key) degrades to null', () {
      final withGust = WeatherBundle.fromJson(
        forecast: {
          'hourly': {
            'time': ['2026-07-09T12:00'],
            'wind_speed_10m': [10.0],
            'wind_gusts_10m': [16.0],
          },
        },
        lat: 1,
        lon: 2,
        fetchedAt: DateTime(2026, 7, 9),
        fromCache: false,
      );
      final roundTrip = WeatherBundle.fromStorage(withGust.toJson());
      expect(roundTrip.hourly.single.windGustMs, 16.0);

      final legacyJson = withGust.toJson();
      (legacyJson['hourly'] as List)
          .cast<Map<String, dynamic>>()
          .first
          .remove('windGustMs');
      final legacy = WeatherBundle.fromStorage(legacyJson);
      expect(legacy.hourly.single.windGustMs, isNull);
      expect(legacy.hourly.single.windMs, 10.0);
    });
  });

  /// TEST26 — offline / stale cache: never hang; fail only with no cache.
  group('TEST26 weather offline + stale cache', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isCacheFresh within max age, stale beyond', () {
      final now = DateTime.utc(2026, 7, 30, 12);
      expect(
        WeatherService.isCacheFresh(
          now.subtract(const Duration(hours: 1)),
          now: now,
        ),
        isTrue,
      );
      expect(
        WeatherService.isCacheFresh(
          now.subtract(WeatherService.cacheMaxAge + const Duration(minutes: 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('loadCache returns null for missing or corrupt JSON', () async {
      final svc = WeatherService();
      expect(await svc.loadCache(), isNull);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('weather_cache_v2', '{not-json');
      expect(await svc.loadCache(), isNull);
    });

    test('offline with fresh cache returns fromCache without hanging',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final cached = _sampleBundle(
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        tempC: 21,
      );
      await prefs.setString('weather_cache_v2', jsonEncode(cached.toJson()));

      final client = MockClient((request) async {
        throw Exception('network offline');
      });

      final bundle = await WeatherService().fetch(
        lat: 32.7,
        lon: -117.2,
        client: client,
      );
      expect(bundle.fromCache, isTrue);
      expect(bundle.tempC, 21);
    });

    test('offline with STALE cache still returns it (never hang / hard-fail)',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final staleAt = DateTime.now().subtract(const Duration(hours: 48));
      final cached = _sampleBundle(fetchedAt: staleAt, tempC: 9);
      await prefs.setString('weather_cache_v2', jsonEncode(cached.toJson()));

      final client = MockClient((request) async {
        throw Exception('network offline');
      });

      final bundle = await WeatherService().fetch(
        lat: 32.7,
        lon: -117.2,
        client: client,
      );
      expect(bundle.fromCache, isTrue);
      expect(bundle.tempC, 9);
      expect(WeatherService.isCacheFresh(bundle.fetchedAt), isFalse);
    });

    test('offline with no cache throws WeatherException quickly', () async {
      final client = MockClient((request) async {
        throw Exception('network offline');
      });

      await expectLater(
        WeatherService().fetch(lat: 1, lon: 2, client: client),
        throwsA(isA<WeatherException>()),
      );
    });

    test('HTTP non-200 falls back to cache', () async {
      final prefs = await SharedPreferences.getInstance();
      final cached = _sampleBundle(
        fetchedAt: DateTime.now(),
        tempC: 15,
      );
      await prefs.setString('weather_cache_v2', jsonEncode(cached.toJson()));

      final client = MockClient((request) async {
        return http.Response('error', 503);
      });

      final bundle = await WeatherService().fetch(
        lat: 1,
        lon: 2,
        client: client,
      );
      expect(bundle.fromCache, isTrue);
      expect(bundle.tempC, 15);
    });

    test('searchPlaces returns empty on network failure (no hang)', () async {
      final client = MockClient((request) async {
        throw Exception('offline');
      });
      final places =
          await WeatherService().searchPlaces('San Diego', client: client);
      expect(places, isEmpty);
    });

    test('networkTimeout is short enough for offline UX', () {
      expect(WeatherService.networkTimeout.inSeconds, lessThanOrEqualTo(15));
    });

    // #242: Open-Meteo's actual default wind-speed unit is km/h, not m/s —
    // windMs (and every UnitConverter.formatSpeedFromMs caller) treats the
    // stored value as true m/s, so the request must ask for m/s explicitly
    // or every displayed wind speed is inflated ~3.6x.
    test('fetch() requests windspeed_unit=ms from Open-Meteo', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        if (request.url.host == 'api.open-meteo.com') {
          capturedUri = request.url;
        }
        return http.Response(
          jsonEncode({
            'current': <String, dynamic>{},
            'hourly': <String, dynamic>{'time': <String>[]},
            'daily': <String, dynamic>{'time': <String>[]},
          }),
          200,
        );
      });

      await WeatherService().fetch(lat: 1, lon: 2, client: client);

      expect(capturedUri, isNotNull);
      expect(capturedUri!.queryParameters['windspeed_unit'], 'ms');
    });
  });
}
