import '../models/sailing_polar_sample.dart';
import '../models/sea_state.dart';
import 'predictwind_datahub_service.dart';

/// Live / preview values for the polar chart "what would be logged" panel.
///
/// Values are display strings (already unit-suffixed). Empty/`—` means the
/// instrument path has no reading. [wouldAccept] mirrors [tryBuild] success
/// only — steady-state / min-interval gates still apply before a row is stored.
class PolarLogFieldSnapshot {
  final bool wouldAccept;
  final String statusMessage;
  final String observedAt;
  final String boatSpeedKt;
  final String speedSource;
  final String sogKt;
  final String stwKt;
  final String twaDeg;
  final String twsKt;
  final String cogDeg;
  final String twdDeg;
  final String awsKt;
  final String awaDeg;
  final String depthMeters;
  final String enginePortRpm;
  final String engineStbdRpm;
  final String seaState;
  final String speedCv;
  final String twaStdDeg;
  final String sourceLabel;

  const PolarLogFieldSnapshot({
    required this.wouldAccept,
    required this.statusMessage,
    required this.observedAt,
    required this.boatSpeedKt,
    required this.speedSource,
    required this.sogKt,
    required this.stwKt,
    required this.twaDeg,
    required this.twsKt,
    required this.cogDeg,
    required this.twdDeg,
    required this.awsKt,
    required this.awaDeg,
    required this.depthMeters,
    required this.enginePortRpm,
    required this.engineStbdRpm,
    required this.seaState,
    required this.speedCv,
    required this.twaStdDeg,
    required this.sourceLabel,
  });

  static const empty = PolarLogFieldSnapshot(
    wouldAccept: false,
    statusMessage: 'No instrument data yet',
    observedAt: '—',
    boatSpeedKt: '—',
    speedSource: '—',
    sogKt: '—',
    stwKt: '—',
    twaDeg: '—',
    twsKt: '—',
    cogDeg: '—',
    twdDeg: '—',
    awsKt: '—',
    awaDeg: '—',
    depthMeters: '—',
    enginePortRpm: '—',
    engineStbdRpm: '—',
    seaState: '—',
    speedCv: '—',
    twaStdDeg: '—',
    sourceLabel: '—',
  );

  /// Ordered (label, value) pairs for the UI — wire-relevant first.
  List<({String label, String value, String? hint})> get textFields => [
        (label: 'Boat speed', value: boatSpeedKt, hint: 'Preferred STW else SOG'),
        (label: 'Speed source', value: speedSource, hint: 'stw or sog'),
        (label: 'SOG', value: sogKt, hint: 'Speed over ground'),
        (label: 'STW', value: stwKt, hint: 'Speed through water'),
        (label: 'TWA', value: twaDeg, hint: 'True wind angle 0–180°'),
        (label: 'TWS', value: twsKt, hint: 'True wind speed'),
        (label: 'Sea state', value: seaState, hint: 'calm / moderate / rough'),
        (label: 'COG', value: cogDeg, hint: 'Local only — used to compute TWA'),
        (label: 'TWD', value: twdDeg, hint: 'Local only — used to compute TWA'),
        (label: 'AWS', value: awsKt, hint: 'Local only'),
        (label: 'AWA', value: awaDeg, hint: 'Local only'),
        (label: 'Depth', value: depthMeters, hint: 'Local only'),
        (label: 'Engine port RPM', value: enginePortRpm, hint: 'Local gate'),
        (label: 'Engine stbd RPM', value: engineStbdRpm, hint: 'Local gate'),
        (label: 'Speed CV', value: speedCv, hint: 'Local sea-state metric'),
        (label: 'TWA std', value: twaStdDeg, hint: 'Local sea-state metric'),
        (label: 'Source', value: sourceLabel, hint: 'Instrument path'),
        (label: 'Observed at', value: observedAt, hint: null),
      ];
}

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

  /// Why [tryBuild] would reject this reading, or null if acceptable.
  static String? rejectReason({
    required PredictWindBoatData data,
    required String boatSupabaseId,
    double? enginePortRpm,
    double? engineStbdRpm,
  }) {
    if (boatSupabaseId.isEmpty) return 'No active boat id';
    final preferred = preferredBoatSpeed(stwKt: data.stwKt, sogKt: data.sogKt);
    if (preferred == null) {
      return 'Boat speed below ${minBoatSpeedKt.toStringAsFixed(1)} kn '
          '(need STW or SOG)';
    }
    final tws = data.windSpeedKt;
    final twd = data.windDirectionDeg;
    final cog = data.cogDeg;
    if (tws == null || !tws.isFinite) return 'True wind speed missing';
    if (tws < minTwsKt) {
      return 'True wind below ${minTwsKt.toStringAsFixed(0)} kn';
    }
    if (twd == null || !twd.isFinite) return 'True wind direction missing';
    if (cog == null || !cog.isFinite) return 'Course over ground missing';
    if (!enginesNotRunning(
      enginePortRpm: enginePortRpm,
      engineStbdRpm: engineStbdRpm,
    )) {
      return 'Engine RPM above idle — under-sail samples only';
    }
    if (!preferred.speed.isFinite) return 'Boat speed not finite';
    return null;
  }

  /// Build a sample from live instrument data, or null if ineligible.
  static SailingPolarSample? tryBuild({
    required PredictWindBoatData data,
    required String boatSupabaseId,
    double? enginePortRpm,
    double? engineStbdRpm,
  }) {
    if (rejectReason(
          data: data,
          boatSupabaseId: boatSupabaseId,
          enginePortRpm: enginePortRpm,
          engineStbdRpm: engineStbdRpm,
        ) !=
        null) {
      return null;
    }

    final preferred = preferredBoatSpeed(stwKt: data.stwKt, sogKt: data.sogKt)!;
    final tws = data.windSpeedKt!;
    final twd = data.windDirectionDeg!;
    final cog = data.cogDeg!;
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

  /// Display snapshot of fields that would be written into a polar sample.
  static PolarLogFieldSnapshot logFieldSnapshot({
    PredictWindBoatData? data,
    required String boatSupabaseId,
    SeaState seaState = SeaState.unknown,
    double? speedCv,
    double? twaStdDeg,
    String? instrumentSummary,
  }) {
    if (data == null) {
      return PolarLogFieldSnapshot(
        wouldAccept: false,
        statusMessage: instrumentSummary?.isNotEmpty == true
            ? instrumentSummary!
            : PolarLogFieldSnapshot.empty.statusMessage,
        observedAt: '—',
        boatSpeedKt: '—',
        speedSource: '—',
        sogKt: '—',
        stwKt: '—',
        twaDeg: '—',
        twsKt: '—',
        cogDeg: '—',
        twdDeg: '—',
        awsKt: '—',
        awaDeg: '—',
        depthMeters: '—',
        enginePortRpm: '—',
        engineStbdRpm: '—',
        seaState: seaState.label,
        speedCv: _fmtRatio(speedCv),
        twaStdDeg: _fmtDeg(twaStdDeg),
        sourceLabel: '—',
      );
    }

    final port = data.enginePortRpm;
    final stbd = data.engineStbdRpm;
    final reject = rejectReason(
      data: data,
      boatSupabaseId: boatSupabaseId,
      enginePortRpm: port,
      engineStbdRpm: stbd,
    );
    final preferred =
        preferredBoatSpeed(stwKt: data.stwKt, sogKt: data.sogKt);
    final cog = data.cogDeg;
    final twd = data.windDirectionDeg;
    final twa = (cog != null && twd != null) ? absoluteTwaDeg(cog, twd) : null;

    final status = reject == null
        ? 'Eligible — would log if steady-state + ${minInterval.inSeconds}s gap'
        : 'Not logged: $reject';

    return PolarLogFieldSnapshot(
      wouldAccept: reject == null,
      statusMessage: status,
      observedAt: data.observedAt.toUtc().toIso8601String(),
      boatSpeedKt: preferred != null
          ? '${preferred.speed.toStringAsFixed(1)} kn'
          : '—',
      speedSource: preferred?.source ?? '—',
      sogKt: _fmtKn(data.sogKt),
      stwKt: _fmtKn(data.stwKt),
      twaDeg: _fmtDeg(twa),
      twsKt: _fmtKn(data.windSpeedKt),
      cogDeg: _fmtDeg(data.cogDeg),
      twdDeg: _fmtDeg(data.windDirectionDeg),
      awsKt: _fmtKn(data.apparentWindSpeedKt),
      awaDeg: _fmtDeg(data.apparentWindDirectionDeg),
      depthMeters: data.depthMeters == null
          ? '—'
          : '${data.depthMeters!.toStringAsFixed(1)} m',
      enginePortRpm: _fmtRpm(port),
      engineStbdRpm: _fmtRpm(stbd),
      seaState: seaState.label,
      speedCv: _fmtRatio(speedCv),
      twaStdDeg: _fmtDeg(twaStdDeg),
      sourceLabel: (data.sourceLabel?.isNotEmpty == true)
          ? data.sourceLabel!
          : (instrumentSummary?.isNotEmpty == true ? instrumentSummary! : '—'),
    );
  }

  static String _fmtKn(double? v) =>
      v == null || !v.isFinite ? '—' : '${v.toStringAsFixed(1)} kn';

  static String _fmtDeg(double? v) =>
      v == null || !v.isFinite ? '—' : '${v.toStringAsFixed(0)}°';

  static String _fmtRpm(double? v) =>
      v == null || !v.isFinite ? '—' : v.toStringAsFixed(0);

  static String _fmtRatio(double? v) =>
      v == null || !v.isFinite ? '—' : v.toStringAsFixed(3);

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
