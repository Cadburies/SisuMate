import 'dart:math' as math;

import '../models/sea_state.dart';
import 'polar_sample_eligibility.dart';

/// One instrument snapshot used for sea-state / steady-state windows.
class InstrumentReading {
  final DateTime at;
  final double boatSpeedKt;
  final double twaDeg;
  final double twsKt;
  final double? sogKt;
  final double? stwKt;

  const InstrumentReading({
    required this.at,
    required this.boatSpeedKt,
    required this.twaDeg,
    required this.twsKt,
    this.sogKt,
    this.stwKt,
  });
}

/// Metrics derived from a rolling instrument window.
class SeaStateMetrics {
  final double speedCv;
  final double twaStdDeg;
  final double? sogStwSpreadKt;
  final int windowSize;
  final SeaState seaState;

  const SeaStateMetrics({
    required this.speedCv,
    required this.twaStdDeg,
    required this.sogStwSpreadKt,
    required this.windowSize,
    required this.seaState,
  });
}

/// #276 — pure offline sea-state proxy + steady-state (maneuver) gate.
///
/// **Sea state** uses a multi-minute-ish window of speed CV and TWA std
/// (and optional |SOG−STW| when both present). No wave sensor required.
///
/// **Steady state** rejects hard turns / acceleration using only the last
/// few readings — independent of sea state so rough water still contributes
/// when the course is held.
class SeaStateEstimator {
  /// Minimum readings before sea state is not [SeaState.unknown].
  static const minWindow = 3;

  /// Keep this many recent readings for the sea-state window.
  static const maxWindow = 12;

  /// Speed coefficient of variation below this → calm.
  static const calmSpeedCv = 0.08;

  /// TWA std (°) below this → calm (with calm speed CV).
  static const calmTwaStdDeg = 8.0;

  /// Speed CV at/above this → rough (or high TWA std).
  static const roughSpeedCv = 0.18;

  /// TWA std (°) at/above this → rough.
  static const roughTwaStdDeg = 18.0;

  /// |SOG−STW| (kn) that pushes toward rough when both available.
  static const roughSogStwSpreadKt = 1.2;

  /// Steady-state: max |ΔTWA| (°) between consecutive samples.
  static const steadyMaxTwaJumpDeg = 15.0;

  /// Steady-state: max relative |Δspeed| / mean between consecutive samples.
  static const steadyMaxSpeedRelDelta = 0.20;

  /// Need this many prior readings to judge steady-state (else allow).
  static const steadyMinPrior = 1;

  /// Compute sample stddev of [values] (population, n≥2).
  static double? stdDev(List<double> values) {
    if (values.length < 2) return null;
    final mean = values.reduce((a, b) => a + b) / values.length;
    var sumSq = 0.0;
    for (final v in values) {
      final d = v - mean;
      sumSq += d * d;
    }
    return math.sqrt(sumSq / values.length);
  }

  /// Coefficient of variation = std/mean (0 if mean ~0).
  static double speedCv(List<double> speeds) {
    if (speeds.isEmpty) return 0;
    final mean = speeds.reduce((a, b) => a + b) / speeds.length;
    if (mean.abs() < 1e-6) return 0;
    final sd = stdDev(speeds) ?? 0;
    return sd / mean.abs();
  }

  static SeaStateMetrics evaluate(List<InstrumentReading> window) {
    if (window.length < minWindow) {
      return SeaStateMetrics(
        speedCv: 0,
        twaStdDeg: 0,
        sogStwSpreadKt: null,
        windowSize: window.length,
        seaState: SeaState.unknown,
      );
    }

    final speeds = window.map((r) => r.boatSpeedKt).toList();
    final twas = window.map((r) => polarNormalizeTwa(r.twaDeg)).toList();
    final cv = speedCv(speeds);
    final twaSd = stdDev(twas) ?? 0;

    double? spread;
    final spreads = <double>[];
    for (final r in window) {
      final sog = r.sogKt;
      final stw = r.stwKt;
      if (sog != null && stw != null && sog.isFinite && stw.isFinite) {
        spreads.add((sog - stw).abs());
      }
    }
    if (spreads.isNotEmpty) {
      spread = spreads.reduce((a, b) => a + b) / spreads.length;
    }

    final sea = classify(
      speedCv: cv,
      twaStdDeg: twaSd,
      sogStwSpreadKt: spread,
    );

    return SeaStateMetrics(
      speedCv: cv,
      twaStdDeg: twaSd,
      sogStwSpreadKt: spread,
      windowSize: window.length,
      seaState: sea,
    );
  }

  static SeaState classify({
    required double speedCv,
    required double twaStdDeg,
    double? sogStwSpreadKt,
  }) {
    final spreadRough =
        sogStwSpreadKt != null && sogStwSpreadKt >= roughSogStwSpreadKt;
    if (speedCv >= roughSpeedCv ||
        twaStdDeg >= roughTwaStdDeg ||
        spreadRough) {
      return SeaState.rough;
    }
    if (speedCv <= calmSpeedCv && twaStdDeg <= calmTwaStdDeg) {
      return SeaState.calm;
    }
    return SeaState.moderate;
  }

  /// True when the latest reading is not a hard turn / accel relative to
  /// the previous reading(s). Empty prior → true (first sample allowed).
  static bool isSteadyState(List<InstrumentReading> recent) {
    if (recent.length <= steadyMinPrior) return true;
    final cur = recent.last;
    final prev = recent[recent.length - 2];
    final dTwa =
        (polarNormalizeTwa(cur.twaDeg) - polarNormalizeTwa(prev.twaDeg)).abs();
    if (dTwa > steadyMaxTwaJumpDeg) return false;
    final meanSpeed = (cur.boatSpeedKt + prev.boatSpeedKt) / 2;
    if (meanSpeed < 0.5) return false;
    final rel = (cur.boatSpeedKt - prev.boatSpeedKt).abs() / meanSpeed;
    if (rel > steadyMaxSpeedRelDelta) return false;
    return true;
  }
}
