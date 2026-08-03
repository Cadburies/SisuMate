import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/boat_polar_service.dart';

/// #236: boat polar performance data — pure lookup/interpolation +
/// per-leg passage planning, no DB/network involved.
void main() {
  group('parsePolarTable / encodePolarTable', () {
    test('round-trips a table through JSON', () {
      const points = [
        PolarPoint(twaDeg: 45, twsKt: 10, boatSpeedKt: 6.5),
        PolarPoint(twaDeg: 90, twsKt: 10, boatSpeedKt: 7.2),
      ];
      final json = encodePolarTable(points);
      expect(parsePolarTable(json), points);
    });

    test('null/empty/malformed input degrades to an empty table, never '
        'throws', () {
      expect(parsePolarTable(null), isEmpty);
      expect(parsePolarTable(''), isEmpty);
      expect(parsePolarTable('{not-json'), isEmpty);
    });
  });

  group('interpolatePolarBoatSpeedKt', () {
    test('exact match returns that point\'s boat speed directly', () {
      const polar = [
        PolarPoint(twaDeg: 90, twsKt: 15, boatSpeedKt: 7.0),
        PolarPoint(twaDeg: 120, twsKt: 15, boatSpeedKt: 8.0),
      ];
      final speed = interpolatePolarBoatSpeedKt(
          polar: polar, twaDeg: 90, twsKt: 15);
      expect(speed, 7.0);
    });

    test('a point roughly between two entries interpolates between their '
        'boat speeds, not equal to either', () {
      const polar = [
        PolarPoint(twaDeg: 90, twsKt: 15, boatSpeedKt: 6.0),
        PolarPoint(twaDeg: 100, twsKt: 15, boatSpeedKt: 8.0),
      ];
      final speed = interpolatePolarBoatSpeedKt(
          polar: polar, twaDeg: 95, twsKt: 15)!;
      expect(speed, greaterThan(6.0));
      expect(speed, lessThan(8.0));
    });

    test('closer to one entry weights the result toward it', () {
      const polar = [
        PolarPoint(twaDeg: 90, twsKt: 15, boatSpeedKt: 6.0),
        PolarPoint(twaDeg: 120, twsKt: 15, boatSpeedKt: 9.0),
      ];
      final nearFirst = interpolatePolarBoatSpeedKt(
          polar: polar, twaDeg: 92, twsKt: 15)!;
      final nearSecond = interpolatePolarBoatSpeedKt(
          polar: polar, twaDeg: 118, twsKt: 15)!;
      expect(nearFirst, lessThan(nearSecond));
      expect((nearFirst - 6.0).abs(), lessThan((nearFirst - 9.0).abs()));
    });

    test('TWA is treated symmetrically (port/starboard)', () {
      const polar = [PolarPoint(twaDeg: 90, twsKt: 15, boatSpeedKt: 7.0)];
      final port = interpolatePolarBoatSpeedKt(
          polar: polar, twaDeg: -90, twsKt: 15);
      final starboard = interpolatePolarBoatSpeedKt(
          polar: polar, twaDeg: 90, twsKt: 15);
      expect(port, starboard);
    });

    test('empty table returns null so the caller falls back to flat speed',
        () {
      expect(
        interpolatePolarBoatSpeedKt(polar: const [], twaDeg: 90, twsKt: 15),
        isNull,
      );
    });
  });

  group('bearingDeg', () {
    test('due north is 0/360, due east is ~90', () {
      expect(bearingDeg(0, 0, 1, 0), closeTo(0, 0.01));
      expect(bearingDeg(0, 0, 0, 1), closeTo(90, 0.5));
    });
  });

  group('planPassageWithPolar', () {
    final waypoints = [
      (lat: 0.0, lon: 0.0),
      (lat: 1.0, lon: 0.0), // due north
    ];

    test('with no polar data, output matches flat-speed planPassage '
        'exactly — no regression', () {
      final result = planPassageWithPolar(
        waypoints: waypoints,
        flatSpeedKn: 6,
        litersPerHour: 3,
        polar: const [],
      );
      // ~60nm due north at 6kn ≈ 10h, matching plain planPassage's math.
      expect(result.nm, closeTo(60, 1));
      expect(result.hours, closeTo(result.nm / 6, 0.01));
      expect(result.liters, closeTo(result.hours * 3, 0.01));
    });

    test('with polar data but no wind data for any leg, still falls back '
        'to flat speed exactly', () {
      const polar = [PolarPoint(twaDeg: 0, twsKt: 15, boatSpeedKt: 9.0)];
      final withPolarNoWind = planPassageWithPolar(
        waypoints: waypoints,
        flatSpeedKn: 6,
        litersPerHour: 3,
        polar: polar,
      );
      final flat = planPassageWithPolar(
        waypoints: waypoints,
        flatSpeedKn: 6,
        litersPerHour: 3,
        polar: const [],
      );
      expect(withPolarNoWind.hours, flat.hours);
    });

    test('with polar + wind data for the leg, uses the polar-derived '
        'speed instead of the flat speed', () {
      const polar = [
        PolarPoint(twaDeg: 0, twsKt: 15, boatSpeedKt: 9.0),
      ];
      // Wind straight from the north (0deg) on a due-north leg (bearing
      // ~0deg) => TWA ~0deg => matches the polar point directly.
      final result = planPassageWithPolar(
        waypoints: waypoints,
        flatSpeedKn: 6,
        litersPerHour: 3,
        polar: polar,
        windByLegIndex: {1: (windDirDeg: 0, windSpeedKt: 15)},
      );
      // At 9kn instead of 6kn, hours should be lower (faster passage).
      expect(result.hours, lessThan(result.nm / 6));
      expect(result.hours, closeTo(result.nm / 9, 0.05));
    });
  });
}
