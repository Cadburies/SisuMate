import '../models/models.dart' show PolarPoint;
import '../models/sailing_polar_sample.dart';
import 'polar_sample_eligibility.dart';

/// One TWA×TWS bucket of measured under-sail speeds.
class PolarBucket {
  final double twaCentreDeg;
  final double twsCentreKt;
  final List<double> sogSamples;
  final int sampleCount;

  const PolarBucket({
    required this.twaCentreDeg,
    required this.twsCentreKt,
    required this.sogSamples,
    required this.sampleCount,
  });

  /// High quantile (default p90) — matches measured-polar practice so
  /// lazy/dirty sailing does not pull the target down as hard as a mean.
  double? representativeSogKt({double p = 0.9}) => percentile(sogSamples, p);
}

/// #274 — aggregate [SailingPolarSample]s into polar-table candidates.
class PolarBucketAggregator {
  /// Minimum samples in a bucket before it can update the polar.
  static const minSamplesPerBucket = 5;

  static List<PolarBucket> bucket(
    Iterable<SailingPolarSample> samples, {
    double twaStep = 10,
    List<double> twsCentres = kPolarTwsCentresKt,
  }) {
    final twaCentres = polarTwaCentresDeg(step: twaStep);
    final map = <String, List<double>>{};
    final meta = <String, (double, double)>{};

    for (final s in samples) {
      final twa = nearestCentre(polarNormalizeTwa(s.twaDeg), twaCentres);
      final tws = nearestCentre(s.twsKt, twsCentres);
      final key = '${twa.toStringAsFixed(1)}_${tws.toStringAsFixed(1)}';
      map.putIfAbsent(key, () => []).add(s.sogKt);
      meta[key] = (twa, tws);
    }

    return [
      for (final e in map.entries)
        PolarBucket(
          twaCentreDeg: meta[e.key]!.$1,
          twsCentreKt: meta[e.key]!.$2,
          sogSamples: e.value,
          sampleCount: e.value.length,
        ),
    ]..sort((a, b) {
        final c = a.twsCentreKt.compareTo(b.twsCentreKt);
        return c != 0 ? c : a.twaCentreDeg.compareTo(b.twaCentreDeg);
      });
  }

  /// Merge measured bucket targets into [existing] polar.
  ///
  /// For each bucket with enough samples: if no nearby existing point,
  /// insert; if nearby, take **max** of existing speed and measured p90
  /// (healing improves targets, never silently degrades a good manual row).
  static List<PolarPoint> mergeIntoPolar({
    required List<PolarPoint> existing,
    required List<PolarBucket> buckets,
    int minSamples = minSamplesPerBucket,
    double p = 0.9,
    double twaNear = 8,
    double twsNear = 2,
  }) {
    final out = [...existing];

    for (final b in buckets) {
      if (b.sampleCount < minSamples) continue;
      final sog = b.representativeSogKt(p: p);
      if (sog == null || sog <= 0) continue;

      final idx = out.indexWhere(
        (pt) =>
            (polarNormalizeTwa(pt.twaDeg) - b.twaCentreDeg).abs() <= twaNear &&
            (pt.twsKt - b.twsCentreKt).abs() <= twsNear,
      );
      if (idx < 0) {
        out.add(PolarPoint(
          twaDeg: b.twaCentreDeg,
          twsKt: b.twsCentreKt,
          boatSpeedKt: sog,
        ));
      } else {
        final old = out[idx];
        out[idx] = PolarPoint(
          twaDeg: old.twaDeg,
          twsKt: old.twsKt,
          boatSpeedKt: sog > old.boatSpeedKt ? sog : old.boatSpeedKt,
        );
      }
    }

    out.sort((a, b) {
      final c = a.twsKt.compareTo(b.twsKt);
      return c != 0
          ? c
          : polarNormalizeTwa(a.twaDeg).compareTo(polarNormalizeTwa(b.twaDeg));
    });
    return out;
  }
}
