import 'dart:math' as math;

import '../models/sea_state.dart';

/// #280 — one phone accelerometer sample (m/s², typically includes gravity).
class ImuAccelSample {
  final DateTime at;
  final double ax;
  final double ay;
  final double az;

  const ImuAccelSample({
    required this.at,
    required this.ax,
    required this.ay,
    required this.az,
  });

  /// Magnitude of specific force (≈ g when still).
  double get magnitude => math.sqrt(ax * ax + ay * ay + az * az);
}

/// Result of phone-IMU sea-state estimation (boat-relative motion climate).
///
/// [significantWaveHeightM] is a **proxy** Hs from heave variance
/// (Hs ≈ 4·σ_z), not a calibrated buoy measurement. UI must not claim
/// true open-ocean WMO codes.
class ImuSeaStateEstimate {
  final SeaState seaState;
  final double? significantWaveHeightM;
  final double residualAccelRms;
  final double residualAccelP90;
  final double? dominantPeriodS;
  final int sampleCount;
  final double windowSeconds;
  final bool confident;
  final String statusMessage;

  const ImuSeaStateEstimate({
    required this.seaState,
    required this.significantWaveHeightM,
    required this.residualAccelRms,
    required this.residualAccelP90,
    required this.dominantPeriodS,
    required this.sampleCount,
    required this.windowSeconds,
    required this.confident,
    required this.statusMessage,
  });

  static const empty = ImuSeaStateEstimate(
    seaState: SeaState.unknown,
    significantWaveHeightM: null,
    residualAccelRms: 0,
    residualAccelP90: 0,
    dominantPeriodS: null,
    sampleCount: 0,
    windowSeconds: 0,
    confident: false,
    statusMessage: 'Collecting phone motion…',
  );
}

/// #280 — heave / pseudo-Hs from phone accelerometer (wave-buoy analogy).
///
/// Pipeline (inspired by MEMS heave / leaky double-integrate + Kalman-lite):
/// 1. Residual accel = |a| − g (orientation-tolerant for small motions).
/// 2. High-pass residual (remove bias / slow tilt).
/// 3. Leaky integrate → velocity → heave (bounds drift like a damped KF).
/// 4. Hs_proxy = 4 · std(heave) over a multi-second window (irregular-wave m0).
/// 5. WMO-style bands: 0–0.5 m calm, 0.5–2.5 moderate, ≥2.5 rough.
///
/// Pure Dart — feed synthetic streams in tests; [ImuSeaStateService] owns sensors.
class ImuHeaveEstimator {
  /// Standard gravity (m/s²).
  static const g = 9.80665;

  /// Keep this many seconds of heave/residual for window stats.
  static const windowSeconds = 45.0;

  /// Need this much wall time before [confident].
  static const minConfidentSeconds = 12.0;

  /// Minimum samples before any estimate (beyond unknown).
  static const minSamples = 40;

  /// WMO-style Hs thresholds (m) → our [SeaState] buckets.
  static const hsCalmMaxM = 0.5;
  static const hsModerateMaxM = 2.5;

  /// Leaky integrator decay per second (≈ high-pass on integrated states).
  static const leakPerSecond = 0.35;

  /// Bias tracker for residual accel (fraction toward sample per second).
  static const residualBiasTauS = 8.0;

  final List<({DateTime at, double residual, double heave})> _buf = [];
  double _aBias = 0;
  double _v = 0;
  double _z = 0;
  DateTime? _lastAt;
  bool _biasPrimed = false;

  void reset() {
    _buf.clear();
    _aBias = 0;
    _v = 0;
    _z = 0;
    _lastAt = null;
    _biasPrimed = false;
  }

  /// Push one accelerometer reading (m/s², gravity-included).
  void addSample(ImuAccelSample s) {
    final mag = s.magnitude;
    if (!mag.isFinite) return;

    // Orientation-tolerant residual: deviation of |a| from 1 g.
    final rawResidual = mag - g;

    final last = _lastAt;
    final dt = last == null
        ? 0.02
        : (s.at.difference(last).inMicroseconds / 1e6).clamp(0.005, 0.2);
    _lastAt = s.at;

    if (!_biasPrimed) {
      _aBias = rawResidual;
      _biasPrimed = true;
    } else {
      // Exponential bias toward slow residual (tilt / phone offset).
      final alpha = 1 - math.exp(-dt / residualBiasTauS);
      _aBias += (rawResidual - _aBias) * alpha;
    }
    final aHp = rawResidual - _aBias;

    // Leaky double integrate (damped KF-style heave).
    final leak = math.exp(-leakPerSecond * dt);
    _v = (_v + aHp * dt) * leak;
    _z = (_z + _v * dt) * leak;

    _buf.add((at: s.at, residual: aHp, heave: _z));
    _trim(s.at);
  }

  void _trim(DateTime now) {
    final cut = now.subtract(
      Duration(milliseconds: (windowSeconds * 1000).round()),
    );
    while (_buf.isNotEmpty && _buf.first.at.isBefore(cut)) {
      _buf.removeAt(0);
    }
  }

  ImuSeaStateEstimate evaluate() {
    if (_buf.length < minSamples) {
      return ImuSeaStateEstimate(
        seaState: SeaState.unknown,
        significantWaveHeightM: null,
        residualAccelRms: 0,
        residualAccelP90: 0,
        dominantPeriodS: null,
        sampleCount: _buf.length,
        windowSeconds: _spanSeconds(),
        confident: false,
        statusMessage: 'Collecting phone motion… (${_buf.length}/$minSamples)',
      );
    }

    final residuals = _buf.map((e) => e.residual).toList();
    final heaves = _buf.map((e) => e.heave).toList();
    final span = _spanSeconds();
    final rms = _rms(residuals);
    final p90 = _percentile(residuals.map((v) => v.abs()).toList(), 0.9) ?? 0;
    final heaveStd = _std(heaves) ?? 0;
    // Irregular-wave significant height proxy from heave displacement.
    final hs = 4.0 * heaveStd;
    final period = _zeroCrossingPeriodS();
    final confident = span >= minConfidentSeconds && _buf.length >= minSamples;
    final sea = classifyHs(hs);

    final status = confident
        ? 'Phone IMU Hs≈${hs.toStringAsFixed(2)} m → ${sea.label}'
        : 'Warming up phone IMU (${span.toStringAsFixed(0)}s)';

    return ImuSeaStateEstimate(
      seaState: confident ? sea : SeaState.unknown,
      significantWaveHeightM: hs,
      residualAccelRms: rms,
      residualAccelP90: p90,
      dominantPeriodS: period,
      sampleCount: _buf.length,
      windowSeconds: span,
      confident: confident,
      statusMessage: status,
    );
  }

  /// WMO-style mapping used for suggested sea state.
  static SeaState classifyHs(double hsM) {
    if (!hsM.isFinite || hsM < 0) return SeaState.unknown;
    if (hsM < hsCalmMaxM) return SeaState.calm;
    if (hsM < hsModerateMaxM) return SeaState.moderate;
    return SeaState.rough;
  }

  /// Rougher of two sea states (for optional fuse with instrument proxy).
  static SeaState rougher(SeaState a, SeaState b) {
    return _rank(a) >= _rank(b) ? a : b;
  }

  static int _rank(SeaState s) => switch (s) {
        SeaState.unknown => 0,
        SeaState.calm => 1,
        SeaState.moderate => 2,
        SeaState.rough => 3,
      };

  double _spanSeconds() {
    if (_buf.length < 2) return 0;
    return _buf.last.at.difference(_buf.first.at).inMicroseconds / 1e6;
  }

  static double _rms(List<double> v) {
    if (v.isEmpty) return 0;
    var s = 0.0;
    for (final x in v) {
      s += x * x;
    }
    return math.sqrt(s / v.length);
  }

  static double? _std(List<double> v) {
    if (v.length < 2) return null;
    final mean = v.reduce((a, b) => a + b) / v.length;
    var sumSq = 0.0;
    for (final x in v) {
      final d = x - mean;
      sumSq += d * d;
    }
    return math.sqrt(sumSq / v.length);
  }

  static double? _percentile(List<double> values, double p) {
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

  /// Dominant period from zero-crossings of high-pass residual (s).
  double? _zeroCrossingPeriodS() {
    if (_buf.length < 20) return null;
    var crossings = 0;
    for (var i = 1; i < _buf.length; i++) {
      final a = _buf[i - 1].residual;
      final b = _buf[i].residual;
      if ((a <= 0 && b > 0) || (a >= 0 && b < 0)) crossings++;
    }
    final span = _spanSeconds();
    if (span <= 0 || crossings < 2) return null;
    // Two crossings per full period.
    final period = 2 * span / crossings;
    if (period < 0.8 || period > 25) return null;
    return period;
  }
}
