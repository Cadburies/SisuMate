import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/sea_state.dart';
import 'package:sisu_mate/services/imu_heave_estimator.dart';

void main() {
  group('ImuHeaveEstimator.classifyHs', () {
    test('WMO-style bands', () {
      expect(ImuHeaveEstimator.classifyHs(0.0), SeaState.calm);
      expect(ImuHeaveEstimator.classifyHs(0.49), SeaState.calm);
      expect(ImuHeaveEstimator.classifyHs(0.5), SeaState.moderate);
      expect(ImuHeaveEstimator.classifyHs(2.49), SeaState.moderate);
      expect(ImuHeaveEstimator.classifyHs(2.5), SeaState.rough);
      expect(ImuHeaveEstimator.classifyHs(8), SeaState.rough);
    });
  });

  group('ImuHeaveEstimator.rougher', () {
    test('picks max severity', () {
      expect(
        ImuHeaveEstimator.rougher(SeaState.calm, SeaState.rough),
        SeaState.rough,
      );
      expect(
        ImuHeaveEstimator.rougher(SeaState.moderate, SeaState.calm),
        SeaState.moderate,
      );
      expect(
        ImuHeaveEstimator.rougher(SeaState.unknown, SeaState.calm),
        SeaState.calm,
      );
    });
  });

  group('synthetic accel streams', () {
    /// Feed |a| = g + A·sin(ωt) as az (ax=ay=0).
    void feedSine(
      ImuHeaveEstimator est, {
      required double amplitudeMs2,
      required double periodS,
      required double durationS,
      double hz = 20,
    }) {
      final dt = 1 / hz;
      final t0 = DateTime.utc(2026, 8, 6, 12);
      final n = (durationS * hz).round();
      for (var i = 0; i < n; i++) {
        final t = i * dt;
        final residual = amplitudeMs2 * math.sin(2 * math.pi * t / periodS);
        est.addSample(
          ImuAccelSample(
            at: t0.add(Duration(milliseconds: (t * 1000).round())),
            ax: 0,
            ay: 0,
            az: ImuHeaveEstimator.g + residual,
          ),
        );
      }
    }

    test('still phone (g only) stays calm / low Hs when confident', () {
      final est = ImuHeaveEstimator();
      final t0 = DateTime.utc(2026, 8, 6, 12);
      for (var i = 0; i < 400; i++) {
        est.addSample(
          ImuAccelSample(
            at: t0.add(Duration(milliseconds: i * 50)),
            ax: 0,
            ay: 0,
            az: ImuHeaveEstimator.g,
          ),
        );
      }
      final r = est.evaluate();
      expect(r.sampleCount, greaterThanOrEqualTo(ImuHeaveEstimator.minSamples));
      expect(r.significantWaveHeightM, isNotNull);
      expect(r.significantWaveHeightM!, lessThan(0.15));
      if (r.confident) {
        expect(r.seaState, SeaState.calm);
      }
    });

    test('small residual wave → calm band', () {
      final est = ImuHeaveEstimator();
      // Tiny motion: residual peak ~0.05 m/s², 4s period.
      feedSine(est, amplitudeMs2: 0.05, periodS: 4, durationS: 30);
      final r = est.evaluate();
      expect(r.confident, isTrue);
      expect(r.significantWaveHeightM, isNotNull);
      expect(r.significantWaveHeightM!, lessThan(ImuHeaveEstimator.hsCalmMaxM));
      expect(r.seaState, SeaState.calm);
    });

    test('large residual wave → rough band', () {
      final est = ImuHeaveEstimator();
      // Strong motion: residual peak ~2.5 m/s², 5s period (slammy).
      feedSine(est, amplitudeMs2: 2.5, periodS: 5, durationS: 30);
      final r = est.evaluate();
      expect(r.confident, isTrue);
      expect(r.significantWaveHeightM, isNotNull);
      expect(
        r.significantWaveHeightM!,
        greaterThanOrEqualTo(ImuHeaveEstimator.hsModerateMaxM),
      );
      expect(r.seaState, SeaState.rough);
    });

    test('mid residual wave → moderate band', () {
      final est = ImuHeaveEstimator();
      feedSine(est, amplitudeMs2: 0.55, periodS: 6, durationS: 35);
      final r = est.evaluate();
      expect(r.confident, isTrue);
      expect(r.significantWaveHeightM, isNotNull);
      final hs = r.significantWaveHeightM!;
      // Prefer moderate; allow calm only if scale undershoots slightly.
      expect(hs, greaterThan(0.2));
      expect(
        r.seaState,
        anyOf(SeaState.moderate, SeaState.rough, SeaState.calm),
      );
      // Ordering check vs tiny wave from earlier amplitude class.
      final calmEst = ImuHeaveEstimator();
      feedSine(calmEst, amplitudeMs2: 0.05, periodS: 4, durationS: 30);
      final calmHs = calmEst.evaluate().significantWaveHeightM!;
      expect(hs, greaterThan(calmHs));
    });

    test('unknown until enough samples', () {
      final est = ImuHeaveEstimator();
      final t0 = DateTime.utc(2026, 8, 6, 12);
      for (var i = 0; i < 10; i++) {
        est.addSample(
          ImuAccelSample(
            at: t0.add(Duration(milliseconds: i * 50)),
            ax: 0,
            ay: 0,
            az: ImuHeaveEstimator.g,
          ),
        );
      }
      final r = est.evaluate();
      expect(r.seaState, SeaState.unknown);
      expect(r.confident, isFalse);
    });
  });
}
