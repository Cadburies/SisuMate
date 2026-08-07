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

  /// Suggested geofence radius from scope ratio.
  ///
  /// Classic rule: scope ≈ (depth + freeboard) × ratio, so the swing radius
  /// is that chain length (meters). [freeboardMeters] defaults to 0 when
  /// unknown (depth-only). Depth-based, so it only applies when a live depth
  /// reading exists — callers fall back to a fixed default otherwise.
  double suggestRadiusMeters({
    required double depthMeters,
    required double scopeRatio,
    double freeboardMeters = 0,
  }) {
    final waterColumn = depthMeters + (freeboardMeters < 0 ? 0 : freeboardMeters);
    if (waterColumn <= 0 || scopeRatio <= 0) return 0;
    return waterColumn * scopeRatio;
  }

  /// #304 — inverse of [suggestRadiusMeters]: scope ratio from a chosen
  /// geofence radius and water column (depth + freeboard/roller height).
  /// Returns null when the column is unknown or non-positive so callers keep
  /// the previous scope instead of inventing a ratio.
  double? scopeFromRadius({
    required double radiusMeters,
    required double depthMeters,
    double freeboardMeters = 0,
  }) {
    final waterColumn = depthMeters + (freeboardMeters < 0 ? 0 : freeboardMeters);
    if (waterColumn <= 0 || radiusMeters <= 0) return null;
    return radiusMeters / waterColumn;
  }

  /// #307 — true when live depth is under the configured min (and min > 0).
  bool isShallow({
    required double? depthMeters,
    required double minDepthMeters,
  }) {
    if (minDepthMeters <= 0 || depthMeters == null) return false;
    return depthMeters < minDepthMeters;
  }

  /// #307 — true when wind speed exceeds the threshold (and max > 0).
  /// Callers should pass AWS when available, else TWS.
  bool isStrongWind({
    required double? windKt,
    required double maxWindKt,
  }) {
    if (maxWindKt <= 0 || windKt == null) return false;
    return windKt > maxWindKt;
  }

  /// #307 — AIS risk evaluation seam. No ship targets in the app yet, so
  /// this always returns false; keep the method so UI can arm the setting
  /// without inventing targets.
  bool isAisCollisionRisk({required bool enabled}) {
    if (!enabled) return false;
    return false;
  }

  /// #293 — append a GPS breadcrumb while armed; drops points closer than
  /// [minStepMeters] to the last sample so the trail stays light.
  List<({double lat, double lon, DateTime at})> appendSwingPoint({
    required List<({double lat, double lon, DateTime at})> trail,
    required double lat,
    required double lon,
    DateTime? at,
    double minStepMeters = 3,
    int maxPoints = 500,
  }) {
    final t = at ?? DateTime.now().toUtc();
    if (trail.isNotEmpty) {
      final last = trail.last;
      final d = distanceMeters(
        lat1: last.lat,
        lon1: last.lon,
        lat2: lat,
        lon2: lon,
      );
      if (d < minStepMeters) return trail;
    }
    final next = [...trail, (lat: lat, lon: lon, at: t)];
    if (next.length <= maxPoints) return next;
    return next.sublist(next.length - maxPoints);
  }

  /// #266 — meters of margin remaining before the geofence perimeter
  /// (`radius − distanceFromAnchor`). Positive = still inside; zero = on
  /// the line; negative = meters past the circle (dragging).
  double distanceFromPerimeterMeters({
    required double distanceFromAnchorMeters,
    required double radiusMeters,
  }) =>
      radiusMeters - distanceFromAnchorMeters;

  /// #266 — true bearing (°) from the boat to the anchor (inverse of the
  /// usual "bearing from anchor to boat" used for the danger-zone sector).
  double bearingToAnchorDeg({
    required double boatLat,
    required double boatLon,
    required double anchorLat,
    required double anchorLon,
  }) =>
      bearingDeg(boatLat, boatLon, anchorLat, anchorLon);

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
