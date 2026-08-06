import 'dart:convert';

import '../models/models.dart' show PolarPoint;
import '../models/sailing_polar_sample.dart';
import '../models/sea_state.dart';
import 'polar_bucket_aggregator.dart';
import 'polar_sample_eligibility.dart';

/// #276 — offline polar upgrades: outlier rejection + optional spline smooth.
///
/// Steady-state filtering happens at **collection** time
/// ([SeaStateEstimator.isSteadyState]). This layer cleans buckets and
/// curves after samples are already stored.
class PolarLocalImprove {
  /// Reject values farther than this many MADs from the median (robust).
  static const outlierMadK = 3.0;

  /// Minimum samples remaining after outlier drop to still use the bucket.
  static const minAfterOutliers = 3;

  /// MAD of sorted speeds; null if empty.
  static double? medianAbsoluteDeviation(List<double> values) {
    if (values.isEmpty) return null;
    final med = percentile(values, 0.5);
    if (med == null) return null;
    final devs = values.map((v) => (v - med).abs()).toList()..sort();
    return percentile(devs, 0.5);
  }

  /// Drop speed outliers via median ± k·MAD (falls back to IQR if MAD≈0).
  static List<double> rejectOutliers(
    List<double> speeds, {
    double k = outlierMadK,
  }) {
    if (speeds.length < 4) return List<double>.from(speeds);
    final med = percentile(speeds, 0.5);
    if (med == null) return List<double>.from(speeds);
    final mad = medianAbsoluteDeviation(speeds) ?? 0;
    if (mad > 1e-6) {
      final lo = med - k * mad;
      final hi = med + k * mad;
      final kept = speeds.where((v) => v >= lo && v <= hi).toList();
      return kept.length >= minAfterOutliers ? kept : List<double>.from(speeds);
    }
    // IQR fallback when all values nearly equal or MAD is 0.
    final q1 = percentile(speeds, 0.25) ?? med;
    final q3 = percentile(speeds, 0.75) ?? med;
    final iqr = q3 - q1;
    if (iqr < 1e-6) return List<double>.from(speeds);
    final lo = q1 - 1.5 * iqr;
    final hi = q3 + 1.5 * iqr;
    final kept = speeds.where((v) => v >= lo && v <= hi).toList();
    return kept.length >= minAfterOutliers ? kept : List<double>.from(speeds);
  }

  /// Re-bucket with outlier-cleaned speeds; optional sea-state filter.
  static List<PolarBucket> bucketClean({
    required Iterable<SailingPolarSample> samples,
    SeaState? seaStateOnly,
    double twaStep = 10,
    List<double> twsCentres = kPolarTwsCentresKt,
  }) {
    final filtered = samples.where((s) {
      if (seaStateOnly == null) return true;
      if (seaStateOnly == SeaState.unknown) return true;
      return s.seaState == seaStateOnly.wireValue;
    });
    final raw = PolarBucketAggregator.bucket(
      filtered,
      twaStep: twaStep,
      twsCentres: twsCentres,
    );
    return [
      for (final b in raw)
        () {
          final cleaned = rejectOutliers(b.sogSamples);
          return PolarBucket(
            twaCentreDeg: b.twaCentreDeg,
            twsCentreKt: b.twsCentreKt,
            sogSamples: cleaned,
            sampleCount: cleaned.length,
          );
        }(),
    ];
  }

  /// Smooth boat speeds along increasing TWA for one TWS curve.
  ///
  /// Endpoints fixed; interior points blend toward neighbor mean.
  /// [alpha] 0 = no change, ~0.35 is a light smooth.
  static List<PolarPoint> smoothTwsCurve(
    List<PolarPoint> points, {
    double alpha = 0.35,
  }) {
    if (points.length < 3 || alpha <= 0) {
      return List<PolarPoint>.from(points);
    }
    final sorted = [...points]
      ..sort((a, b) =>
          polarNormalizeTwa(a.twaDeg).compareTo(polarNormalizeTwa(b.twaDeg)));
    final out = <PolarPoint>[];
    for (var i = 0; i < sorted.length; i++) {
      final p = sorted[i];
      if (i == 0 || i == sorted.length - 1) {
        out.add(p);
        continue;
      }
      final prev = sorted[i - 1].boatSpeedKt;
      final next = sorted[i + 1].boatSpeedKt;
      final neighborMean = (prev + next) / 2;
      final blended = p.boatSpeedKt * (1 - alpha) + neighborMean * alpha;
      out.add(PolarPoint(
        twaDeg: p.twaDeg,
        twsKt: p.twsKt,
        boatSpeedKt: blended.clamp(0.1, 100),
      ));
    }
    return out;
  }

  /// Smooth each TWS group independently, then recombine.
  static List<PolarPoint> smoothPolar(
    List<PolarPoint> polar, {
    double alpha = 0.35,
  }) {
    if (polar.length < 3) return List<PolarPoint>.from(polar);
    final byTws = <double, List<PolarPoint>>{};
    for (final p in polar) {
      byTws.putIfAbsent(p.twsKt, () => []).add(p);
    }
    final out = <PolarPoint>[];
    for (final e in byTws.entries) {
      out.addAll(smoothTwsCurve(e.value, alpha: alpha));
    }
    out.sort((a, b) {
      final c = a.twsKt.compareTo(b.twsKt);
      return c != 0
          ? c
          : polarNormalizeTwa(a.twaDeg).compareTo(polarNormalizeTwa(b.twaDeg));
    });
    return out;
  }

  /// Build per-sea-state polars + primary (calm-preferring) polar for routing.
  static PolarLocalResult improveOffline({
    required List<PolarPoint> existing,
    required List<SailingPolarSample> samples,
    bool applySpline = true,
    double smoothAlpha = 0.35,
    int minSamples = PolarBucketAggregator.minSamplesPerBucket,
  }) {
    final bySea = <String, List<PolarPoint>>{};
    var totalUsableBuckets = 0;

    for (final sea in SeaState.chartOrder) {
      final buckets = bucketClean(samples: samples, seaStateOnly: sea);
      final usable =
          buckets.where((b) => b.sampleCount >= minSamples).length;
      totalUsableBuckets += usable;
      if (usable == 0) continue;
      var merged = PolarBucketAggregator.mergeIntoPolar(
        existing: sea == SeaState.calm ? existing : const [],
        buckets: buckets,
        minSamples: minSamples,
      );
      if (applySpline) {
        merged = smoothPolar(merged, alpha: smoothAlpha);
      }
      if (merged.isNotEmpty) {
        bySea[sea.wireValue] = merged;
      }
    }

    // Fallback: if no sea-state tags (legacy samples), build overall polar.
    if (bySea.isEmpty) {
      final buckets = bucketClean(samples: samples);
      final usable =
          buckets.where((b) => b.sampleCount >= minSamples).length;
      totalUsableBuckets = usable;
      if (usable > 0) {
        var merged = PolarBucketAggregator.mergeIntoPolar(
          existing: existing,
          buckets: buckets,
          minSamples: minSamples,
        );
        if (applySpline) {
          merged = smoothPolar(merged, alpha: smoothAlpha);
        }
        bySea[SeaState.calm.wireValue] = merged;
      }
    }

    // Primary routing polar: calm if present, else max envelope of all.
    List<PolarPoint> primary;
    if (bySea.containsKey(SeaState.calm.wireValue)) {
      primary = bySea[SeaState.calm.wireValue]!;
    } else if (bySea.isEmpty) {
      primary = existing;
    } else {
      primary = _maxEnvelope(bySea.values.expand((e) => e).toList());
      if (existing.isNotEmpty) {
        primary = PolarBucketAggregator.mergeIntoPolar(
          existing: existing,
          buckets: [
            for (final p in primary)
              PolarBucket(
                twaCentreDeg: polarNormalizeTwa(p.twaDeg),
                twsCentreKt: p.twsKt,
                sogSamples: [p.boatSpeedKt],
                sampleCount: minSamples,
              ),
          ],
          minSamples: minSamples,
        );
      }
    }

    return PolarLocalResult(
      primaryPolar: primary,
      polarBySeaState: bySea,
      usableBucketCount: totalUsableBuckets,
    );
  }

  /// Pointwise max speed across same TWA×TWS neighbourhoods.
  static List<PolarPoint> _maxEnvelope(List<PolarPoint> points) {
    if (points.isEmpty) return const [];
    return PolarBucketAggregator.mergeIntoPolar(
      existing: const [],
      buckets: [
        for (final p in points)
          PolarBucket(
            twaCentreDeg: polarNormalizeTwa(p.twaDeg),
            twsCentreKt: p.twsKt,
            sogSamples: [p.boatSpeedKt],
            sampleCount: PolarBucketAggregator.minSamplesPerBucket,
          ),
      ],
      minSamples: PolarBucketAggregator.minSamplesPerBucket,
    );
  }
}

class PolarLocalResult {
  final List<PolarPoint> primaryPolar;
  final Map<String, List<PolarPoint>> polarBySeaState;
  final int usableBucketCount;

  const PolarLocalResult({
    required this.primaryPolar,
    required this.polarBySeaState,
    required this.usableBucketCount,
  });
}

/// Encode / decode multi-polar map for Drift + wire.
String encodePolarBySeaState(Map<String, List<PolarPoint>> map) {
  final j = <String, dynamic>{
    for (final e in map.entries)
      e.key: e.value.map((p) => p.toJson()).toList(),
  };
  return jsonEncode(j);
}

Map<String, List<PolarPoint>> parsePolarBySeaState(String? raw) {
  if (raw == null || raw.isEmpty || raw == '{}') return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    final out = <String, List<PolarPoint>>{};
    for (final e in decoded.entries) {
      final list = e.value;
      if (list is! List) continue;
      out[e.key.toString()] = [
        for (final item in list)
          if (item is Map)
            PolarPoint.fromJson(Map<String, dynamic>.from(item)),
      ];
    }
    return out;
  } catch (_) {
    return {};
  }
}
