import '../models/sailing_polar_sample.dart';
import 'predictwind_datahub_service.dart';

/// #274/#275 — pure rules for "is this reading usable under-sail polar data?".
///
/// Research (Njord / measured-polar tooling):
/// - Prefer **STW** (through-water) over SOG when both available — polar is
///   a water-speed target; current biases SOG.
/// - Need boat speed + true wind (or enough to derive TWA).
/// - Engines not turning (RPM absent or at/near idle for both shafts).
/// - Absolute TWA 0–180° (port/starboard symmetric for polar tables).
class PolarSampleEligibility {
  /// Minimum preferred boat speed (kn) to count as "making way under sail".
  static const minBoatSpeedKt = 1.5;

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

  /// Prefer STW when finite and above noise; else SOG.
  static ({double speed, String source})? preferredBoatSpeed({
    double? stwKt,
    double? sogKt,
  }) {
    if (stwKt != null && stwKt.isFinite && stwKt >= minBoatSpeedKt) {
      return (speed: stwKt, source: 'stw');
    }
    if (sogKt != null && sogKt.isFinite && sogKt >= minBoatSpeedKt) {
      return (speed: sogKt, source: 'sog');
    }
    return null;
  }

  /// True when NMEA is not reporting useful engine revs (both shafts idle
  /// or missing) — user's "engines not showing revs" under-sail gate.
  static bool enginesNotRunning({
    double? enginePortRpm,
    double? engineStbdRpm,
  }) {
    final port = enginePortRpm;
    final stbd = engineStbdRpm;
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
    final preferred = preferredBoatSpeed(stwKt: data.stwKt, sogKt: data.sogKt);
    if (preferred == null) return null;

    final tws = data.windSpeedKt;
    final twd = data.windDirectionDeg;
    final cog = data.cogDeg;
    if (tws == null || tws < minTwsKt) return null;
    if (twd == null || cog == null) return null;
    if (!enginesNotRunning(
      enginePortRpm: enginePortRpm,
      engineStbdRpm: engineStbdRpm,
    )) {
      return null;
    }
    if (![preferred.speed, tws, twd, cog].every((v) => v.isFinite)) {
      return null;
    }

    final twa = absoluteTwaDeg(cog, twd);
    return SailingPolarSample()
      ..boatSupabaseId = boatSupabaseId
      ..observedAt = data.observedAt.toUtc()
      ..sogKt = data.sogKt
      ..stwKt = data.stwKt
      ..boatSpeedKt = preferred.speed
      ..speedSource = preferred.source
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
      ..usedInPolarBuild = false
      ..isSynced = false
      ..lastModified = DateTime.now().toUtc();
  }

  static bool enoughTimeSince(DateTime? last, DateTime now) {
    if (last == null) return true;
    return now.difference(last) >= minInterval;
  }
}

double polarNormalizeTwa(double twaDeg) {
  final a = twaDeg.abs() % 360;
  return a > 180 ? 360 - a : a;
}

const kPolarTwsCentresKt = [4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 20.0, 25.0];

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
