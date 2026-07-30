import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/recipe_allergen_service.dart';

void main() {
  group('RecipeAllergenService.assess', () {
    test('unions allergen tags across all matched ingredients', () {
      final ingredients = [
        RecipeIngredient()..name = 'Flour',
        RecipeIngredient()..name = 'Peanuts',
      ];
      final pantry = [
        PantryIngredient()
          ..name = 'Flour'
          ..allergenTags = ['gluten'],
        PantryIngredient()
          ..name = 'Peanuts'
          ..allergenTags = ['nuts'],
      ];

      final result = RecipeAllergenService.assess(ingredients, pantry);
      expect(result.allergens, {'gluten', 'nuts'});
    });

    test('dietary badge only applies when every non-garnish ingredient carries it', () {
      final ingredients = [
        RecipeIngredient()..name = 'Tofu',
        RecipeIngredient()..name = 'Rice',
      ];
      final pantry = [
        PantryIngredient()
          ..name = 'Tofu'
          ..dietaryTags = ['vegan', 'vegetarian'],
        PantryIngredient()
          ..name = 'Rice'
          ..dietaryTags = ['vegan'],
      ];

      final result = RecipeAllergenService.assess(ingredients, pantry);
      expect(result.dietaryBadges, {'vegan'});
    });

    test('garnish ingredients are excluded from the dietary intersection', () {
      final ingredients = [
        RecipeIngredient()..name = 'Tofu',
        RecipeIngredient()
          ..name = 'Bacon bits'
          ..isGarnish = true,
      ];
      final pantry = [
        PantryIngredient()
          ..name = 'Tofu'
          ..dietaryTags = ['vegan'],
        PantryIngredient()
          ..name = 'Bacon bits'
          ..dietaryTags = [], // not vegan, but it's a garnish so shouldn't break the badge
      ];

      final result = RecipeAllergenService.assess(ingredients, pantry);
      expect(result.dietaryBadges, {'vegan'});
    });

    test('unmatched ingredients (no pantry entry) are silently skipped', () {
      final ingredients = [RecipeIngredient()..name = 'Unknown Item'];
      final result = RecipeAllergenService.assess(ingredients, []);
      expect(result.allergens, isEmpty);
      expect(result.dietaryBadges, isEmpty);
    });

    test('non-positive dietary tags are filtered out of the badges', () {
      final ingredients = [RecipeIngredient()..name = 'Mystery Sauce'];
      final pantry = [
        PantryIngredient()
          ..name = 'Mystery Sauce'
          ..dietaryTags = ['house-special'], // not in positiveDietaryLabels
      ];

      final result = RecipeAllergenService.assess(ingredients, pantry);
      expect(result.dietaryBadges, isEmpty);
    });
  });
}
