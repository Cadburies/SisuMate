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
    List<PantryIngredient> pantry,
  ) {
    final pantryByName = {
      for (final p in pantry) p.name.toLowerCase().trim(): p,
    };
    final allergens = <String>{};
    Set<String>? dietaryIntersection;
    for (final ing in ingredients) {
      final p = pantryByName[ing.name.toLowerCase().trim()];
      if (p == null) continue;
      allergens.addAll(p.allergenTags);
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
