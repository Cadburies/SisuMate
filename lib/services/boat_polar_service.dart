import 'dart:math' as math;

import '../models/models.dart' show PolarPoint;
import 'weather_service.dart' show haversineNm;

double _normalizeTwaDeg(double d) {
  final a = d.abs() % 360;
  return a > 180 ? 360 - a : a;
}

/// Great-circle initial bearing from point 1 to point 2, degrees 0-360.
double bearingDeg(double lat1, double lon1, double lat2, double lon2) {
  final phi1 = lat1 * math.pi / 180;
  final phi2 = lat2 * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final y = math.sin(dLon) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(dLon);
  final theta = math.atan2(y, x);
  return (theta * 180 / math.pi + 360) % 360;
}

/// #236: interpolates boat speed for a given (twaDeg, twsKt) from a
/// manually-entered polar table (`PolarPoint`, `lib/models/boat.dart`) via
/// inverse-distance weighting over the nearest points. Manual entry can't
/// be relied on to form a complete TWA×TWS grid (unlike an imported
/// ORC-style polar file), so this is a deliberately simple v1 — a proper
/// bilinear grid interpolation is a natural upgrade once polar *import*
/// exists, not required to make routing (#238) usable today. TWA is
/// treated symmetrically (port/starboard) since polar diagrams are.
/// Returns null for an empty table so the caller can fall back to the flat
/// user-entered speed exactly as before this feature existed.
double? interpolatePolarBoatSpeedKt({
  required List<PolarPoint> polar,
  required double twaDeg,
  required double twsKt,
}) {
  if (polar.isEmpty) return null;
  final targetTwa = _normalizeTwaDeg(twaDeg);

  var weightedSum = 0.0;
  var weightTotal = 0.0;
  for (final p in polar) {
    final dTwa = _normalizeTwaDeg(p.twaDeg) - targetTwa;
    final dTws = p.twsKt - twsKt;
    final distSq = dTwa * dTwa + dTws * dTws;
    if (distSq == 0) return p.boatSpeedKt;
    final weight = 1 / distSq;
    weightedSum += weight * p.boatSpeedKt;
    weightTotal += weight;
  }
  return weightedSum / weightTotal;
}

/// #236: per-leg passage plan using polar-derived speed wherever a leg's
/// wind is known (via [windByLegIndex], keyed by the *destination*
/// waypoint's index — leg `i` runs from waypoint `i-1` to `i`), falling
/// back to [flatSpeedKn] for any leg missing wind data. With an empty
/// [polar] table or no [windByLegIndex] entries at all, every leg falls
/// back to [flatSpeedKn] — output is then identical to plain `planPassage`
/// (`weather_service.dart`), so a boat with no polar data configured sees
/// no behavior change at all.
({double nm, double hours, double liters}) planPassageWithPolar({
  required List<({double lat, double lon})> waypoints,
  required double flatSpeedKn,
  required double litersPerHour,
  required List<PolarPoint> polar,
  Map<int, ({double windDirDeg, double windSpeedKt})?> windByLegIndex = const {},
}) {
  if (waypoints.length < 2) return (nm: 0.0, hours: 0.0, liters: 0.0);
  var totalNm = 0.0;
  var totalHours = 0.0;
  for (var i = 1; i < waypoints.length; i++) {
    final legNm = haversineNm(
      waypoints[i - 1].lat,
      waypoints[i - 1].lon,
      waypoints[i].lat,
      waypoints[i].lon,
    );
    var legSpeedKn = flatSpeedKn;
    final wind = windByLegIndex[i];
    if (polar.isNotEmpty && wind != null) {
      final bearing = bearingDeg(
        waypoints[i - 1].lat,
        waypoints[i - 1].lon,
        waypoints[i].lat,
        waypoints[i].lon,
      );
      final twa = wind.windDirDeg - bearing;
      final polarSpeed = interpolatePolarBoatSpeedKt(
        polar: polar,
        twaDeg: twa,
        twsKt: wind.windSpeedKt,
      );
      if (polarSpeed != null && polarSpeed > 0) legSpeedKn = polarSpeed;
    }
    totalNm += legNm;
    if (legSpeedKn > 0) totalHours += legNm / legSpeedKn;
  }
  return (nm: totalNm, hours: totalHours, liters: totalHours * litersPerHour);
}
