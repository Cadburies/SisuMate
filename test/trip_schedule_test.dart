import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/trip_schedule.dart';

void main() {
  group('mealTypesForDay (CF25 — flexible trip length)', () {
    test('first day of a multi-day trip has no breakfast but has lunch, dinner and a snack', () {
      expect(mealTypesForDay(0, 5), ['snack', 'lunch', 'dinner']);
    });

    test('last day of a multi-day trip is breakfast only', () {
      expect(mealTypesForDay(4, 5), ['breakfast']);
    });

    test('middle days keep the full breakfast/lunch/dinner set', () {
      expect(mealTypesForDay(1, 5), ['breakfast', 'lunch', 'dinner']);
      expect(mealTypesForDay(2, 5), ['breakfast', 'lunch', 'dinner']);
      expect(mealTypesForDay(3, 5), ['breakfast', 'lunch', 'dinner']);
    });

    test('a 1-day trip falls back to the full meal set', () {
      expect(mealTypesForDay(0, 1), ['breakfast', 'lunch', 'dinner']);
    });

    test('works for trip lengths beyond a week', () {
      expect(mealTypesForDay(0, 10), ['snack', 'lunch', 'dinner']);
      expect(mealTypesForDay(9, 10), ['breakfast']);
      expect(mealTypesForDay(5, 10), ['breakfast', 'lunch', 'dinner']);
    });
  });

  group('totalSlotsForTrip', () {
    test('sums the per-day meal counts across the whole trip', () {
      // day0: 3 (snack, lunch, dinner) + days1-3: 3 each + day4: 1 (breakfast) = 13
      expect(totalSlotsForTrip(5), 3 + 3 + 3 + 3 + 1);
    });

    test('single-day trip totals 3', () {
      expect(totalSlotsForTrip(1), 3);
    });
  });
}
