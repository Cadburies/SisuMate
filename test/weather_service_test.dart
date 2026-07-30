import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/weather_service.dart';

void main() {
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
      expect(b.windKn, 12);
      expect(b.hourly, hasLength(2));
      expect(b.daily, hasLength(1));
      expect(b.marine.single.waveHeightM, 1.2);
      expect(WeatherBundle.weatherCodeLabel(0), 'Clear');

      final roundTrip = WeatherBundle.fromStorage(b.toJson());
      expect(roundTrip.tempC, 22.5);
      expect(roundTrip.hourly, hasLength(2));
    });
  });
}
