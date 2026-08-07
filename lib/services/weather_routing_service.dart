import 'dart:math' as math;

import '../models/models.dart' show PolarPoint;
import 'boat_polar_service.dart' show bearingDeg, interpolatePolarBoatSpeedKt;
import 'weather_service.dart' show haversineNm;

/// #238: wind at a point/time — a full spatial/temporal wind field, or (v1's
/// sanctioned simplification, per this issue's own Notes) a function
/// returning the same sample everywhere, wrapping one already-fetched
/// [HourlyWeather] point. Injected so the algorithm stays pure/testable
/// against synthetic fields, independent of any real forecast fetch.
typedef WindAt = ({double windDirDeg, double windSpeedKt}) Function({
  required double lat,
  required double lon,
  required DateTime time,
});

/// #291 — optional significant wave height (m) at a point/time. Null means
/// "unknown / no wave layer" — routing degrades to wind-only (factor 1.0).
typedef WaveAt = double? Function({
  required double lat,
  required double lon,
  required DateTime time,
});

/// #291 — pure comfort factor on boat speed from Hs (meters).
///
/// Flat calm → 1.0; rises in penalty through rough seas. Missing data → 1.0
/// so routes still compute when only wind GRIB is available.
double waveSpeedFactor(double? significantWaveHeightM) {
  final hs = significantWaveHeightM;
  if (hs == null || hs.isNaN || hs <= 0.8) return 1.0;
  if (hs >= 5.0) return 0.5;
  // Linear ease from 0.8 m (1.0) to 5.0 m (0.5).
  return 1.0 - (hs - 0.8) * (0.5 / (5.0 - 0.8));
}

class IsochroneRoute {
  final List<({double lat, double lon})> path;
  final Duration totalDuration;

  const IsochroneRoute({required this.path, required this.totalDuration});
}

class _Node {
  final double lat;
  final double lon;
  final Duration elapsed;
  final _Node? parent;

  const _Node({
    required this.lat,
    required this.lon,
    required this.elapsed,
    this.parent,
  });
}

/// Great-circle destination point from ([lat],[lon]) after travelling
/// [distanceNm] on initial bearing [bearingDeg].
({double lat, double lon}) destinationPoint({
  required double lat,
  required double lon,
  required double bearingDeg,
  required double distanceNm,
}) {
  const rNm = 3440.065;
  final delta = distanceNm / rNm;
  final theta = bearingDeg * math.pi / 180;
  final phi1 = lat * math.pi / 180;
  final lambda1 = lon * math.pi / 180;
  final phi2 = math.asin(math.sin(phi1) * math.cos(delta) +
      math.cos(phi1) * math.sin(delta) * math.cos(theta));
  final lambda2 = lambda1 +
      math.atan2(
        math.sin(theta) * math.sin(delta) * math.cos(phi1),
        math.cos(delta) - math.sin(phi1) * math.sin(phi2),
      );
  return (lat: phi2 * 180 / math.pi, lon: lambda2 * 180 / math.pi);
}

/// #238: isochrone weather routing — given a start/end point, boat polars
/// (#236), and a wind field, computes a route accounting for how boat speed
/// varies with true wind angle, rather than the flat great-circle line
/// `planPassage` draws. Classic isochrone expansion: at each [timeStep],
/// every frontier point tries [headingCount] candidate headings (polar-
/// derived speed per heading), then the frontier is pruned to one
/// best-progress point per angular sector (relative to the start→end
/// bearing) so it stays bounded rather than exploding combinatorially.
/// Returns null if [polar] is empty, the boat can't make progress on any
/// heading, or the route doesn't converge within [maxSteps].
IsochroneRoute? computeIsochroneRoute({
  required ({double lat, double lon}) start,
  required ({double lat, double lon}) end,
  required List<PolarPoint> polar,
  required WindAt windAt,
  required DateTime startTime,
  Duration timeStep = const Duration(hours: 1),
  int headingCount = 24,
  int maxSteps = 72,
  double arrivalToleranceNm = 5,
  /// #291 — optional Hs field; when null, wind-only routing (no penalty).
  WaveAt? waveAt,
}) {
  if (polar.isEmpty || headingCount <= 0) return null;

  final totalNm = haversineNm(start.lat, start.lon, end.lat, end.lon);
  if (totalNm <= arrivalToleranceNm) {
    return IsochroneRoute(path: [start, end], totalDuration: Duration.zero);
  }
  final targetBearing = bearingDeg(start.lat, start.lon, end.lat, end.lon);
  final stepHours = timeStep.inMinutes / 60.0;
  final sectorWidth = 360 / headingCount;

  var frontier = <_Node>[
    _Node(lat: start.lat, lon: start.lon, elapsed: Duration.zero),
  ];

  for (var step = 0; step < maxSteps; step++) {
    final candidates = <_Node>[];
    for (final node in frontier) {
      final time = startTime.add(node.elapsed);
      for (var h = 0; h < headingCount; h++) {
        final heading = h * sectorWidth;
        final wind = windAt(lat: node.lat, lon: node.lon, time: time);
        final twa = heading - wind.windDirDeg;
        var speedKt = interpolatePolarBoatSpeedKt(
          polar: polar,
          twaDeg: twa,
          twsKt: wind.windSpeedKt,
        );
        if (speedKt == null || speedKt <= 0) continue;
        // #291 — optional wave comfort penalty (degrades if waveAt missing).
        if (waveAt != null) {
          final hs = waveAt(lat: node.lat, lon: node.lon, time: time);
          speedKt = speedKt * waveSpeedFactor(hs);
          if (speedKt <= 0) continue;
        }
        final dest = destinationPoint(
          lat: node.lat,
          lon: node.lon,
          bearingDeg: heading,
          distanceNm: speedKt * stepHours,
        );
        candidates.add(_Node(
          lat: dest.lat,
          lon: dest.lon,
          elapsed: node.elapsed + timeStep,
          parent: node,
        ));
      }
    }
    if (candidates.isEmpty) return null;

    for (final c in candidates) {
      if (haversineNm(c.lat, c.lon, end.lat, end.lon) <= arrivalToleranceNm) {
        return IsochroneRoute(
          path: [..._reconstruct(c), end],
          totalDuration: c.elapsed,
        );
      }
    }

    final bestPerSector = <int, _Node>{};
    final bestDistPerSector = <int, double>{};
    for (final c in candidates) {
      final bearingFromStart = bearingDeg(start.lat, start.lon, c.lat, c.lon);
      final relative = ((bearingFromStart - targetBearing) % 360 + 360) % 360;
      final signedRelative = relative > 180 ? relative - 360 : relative;
      final sector =
          ((signedRelative + 180) / sectorWidth).floor().clamp(0, headingCount - 1);
      final dist = haversineNm(c.lat, c.lon, end.lat, end.lon);
      if (!bestDistPerSector.containsKey(sector) ||
          dist < bestDistPerSector[sector]!) {
        bestDistPerSector[sector] = dist;
        bestPerSector[sector] = c;
      }
    }
    frontier = bestPerSector.values.toList();
  }
  return null;
}

List<({double lat, double lon})> _reconstruct(_Node node) {
  final path = <({double lat, double lon})>[];
  _Node? cur = node;
  while (cur != null) {
    path.add((lat: cur.lat, lon: cur.lon));
    cur = cur.parent;
  }
  return path.reversed.toList();
}
