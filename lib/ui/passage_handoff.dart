import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/app_router.dart';

/// #329 — how Anchor and Weather talk, without merging the two maps.
///
/// **Ownership**
/// - **Anchor** owns the live hook (`AnchorWatch`) and, later, the saved-spot
///   catalog (#328). It does **not** compute isochrones or copy polar math.
/// - **Weather** owns passage planner, isochrone routing, GRIB, and the
///   departure-window scorer.
/// - **Home** keeps two tiles: watch the hook vs plan a passage.
///
/// **How a destination becomes a waypoint**
/// A named lat/lng is a [PassageHandoff]. #328 saved spots call
/// [PassageHandoff.toDestination] (start = boat/hook, dest = spot) and
/// [PassageHandoff.open]. Until that catalog exists, Anchor opens the
/// planner with **start = hook** (or boat fix) and no dest — the sailor
/// adds the far end in the existing planner.
class PassageHandoff {
  final String? startName;
  final double? startLat;
  final double? startLon;
  final String? destName;
  final double? destLat;
  final double? destLon;

  const PassageHandoff({
    this.startName,
    this.startLat,
    this.startLon,
    this.destName,
    this.destLat,
    this.destLon,
  });

  bool get hasStart => startLat != null && startLon != null;
  bool get hasDest => destLat != null && destLon != null;

  /// Route from [start] (boat or hook, optional) to a named destination
  /// (saved spot). Missing start is filled by the planner near the dest.
  factory PassageHandoff.toDestination({
    String startName = 'Departure',
    double? startLat,
    double? startLon,
    required String destName,
    required double destLat,
    required double destLon,
  }) =>
      PassageHandoff(
        startName: startName,
        startLat: startLat,
        startLon: startLon,
        destName: destName,
        destLat: destLat,
        destLon: destLon,
      );

  /// Start a plan at the hook (or last boat fix). Dest is left for the planner.
  factory PassageHandoff.fromHook({
    String startName = 'Hook',
    required double lat,
    required double lon,
  }) =>
      PassageHandoff(startName: startName, startLat: lat, startLon: lon);

  Map<String, Object?> toExtra() => {
        if (startName != null) 'startName': startName,
        if (startLat != null) 'startLat': startLat,
        if (startLon != null) 'startLon': startLon,
        // Legacy Weather extra keys — start-only.
        if (startLat != null) 'lat': startLat,
        if (startLon != null) 'lon': startLon,
        if (destName != null) 'destName': destName,
        if (destLat != null) 'destLat': destLat,
        if (destLon != null) 'destLon': destLon,
      };

  static PassageHandoff? fromExtra(Object? extra) {
    if (extra == null) return null;
    if (extra is PassageHandoff) return extra;
    if (extra is! Map) return null;
    double? d(String k) {
      final v = extra[k];
      if (v is num) return v.toDouble();
      return null;
    }

    String? s(String k) {
      final v = extra[k];
      return v is String && v.isNotEmpty ? v : null;
    }

    return PassageHandoff(
      startName: s('startName'),
      startLat: d('startLat') ?? d('lat'),
      startLon: d('startLon') ?? d('lon'),
      destName: s('destName'),
      destLat: d('destLat'),
      destLon: d('destLon'),
    );
  }

  static void open(BuildContext context, PassageHandoff handoff) {
    context.push(AppRoutes.passage, extra: handoff.toExtra());
  }

  static void openWeatherAt(
    BuildContext context, {
    required double lat,
    required double lon,
    String? placeName,
  }) {
    context.push(AppRoutes.weather, extra: {
      'lat': lat,
      'lon': lon,
      'placeName': ?placeName,
    });
  }
}
