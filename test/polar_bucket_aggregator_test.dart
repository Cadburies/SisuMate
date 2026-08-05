import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/models/sailing_polar_sample.dart';
import 'package:sisu_mate/services/polar_bucket_aggregator.dart';

SailingPolarSample sample({
  required double twa,
  required double tws,
  required double sog,
}) =>
    SailingPolarSample()
      ..boatSupabaseId = 'b'
      ..observedAt = DateTime.utc(2026, 8, 5)
      ..twaDeg = twa
      ..twsKt = tws
      ..sogKt = sog;

void main() {
  group('PolarBucketAggregator', () {
    test('buckets by nearest TWA/TWS centres', () {
      final samples = [
        for (var i = 0; i < 6; i++)
          sample(twa: 88 + i * 0.1, tws: 11.5, sog: 6.0 + i * 0.1),
      ];
      final buckets = PolarBucketAggregator.bucket(samples);
      expect(buckets, isNotEmpty);
      final b = buckets.firstWhere((x) => x.twsCentreKt == 12);
      expect(b.twaCentreDeg, 90);
      expect(b.sampleCount, 6);
      expect(b.representativeSogKt(p: 0.9), greaterThan(6.0));
    });

    test('mergeIntoPolar inserts and never lowers existing speeds', () {
      final existing = [
        const PolarPoint(twaDeg: 90, twsKt: 12, boatSpeedKt: 7.0),
      ];
      final buckets = PolarBucketAggregator.bucket([
        for (var i = 0; i < 8; i++) sample(twa: 90, tws: 12, sog: 6.0),
      ]);
      final merged = PolarBucketAggregator.mergeIntoPolar(
        existing: existing,
        buckets: buckets,
        minSamples: 5,
      );
      // Measured p90 is ~6; existing 7 is higher → keep 7.
      final pt = merged.singleWhere((p) => p.twaDeg == 90 && p.twsKt == 12);
      expect(pt.boatSpeedKt, 7.0);
    });

    test('mergeIntoPolar raises when measured p90 is higher', () {
      final existing = [
        const PolarPoint(twaDeg: 90, twsKt: 12, boatSpeedKt: 5.0),
      ];
      final buckets = PolarBucketAggregator.bucket([
        for (var i = 0; i < 10; i++) sample(twa: 90, tws: 12, sog: 8.0),
      ]);
      final merged = PolarBucketAggregator.mergeIntoPolar(
        existing: existing,
        buckets: buckets,
      );
      expect(merged.single.boatSpeedKt, 8.0);
    });
  });
}
