import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/anchor_alarm_service.dart';

/// #256 — pure geofence/danger-zone math, independent of UI/location
/// plumbing. Test points are built at the equator (lat=0) so 1 degree of
/// latitude and longitude are both ≈111,195 m (matching the same
/// spherical-earth radius `haversineNm` uses), which keeps the flat-earth
/// meter↔degree conversion below accurate to well under a meter at the
/// ~100 m scales used here.
void main() {
  const service = AnchorAlarmService();
  const anchorLat = 0.0;
  const anchorLon = 0.0;
  const metersPerDegree = 111194.93;

  // A point [northMeters]/[eastMeters] from the anchor, at the equator.
  ({double lat, double lon}) offset({double northMeters = 0, double eastMeters = 0}) {
    return (
      lat: anchorLat + northMeters / metersPerDegree,
      lon: anchorLon + eastMeters / metersPerDegree,
    );
  }

  group('distanceMeters', () {
    test('a known ~50m offset comes back close to 50m', () {
      final boat = offset(northMeters: 50);
      final d = service.distanceMeters(
        lat1: anchorLat,
        lon1: anchorLon,
        lat2: boat.lat,
        lon2: boat.lon,
      );
      expect(d, closeTo(50, 1));
    });

    test('zero distance for the same point', () {
      final d = service.distanceMeters(
          lat1: anchorLat, lon1: anchorLon, lat2: anchorLat, lon2: anchorLon);
      expect(d, closeTo(0, 0.001));
    });
  });

  group('isOutsideCircle', () {
    test('a boat inside the radius is not outside', () {
      final boat = offset(northMeters: 50);
      final outside = service.isOutsideCircle(
        boatLat: boat.lat,
        boatLon: boat.lon,
        anchorLat: anchorLat,
        anchorLon: anchorLon,
        radiusMeters: 100,
      );
      expect(outside, isFalse);
    });

    test('a boat beyond the radius is outside (dragging)', () {
      final boat = offset(northMeters: 150);
      final outside = service.isOutsideCircle(
        boatLat: boat.lat,
        boatLon: boat.lon,
        anchorLat: anchorLat,
        anchorLon: anchorLon,
        radiusMeters: 100,
      );
      expect(outside, isTrue);
    });
  });

  group('isInDangerZone', () {
    test(
        'a boat inside the outer radius, outside the inner radius, AND '
        'inside the sector is in the danger zone', () {
      final boat = offset(northMeters: 50); // bearing ≈ 0° (north)
      final inZone = service.isInDangerZone(
        boatLat: boat.lat,
        boatLon: boat.lon,
        anchorLat: anchorLat,
        anchorLon: anchorLon,
        centerDeg: 0,
        widthDeg: 60,
        innerRadiusMeters: 0,
        outerRadiusMeters: 100,
      );
      expect(inZone, isTrue);
    });

    test(
        'a boat inside the outer radius but outside the sector angle is '
        'not in the danger zone', () {
      final boat = offset(eastMeters: 50); // bearing ≈ 90° (east)
      final inZone = service.isInDangerZone(
        boatLat: boat.lat,
        boatLon: boat.lon,
        anchorLat: anchorLat,
        anchorLon: anchorLon,
        centerDeg: 0,
        widthDeg: 60, // covers -30..30
        innerRadiusMeters: 0,
        outerRadiusMeters: 100,
      );
      expect(inZone, isFalse);
    });

    test(
        'a boat within the sector angle but beyond the outer radius is '
        'not in the danger zone', () {
      final boat = offset(northMeters: 150); // bearing ≈ 0°, but far
      final inZone = service.isInDangerZone(
        boatLat: boat.lat,
        boatLon: boat.lon,
        anchorLat: anchorLat,
        anchorLon: anchorLon,
        centerDeg: 0,
        widthDeg: 60,
        innerRadiusMeters: 0,
        outerRadiusMeters: 100,
      );
      expect(inZone, isFalse);
    });

    test('sector wraps correctly across the 0/360 boundary', () {
      // bearing ≈ atan2(10, 100) ≈ 5.7°, just past the 0/360 seam for a
      // sector centered at 350° (i.e. covering 330°..360°..10°).
      final boat = offset(northMeters: 100, eastMeters: 10);
      final inZone = service.isInDangerZone(
        boatLat: boat.lat,
        boatLon: boat.lon,
        anchorLat: anchorLat,
        anchorLon: anchorLon,
        centerDeg: 350,
        widthDeg: 40,
        innerRadiusMeters: 0,
        outerRadiusMeters: 200,
      );
      expect(inZone, isTrue);
    });

    group('#262 — ring segment (inner radius)', () {
      test(
          'a boat within the sector angle but still inside the inner '
          'radius is NOT in the danger zone (still safely within the '
          'swinging circle)', () {
        final boat = offset(northMeters: 20); // bearing ≈ 0°, close in
        final inZone = service.isInDangerZone(
          boatLat: boat.lat,
          boatLon: boat.lon,
          anchorLat: anchorLat,
          anchorLon: anchorLon,
          centerDeg: 0,
          widthDeg: 60,
          innerRadiusMeters: 30,
          outerRadiusMeters: 100,
        );
        expect(inZone, isFalse);
      });

      test(
          'a boat between the inner and outer radius, within the sector '
          'angle, is in the danger zone', () {
        final boat = offset(northMeters: 50);
        final inZone = service.isInDangerZone(
          boatLat: boat.lat,
          boatLon: boat.lon,
          anchorLat: anchorLat,
          anchorLon: anchorLon,
          centerDeg: 0,
          widthDeg: 60,
          innerRadiusMeters: 30,
          outerRadiusMeters: 100,
        );
        expect(inZone, isTrue);
      });

      test('a boat exactly at the inner radius counts as in the zone (inclusive)',
          () {
        final boat = offset(northMeters: 30);
        final inZone = service.isInDangerZone(
          boatLat: boat.lat,
          boatLon: boat.lon,
          anchorLat: anchorLat,
          anchorLon: anchorLon,
          centerDeg: 0,
          widthDeg: 60,
          innerRadiusMeters: 30,
          outerRadiusMeters: 100,
        );
        expect(inZone, isTrue);
      });
    });
  });

  group('suggestRadiusMeters', () {
    test('scope = depth × ratio', () {
      expect(
        service.suggestRadiusMeters(depthMeters: 6, scopeRatio: 5),
        30,
      );
    });

    test('#293 freeboard increases suggested radius', () {
      expect(
        service.suggestRadiusMeters(
          depthMeters: 6,
          scopeRatio: 5,
          freeboardMeters: 2,
        ),
        40, // (6+2)*5
      );
    });

    test('#304 scopeFromRadius is inverse of suggestRadiusMeters', () {
      expect(
        service.scopeFromRadius(radiusMeters: 30, depthMeters: 6),
        5,
      );
      expect(
        service.scopeFromRadius(
          radiusMeters: 40,
          depthMeters: 6,
          freeboardMeters: 2,
        ),
        5, // 40 / (6+2)
      );
    });

    test('#304 scopeFromRadius returns null for non-positive column', () {
      expect(
        service.scopeFromRadius(radiusMeters: 30, depthMeters: 0),
        isNull,
      );
      expect(
        service.scopeFromRadius(radiusMeters: 0, depthMeters: 6),
        isNull,
      );
    });

    test('#293 swing trail drops near-duplicate points', () {
      var trail = <({double lat, double lon, DateTime at})>[];
      trail = service.appendSwingPoint(
        trail: trail,
        lat: 0,
        lon: 0,
        at: DateTime.utc(2026, 8, 1),
      );
      trail = service.appendSwingPoint(
        trail: trail,
        lat: 0.000001, // ~0.1 m — under 3 m step
        lon: 0,
        at: DateTime.utc(2026, 8, 1, 0, 1),
      );
      expect(trail, hasLength(1));
      trail = service.appendSwingPoint(
        trail: trail,
        lat: 0.0001, // ~11 m
        lon: 0,
        at: DateTime.utc(2026, 8, 1, 0, 2),
      );
      expect(trail, hasLength(2));
    });
  });

  group('#266 — info-tab geometry helpers', () {
    test('distanceFromPerimeterMeters is positive inside, negative past', () {
      expect(
        service.distanceFromPerimeterMeters(
          distanceFromAnchorMeters: 20,
          radiusMeters: 50,
        ),
        30,
      );
      expect(
        service.distanceFromPerimeterMeters(
          distanceFromAnchorMeters: 50,
          radiusMeters: 50,
        ),
        0,
      );
      expect(
        service.distanceFromPerimeterMeters(
          distanceFromAnchorMeters: 70,
          radiusMeters: 50,
        ),
        -20,
      );
    });

    test('bearingToAnchorDeg is the reverse of boat bearing from anchor', () {
      // Boat due north of anchor → bearing from boat to anchor is ~180°T.
      final boat = offset(northMeters: 100);
      final bearing = service.bearingToAnchorDeg(
        boatLat: boat.lat,
        boatLon: boat.lon,
        anchorLat: anchorLat,
        anchorLon: anchorLon,
      );
      expect(bearing, closeTo(180, 2));
    });
  });
}
