import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/polar_sample_eligibility.dart';
import 'package:sisu_mate/services/predictwind_datahub_service.dart';

void main() {
  group('PolarSampleEligibility', () {
    PredictWindBoatData data({
      double? sog = 5,
      double? stw,
      double? tws = 12,
      double? twd = 0,
      double? cog = 45,
    }) =>
        PredictWindBoatData(
          sogKt: sog,
          stwKt: stw,
          windSpeedKt: tws,
          windDirectionDeg: twd,
          cogDeg: cog,
          observedAt: DateTime.utc(2026, 8, 5, 12),
        );

    test('absoluteTwaDeg folds to 0–180', () {
      expect(PolarSampleEligibility.absoluteTwaDeg(0, 0), 0);
      expect(PolarSampleEligibility.absoluteTwaDeg(90, 0), 90);
      expect(PolarSampleEligibility.absoluteTwaDeg(0, 90), 90);
      expect(PolarSampleEligibility.absoluteTwaDeg(270, 0), 90);
    });

    test('enginesNotRunning when both RPM null or idle', () {
      expect(PolarSampleEligibility.enginesNotRunning(), isTrue);
      expect(
        PolarSampleEligibility.enginesNotRunning(
          enginePortRpm: 0,
          engineStbdRpm: 0,
        ),
        isTrue,
      );
      expect(
        PolarSampleEligibility.enginesNotRunning(
          enginePortRpm: 1200,
          engineStbdRpm: 0,
        ),
        isFalse,
      );
    });

    test('tryBuild accepts under-sail reading', () {
      final s = PolarSampleEligibility.tryBuild(
        data: data(),
        boatSupabaseId: 'boat-1',
      );
      expect(s, isNotNull);
      expect(s!.twaDeg, closeTo(45, 0.01));
      expect(s.boatSpeedKt, 5);
      expect(s.speedSource, 'sog');
    });

    test('prefers STW over SOG when both present', () {
      final s = PolarSampleEligibility.tryBuild(
        data: data(sog: 6, stw: 5.5),
        boatSupabaseId: 'boat-1',
      );
      expect(s, isNotNull);
      expect(s!.boatSpeedKt, 5.5);
      expect(s.speedSource, 'stw');
      expect(s.sogKt, 6);
      expect(s.stwKt, 5.5);
    });

    test('toSyncJson is anonymized (no engines / track fields)', () {
      final s = PolarSampleEligibility.tryBuild(
        data: data(),
        boatSupabaseId: 'boat-1',
        enginePortRpm: 0,
      )!;
      s.supabaseId = 'sample-1';
      final wire = s.toSyncJson();
      expect(wire.containsKey('enginePortRpm'), isFalse);
      expect(wire.containsKey('cogDeg'), isFalse);
      expect(wire.containsKey('twdDeg'), isFalse);
      expect(wire.containsKey('sourceLabel'), isFalse);
      expect(wire['boatSpeedKt'], isNotNull);
      expect(wire['twaDeg'], isNotNull);
      expect(wire['twsKt'], isNotNull);
    });

    test('tryBuild rejects motoring (engine revs)', () {
      final s = PolarSampleEligibility.tryBuild(
        data: data(),
        boatSupabaseId: 'boat-1',
        enginePortRpm: 900,
      );
      expect(s, isNull);
    });

    test('tryBuild rejects low SOG or light wind', () {
      expect(
        PolarSampleEligibility.tryBuild(
          data: data(sog: 0.5),
          boatSupabaseId: 'boat-1',
        ),
        isNull,
      );
      expect(
        PolarSampleEligibility.tryBuild(
          data: data(tws: 1),
          boatSupabaseId: 'boat-1',
        ),
        isNull,
      );
    });
  });
}
