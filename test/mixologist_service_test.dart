import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/mixologist_service.dart';

void main() {
  group('MixologistService.suggest (cocktails)', () {
    test('returns null when no ingredients are marked in-bar', () {
      final bar = [
        BarIngredient()
          ..name = 'Gin'
          ..category = 'spirit'
          ..inMyBar = false,
      ];
      expect(MixologistService.suggest(vibes: const ['citrus'], barIngredients: bar), isNull);
    });

    test('returns null when in-bar ingredients contain no spirit', () {
      final bar = [
        BarIngredient()
          ..name = 'Fresh Lime Juice'
          ..category = 'juice'
          ..flavorProfiles = ['sour', 'citrus']
          ..inMyBar = true,
      ];
      expect(MixologistService.suggest(vibes: const ['citrus'], barIngredients: bar), isNull);
    });

    test('builds a shaken cocktail from a spirit, acid, and sweet', () {
      final bar = [
        BarIngredient()
          ..name = 'Gin'
          ..category = 'spirit'
          ..flavorProfiles = ['citrus', 'fresh']
          ..inMyBar = true,
        BarIngredient()
          ..name = 'Fresh Lime Juice'
          ..category = 'juice'
          ..flavorProfiles = ['sour', 'citrus']
          ..inMyBar = true,
        BarIngredient()
          ..name = 'Simple Syrup'
          ..category = 'syrup'
          ..flavorProfiles = ['sweet']
          ..inMyBar = true,
      ];

      final suggestion = MixologistService.suggest(vibes: const ['citrus'], barIngredients: bar);

      expect(suggestion, isNotNull);
      expect(suggestion!.technique, 'shake');
      expect(suggestion.ingredients.first.name, 'Gin');
      expect(suggestion.ingredients.first.quantity, 2.0);
      expect(suggestion.name, isNotEmpty);
      expect(suggestion.instructions, contains('shaker'));
    });

    test('an empty vibe list falls back to a default flavor set instead of throwing', () {
      final bar = [
        BarIngredient()
          ..name = 'Gin'
          ..category = 'spirit'
          ..inMyBar = true,
      ];
      final suggestion = MixologistService.suggest(vibes: const [], barIngredients: bar);
      expect(suggestion, isNotNull);
    });
  });

  group('MixologistService.foodPairings', () {
    test('returns rum pairings for a rum spirit name', () {
      expect(MixologistService.foodPairings('Appleton Estate Rum'), contains('Jerk chicken'));
    });

    test('falls back to a generic list for an unrecognized spirit', () {
      expect(MixologistService.foodPairings('Absinthe'), isNotEmpty);
    });
  });

  group('MixologistService.suggestDish', () {
    test('returns null when no pantry ingredients are marked in-pantry', () {
      final pantry = [
        PantryIngredient()
          ..name = 'Garlic'
          ..category = 'vegetable'
          ..inMyPantry = false,
      ];
      expect(MixologistService.suggestDish(vibes: const ['italian'], pantryIngredients: pantry), isNull);
    });

    test('excludes ingredients that carry a restricted allergen', () {
      final pantry = [
        PantryIngredient()
          ..name = 'Parmesan'
          ..category = 'dairy'
          ..inMyPantry = true
          ..allergenTags = ['dairy'],
        PantryIngredient()
          ..name = 'Extra Virgin Olive Oil'
          ..category = 'oil'
          ..inMyPantry = true,
      ];

      final suggestion = MixologistService.suggestDish(
        vibes: const ['italian'],
        pantryIngredients: pantry,
        allergenRestrictions: const ['dairy'],
      );

      // Parmesan excluded, but the remaining oil is enough to build a dish.
      expect(suggestion, isNotNull);
      final names = suggestion!.ingredients.map((i) => i.name);
      expect(names, isNot(contains('Parmesan')));
    });

    test('requires every dietary tag to be present when dietaryRequirements is set', () {
      final pantry = [
        PantryIngredient()
          ..name = 'Butter'
          ..category = 'dairy'
          ..inMyPantry = true
          ..dietaryTags = ['vegetarian'],
      ];

      final suggestion = MixologistService.suggestDish(
        vibes: const ['comfort'],
        pantryIngredients: pantry,
        dietaryRequirements: const ['vegan'],
      );

      expect(suggestion, isNull);
    });
  });
}
