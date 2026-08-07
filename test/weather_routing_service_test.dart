import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/weather_routing_service.dart';
import 'package:sisu_mate/services/weather_service.dart' show haversineNm;

/// #238: isochrone weather routing — pure algorithm, synthetic wind fields
/// (no network/UI involved).
void main() {
  group('destinationPoint / bearingDeg round-trip', () {
    test('travelling a known bearing/distance lands at the expected point',
        () {
      const start = (lat: 10.0, lon: 20.0);
      final dest = destinationPoint(
        lat: start.lat,
        lon: start.lon,
        bearingDeg: 90,
        distanceNm: 60,
      );
      // Due east ~60nm at this latitude.
      expect(dest.lat, closeTo(start.lat, 0.5));
      expect(dest.lon, greaterThan(start.lon));
      expect(
        haversineNm(start.lat, start.lon, dest.lat, dest.lon),
        closeTo(60, 1),
      );
    });
  });

  group('computeIsochroneRoute', () {
    ({double windDirDeg, double windSpeedKt}) constantWind({
      required double lat,
      required double lon,
      required DateTime time,
    }) =>
        (windDirDeg: 0, windSpeedKt: 10);

    test('empty polar returns null', () {
      final route = computeIsochroneRoute(
        start: (lat: 0, lon: 0),
        end: (lat: 0, lon: 1),
        polar: const [],
        windAt: constantWind,
        startTime: DateTime(2026, 7, 9),
      );
      expect(route, isNull);
    });

    test('start already within arrival tolerance returns a trivial '
        'zero-duration route', () {
      final route = computeIsochroneRoute(
        start: (lat: 0, lon: 0),
        end: (lat: 0.001, lon: 0.001),
        polar: const [PolarPoint(twaDeg: 90, twsKt: 10, boatSpeedKt: 6)],
        windAt: constantWind,
        startTime: DateTime(2026, 7, 9),
      );
      expect(route, isNotNull);
      expect(route!.totalDuration, Duration.zero);
    });

    // "known-optimal answer": with boat speed constant regardless of TWA,
    // the isochrone method has no reason to deviate from the great circle
    // — total duration should land very close to distance/speed, and the
    // path shouldn't wander far from the direct line.
    test('uniform-speed polar converges to ~the great-circle time (known '
        'optimal answer)', () {
      const polar = [
        PolarPoint(twaDeg: 0, twsKt: 10, boatSpeedKt: 6),
        PolarPoint(twaDeg: 90, twsKt: 10, boatSpeedKt: 6),
        PolarPoint(twaDeg: 180, twsKt: 10, boatSpeedKt: 6),
      ];
      const start = (lat: 0.0, lon: 0.0);
      const end = (lat: 0.0, lon: 1.0);
      final totalNm = haversineNm(start.lat, start.lon, end.lat, end.lon);
      final optimalHours = totalNm / 6;

      final route = computeIsochroneRoute(
        start: start,
        end: end,
        polar: polar,
        windAt: constantWind,
        startTime: DateTime(2026, 7, 9),
        timeStep: const Duration(hours: 1),
        headingCount: 24,
      );

      expect(route, isNotNull);
      expect(route!.path.first.lat, closeTo(start.lat, 0.01));
      expect(route.path.last.lat, closeTo(end.lat, 0.1));
      expect(route.path.last.lon, closeTo(end.lon, 0.1));
      final actualHours = route.totalDuration.inMinutes / 60.0;
      expect(actualHours, closeTo(optimalHours, 1.0));
    });

    // Wind blows from directly ahead on the great-circle bearing, and the
    // polar is much slower dead upwind than reaching — the router must
    // find a faster route than naively ploughing straight upwind the
    // whole way, proving it actually uses the polar/wind to pick headings
    // rather than always heading straight at the destination.
    test('routes around a slow point of sail instead of ploughing straight '
        'upwind', () {
      const polar = [
        PolarPoint(twaDeg: 0, twsKt: 10, boatSpeedKt: 1), // dead upwind: slow
        PolarPoint(twaDeg: 60, twsKt: 10, boatSpeedKt: 7), // close reach: fast
        PolarPoint(twaDeg: 120, twsKt: 10, boatSpeedKt: 7),
        PolarPoint(twaDeg: 180, twsKt: 10, boatSpeedKt: 5),
      ];
      const start = (lat: 0.0, lon: 0.0);
      const end = (lat: 0.0, lon: 1.0); // due east, bearing ~90
      // Wind FROM the east — sailing straight at the destination is dead
      // upwind (TWA 0).
      ({double windDirDeg, double windSpeedKt}) windFromEast({
        required double lat,
        required double lon,
        required DateTime time,
      }) =>
          (windDirDeg: 90, windSpeedKt: 10);

      final totalNm = haversineNm(start.lat, start.lon, end.lat, end.lon);
      final naiveDeadUpwindHours = totalNm / 1; // if it just plodded straight

      final route = computeIsochroneRoute(
        start: start,
        end: end,
        polar: polar,
        windAt: windFromEast,
        startTime: DateTime(2026, 7, 9),
        timeStep: const Duration(hours: 1),
        headingCount: 24,
        maxSteps: 200,
      );

      expect(route, isNotNull);
      final actualHours = route!.totalDuration.inMinutes / 60.0;
      expect(actualHours, lessThan(naiveDeadUpwindHours),
          reason: 'must be faster than sailing dead upwind the whole way');
    });

    test('#291 waveSpeedFactor is 1.0 when Hs missing or calm', () {
      expect(waveSpeedFactor(null), 1.0);
      expect(waveSpeedFactor(0.5), 1.0);
      expect(waveSpeedFactor(5.0), 0.5);
      expect(waveSpeedFactor(2.9), lessThan(1.0));
      expect(waveSpeedFactor(2.9), greaterThan(0.5));
    });

    test('#291 high waves slow the route vs wind-only (same polar)', () {
      const polar = [
        PolarPoint(twaDeg: 0, twsKt: 10, boatSpeedKt: 6),
        PolarPoint(twaDeg: 90, twsKt: 10, boatSpeedKt: 6),
        PolarPoint(twaDeg: 180, twsKt: 10, boatSpeedKt: 6),
      ];
      const start = (lat: 0.0, lon: 0.0);
      const end = (lat: 0.0, lon: 1.0);

      final calm = computeIsochroneRoute(
        start: start,
        end: end,
        polar: polar,
        windAt: constantWind,
        startTime: DateTime(2026, 7, 9),
      );
      final rough = computeIsochroneRoute(
        start: start,
        end: end,
        polar: polar,
        windAt: constantWind,
        startTime: DateTime(2026, 7, 9),
        waveAt: ({required lat, required lon, required time}) => 4.0,
      );

      expect(calm, isNotNull);
      expect(rough, isNotNull);
      expect(
        rough!.totalDuration.inMinutes,
        greaterThan(calm!.totalDuration.inMinutes),
      );
    });
  });
}
