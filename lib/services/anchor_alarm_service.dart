import 'weather_service.dart' show haversineNm;
import 'boat_polar_service.dart' show bearingDeg;

/// #256 — pure geofence/danger-zone math for the Anchor Alarm, independent
/// of UI/location plumbing so it's directly unit-testable. Nautical miles
/// (from the existing [haversineNm]) are converted to meters since anchor
/// scope/swing radii are naturally small (tens of meters), not nautical
/// miles.
class AnchorAlarmService {
  const AnchorAlarmService();

  static const _metersPerNm = 1852.0;

  double distanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) =>
      haversineNm(lat1, lon1, lat2, lon2) * _metersPerNm;

  /// True once the boat has dragged outside the geofence circle.
  bool isOutsideCircle({
    required double boatLat,
    required double boatLon,
    required double anchorLat,
    required double anchorLon,
    required double radiusMeters,
  }) {
    return distanceMeters(
          lat1: anchorLat,
          lon1: anchorLon,
          lat2: boatLat,
          lon2: boatLon,
        ) >
        radiusMeters;
  }

  /// True once the boat has swung into the danger-zone sector — a *ring*
  /// segment (#262: a hazard is typically beyond the safe swinging circle,
  /// not at the anchor itself), between [innerRadiusMeters] and
  /// [outerRadiusMeters] of the anchor AND within [widthDeg]/2 of
  /// [centerDeg] (the sector's center bearing, measured from the anchor,
  /// degrees true). A boat still inside [innerRadiusMeters] — even on the
  /// danger bearing — is not in the zone; it's still safely within the
  /// swinging circle.
  bool isInDangerZone({
    required double boatLat,
    required double boatLon,
    required double anchorLat,
    required double anchorLon,
    required double centerDeg,
    required double widthDeg,
    required double innerRadiusMeters,
    required double outerRadiusMeters,
  }) {
    final dist = distanceMeters(
      lat1: anchorLat,
      lon1: anchorLon,
      lat2: boatLat,
      lon2: boatLon,
    );
    if (dist < innerRadiusMeters || dist > outerRadiusMeters) return false;
    final boatBearing = bearingDeg(anchorLat, anchorLon, boatLat, boatLon);
    return angleDiff(boatBearing, centerDeg).abs() <= widthDeg / 2;
  }

  /// Suggested geofence radius: scope (chain paid out) ≈ depth × ratio.
  /// Depth-based, so it only applies when a live depth reading exists —
  /// callers fall back to a fixed default otherwise.
  double suggestRadiusMeters({
    required double depthMeters,
    required double scopeRatio,
  }) =>
      depthMeters * scopeRatio;

  /// Signed difference `a - b` normalized to (-180, 180]. Public — also
  /// used by the chart map's drag-handle math (#256 follow-up) to turn a
  /// dragged bearing into a sector width/center.
  double angleDiff(double a, double b) {
    var d = (a - b) % 360;
    if (d > 180) d -= 360;
    if (d <= -180) d += 360;
    return d;
  }
}
