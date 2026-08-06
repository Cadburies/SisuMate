import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/models/sailing_polar_sample.dart';
import 'package:sisu_mate/models/sea_state.dart';
import 'package:sisu_mate/services/polar_local_improve.dart';

SailingPolarSample sample({
  required double twa,
  required double tws,
  required double speed,
  String sea = 'calm',
}) =>
    SailingPolarSample()
      ..boatSupabaseId = 'b'
      ..observedAt = DateTime.utc(2026, 8, 6)
      ..twaDeg = twa
      ..twsKt = tws
      ..sogKt = speed
      ..boatSpeedKt = speed
      ..speedSource = 'sog'
      ..seaState = sea;

void main() {
  group('PolarLocalImprove', () {
    test('rejectOutliers drops extreme speeds', () {
      final speeds = [6.0, 6.1, 5.9, 6.2, 6.0, 20.0, 5.8];
      final cleaned = PolarLocalImprove.rejectOutliers(speeds);
      expect(cleaned, isNot(contains(20.0)));
      expect(cleaned.length, lessThan(speeds.length));
    });

    test('smoothTwsCurve blends interior points', () {
      final pts = [
        const PolarPoint(twaDeg: 60, twsKt: 12, boatSpeedKt: 5),
        const PolarPoint(twaDeg: 90, twsKt: 12, boatSpeedKt: 9),
        const PolarPoint(twaDeg: 120, twsKt: 12, boatSpeedKt: 5),
      ];
      final smooth = PolarLocalImprove.smoothTwsCurve(pts, alpha: 0.5);
      expect(smooth.first.boatSpeedKt, 5);
      expect(smooth.last.boatSpeedKt, 5);
      // Interior pulled toward neighbor mean (5).
      expect(smooth[1].boatSpeedKt, lessThan(9));
      expect(smooth[1].boatSpeedKt, greaterThan(5));
    });

    test('improveOffline builds separate sea-state polars', () {
      final samples = [
        for (var i = 0; i < 8; i++)
          sample(twa: 90, tws: 12, speed: 7.0, sea: 'calm'),
        for (var i = 0; i < 8; i++)
          sample(twa: 90, tws: 12, speed: 4.5, sea: 'rough'),
      ];
      final result = PolarLocalImprove.improveOffline(
        existing: const [],
        samples: samples,
        applySpline: false,
      );
      expect(result.usableBucketCount, greaterThan(0));
      expect(result.polarBySeaState.containsKey(SeaState.calm.wireValue), isTrue);
      expect(result.polarBySeaState.containsKey(SeaState.rough.wireValue), isTrue);
      final calm = result.polarBySeaState[SeaState.calm.wireValue]!;
      final rough = result.polarBySeaState[SeaState.rough.wireValue]!;
      final calmPt = calm.firstWhere((p) => p.twsKt == 12);
      final roughPt = rough.firstWhere((p) => p.twsKt == 12);
      expect(calmPt.boatSpeedKt, greaterThan(roughPt.boatSpeedKt));
      // Primary prefers calm.
      expect(result.primaryPolar, isNotEmpty);
      expect(
        result.primaryPolar.firstWhere((p) => p.twsKt == 12).boatSpeedKt,
        closeTo(calmPt.boatSpeedKt, 0.01),
      );
    });

    test('encode/parse polarBySeaState round-trip', () {
      final map = {
        'calm': [const PolarPoint(twaDeg: 90, twsKt: 12, boatSpeedKt: 7)],
        'rough': [const PolarPoint(twaDeg: 90, twsKt: 12, boatSpeedKt: 4)],
      };
      final raw = encodePolarBySeaState(map);
      final back = parsePolarBySeaState(raw);
      expect(back['calm']!.single.boatSpeedKt, 7);
      expect(back['rough']!.single.boatSpeedKt, 4);
    });
  });
}
