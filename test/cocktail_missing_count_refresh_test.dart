import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/cocktails/cocktails_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #131: the "N missing" banner + "Add to shopping" button on
/// CocktailRecipeDetailScreen must update live when a missing bar ingredient
/// is marked in-stock while the screen stays open — not just on a fresh
/// navigation (which re-captures widget.recipe as a new snapshot).
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

  testWidgets(
      'marking the missing ingredient in-stock updates the banner without '
      'leaving the screen', (tester) async {
    final recipe = Recipe()
      ..supabaseId = 'cocktail_1'
      ..name = 'Test Gimlet'
      ..recipeType = 'cocktail'
      ..missingIngredientCount = 1;
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('cocktail_1'),
          name: const Value('Test Gimlet'),
          recipeType: const Value('cocktail'),
          missingIngredientCount: const Value(1),
        ));
    await db.into(db.recipeIngredients).insert(RecipeIngredientsCompanion.insert(
          supabaseId: const Value('ri_1'),
          recipeSupabaseId: const Value('cocktail_1'),
          name: const Value('Gin'),
        ));
    await db.into(db.barIngredients).insert(BarIngredientsCompanion.insert(
          supabaseId: const Value('bar_gin'),
          name: const Value('Gin'),
          inMyBar: const Value(false),
        ));

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: CocktailRecipeDetailScreen(recipe: recipe)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Add 1 missing to shopping'), findsOneWidget);

    // Mark Gin in-stock the same way My Bar's swipe action does — through
    // the real repository, so syncMissingIngredientCounts() runs too.
    final barRepo = container.read(barIngredientRepositoryProvider);
    final ginRow = await (db.select(db.barIngredients)
          ..where((t) => t.supabaseId.equals('bar_gin')))
        .getSingle();
    final gin = BarIngredient()
      ..id = ginRow.id
      ..supabaseId = ginRow.supabaseId
      ..name = ginRow.name
      ..inMyBar = ginRow.inMyBar;
    await barRepo.toggleInMyBar(gin);

    await tester.pump();
    await tester.pump();

    expect(find.text('Add 1 missing to shopping'), findsNothing,
        reason: 'the detail screen was never re-navigated to, so this must '
            'come from a live watch, not the widget.recipe snapshot (#131)');
  });
}
