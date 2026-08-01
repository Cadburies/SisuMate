import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/smart_shopping_service.dart';

ShoppingItem _item({
  required String name,
  String origin = 'galley',
  bool isBought = false,
  bool isHidden = false,
  int quantity = 1,
  double? price,
}) {
  return ShoppingItem()
    ..name = name
    ..origin = origin
    ..isBought = isBought
    ..isHidden = isHidden
    ..quantity = quantity
    ..lastPurchasePrice = price
    ..supabaseId = 's_$name';
}

void main() {
  group('SmartShoppingService.rankForPassage (BAI2)', () {
    test('skips hidden; bought score 0 at bottom', () {
      final ranked = SmartShoppingService.rankForPassage(
        items: [
          _item(name: 'Hidden', isHidden: true),
          _item(name: 'Bought milk', isBought: true),
          _item(name: 'Open bread'),
        ],
        inSeasonNames: const [],
      );
      expect(ranked.map((r) => r.item.name), ['Open bread', 'Bought milk']);
      expect(ranked.last.score, 0);
    });

    test('meal-plan ingredients rank above random lines', () {
      final plan = MealPlan()
        ..numberOfDays = 3
        ..slots = [
          MealPlanSlot()
            ..dayOffset = 0
            ..mealType = 'dinner'
            ..recipeSupabaseId = 'r1'
            ..recipeName = 'Pasta',
        ];
      final ranked = SmartShoppingService.rankForPassage(
        items: [
          _item(name: 'Basil'),
          _item(name: 'Duct tape', origin: 'spares'),
        ],
        mealPlans: [plan],
        ingredientsByRecipe: {
          'r1': [
            RecipeIngredient()..name = 'Basil',
          ],
        },
        inSeasonNames: const [],
      );
      expect(ranked.first.item.name, 'Basil');
      expect(ranked.first.reasons, contains('On meal plan'));
      expect(ranked.first.score, greaterThan(ranked.last.score));
    });

    test('a meal plan that has already ended no longer boosts its ingredients', () {
      final finishedPlan = MealPlan()
        ..startDate = DateTime.utc(2026, 1, 1)
        ..numberOfDays = 3 // ends 2026-01-04, well before `now` below
        ..slots = [
          MealPlanSlot()
            ..dayOffset = 0
            ..mealType = 'dinner'
            ..recipeSupabaseId = 'r1'
            ..recipeName = 'Pasta',
        ];
      final ranked = SmartShoppingService.rankForPassage(
        items: [
          _item(name: 'Basil'),
          _item(name: 'Duct tape', origin: 'spares'),
        ],
        mealPlans: [finishedPlan],
        ingredientsByRecipe: {
          'r1': [RecipeIngredient()..name = 'Basil'],
        },
        inSeasonNames: const [],
        now: DateTime.utc(2026, 7, 30),
      );
      final basil = ranked.firstWhere((r) => r.item.name == 'Basil');
      expect(basil.reasons, isNot(contains('On meal plan')),
          reason: 'the plan needing basil ended months ago — nothing left '
              'to provision for it');
    });

    test('not-in-pantry and seasonal boost score', () {
      final pantry = [
        PantryIngredient()
          ..name = 'Tomatoes'
          ..inMyPantry = false,
      ];
      final ranked = SmartShoppingService.rankForPassage(
        items: [
          _item(name: 'Tomatoes'),
          _item(name: 'Paper towels', origin: 'other'),
        ],
        pantry: pantry,
        inSeasonNames: const ['tomatoes', 'sweetcorn'],
      );
      expect(ranked.first.item.name, 'Tomatoes');
      expect(ranked.first.reasons, contains('Not in pantry'));
      expect(ranked.first.reasons, contains('In season now'));
    });

    test('engine/spares origin gets boat-critical boost', () {
      final ranked = SmartShoppingService.rankForPassage(
        items: [
          _item(name: 'Impeller', origin: 'engine', price: 40),
          _item(name: 'Napkins', origin: 'other'),
        ],
        inSeasonNames: const [],
      );
      expect(ranked.first.item.name, 'Impeller');
      expect(ranked.first.reasons.any((r) => r.contains('Boat-critical')),
          isTrue);
    });

    test('tie-break prefers higher known price', () {
      final ranked = SmartShoppingService.rankForPassage(
        items: [
          _item(name: 'Cheap filter', origin: 'engine', price: 5),
          _item(name: 'Pricey filter', origin: 'engine', price: 90),
        ],
        inSeasonNames: const [],
      );
      // Same origin boost + price-on-file; price tie-break puts pricey first.
      expect(ranked.first.item.name, 'Pricey filter');
    });
  });
}
