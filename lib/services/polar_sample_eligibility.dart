import '../models/sailing_polar_sample.dart';
import 'predictwind_datahub_service.dart';

/// #274 — pure rules for "is this reading usable under-sail polar data?".
///
/// Research (Njord / measured-polar tooling):
/// - Need boat speed + true wind (or enough to derive TWA).
/// - Prefer high-quality sailing, not motoring: engines not turning
///   (RPM absent or at/near idle for both shafts).
/// - Absolute TWA 0–180° (port/starboard symmetric for polar tables).
class PolarSampleEligibility {
  /// Minimum SOG (kn) to count as "making way under sail".
  static const minSogKt = 1.5;

  /// Minimum true wind (kn) — below this TWA is noisy.
  static const minTwsKt = 3.0;

  /// RPM above this means an engine is driving (not residual idle noise).
  static const engineRunningRpm = 80.0;

  /// Minimum seconds between stored samples for the same boat.
  static const minInterval = Duration(seconds: 30);

  /// Fold any heading difference into absolute TWA 0–180°.
  static double absoluteTwaDeg(double cogDeg, double twdDeg) {
    var d = (cogDeg - twdDeg) % 360;
    if (d < 0) d += 360;
    if (d > 180) d = 360 - d;
    return d;
  }

  /// True when NMEA is not reporting useful engine revs (both shafts idle
  /// or missing) — user's "engines not showing revs" under-sail gate.
  static bool enginesNotRunning({
    double? enginePortRpm,
    double? engineStbdRpm,
  }) {
    final port = enginePortRpm;
    final stbd = engineStbdRpm;
    // No RPM fields at all → "not showing revs" → allow (user intent).
    if (port == null && stbd == null) return true;
    final portRunning = port != null && port >= engineRunningRpm;
    final stbdRunning = stbd != null && stbd >= engineRunningRpm;
    return !portRunning && !stbdRunning;
  }

  /// Build a sample from live instrument data, or null if ineligible.
  static SailingPolarSample? tryBuild({
    required PredictWindBoatData data,
    required String boatSupabaseId,
    double? enginePortRpm,
    double? engineStbdRpm,
  }) {
    if (boatSupabaseId.isEmpty) return null;
    final sog = data.sogKt;
    final tws = data.windSpeedKt;
    final twd = data.windDirectionDeg;
    final cog = data.cogDeg;
    if (sog == null || sog < minSogKt) return null;
    if (tws == null || tws < minTwsKt) return null;
    if (twd == null || cog == null) return null;
    if (!enginesNotRunning(
      enginePortRpm: enginePortRpm,
      engineStbdRpm: engineStbdRpm,
    )) {
      return null;
    }
    // Reject NaN/inf.
    if (![sog, tws, twd, cog].every((v) => v.isFinite)) return null;

    final twa = absoluteTwaDeg(cog, twd);
    return SailingPolarSample()
      ..boatSupabaseId = boatSupabaseId
      ..observedAt = data.observedAt.toUtc()
      ..sogKt = sog
      ..cogDeg = cog
      ..twsKt = tws
      ..twdDeg = twd
      ..twaDeg = twa
      ..awsKt = data.apparentWindSpeedKt
      ..awaDeg = data.apparentWindDirectionDeg
      ..depthMeters = data.depthMeters
      ..enginePortRpm = enginePortRpm
      ..engineStbdRpm = engineStbdRpm
      ..sourceLabel = data.sourceLabel ?? ''
      ..usedInPolarBuild = false;
  }

  /// Spacing gate against the last stored sample time.
  static bool enoughTimeSince(DateTime? last, DateTime now) {
    if (last == null) return true;
    return now.difference(last) >= minInterval;
  }
}

/// Normalize TWA for bucketing (0–180).
double polarNormalizeTwa(double twaDeg) {
  final a = twaDeg.abs() % 360;
  return a > 180 ? 360 - a : a;
}

/// Standard TWS centres used by many polar tables (ORC-ish).
const kPolarTwsCentresKt = [4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 20.0, 25.0];

/// TWA centres every 10° from 0 to 180.
List<double> polarTwaCentresDeg({double step = 10}) {
  final out = <double>[];
  for (var t = 0.0; t <= 180.0 + 1e-9; t += step) {
    out.add(t);
  }
  return out;
}

double nearestCentre(double value, List<double> centres) {
  var best = centres.first;
  var bestD = (value - best).abs();
  for (final c in centres.skip(1)) {
    final d = (value - c).abs();
    if (d < bestD) {
      best = c;
      bestD = d;
    }
  }
  return best;
}

/// Percentile of a sorted-or-unsorted list (0–1). Empty → null.
double? percentile(List<double> values, double p) {
  if (values.isEmpty) return null;
  final s = [...values]..sort();
  if (s.length == 1) return s.first;
  final rank = p.clamp(0.0, 1.0) * (s.length - 1);
  final lo = rank.floor();
  final hi = rank.ceil();
  if (lo == hi) return s[lo];
  final t = rank - lo;
  return s[lo] * (1 - t) + s[hi] * t;
}

