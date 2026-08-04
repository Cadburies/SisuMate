/// #245: saildocs GRIB request query builder — pure, no I/O. Syntax
/// confirmed against saildocs.com/gribinfo before writing this, not
/// assumed: `gfs:lat0,lat1,lon0,lon1|dlat,dlon|VTs|Params`, sent as a
/// plain email to query@saildocs.com with the query text in the message
/// **body** (not the subject line). This app doesn't send the email
/// itself — it hands off to whichever email client the user already has
/// configured for their satellite/HF connection via a `mailto:` URI (see
/// [buildSaildocsMailtoUri]); the response (a GRIB attachment) is handled
/// entirely by #244's existing import flow, no new receiving mechanism
/// needed. v1 scope: GFS model only (saildocs' most common free option),
/// `send` (one-time request) only, not `sub` (scheduled/recurring).
class SaildocsQueryParams {
  /// Bounding box — signed degrees (negative = south/west), same
  /// convention as the rest of this app (e.g. `weather_service.dart`).
  final double latMin;
  final double latMax;
  final double lonMin;
  final double lonMax;
  final double latResolution;
  final double lonResolution;
  final List<int> forecastHours;
  final List<String> parameters;

  const SaildocsQueryParams({
    required this.latMin,
    required this.latMax,
    required this.lonMin,
    required this.lonMax,
    this.latResolution = 2,
    this.lonResolution = 2,
    this.forecastHours = const [24, 48, 72],
    this.parameters = const ['WIND'],
  });
}

String _formatLat(double lat) => '${lat.abs().round()}${lat >= 0 ? 'N' : 'S'}';
String _formatLon(double lon) => '${lon.abs().round()}${lon >= 0 ? 'E' : 'W'}';

/// Saildocs' own examples show resolution as e.g. "0.5" or "1", not
/// "1.0" — strip a trailing ".0" for a whole-number resolution.
String _formatResolution(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toString();

/// Builds the saildocs query body text, e.g.
/// `"send gfs:40N,60N,140W,120W|1,1|24,48,72|WIND,WAVES"`.
String buildSaildocsQuery(SaildocsQueryParams p) {
  final lat0 = _formatLat(p.latMin); // south bound
  final lat1 = _formatLat(p.latMax); // north bound
  final lon0 = _formatLon(p.lonMin); // west bound
  final lon1 = _formatLon(p.lonMax); // east bound
  final res =
      '${_formatResolution(p.latResolution)},${_formatResolution(p.lonResolution)}';
  final hours = p.forecastHours.map((h) => h.toString()).join(',');
  final params = p.parameters.join(',');
  return 'send gfs:$lat0,$lat1,$lon0,$lon1|$res|$hours|$params';
}

/// A `mailto:` URI pre-filled to query@saildocs.com with [queryBody] in
/// the message body — `launchUrl()` (url_launcher) hands this off to
/// whichever mail app is registered on the device.
Uri buildSaildocsMailtoUri(String queryBody) {
  return Uri(
    scheme: 'mailto',
    path: 'query@saildocs.com',
    query: 'body=${Uri.encodeComponent(queryBody)}',
  );
}
