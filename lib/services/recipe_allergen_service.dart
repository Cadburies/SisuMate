import '../models/models.dart';

class RecipeAllergenAssessment {
  final Set<String> allergens;
  final Set<String> dietaryBadges;
  const RecipeAllergenAssessment({
    required this.allergens,
    required this.dietaryBadges,
  });
}

class RecipeAllergenService {
  static const positiveDietaryLabels = {
    'vegan', 'vegetarian', 'gluten-free', 'dairy-free',
    'keto', 'paleo', 'halal', 'kosher',
  };

  /// Derives allergen tags (union) and dietary badges (intersection) for a
  /// recipe from the pantry ingredients matching its RecipeIngredient names.
  /// A dietary badge only applies if EVERY matched non-garnish ingredient
  /// carries that tag.
  static RecipeAllergenAssessment assess(
    List<RecipeIngredient> ingredients,
    List<PantryIngredient> pantry, {
    List<BarIngredient> bar = const [],
  }) {
    final pantryByName = {
      for (final p in pantry) p.name.toLowerCase().trim(): p,
    };
    final barByName = {
      for (final b in bar) b.name.toLowerCase().trim(): b,
    };
    final allergens = <String>{};
    Set<String>? dietaryIntersection;
    for (final ing in ingredients) {
      final key = ing.name.toLowerCase().trim();
      final p = pantryByName[key];
      final b = barByName[key];
      if (p != null) allergens.addAll(p.allergenTags);
      if (b != null) allergens.addAll(b.allergenTags);
      if (p == null) continue;
      if (!ing.isGarnish && p.dietaryTags.isNotEmpty) {
        dietaryIntersection = dietaryIntersection == null
            ? p.dietaryTags.toSet()
            : dietaryIntersection.intersection(p.dietaryTags.toSet());
      }
    }
    final dietaryBadges = dietaryIntersection == null
        ? <String>{}
        : dietaryIntersection.intersection(positiveDietaryLabels);
    return RecipeAllergenAssessment(
        allergens: allergens, dietaryBadges: dietaryBadges);
  }
}
