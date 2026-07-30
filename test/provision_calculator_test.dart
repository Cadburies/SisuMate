import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/provision_calculator.dart';

RecipeIngredient _ingredient(
  String name, {
  double? quantity,
  String? unit,
  bool isGarnish = false,
}) {
  return RecipeIngredient()
    ..name = name
    ..quantity = quantity
    ..unit = unit
    ..isGarnish = isGarnish;
}

PantryIngredient _pantryItem(
  String name, {
  required String category,
  List<String> allergenTags = const [],
}) {
  return PantryIngredient()
    ..name = name
    ..category = category
    ..allergenTags = allergenTags;
}

MealPlanSlot _slot(int dayOffset, String mealType, String recipeId, String recipeName) {
  return MealPlanSlot()
    ..dayOffset = dayOffset
    ..mealType = mealType
    ..recipeSupabaseId = recipeId
    ..recipeName = recipeName;
}

void main() {
  group('ProvisionCalculator', () {
    test('scales consolidated (non-protein) ingredients by guest count and sums across meals', () {
      final plan = MealPlan()
        ..guestCount = 4
        ..slots = [
          _slot(0, 'dinner', 'r1', 'Roast Veg'),
          _slot(1, 'lunch', 'r2', 'Garlic Bread'),
        ];
      final ingredientsByRecipe = {
        'r1': [_ingredient('Garlic', quantity: 1, unit: 'cloves')],
        'r2': [_ingredient('Garlic', quantity: 1.75, unit: 'cloves')],
      };
      final pantry = [_pantryItem('Garlic', category: 'vegetable')];

      final result = ProvisionCalculator.compute(
        plan: plan,
        ingredientsByRecipe: ingredientsByRecipe,
        pantry: pantry,
        profiles: const [],
      );

      expect(result.consolidatedItems, hasLength(1));
      expect(result.consolidatedItems.first.name, 'Garlic');
      // (1 * 4) + (1.75 * 4) = 4 + 7 = 11
      expect(result.consolidatedItems.first.quantity, 11);
      expect(result.consolidatedItems.first.formatted, 'Garlic: 11 cloves');
      expect(result.portionedItems, isEmpty);
    });

    test('keeps protein-category ingredients as separate portioned line items', () {
      final plan = MealPlan()
        ..startDate = DateTime(2026, 6, 29) // a Monday
        ..guestCount = 2
        ..slots = [_slot(3, 'dinner', 'r1', 'Grilled Steak')];
      final ingredientsByRecipe = {
        'r1': [_ingredient('Sirloin Steak', quantity: 1, unit: null)],
      };
      final pantry = [_pantryItem('Sirloin Steak', category: 'protein')];

      final result = ProvisionCalculator.compute(
        plan: plan,
        ingredientsByRecipe: ingredientsByRecipe,
        pantry: pantry,
        profiles: const [],
      );

      expect(result.consolidatedItems, isEmpty);
      expect(result.portionedItems, hasLength(1));
      expect(result.portionedItems.first.name, 'Sirloin Steak');
      expect(result.portionedItems.first.count, 1);
      expect(result.portionedItems.first.quantities, [2]);
      expect(result.portionedItems.first.notes, ['Thu Dinner']);
      expect(result.portionedItems.first.formatted,
          'Sirloin Steak × 2 (Thu Dinner)');
    });

    test('groups repeated same-quantity portioned items with a count multiplier (CF26)', () {
      final plan = MealPlan()
        ..startDate = DateTime(2026, 6, 29) // a Monday
        ..guestCount = 4
        ..slots = [
          _slot(0, 'lunch', 'r1', 'Mediterranean Seafood Feast'),
          _slot(2, 'dinner', 'r1', 'Mediterranean Seafood Feast'),
        ];
      final ingredientsByRecipe = {
        'r1': [_ingredient('Fresh Sea Bass', quantity: 6, unit: 'fillets')],
      };

      final result = ProvisionCalculator.compute(
        plan: plan,
        ingredientsByRecipe: ingredientsByRecipe,
        pantry: const [],
        profiles: const [],
      );

      expect(result.portionedItems, hasLength(1));
      final group = result.portionedItems.first;
      expect(group.name, 'Fresh Sea Bass');
      expect(group.count, 2);
      expect(group.quantities, [24, 24]); // 6 * 4 guests, twice
      expect(group.notes, ['Mon Lunch', 'Wed Dinner']);
      expect(group.formatted,
          'Fresh Sea Bass — 2 × 24 fillets (Mon Lunch, Wed Dinner)');
    });

    test('groups repeated portioned items with differing quantities as distinct entries (CF26)', () {
      final plan = MealPlan()
        ..startDate = DateTime(2026, 6, 29) // a Monday
        ..guestCount = 1
        ..slots = [
          _slot(0, 'lunch', 'r1', 'Small Batch'),
          _slot(1, 'dinner', 'r2', 'Big Batch'),
        ];
      final ingredientsByRecipe = {
        'r1': [_ingredient('Fresh Sea Bass', quantity: 12, unit: 'fillets')],
        'r2': [_ingredient('Fresh Sea Bass', quantity: 24, unit: 'fillets')],
      };

      final result = ProvisionCalculator.compute(
        plan: plan,
        ingredientsByRecipe: ingredientsByRecipe,
        pantry: const [],
        profiles: const [],
      );

      expect(result.portionedItems, hasLength(1));
      final group = result.portionedItems.first;
      expect(group.count, 2);
      expect(group.quantities, [12, 24]);
      expect(group.formatted,
          'Fresh Sea Bass — 12 fillets (Mon Lunch), 24 fillets (Tue Dinner)');
    });

    test('computes the day/meal label from the plan\'s own start date, not a fixed Monday assumption (CF25)', () {
      final plan = MealPlan()
        ..startDate = DateTime(2026, 7, 8) // a Wednesday
        ..guestCount = 2
        ..slots = [_slot(2, 'dinner', 'r1', 'Some Dish')]; // Wed + 2 = Friday
      final ingredientsByRecipe = {
        'r1': [_ingredient('Sirloin Steak', quantity: 1, unit: null)],
      };

      final result = ProvisionCalculator.compute(
        plan: plan,
        ingredientsByRecipe: ingredientsByRecipe,
        pantry: const [],
        profiles: const [],
      );

      expect(result.portionedItems.first.notes, ['Fri Dinner']);
    });

    test('classifies fresh seafood/meat as protein by name even with no pantry match', () {
      // Fresh proteins are typically not stocked PantryIngredients (the pantry
      // seed only tracks shelf-stable goods), so this must not depend on a
      // pantry match to classify correctly.
      final plan = MealPlan()
        ..guestCount = 4
        ..slots = [_slot(0, 'dinner', 'r1', 'Mediterranean Seafood Feast')];
      final ingredientsByRecipe = {
        'r1': [
          _ingredient('Fresh Sea Bass', quantity: 6, unit: 'fillets'),
          _ingredient('Mussels', quantity: 2, unit: 'lbs'),
          _ingredient('Cherry Tomatoes', quantity: 1, unit: 'pint'),
        ],
      };

      final result = ProvisionCalculator.compute(
        plan: plan,
        ingredientsByRecipe: ingredientsByRecipe,
        pantry: const [], // no pantry entries at all
        profiles: const [],
      );

      final portionedNames = result.portionedItems.map((r) => r.name).toSet();
      expect(portionedNames, {'Fresh Sea Bass', 'Mussels'});
      expect(result.consolidatedItems.map((r) => r.name), ['Cherry Tomatoes']);
    });

    test('flags an allergen conflict between a recipe and a selected guest profile', () {
      final profile = GuestProfile()
        ..id = 1
        ..name = 'Alice'
        ..allergenRestrictions = ['nuts'];
      final plan = MealPlan()
        ..guestCount = 2
        ..guestProfileIds = [1]
        ..slots = [_slot(0, 'lunch', 'r1', 'Nutty Granola')];
      final ingredientsByRecipe = {
        'r1': [_ingredient('Almonds', quantity: 1, unit: 'cup')],
      };
      final pantry = [
        _pantryItem('Almonds', category: 'nut', allergenTags: ['nuts']),
      ];

      final result = ProvisionCalculator.compute(
        plan: plan,
        ingredientsByRecipe: ingredientsByRecipe,
        pantry: pantry,
        profiles: [profile],
      );

      expect(result.allergenWarnings, hasLength(1));
      expect(result.allergenWarnings.first, contains('Nutty Granola'));
      expect(result.allergenWarnings.first, contains('nuts'));
    });

    test('does not warn when the guest profile is not selected on the plan', () {
      final profile = GuestProfile()
        ..id = 1
        ..name = 'Alice'
        ..allergenRestrictions = ['nuts'];
      final plan = MealPlan()
        ..guestCount = 2
        ..guestProfileIds = [] // Alice not selected for this plan
        ..slots = [_slot(0, 'lunch', 'r1', 'Nutty Granola')];
      final ingredientsByRecipe = {
        'r1': [_ingredient('Almonds', quantity: 1, unit: 'cup')],
      };
      final pantry = [
        _pantryItem('Almonds', category: 'nut', allergenTags: ['nuts']),
      ];

      final result = ProvisionCalculator.compute(
        plan: plan,
        ingredientsByRecipe: ingredientsByRecipe,
        pantry: pantry,
        profiles: [profile],
      );

      expect(result.allergenWarnings, isEmpty);
    });

    test('ignores orphaned slots whose meal type is no longer valid for their day', () {
      // e.g. a slot saved before flexible trip lengths existed, or a day
      // dropped by shortening the trip — must not silently inflate totals.
      final plan = MealPlan()
        ..startDate = DateTime(2026, 6, 29) // a Monday
        ..numberOfDays = 7
        ..guestCount = 4
        ..slots = [
          _slot(0, 'breakfast', 'r1', 'Mediterranean Seafood Feast'), // invalid: day 0 has no breakfast
          _slot(1, 'lunch', 'r1', 'Mediterranean Seafood Feast'), // valid
        ];
      final ingredientsByRecipe = {
        'r1': [_ingredient('Fresh Sea Bass', quantity: 6, unit: 'fillets')],
      };

      final result = ProvisionCalculator.compute(
        plan: plan,
        ingredientsByRecipe: ingredientsByRecipe,
        pantry: const [],
        profiles: const [],
      );

      expect(result.portionedItems, hasLength(1));
      expect(result.portionedItems.first.count, 1);
      expect(result.portionedItems.first.notes, ['Tue Lunch']);
    });

    test('ignores slots with no recipe assigned', () {
      final plan = MealPlan()
        ..guestCount = 4
        ..slots = [MealPlanSlot()..dayOffset = 0..mealType = 'lunch'];

      final result = ProvisionCalculator.compute(
        plan: plan,
        ingredientsByRecipe: const {},
        pantry: const [],
        profiles: const [],
      );

      expect(result.consolidatedItems, isEmpty);
      expect(result.portionedItems, isEmpty);
      expect(result.allergenWarnings, isEmpty);
    });
  });
}
