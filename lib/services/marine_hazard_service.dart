import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'error_log_service.dart';

/// #239: marine hazard / gale & storm advisory feed. NOAA/NWS
/// (api.weather.gov/alerts) chosen after live research — free, no API key,
/// a single point-based query already returns exactly "active advisories
/// for this location" with no client-side area filtering needed (confirmed
/// live before implementing). Covers gale/small-craft/storm warnings and,
/// since NWS issues tropical cyclone watches/warnings through the same
/// unified alert feed, National Hurricane Center advisories too — no
/// separate NHC integration needed for v1 (a cone-of-uncertainty *track*
/// visualization would need NHC's separate GIS feed, but that's beyond
/// this issue's "active advisories shown clearly" acceptance bar).
///
/// US/territories coverage only (NWS's scope) — [MarineHazardAlert] is a
/// plain model with no NWS-specific fields, so a second region's provider
/// could plug in later without a model rework, per this issue's own design
/// note (same pattern already used for #234's tide/current models).
class MarineHazardAlert {
  final String event;
  final String severity;
  final String headline;
  final String areaDesc;
  final DateTime? effective;
  final DateTime? expires;
  final String? description;

  const MarineHazardAlert({
    required this.event,
    required this.severity,
    required this.headline,
    required this.areaDesc,
    this.effective,
    this.expires,
    this.description,
  });
}

/// NWS alert `event` names relevant to a sailor — deliberately narrower
/// than the full alert feed (which also carries e.g. heat/winter weather
/// advisories unrelated to marine hazards), matching this issue's own
/// "gale & storm advisory feed" framing. Tropical cyclone watches/warnings
/// are included since NWS issues them through this same feed.
const marineHazardEventWhitelist = {
  'Small Craft Advisory',
  'Gale Warning',
  'Gale Watch',
  'Storm Warning',
  'Storm Watch',
  'Hurricane Warning',
  'Hurricane Watch',
  'Tropical Storm Warning',
  'Tropical Storm Watch',
  'Special Marine Warning',
  'Marine Weather Statement',
  'Storm Surge Warning',
  'Storm Surge Watch',
};

/// Parses an api.weather.gov `/alerts/active` GeoJSON FeatureCollection,
/// keeping only [marineHazardEventWhitelist] events. A malformed/error
/// response degrades to an empty list, never throws.
List<MarineHazardAlert> parseMarineHazardAlertsJson(String body) {
  final map = jsonDecode(body) as Map<String, dynamic>;
  final features = map['features'] as List? ?? const [];
  final out = <MarineHazardAlert>[];
  for (final f in features) {
    final props = (f as Map<String, dynamic>)['properties'] as Map<String, dynamic>?;
    if (props == null) continue;
    final event = props['event'] as String? ?? '';
    if (!marineHazardEventWhitelist.contains(event)) continue;
    out.add(MarineHazardAlert(
      event: event,
      severity: props['severity'] as String? ?? 'Unknown',
      headline: props['headline'] as String? ?? event,
      areaDesc: props['areaDesc'] as String? ?? '',
      effective: DateTime.tryParse(props['effective'] as String? ?? ''),
      expires: DateTime.tryParse(props['expires'] as String? ?? ''),
      description: props['description'] as String?,
    ));
  }
  return out;
}

class MarineHazardService {
  static const networkTimeout = Duration(seconds: 12);

  /// Best-effort: a failure returns an empty list (no banner shown) rather
  /// than throwing — matches the acceptance criterion that "no advisory
  /// active" and "couldn't check" must never be conflated into a false
  /// all-clear claim... but a failed check truly has no data to show, so
  /// silence is the only honest option here, same as other best-effort
  /// enrichment calls in this app.
  Future<List<MarineHazardAlert>> fetchActiveAlerts({
    required double lat,
    required double lon,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final uri = Uri.https('api.weather.gov', '/alerts/active', {
        'point': '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}',
      });
      final res = await c.get(
        uri,
        headers: {
          'User-Agent': 'SisuMate/1.0 (weather; offline-first sailor app)',
        },
      ).timeout(networkTimeout);
      if (res.statusCode != 200) return const [];
      return parseMarineHazardAlertsJson(res.body);
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'marine hazard alerts fetch failed: $e',
        context: 'marine_hazard_service: fetchActiveAlerts',
      ));
      return const [];
    } finally {
      if (client == null) c.close();
    }
  }
}
