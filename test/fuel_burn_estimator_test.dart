import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/fuel_burn_estimator.dart';

FuelLogEntry _fill({
  required String type,
  required DateTime date,
  required double liters,
}) {
  return FuelLogEntry()
    ..type = type
    ..date = date
    ..liters = liters
    ..pricePerLiter = 0
    ..totalCost = 0
    ..supabaseId = 'f_${date.millisecondsSinceEpoch}_$type';
}

void main() {
  const estimator = FuelBurnEstimator();
  final now = DateTime.utc(2026, 7, 30);

  group('FuelBurnEstimator (BAI4)', () {
    test('returns null series when no fills of that type', () {
      final out = estimator.estimate(
        entries: [_fill(type: 'Fuel', date: DateTime.utc(2026, 7, 1), liters: 40)],
        now: now,
      );
      expect(out.map((e) => e.type), ['Fuel']);
      expect(out.where((e) => e.type == 'Water'), isEmpty);
    });

    test('single fill: capacity known, remaining unknown (no burn rate)', () {
      final out = estimator.estimate(
        entries: [
          _fill(type: 'Fuel', date: DateTime.utc(2026, 7, 20), liters: 80),
        ],
        now: now,
      );
      final fuel = out.single;
      expect(fuel.litersPerDay, isNull);
      expect(fuel.inferredCapacityLiters, 80);
      // Without a burn rate, remaining is unknown — not "full capacity".
      expect(fuel.estimatedRemainingLiters, isNull);
      expect(fuel.daysUntilEmpty, isNull);
      expect(fuel.summary, contains('unknown remaining'));
      expect(fuel.summary, contains('log another fill'));
    });

    test('two fills: burn rate from top-up / days span', () {
      // Day 0: 100 L, day 10: 50 L top-up → 50 L / 10 d = 5 L/day.
      final out = estimator.estimate(
        entries: [
          _fill(type: 'Fuel', date: DateTime.utc(2026, 7, 1), liters: 100),
          _fill(type: 'Fuel', date: DateTime.utc(2026, 7, 11), liters: 50),
        ],
        now: now, // 19 days after last fill
      );
      final fuel = out.single;
      expect(fuel.litersPerDay, closeTo(5.0, 0.01));
      expect(fuel.inferredCapacityLiters, 100);
      // remaining = 100 - 5*19 = 5
      expect(fuel.estimatedRemainingLiters, closeTo(5.0, 0.01));
      expect(fuel.daysUntilEmpty, 1);
      expect(fuel.summary, contains('L/day'));
      expect(fuel.summary, contains('to empty'));
    });

    test('hours and distance yield L/h and L/NM on fuel only', () {
      final out = estimator.estimate(
        entries: [
          _fill(type: 'Fuel', date: DateTime.utc(2026, 7, 1), liters: 100),
          _fill(type: 'Fuel', date: DateTime.utc(2026, 7, 11), liters: 40),
          _fill(type: 'Water', date: DateTime.utc(2026, 7, 1), liters: 200),
          _fill(type: 'Water', date: DateTime.utc(2026, 7, 11), liters: 100),
        ],
        hoursMotored: 20,
        distanceNm: 100,
        now: now,
      );
      final fuel = out.firstWhere((e) => e.type == 'Fuel');
      final water = out.firstWhere((e) => e.type == 'Water');
      // Fuel consumed after first fill = 40 L
      expect(fuel.litersPerHour, closeTo(2.0, 0.01));
      expect(fuel.litersPerNm, closeTo(0.4, 0.01));
      expect(water.litersPerHour, isNull);
      expect(water.litersPerNm, isNull);
    });

    test('capacity override and empty ETA when burn exceeds remaining', () {
      final out = estimator.estimate(
        entries: [
          _fill(type: 'Water', date: DateTime.utc(2026, 6, 1), liters: 50),
          _fill(type: 'Water', date: DateTime.utc(2026, 6, 11), liters: 50),
        ],
        waterCapacityLiters: 50,
        now: now, // far past last fill
      );
      final water = out.single;
      // 50 L / 10 d = 5 L/day; days since last = many → remaining 0
      expect(water.litersPerDay, closeTo(5.0, 0.01));
      expect(water.estimatedRemainingLiters, 0);
      expect(water.daysUntilEmpty, 0);
      expect(water.summary, contains('empty'));
    });

    test('same-day consecutive fills use 1-day span', () {
      final out = estimator.estimate(
        entries: [
          _fill(type: 'Fuel', date: DateTime.utc(2026, 7, 29), liters: 40),
          _fill(type: 'Fuel', date: DateTime.utc(2026, 7, 29, 18), liters: 20),
        ],
        now: now,
      );
      expect(out.single.litersPerDay, closeTo(20.0, 0.01));
    });

    test('recent intervals weigh more than older ones in L/day', () {
      // Three equal 10-day spans: rates 10, 10, then 2 L/day.
      // Flat mean would be (10+10+2)/3 ≈ 7.33; linear weights 1,2,3 →
      // (10·1 + 10·2 + 2·3) / 6 = 36/6 = 6.0 (pulled toward recent low burn).
      final out = estimator.estimate(
        entries: [
          _fill(type: 'Fuel', date: DateTime.utc(2026, 6, 1), liters: 100),
          _fill(type: 'Fuel', date: DateTime.utc(2026, 6, 11), liters: 100),
          _fill(type: 'Fuel', date: DateTime.utc(2026, 6, 21), liters: 100),
          _fill(type: 'Fuel', date: DateTime.utc(2026, 7, 1), liters: 20),
        ],
        now: now,
      );
      expect(out.single.litersPerDay, closeTo(6.0, 0.01));
    });

    test('rate window keeps only the last maxRateIntervals intervals', () {
      // 8 intervals of 1 L/day, then one recent 10 L/day — old 1s outside the
      // window of 6 must not dilute the weighted average as much as all 9 would.
      final entries = <FuelLogEntry>[
        _fill(type: 'Fuel', date: DateTime.utc(2026, 1, 1), liters: 100),
      ];
      // 8 early top-ups of 10 L every 10 days → 1 L/day each
      for (var i = 1; i <= 8; i++) {
        entries.add(_fill(
          type: 'Fuel',
          date: DateTime.utc(2026, 1, 1).add(Duration(days: 10 * i)),
          liters: 10,
        ));
      }
      // 9th interval: 100 L over 10 days → 10 L/day (most recent)
      entries.add(_fill(
        type: 'Fuel',
        date: DateTime.utc(2026, 1, 1).add(const Duration(days: 90)),
        liters: 100,
      ));

      final out = estimator.estimate(entries: entries, now: now);
      // Window = last 6 of [1×8, 10]: five 1s + one 10, weights 1..6
      // (1·1+1·2+1·3+1·4+1·5+10·6) / 21 = 75/21 ≈ 3.571
      expect(out.single.litersPerDay, closeTo(75 / 21, 0.01));
    });
  });
}
