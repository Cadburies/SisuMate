import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/chef/chef_screen.dart';
import 'package:sisu_mate/ui/cocktails/cocktails_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #186: a recipe ingredient's swipe action used to show a completely
/// different label ("Track", creating a brand-new catalog row) versus "In
/// Bar"/"In Pantry" (toggling an existing row) purely based on the accident
/// of whether that exact ingredient name had ever been seeded — e.g. "flour"
/// (seeded) vs "vinegar" (not). Regression: the label/mechanism must be
/// identical regardless of prior seed state, for both Bar and Pantry.
///
/// flutter_slidable only builds an [ActionPane]'s [SlidableAction] children
/// once the pane is actually revealed — [Slidable.of] (looked up from a
/// descendant of the tile, not the Slidable itself) + `openEndActionPane()`
/// triggers that without simulating a real drag gesture.
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

  Future<void> openEndPane(WidgetTester tester, String ingredientName) async {
    final ctx = tester.element(find.text(ingredientName));
    Slidable.of(ctx)!.openEndActionPane();
    await tester.pumpAndSettle();
  }

  group('Bar (Cocktails)', () {
    Future<ProviderContainer> pump(WidgetTester tester) async {
      await db.into(db.recipes).insert(RecipesCompanion.insert(
            supabaseId: const Value('cocktail_1'),
            name: const Value('Test Cocktail'),
            recipeType: const Value('cocktail'),
          ));
      await db.into(db.recipeIngredients).insert(RecipeIngredientsCompanion.insert(
            supabaseId: const Value('ri_vinegar'),
            recipeSupabaseId: const Value('cocktail_1'),
            name: const Value('Vinegar'),
          ));
      await db.into(db.recipeIngredients).insert(RecipeIngredientsCompanion.insert(
            supabaseId: const Value('ri_flour'),
            recipeSupabaseId: const Value('cocktail_1'),
            name: const Value('Flour'),
          ));
      // "Flour" already has a seeded (but unstocked) catalog row; "Vinegar"
      // has never been added at all.
      await db.into(db.barIngredients).insert(BarIngredientsCompanion.insert(
            supabaseId: const Value('bar_flour'),
            name: const Value('Flour'),
            inMyBar: const Value(false),
          ));

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        isProProvider.overrideWith((ref) => Stream.value(true)),
      ]);
      addTearDown(container.dispose);
      final recipe = Recipe()
        ..supabaseId = 'cocktail_1'
        ..name = 'Test Cocktail'
        ..recipeType = 'cocktail';
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: CocktailRecipeDetailScreen(recipe: recipe)),
      ));
      await tester.pump();
      await tester.pump();
      return container;
    }

    testWidgets(
        'never-seeded ("Vinegar") and seeded-unstocked ("Flour") ingredients '
        'show the identical "In Bar" action — no separate "Track"',
        (tester) async {
      await pump(tester);
      await openEndPane(tester, 'Vinegar');
      await openEndPane(tester, 'Flour');

      expect(find.text('Track'), findsNothing,
          reason: '#186: no separate create/track action should exist');
      expect(
        find.byWidgetPredicate(
            (w) => w is SlidableAction && w.label == 'In Bar'),
        findsNWidgets(2),
        reason: 'both the never-seeded and seeded-unstocked ingredient use '
            'the same action',
      );
    });

    testWidgets('tapping "In Bar" on a never-seeded ingredient creates it '
        'and marks it in-bar', (tester) async {
      await pump(tester);
      await openEndPane(tester, 'Vinegar');

      final action = tester.widget<SlidableAction>(find.byWidgetPredicate(
          (w) => w is SlidableAction && w.label == 'In Bar'));
      action.onPressed!(tester.element(find.text('Vinegar')));
      await tester.pump();
      await tester.pump();

      final row = await (db.select(db.barIngredients)
            ..where((t) => t.name.equals('Vinegar')))
          .getSingleOrNull();
      expect(row, isNotNull,
          reason: 'a catalog row must be created transparently, same as '
              'toggling an existing one');
      expect(row!.inMyBar, isTrue);
    });
  });

  group('Pantry (Chef)', () {
    Future<ProviderContainer> pump(WidgetTester tester) async {
      await db.into(db.recipes).insert(RecipesCompanion.insert(
            supabaseId: const Value('menu_1'),
            name: const Value('Test Menu'),
            recipeType: const Value('menu'),
          ));
      await db.into(db.recipeIngredients).insert(RecipeIngredientsCompanion.insert(
            supabaseId: const Value('ri_vinegar'),
            recipeSupabaseId: const Value('menu_1'),
            name: const Value('Vinegar'),
          ));
      await db.into(db.recipeIngredients).insert(RecipeIngredientsCompanion.insert(
            supabaseId: const Value('ri_flour'),
            recipeSupabaseId: const Value('menu_1'),
            name: const Value('Flour'),
          ));
      await db.into(db.pantryIngredients).insert(PantryIngredientsCompanion.insert(
            supabaseId: const Value('pantry_flour'),
            name: const Value('Flour'),
            inMyPantry: const Value(false),
          ));

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        isProProvider.overrideWith((ref) => Stream.value(true)),
      ]);
      addTearDown(container.dispose);
      final recipe = Recipe()
        ..supabaseId = 'menu_1'
        ..name = 'Test Menu'
        ..recipeType = 'menu';
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: ChefRecipeDetailScreen(recipe: recipe)),
      ));
      await tester.pump();
      await tester.pump();
      return container;
    }

    testWidgets(
        'never-seeded ("Vinegar") and seeded-unstocked ("Flour") ingredients '
        'show the identical "In Pantry" action — no separate "Track"',
        (tester) async {
      await pump(tester);
      await openEndPane(tester, 'Vinegar');
      await openEndPane(tester, 'Flour');

      expect(find.text('Track'), findsNothing,
          reason: '#186: no separate create/track action should exist');
      expect(
        find.byWidgetPredicate(
            (w) => w is SlidableAction && w.label == 'In Pantry'),
        findsNWidgets(2),
      );
    });

    testWidgets('tapping "In Pantry" on a never-seeded ingredient creates it '
        'and marks it in-pantry', (tester) async {
      await pump(tester);
      await openEndPane(tester, 'Vinegar');

      final action = tester.widget<SlidableAction>(find.byWidgetPredicate(
          (w) => w is SlidableAction && w.label == 'In Pantry'));
      action.onPressed!(tester.element(find.text('Vinegar')));
      await tester.pump();
      await tester.pump();

      final row = await (db.select(db.pantryIngredients)
            ..where((t) => t.name.equals('Vinegar')))
          .getSingleOrNull();
      expect(row, isNotNull);
      expect(row!.inMyPantry, isTrue);
    });
  });
}
