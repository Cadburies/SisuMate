import '../models/models.dart';

// Only genuine weight units are converted — volume units (cup, tbsp, ml...)
// would require an ingredient-specific density assumption (a cup of flour and
// a cup of olive oil weigh very differently), and count units (pieces, bulbs,
// fillets...) have no fixed weight at all. Rather than fabricate a number,
// ingredients measured in those units are simply left out of the total.
const _gramsPerUnit = <String, double>{
  'g': 1,
  'gram': 1,
  'grams': 1,
  'kg': 1000,
  'oz': 28.3495,
  'lb': 453.592,
  'lbs': 453.592,
};

class IngredientCalories {
  final String name;
  final double? calories; // null when the unit can't be converted to grams
  const IngredientCalories(this.name, this.calories);
}

class RecipeCalorieSummary {
  final double? totalCalories; // null when nothing could be computed
  final int computedCount;
  final int totalCount;
  final List<IngredientCalories> perIngredient;
  const RecipeCalorieSummary({
    required this.totalCalories,
    required this.computedCount,
    required this.totalCount,
    required this.perIngredient,
  });
}

/// Estimates total calories for a recipe from its ingredients' weight-based
/// quantities and each matched PantryIngredient's `caloriesPer100g`. Partial
/// by design: only ingredients with a real weight unit (g/kg/oz/lb) and a
/// pantry match with known calories contribute.
class CalorieCalculator {
  static RecipeCalorieSummary compute(
    List<RecipeIngredient> ingredients,
    List<PantryIngredient> pantry,
  ) {
    final pantryByName = {
      for (final p in pantry) p.name.toLowerCase().trim(): p,
    };

    var total = 0.0;
    var computedCount = 0;
    final perIngredient = <IngredientCalories>[];

    for (final ing in ingredients) {
      final gramsPerUnit =
          ing.unit == null ? null : _gramsPerUnit[ing.unit!.toLowerCase()];
      final pantryMatch = pantryByName[ing.name.toLowerCase().trim()];
      final caloriesPer100g = pantryMatch?.caloriesPer100g;

      double? calories;
      if (ing.quantity != null &&
          gramsPerUnit != null &&
          caloriesPer100g != null) {
        final grams = ing.quantity! * gramsPerUnit;
        calories = grams / 100 * caloriesPer100g;
        total += calories;
        computedCount++;
      }
      perIngredient.add(IngredientCalories(ing.name, calories));
    }

    return RecipeCalorieSummary(
      totalCalories: computedCount > 0 ? total : null,
      computedCount: computedCount,
      totalCount: ingredients.length,
      perIngredient: perIngredient,
    );
  }
}
