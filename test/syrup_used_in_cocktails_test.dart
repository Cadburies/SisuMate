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

/// #133: a house mix's own detail screen should show "used in N cocktails"
/// the same way bar ingredients do (`ingredient_detail_screen.dart`), reusing
/// `cocktailRecipesForIngredientProvider` — which already matches by plain
/// `RecipeIngredient.name` regardless of source type, so no provider change
/// was needed, only the UI section on `CocktailRecipeDetailScreen`.
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

  Future<void> pumpSyrup(WidgetTester tester, Recipe syrup) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: CocktailRecipeDetailScreen(recipe: syrup)),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('house mix detail screen lists the cocktails that use it',
      (tester) async {
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('syrup_orgeat'),
          name: const Value('Orgeat'),
          recipeType: const Value('syrup'),
        ));
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('cocktail_mai_tai'),
          name: const Value('Mai Tai'),
          recipeType: const Value('cocktail'),
        ));
    await db.into(db.recipeIngredients).insert(RecipeIngredientsCompanion.insert(
          supabaseId: const Value('ri_1'),
          recipeSupabaseId: const Value('cocktail_mai_tai'),
          name: const Value('Orgeat'),
        ));

    final syrup = Recipe()
      ..supabaseId = 'syrup_orgeat'
      ..name = 'Orgeat'
      ..recipeType = 'syrup';

    await pumpSyrup(tester, syrup);

    expect(find.text('Used in cocktails'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Mai Tai'), findsOneWidget);
    expect(find.text('Not used in any cocktail'), findsNothing);
  });

  testWidgets('house mix with no matching cocktail shows the empty state',
      (tester) async {
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('syrup_gardenia_mix'),
          name: const Value('Gardenia Mix'),
          recipeType: const Value('syrup'),
        ));

    final syrup = Recipe()
      ..supabaseId = 'syrup_gardenia_mix'
      ..name = 'Gardenia Mix'
      ..recipeType = 'syrup';

    await pumpSyrup(tester, syrup);

    expect(find.text('Not used in any cocktail'), findsOneWidget);
  });

  testWidgets('cocktail detail screen (not a syrup) never shows the section',
      (tester) async {
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('cocktail_mai_tai'),
          name: const Value('Mai Tai'),
          recipeType: const Value('cocktail'),
        ));

    final cocktail = Recipe()
      ..supabaseId = 'cocktail_mai_tai'
      ..name = 'Mai Tai'
      ..recipeType = 'cocktail';

    await pumpSyrup(tester, cocktail);

    expect(find.text('Used in cocktails'), findsNothing);
  });
}
