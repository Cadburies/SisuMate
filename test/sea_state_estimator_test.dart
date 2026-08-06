import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/sea_state.dart';
import 'package:sisu_mate/services/sea_state_estimator.dart';

InstrumentReading r({
  required double speed,
  required double twa,
  double tws = 12,
  double? sog,
  double? stw,
  int sec = 0,
}) =>
    InstrumentReading(
      at: DateTime.utc(2026, 8, 6, 12, 0, sec),
      boatSpeedKt: speed,
      twaDeg: twa,
      twsKt: tws,
      sogKt: sog,
      stwKt: stw,
    );

void main() {
  group('SeaStateEstimator', () {
    test('unknown with fewer than minWindow readings', () {
      final m = SeaStateEstimator.evaluate([r(speed: 5, twa: 90)]);
      expect(m.seaState, SeaState.unknown);
    });

    test('classifies calm for stable speed and TWA', () {
      final window = [
        for (var i = 0; i < 6; i++)
          r(speed: 6.0 + i * 0.02, twa: 90 + i * 0.3, sec: i * 30),
      ];
      final m = SeaStateEstimator.evaluate(window);
      expect(m.seaState, SeaState.calm);
      expect(m.speedCv, lessThan(SeaStateEstimator.calmSpeedCv));
    });

    test('classifies rough for high speed variance', () {
      final speeds = [4.0, 7.5, 3.5, 8.0, 4.2, 7.8];
      final window = [
        for (var i = 0; i < speeds.length; i++)
          r(speed: speeds[i], twa: 90, sec: i * 30),
      ];
      final m = SeaStateEstimator.evaluate(window);
      expect(m.seaState, SeaState.rough);
    });

    test('classifies rough for high TWA std', () {
      final twas = [60.0, 90.0, 120.0, 70.0, 110.0, 80.0];
      final window = [
        for (var i = 0; i < twas.length; i++)
          r(speed: 6.0, twa: twas[i], sec: i * 30),
      ];
      final m = SeaStateEstimator.evaluate(window);
      expect(m.seaState, SeaState.rough);
    });

    test('isSteadyState rejects hard TWA jump', () {
      final recent = [
        r(speed: 6, twa: 60, sec: 0),
        r(speed: 6.1, twa: 100, sec: 30),
      ];
      expect(SeaStateEstimator.isSteadyState(recent), isFalse);
    });

    test('isSteadyState accepts stable hold', () {
      final recent = [
        r(speed: 6.0, twa: 90, sec: 0),
        r(speed: 6.1, twa: 92, sec: 30),
      ];
      expect(SeaStateEstimator.isSteadyState(recent), isTrue);
    });

    test('isSteadyState rejects large speed delta', () {
      final recent = [
        r(speed: 5.0, twa: 90, sec: 0),
        r(speed: 8.0, twa: 91, sec: 30),
      ];
      expect(SeaStateEstimator.isSteadyState(recent), isFalse);
    });
  });
}
