import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/departure_window_scorer.dart';
import 'package:sisu_mate/services/weather_service.dart';

/// #232: departure-window planner — pure scoring over an already-fetched
/// synthetic multi-hour bundle, no network involved.
void main() {
  List<HourlyWeather> hourlyFrom(List<({int hour, double windKt, double? gustKt})> spec) {
    return spec
        .map((s) => HourlyWeather(
              time: DateTime(2026, 7, 9, s.hour),
              windMs: s.windKt * 0.514444,
              windGustMs: s.gustKt == null ? null : s.gustKt! * 0.514444,
            ))
        .toList();
  }

  test('a clear best window ranks first ahead of a shorter one and any '
      'breaching windows', () {
    final hourly = hourlyFrom([
      (hour: 0, windKt: 25, gustKt: null), // breach
      (hour: 1, windKt: 10, gustKt: null), // clear, short (1h)
      (hour: 2, windKt: 30, gustKt: null), // breach
      (hour: 3, windKt: 8, gustKt: null), // clear, long run starts
      (hour: 4, windKt: 9, gustKt: null),
      (hour: 5, windKt: 7, gustKt: null), // clear, long run (3h)
    ]);
    final windows = scoreDepartureWindows(
      hourly: hourly,
      thresholds: const DepartureWindowThresholds(maxWindKt: 15),
    );

    final best = windows.first;
    expect(best.clearsThresholds, isTrue);
    expect(best.start, DateTime(2026, 7, 9, 3));
    expect(best.duration, const Duration(hours: 3));
  });

  test('no window clears thresholds — every window is a breach, still '
      'ranked (longest first), never empty/crashing', () {
    final hourly = hourlyFrom([
      (hour: 0, windKt: 25, gustKt: null),
      (hour: 1, windKt: 30, gustKt: null),
      (hour: 2, windKt: 22, gustKt: null),
    ]);
    final windows = scoreDepartureWindows(
      hourly: hourly,
      thresholds: const DepartureWindowThresholds(maxWindKt: 15),
    );

    expect(windows, isNotEmpty);
    expect(windows.every((w) => !w.clearsThresholds), isTrue);
    expect(windows.single.breachReasons, isNotEmpty);
  });

  test('all windows clear — a single window spanning the whole range when '
      'nothing breaches', () {
    final hourly = hourlyFrom([
      (hour: 0, windKt: 8, gustKt: null),
      (hour: 1, windKt: 9, gustKt: null),
      (hour: 2, windKt: 7, gustKt: null),
    ]);
    final windows = scoreDepartureWindows(
      hourly: hourly,
      thresholds: const DepartureWindowThresholds(maxWindKt: 15),
    );

    expect(windows, hasLength(1));
    expect(windows.single.clearsThresholds, isTrue);
    expect(windows.single.duration, const Duration(hours: 3));
  });

  test('gust threshold is checked independently of sustained wind', () {
    final hourly = hourlyFrom([
      (hour: 0, windKt: 10, gustKt: 30), // sustained ok, gust breaches
    ]);
    final windows = scoreDepartureWindows(
      hourly: hourly,
      thresholds: const DepartureWindowThresholds(maxWindKt: 15, maxGustKt: 20),
    );
    expect(windows.single.clearsThresholds, isFalse);
    expect(windows.single.breachReasons.first, contains('gust'));
  });

  test('wave height threshold matched by hour against marine data', () {
    final hourly = hourlyFrom([
      (hour: 0, windKt: 8, gustKt: null),
    ]);
    final marine = [
      HourlyMarine(time: DateTime(2026, 7, 9, 0), waveHeightM: 2.5),
    ];
    final windows = scoreDepartureWindows(
      hourly: hourly,
      marine: marine,
      thresholds: const DepartureWindowThresholds(maxWaveHeightM: 1.5),
    );
    expect(windows.single.clearsThresholds, isFalse);
    expect(windows.single.breachReasons.first, contains('wave'));
  });

  test('no thresholds set — every hour trivially clears', () {
    final hourly = hourlyFrom([
      (hour: 0, windKt: 40, gustKt: 60),
    ]);
    final windows = scoreDepartureWindows(
      hourly: hourly,
      thresholds: const DepartureWindowThresholds(),
    );
    expect(windows.single.clearsThresholds, isTrue);
  });

  test('empty hourly list returns no windows, not an error', () {
    expect(
      scoreDepartureWindows(
        hourly: const [],
        thresholds: const DepartureWindowThresholds(maxWindKt: 15),
      ),
      isEmpty,
    );
  });
}
