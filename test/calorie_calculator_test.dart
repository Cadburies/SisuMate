import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/calorie_calculator.dart';

RecipeIngredient _ingredient(String name, {double? quantity, String? unit}) {
  return RecipeIngredient()
    ..name = name
    ..quantity = quantity
    ..unit = unit;
}

PantryIngredient _pantryItem(String name, {double? caloriesPer100g}) {
  return PantryIngredient()
    ..name = name
    ..caloriesPer100g = caloriesPer100g;
}

void main() {
  group('CalorieCalculator', () {
    test('computes calories for a weight-unit ingredient with a pantry match', () {
      final ingredients = [_ingredient('Butter', quantity: 250, unit: 'g')];
      final pantry = [_pantryItem('Butter', caloriesPer100g: 717)];

      final result = CalorieCalculator.compute(ingredients, pantry);

      expect(result.totalCalories, closeTo(1792.5, 0.01)); // 250/100 * 717
      expect(result.computedCount, 1);
      expect(result.totalCount, 1);
    });

    test('converts oz and lb to grams correctly', () {
      final ingredients = [
        _ingredient('Calamari', quantity: 1, unit: 'lb'),
        _ingredient('Shiitake Mushrooms', quantity: 8, unit: 'oz'),
      ];
      final pantry = [
        _pantryItem('Calamari', caloriesPer100g: 92),
        _pantryItem('Shiitake Mushrooms', caloriesPer100g: 34),
      ];

      final result = CalorieCalculator.compute(ingredients, pantry);

      // 1 lb = 453.592g -> 453.592/100*92 = 417.3
      // 8 oz = 226.796g -> 226.796/100*34 = 77.1
      expect(result.totalCalories, closeTo(417.3 + 77.1, 0.5));
      expect(result.computedCount, 2);
    });

    test('skips ingredients measured in non-weight units (volume/count)', () {
      final ingredients = [
        _ingredient('Extra Virgin Olive Oil', quantity: 0.5, unit: 'cup'),
        _ingredient('Fennel', quantity: 2, unit: 'bulbs'),
        _ingredient('Fresh Sea Bass', quantity: 6, unit: 'fillets'),
      ];
      final pantry = [
        _pantryItem('Extra Virgin Olive Oil', caloriesPer100g: 884),
        _pantryItem('Fennel', caloriesPer100g: 31),
      ];

      final result = CalorieCalculator.compute(ingredients, pantry);

      expect(result.totalCalories, isNull);
      expect(result.computedCount, 0);
      expect(result.totalCount, 3);
      expect(result.perIngredient.every((i) => i.calories == null), isTrue);
    });

    test('is partial when only some ingredients can be computed', () {
      final ingredients = [
        _ingredient('Butter', quantity: 100, unit: 'g'), // computable
        _ingredient('Fresh Basil', quantity: 1, unit: 'bunch'), // not computable
      ];
      final pantry = [
        _pantryItem('Butter', caloriesPer100g: 717),
        _pantryItem('Fresh Basil', caloriesPer100g: 22),
      ];

      final result = CalorieCalculator.compute(ingredients, pantry);

      expect(result.totalCalories, closeTo(717, 0.01));
      expect(result.computedCount, 1);
      expect(result.totalCount, 2);
    });

    test('skips ingredients with no pantry match', () {
      final ingredients = [_ingredient('Mystery Meat', quantity: 200, unit: 'g')];

      final result = CalorieCalculator.compute(ingredients, const []);

      expect(result.totalCalories, isNull);
      expect(result.computedCount, 0);
    });

    test('returns an empty summary for an empty ingredient list', () {
      final result = CalorieCalculator.compute(const [], const []);

      expect(result.totalCalories, isNull);
      expect(result.computedCount, 0);
      expect(result.totalCount, 0);
      expect(result.perIngredient, isEmpty);
    });
  });
}
