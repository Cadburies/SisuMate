import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/mixologist_service.dart';

Recipe _recipe(String id, String name) => Recipe()
  ..supabaseId = id
  ..name = name
  ..recipeType = 'cocktail';

RecipeIngredient _ing(String recipeId, String name,
        {bool optional = false, bool garnish = false}) =>
    RecipeIngredient()
      ..recipeSupabaseId = recipeId
      ..name = name
      ..isOptional = optional
      ..isGarnish = garnish;

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

    test('MIX3 light strength uses a smaller spirit pour than strong', () {
      final bar = [
        BarIngredient()
          ..name = 'Gin'
          ..category = 'spirit'
          ..alcoholByVolume = 40
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
      final light = MixologistService.suggest(
        vibes: const ['citrus'],
        barIngredients: bar,
        strength: CocktailStrength.light,
      )!;
      final strong = MixologistService.suggest(
        vibes: const ['citrus'],
        barIngredients: bar,
        strength: CocktailStrength.strong,
      )!;
      final lightSpirit = light.ingredients.firstWhere((i) => i.name == 'Gin');
      final strongSpirit = strong.ingredients.firstWhere((i) => i.name == 'Gin');
      expect(lightSpirit.quantity, lessThan(strongSpirit.quantity));
      expect(light.strengthLabel, 'Light');
      expect(strong.strengthLabel, 'Strong');
    });

    test('MIX3 glassware Highball forces build technique', () {
      final bar = [
        BarIngredient()
          ..name = 'Rum'
          ..category = 'spirit'
          ..inMyBar = true,
        BarIngredient()
          ..name = 'Soda Water'
          ..category = 'mixer'
          ..flavorProfiles = ['fizzy']
          ..inMyBar = true,
      ];
      final s = MixologistService.suggest(
        vibes: const ['fresh'],
        barIngredients: bar,
        glassware: 'Highball glass',
      )!;
      expect(s.technique, 'build');
      expect(s.glassware, 'Highball glass');
      expect(s.instructions.toLowerCase(), contains('highball'));
    });

    test('MIX3 servings scale pour quantities', () {
      final bar = [
        BarIngredient()
          ..name = 'Gin'
          ..category = 'spirit'
          ..alcoholByVolume = 40
          ..inMyBar = true,
      ];
      final one = MixologistService.suggest(
        vibes: const ['fresh'],
        barIngredients: bar,
        servings: 1,
      )!;
      final four = MixologistService.suggest(
        vibes: const ['fresh'],
        barIngredients: bar,
        servings: 4,
      )!;
      expect(four.servings, 4);
      expect(four.ingredients.first.quantity,
          closeTo(one.ingredients.first.quantity * 4, 0.3));
    });

    test('MIX3 estimates ABV when spirit ABV is known', () {
      final bar = [
        BarIngredient()
          ..name = 'Gin'
          ..category = 'spirit'
          ..alcoholByVolume = 40
          ..inMyBar = true,
        BarIngredient()
          ..name = 'Fresh Lime Juice'
          ..category = 'juice'
          ..alcoholByVolume = 0
          ..flavorProfiles = ['sour', 'citrus']
          ..inMyBar = true,
      ];
      final s = MixologistService.suggest(
        vibes: const ['citrus'],
        barIngredients: bar,
      )!;
      expect(s.estimatedAbvPercent, isNotNull);
      expect(s.estimatedAbvPercent!, greaterThan(5));
      expect(s.estimatedAbvPercent!, lessThan(40));
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

  group('MixologistService.rankMakeableTonight (MIX1)', () {
    test('ranks fully stocked recipes before ones with missing items', () {
      final bar = [
        BarIngredient()
          ..name = 'Gin'
          ..inMyBar = true,
        BarIngredient()
          ..name = 'Fresh Lime Juice'
          ..inMyBar = true,
        BarIngredient()
          ..name = 'Simple Syrup'
          ..inMyBar = true,
      ];
      final recipes = [
        _recipe('a', 'Gimlet'),
        _recipe('b', 'Needs Rum'),
      ];
      final map = {
        'a': [
          _ing('a', 'Gin'),
          _ing('a', 'Fresh Lime Juice'),
          _ing('a', 'Simple Syrup'),
        ],
        'b': [
          _ing('b', 'Dark Rum'),
          _ing('b', 'Fresh Lime Juice'),
        ],
      };

      final ranked = MixologistService.rankMakeableTonight(
        recipes: recipes,
        ingredientsByRecipeId: map,
        barIngredients: bar,
      );

      expect(ranked, hasLength(2));
      expect(ranked.first.recipe.name, 'Gimlet');
      expect(ranked.first.isMakeable, isTrue);
      expect(ranked.last.missingCount, 1);
      expect(ranked.last.missingNames, contains('Dark Rum'));
    });

    test('ignores optional and garnish ingredients for missing count', () {
      final bar = [
        BarIngredient()
          ..name = 'Gin'
          ..inMyBar = true,
      ];
      final ranked = MixologistService.rankMakeableTonight(
        recipes: [_recipe('x', 'Gin Up')],
        ingredientsByRecipeId: {
          'x': [
            _ing('x', 'Gin'),
            _ing('x', 'Lime Wheel', garnish: true),
            _ing('x', 'Bitters', optional: true),
          ],
        },
        barIngredients: bar,
      );
      expect(ranked.single.isMakeable, isTrue);
      expect(ranked.single.haveCount, 1);
    });
  });

  group('MixologistService.findSubstitutes (MIX2)', () {
    test('suggests lemon juice when lime juice is missing and lemon is stocked',
        () {
      final bar = [
        BarIngredient()
          ..name = 'Fresh Lemon Juice'
          ..inMyBar = true,
      ];
      final subs = MixologistService.findSubstitutes(
        neededName: 'Fresh Lime Juice',
        barIngredients: bar,
      );
      expect(subs, isNotEmpty);
      expect(subs.first.using.toLowerCase(), contains('lemon'));
      expect(subs.first.confidence, greaterThanOrEqualTo(0.6));
      expect(subs.first.note, isNotEmpty);
    });

    test('suggests almond syrup for orgeat', () {
      final bar = [
        BarIngredient()
          ..name = 'Almond Syrup'
          ..inMyBar = true,
      ];
      final subs = MixologistService.findSubstitutes(
        neededName: 'Orgeat',
        barIngredients: bar,
      );
      expect(subs.first.using.toLowerCase(), contains('almond'));
      expect(subs.first.countsAsHave, isTrue);
    });

    test('returns empty when the needed ingredient is already stocked', () {
      final bar = [
        BarIngredient()
          ..name = 'Lime Juice'
          ..inMyBar = true,
      ];
      expect(
        MixologistService.findSubstitutes(
          neededName: 'Lime Juice',
          barIngredients: bar,
        ),
        isEmpty,
      );
    });

    test('uses catalog substitute1 when stocked bottle covers the needed name',
        () {
      final bar = [
        BarIngredient()
          ..name = 'Cointreau'
          ..inMyBar = true
          ..substitute1 = 'Triple Sec',
      ];
      final subs = MixologistService.findSubstitutes(
        neededName: 'Triple Sec',
        barIngredients: bar,
      );
      expect(subs.any((s) => s.using == 'Cointreau'), isTrue);
    });

    test('rankMakeableTonight counts high-confidence substitute as have', () {
      final bar = [
        BarIngredient()
          ..name = 'Gin'
          ..inMyBar = true,
        BarIngredient()
          ..name = 'Fresh Lemon Juice'
          ..inMyBar = true,
        BarIngredient()
          ..name = 'Simple Syrup'
          ..inMyBar = true,
      ];
      final ranked = MixologistService.rankMakeableTonight(
        recipes: [_recipe('g', 'Gimlet')],
        ingredientsByRecipeId: {
          'g': [
            _ing('g', 'Gin'),
            _ing('g', 'Fresh Lime Juice'),
            _ing('g', 'Simple Syrup'),
          ],
        },
        barIngredients: bar,
      );
      expect(ranked.single.isMakeable, isTrue);
      expect(ranked.single.substitutesUsed, isNotEmpty);
      expect(ranked.single.isMakeableWithSubs, isTrue);
      expect(
        ranked.single.substitutesUsed.first.needed.toLowerCase(),
        contains('lime'),
      );
    });

    test('weak substitutes under 0.6 do not count as have', () {
      // mint↔basil is 0.45 — garnish-level only.
      final bar = [
        BarIngredient()
          ..name = 'Basil'
          ..inMyBar = true,
      ];
      final sub = MixologistService.bestCountingSubstitute(
        neededName: 'Mint',
        barIngredients: bar,
      );
      expect(sub, isNull);
    });
  });

  group('MixologistService.lowStockBarItems (MIX4)', () {
    test('flags in-bar bottles with old last purchase', () {
      final now = DateTime.utc(2026, 7, 30);
      final bar = [
        BarIngredient()
          ..name = 'Old Rum'
          ..inMyBar = true
          ..purchaseHistory = [
            PurchaseRecord()
              ..purchaseDate = DateTime.utc(2025, 1, 1),
          ],
        BarIngredient()
          ..name = 'Fresh Gin'
          ..inMyBar = true
          ..purchaseHistory = [
            PurchaseRecord()
              ..purchaseDate = DateTime.utc(2026, 7, 1),
          ],
        BarIngredient()
          ..name = 'Not In Bar'
          ..inMyBar = false
          ..purchaseHistory = [
            PurchaseRecord()
              ..purchaseDate = DateTime.utc(2020, 1, 1),
          ],
      ];

      final low = MixologistService.lowStockBarItems(
        barIngredients: bar,
        staleDays: 90,
        now: now,
      );

      expect(low.map((e) => e.ingredient.name), ['Old Rum']);
      expect(low.single.reason, contains('days ago'));
    });

    test('flags in-bar items never purchased after neverBoughtStaleDays', () {
      final now = DateTime.utc(2026, 7, 30);
      final bar = [
        BarIngredient()
          ..name = 'Mystery Bottle'
          ..inMyBar = true
          ..lastModified = DateTime.utc(2025, 1, 1)
          ..purchaseHistory = [],
      ];
      final low = MixologistService.lowStockBarItems(
        barIngredients: bar,
        neverBoughtStaleDays: 120,
        now: now,
      );
      expect(low, hasLength(1));
      expect(low.single.reason, contains('no purchase'));
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

  group('MixologistService.rankPantryForLeftovers / suggestDish (MIX5)', () {
    final now = DateTime.utc(2026, 7, 30);

    test('ranks expiring items above stable shelf stock', () {
      final pantry = [
        PantryIngredient()
          ..name = 'Rice'
          ..category = 'grain'
          ..inMyPantry = true
          ..lastModified = now,
        PantryIngredient()
          ..name = 'Chicken Thighs'
          ..category = 'protein'
          ..flavorProfiles = ['savory', 'rich']
          ..inMyPantry = true
          ..expiryDate = now.add(const Duration(days: 1))
          ..lastModified = now,
      ];
      final ranked = MixologistService.rankPantryForLeftovers(
        pantryIngredients: pantry,
        now: now,
      );
      expect(ranked.first.ingredient.name, 'Chicken Thighs');
      expect(ranked.first.reasons.any((r) => r.toLowerCase().contains('expir')),
          isTrue);
      expect(ranked.first.score,
          greaterThan(MixologistService.pantryPriorityScore(pantry.first, now: now)));
    });

    test('low quantity boosts leftover priority', () {
      final full = PantryIngredient()
        ..name = 'Tomatoes'
        ..category = 'vegetable'
        ..inMyPantry = true
        ..quantity = 10
        ..lastModified = now;
      final scrap = PantryIngredient()
        ..name = 'Spinach'
        ..category = 'vegetable'
        ..inMyPantry = true
        ..quantity = 1
        ..unit = 'bag'
        ..lastModified = now;
      expect(
        MixologistService.pantryPriorityScore(scrap, now: now),
        greaterThan(MixologistService.pantryPriorityScore(full, now: now)),
      );
    });

    test('suggestDish puts expiring produce on the plate and notes leftovers',
        () {
      final pantry = [
        PantryIngredient()
          ..name = 'Olive Oil'
          ..category = 'oil'
          ..inMyPantry = true
          ..lastModified = now,
        PantryIngredient()
          ..name = 'Garlic'
          ..category = 'vegetable'
          ..flavorProfiles = ['pungent', 'aromatic', 'savory']
          ..inMyPantry = true
          ..lastModified = now,
        PantryIngredient()
          ..name = 'Canned Tomatoes'
          ..category = 'tinned'
          ..flavorProfiles = ['savory', 'rich']
          ..inMyPantry = true
          ..lastModified = now,
        PantryIngredient()
          ..name = 'Zucchini'
          ..category = 'vegetable'
          ..flavorProfiles = ['fresh']
          ..inMyPantry = true
          ..expiryDate = now.add(const Duration(days: 2))
          ..lastModified = now,
      ];
      final dish = MixologistService.suggestDish(
        vibes: const ['mediterranean'],
        pantryIngredients: pantry,
        now: now,
      );
      expect(dish, isNotNull);
      expect(
        dish!.ingredients.map((i) => i.name.toLowerCase()),
        contains('zucchini'),
      );
      expect(dish.leftoverNotes, isNotEmpty);
      expect(dish.leftoverNotes.join(' ').toLowerCase(), contains('zucchini'));
      expect(dish.rationale.toLowerCase(), contains('leftover'));
    });
  });
}
