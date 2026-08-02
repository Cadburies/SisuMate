import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/chef/chef_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #157: Chef menu detail had no bulk "add missing to shopping" button
/// (Cocktails has one), and nothing recomputed `missingIngredientCount` for
/// menu recipes on screen load the way Cocktails does for its tab.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<ProviderContainer> seedMenuWithMissingIngredient() async {
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('menu_1'),
          name: const Value('Test Menu'),
          recipeType: const Value('menu'),
        ));
    await db.into(db.recipeIngredients).insert(RecipeIngredientsCompanion.insert(
          supabaseId: const Value('ri_1'),
          recipeSupabaseId: const Value('menu_1'),
          name: const Value('Saffron'),
        ));
    await db.into(db.pantryIngredients).insert(PantryIngredientsCompanion.insert(
          supabaseId: const Value('pantry_saffron'),
          name: const Value('Saffron'),
          inMyPantry: const Value(false),
        ));

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  testWidgets(
      '"Add N missing to shopping" button appears for a menu with a missing '
      'pantry ingredient and adds it', (tester) async {
    final container = await seedMenuWithMissingIngredient();
    final recipe = Recipe()
      ..supabaseId = 'menu_1'
      ..name = 'Test Menu'
      ..recipeType = 'menu';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: ChefRecipeDetailScreen(recipe: recipe)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Add 1 missing to shopping'), findsOneWidget);

    await tester.tap(find.text('Add 1 missing to shopping'));
    await tester.pump();
    await tester.pump();

    final shoppingRows = await db.select(db.shoppingItems).get();
    expect(shoppingRows.any((r) => r.name == 'Saffron'), isTrue,
        reason: 'bulk add must diff against My Pantry (not My Bar) and '
            'queue the missing ingredient (#157)');
  });

  testWidgets(
      'button disappears once the pantry ingredient is marked in-stock '
      'without leaving the screen', (tester) async {
    final container = await seedMenuWithMissingIngredient();
    final recipe = Recipe()
      ..supabaseId = 'menu_1'
      ..name = 'Test Menu'
      ..recipeType = 'menu';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: ChefRecipeDetailScreen(recipe: recipe)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Add 1 missing to shopping'), findsOneWidget);

    final pantryRepo = container.read(pantryIngredientRepositoryProvider);
    final row = await (db.select(db.pantryIngredients)
          ..where((t) => t.supabaseId.equals('pantry_saffron')))
        .getSingle();
    final saffron = PantryIngredient()
      ..id = row.id
      ..supabaseId = row.supabaseId
      ..name = row.name
      ..inMyPantry = row.inMyPantry;
    await pantryRepo.toggleInMyPantry(saffron);

    await tester.pump();
    await tester.pump();

    expect(find.text('Add 1 missing to shopping'), findsNothing);
  });

  testWidgets(
      'opening the Chef screen recomputes missingIngredientCount for menu '
      'recipes (seeded default of 0)', (tester) async {
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('menu_2'),
          name: const Value('Another Menu'),
          recipeType: const Value('menu'),
          missingIngredientCount: const Value(0),
        ));
    await db.into(db.recipeIngredients).insert(RecipeIngredientsCompanion.insert(
          supabaseId: const Value('ri_2'),
          recipeSupabaseId: const Value('menu_2'),
          name: const Value('Truffle Oil'),
        ));

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChefScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final updated = await (db.select(db.recipes)
          ..where((t) => t.supabaseId.equals('menu_2')))
        .getSingle();
    expect(updated.missingIngredientCount, 1,
        reason: 'Chef screen load must recompute missingIngredientCount '
            'against My Pantry the same way Cocktails does on its tab (#157)');
  });
}
