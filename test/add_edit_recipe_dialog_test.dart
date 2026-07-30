import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/cocktails/cocktails_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  Recipe? existingRecipe,
  List<RecipeIngredient> existingIngredients = const [],
  required void Function(Recipe, List<RecipeIngredient>, List<RecipeIngredient>) onSave,
}) {
  // Tall surface so tag comboboxes + ingredients list fit without clipping.
  addTearDown(tester.view.resetPhysicalSize);
  tester.view.physicalSize = const Size(1080, 2800);
  tester.view.devicePixelRatio = 1.0;

  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AddEditRecipeDialog(
        recipeType: RecipeType.menu,
        existingRecipe: existingRecipe,
        existingIngredients: existingIngredients,
        onSave: onSave,
      ),
    ),
  ));
}

void main() {
  group('AddEditRecipeDialog ingredient persistence (F20)', () {
    testWidgets('a manually-added ingredient is included in onSave, not dropped',
        (tester) async {
      Recipe? savedRecipe;
      List<RecipeIngredient>? savedIngredients;

      await _pump(tester, onSave: (recipe, ingredients, removed) {
        savedRecipe = recipe;
        savedIngredients = ingredients;
      });

      await tester.enterText(find.widgetWithText(TextFormField, 'Recipe Name'), 'Test Dish');
      await tester.ensureVisible(find.byTooltip('Add ingredient'));
      await tester.tap(find.byTooltip('Add ingredient'));
      await tester.pump();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Ingredient Name'), 'Fresh Basil');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(savedRecipe, isNotNull);
      expect(savedIngredients, hasLength(1));
      expect(savedIngredients!.single.name, 'Fresh Basil');
      // The ingredient must be linked to the actual saved recipe, not the
      // 'temp' placeholder id it's created with before a name exists.
      expect(savedIngredients!.single.recipeSupabaseId, savedRecipe!.supabaseId);
      expect(savedIngredients!.single.sortOrder, 0);
    });

    testWidgets('removing a pre-existing ingredient reports it in removedIngredients',
        (tester) async {
      final recipe = Recipe()
        ..supabaseId = 'recipe_1'
        ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
        ..name = 'Existing Dish'
        ..recipeType = 'menu'
        ..isBundled = false;
      final stale = RecipeIngredient()
        ..supabaseId = 'ing_remove'
        ..recipeSupabaseId = 'recipe_1'
        ..name = 'Stale Ingredient'
        ..sortOrder = 0;

      List<RecipeIngredient>? savedIngredients;
      List<RecipeIngredient>? removedIngredients;

      await _pump(
        tester,
        existingRecipe: recipe,
        existingIngredients: [stale],
        onSave: (r, ingredients, removed) {
          savedIngredients = ingredients;
          removedIngredients = removed;
        },
      );

      await tester.ensureVisible(find.byIcon(Icons.delete));
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(savedIngredients, isEmpty);
      expect(removedIngredients, hasLength(1));
      expect(removedIngredients!.single.supabaseId, 'ing_remove');
    });

    testWidgets('does not call onSave when the recipe name is empty', (tester) async {
      var saveCalled = false;
      await _pump(tester, onSave: (recipe, ingredients, removed) => saveCalled = true);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saveCalled, isFalse);
    });
  });

  group('AddEditRecipeDialog cooking method dropdown (CB1)', () {
    testWidgets(
        'editing a recipe whose stored cookingMethod is "Oven" does not crash — '
        '_methodOptions previously listed "Bake" instead, so an existing '
        '"Oven" recipe (e.g. seeded Traditional Bobotie) had zero matching '
        'dropdown items instead of exactly one, tripping the '
        'DropdownButtonFormField assertion', (tester) async {
      final recipe = Recipe()
        ..supabaseId = 'recipe_oven'
        ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
        ..name = 'Traditional Bobotie'
        ..recipeType = 'menu'
        ..cookingMethod = 'Oven'
        ..isBundled = false;

      await _pump(
        tester,
        existingRecipe: recipe,
        onSave: (r, ingredients, removed) {},
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Oven'), findsOneWidget);
    });

    testWidgets(
        'editing a recipe whose stored cookingMethod is "Raw / No-cook" '
        '(the exact seed-data spelling, with spaces) does not crash — '
        '_methodOptions previously had "Raw/No-cook" with no spaces',
        (tester) async {
      final recipe = Recipe()
        ..supabaseId = 'recipe_raw'
        ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
        ..name = 'Ceviche'
        ..recipeType = 'menu'
        ..cookingMethod = 'Raw / No-cook'
        ..isBundled = false;

      await _pump(
        tester,
        existingRecipe: recipe,
        onSave: (r, ingredients, removed) {},
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Raw / No-cook'), findsOneWidget);
    });
  });

  group('AddEditRecipeDialog ingredients list viewport (F21)', () {
    testWidgets('a 2nd ingredient is visible without scrolling', (tester) async {
      final recipe = Recipe()
        ..supabaseId = 'recipe_1'
        ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
        ..name = 'Existing Dish'
        ..recipeType = 'menu'
        ..isBundled = false;
      final first = RecipeIngredient()
        ..supabaseId = 'ing_1'
        ..recipeSupabaseId = 'recipe_1'
        ..name = 'Olive Oil'
        ..sortOrder = 0;
      final second = RecipeIngredient()
        ..supabaseId = 'ing_2'
        ..recipeSupabaseId = 'recipe_1'
        ..name = 'Fresh Basil'
        ..sortOrder = 1;

      await _pump(
        tester,
        existingRecipe: recipe,
        existingIngredients: [first, second],
        onSave: (r, ingredients, removed) {},
      );

      // Previously the ingredients ListView's viewport was only ~80px tall
      // (F21), so a 2nd ingredient required scrolling to even discover it
      // existed. No drag/scroll call here — both must render on first pump.
      expect(find.text('Olive Oil'), findsOneWidget);
      expect(find.text('Fresh Basil'), findsOneWidget);
    });
  });
}
