import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/recipe_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

// Recipes + ingredients on Drift (S1). Local-only (not synced).
void main() {
  late AppDatabase db;
  late RecipeRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  group('RecipeRepositoryImpl CRUD — Recipe', () {
    test('Create: addRecipe persists a new recipe', () async {
      await repo.addRecipe(Recipe()
        ..supabaseId = 'recipe_1'
        ..boatSupabaseId = 'boat_1'
        ..name = 'Mai Tai'
        ..recipeType = 'cocktail');

      final all = await repo.watchRecipes().first;
      expect(all, hasLength(1));
      expect(all.single.name, 'Mai Tai');
    });

    test('Read: watchRecipes emits every persisted recipe', () async {
      await repo.addRecipe(Recipe()
        ..supabaseId = 'recipe_1'
        ..boatSupabaseId = 'boat_1'
        ..name = 'Mai Tai'
        ..recipeType = 'cocktail');
      await repo.addRecipe(Recipe()
        ..supabaseId = 'recipe_2'
        ..boatSupabaseId = 'boat_1'
        ..name = 'Pasta Bake'
        ..recipeType = 'menu');

      final recipes = await repo.watchRecipes().first;
      expect(recipes, hasLength(2));
    });

    test('Update: updateRecipe persists field changes', () async {
      final recipe = Recipe()
        ..supabaseId = 'recipe_1'
        ..boatSupabaseId = 'boat_1'
        ..name = 'Draft Name'
        ..recipeType = 'menu';
      await repo.addRecipe(recipe);

      recipe.name = 'Final Name';
      await repo.updateRecipe(recipe);

      final all = await repo.watchRecipes().first;
      expect(all.single.name, 'Final Name');
    });

    test('Delete: deleteRecipe removes it from the database', () async {
      final recipe = Recipe()
        ..supabaseId = 'recipe_1'
        ..boatSupabaseId = 'boat_1'
        ..name = 'To remove'
        ..recipeType = 'menu';
      await repo.addRecipe(recipe);

      await repo.deleteRecipe(recipe);

      final all = await repo.watchRecipes().first;
      expect(all, isEmpty);
    });

    test('tastingLog round-trips through the JSON column', () async {
      final recipe = Recipe()
        ..supabaseId = 'recipe_1'
        ..name = 'Reviewed'
        ..recipeType = 'cocktail'
        ..tastingLog = [
          TastingRecord()
            ..rating = 5
            ..notes = 'Excellent'
            ..location = 'Marina bar'
        ];
      await repo.addRecipe(recipe);

      final saved = (await repo.watchRecipes().first).single;
      expect(saved.tastingLog, hasLength(1));
      expect(saved.tastingLog.single.rating, 5);
      expect(saved.tastingLog.single.notes, 'Excellent');
    });
  });

  group('RecipeRepositoryImpl CRUD — RecipeIngredient', () {
    test('Create: addIngredient persists a new ingredient', () async {
      await repo.addIngredient(RecipeIngredient()
        ..supabaseId = 'ing_1'
        ..recipeSupabaseId = 'recipe_1'
        ..name = 'White Rum');

      final all = await repo.getIngredientsOnce('recipe_1');
      expect(all, hasLength(1));
      expect(all.single.name, 'White Rum');
    });

    test('Read: getIngredientsOnce filters by recipe and sorts by sortOrder',
        () async {
      await repo.addIngredient(RecipeIngredient()
        ..supabaseId = 'ing_2'
        ..recipeSupabaseId = 'recipe_1'
        ..name = 'Second'
        ..sortOrder = 1);
      await repo.addIngredient(RecipeIngredient()
        ..supabaseId = 'ing_1'
        ..recipeSupabaseId = 'recipe_1'
        ..name = 'First'
        ..sortOrder = 0);
      await repo.addIngredient(RecipeIngredient()
        ..supabaseId = 'ing_other'
        ..recipeSupabaseId = 'recipe_2'
        ..name = 'Other recipe');

      final ingredients = await repo.getIngredientsOnce('recipe_1');
      expect(ingredients.map((i) => i.name), ['First', 'Second']);
    });

    test('Update: updateIngredient persists field changes', () async {
      final ingredient = RecipeIngredient()
        ..supabaseId = 'ing_1'
        ..recipeSupabaseId = 'recipe_1'
        ..name = 'White Rum'
        ..quantity = 1;
      await repo.addIngredient(ingredient);

      ingredient.quantity = 2;
      await repo.updateIngredient(ingredient);

      final all = await repo.getIngredientsOnce('recipe_1');
      expect(all.single.quantity, 2);
    });

    test('Delete: deleteIngredient removes it from the database', () async {
      final ingredient = RecipeIngredient()
        ..supabaseId = 'ing_1'
        ..recipeSupabaseId = 'recipe_1'
        ..name = 'To remove';
      await repo.addIngredient(ingredient);

      await repo.deleteIngredient(ingredient);

      final all = await repo.getIngredientsOnce('recipe_1');
      expect(all, isEmpty);
    });
  });

  group('RecipeRepositoryImpl.syncMissingIngredientCounts', () {
    test('counts non-stocked, non-garnish, non-optional ingredients', () async {
      await repo.addRecipe(Recipe()
        ..supabaseId = 'recipe_1'
        ..name = 'Daiquiri'
        ..recipeType = 'cocktail');
      // Two required ingredients, one stocked in the bar, one not.
      await repo.addIngredient(RecipeIngredient()
        ..supabaseId = 'ing_rum'
        ..recipeSupabaseId = 'recipe_1'
        ..name = 'White Rum');
      await repo.addIngredient(RecipeIngredient()
        ..supabaseId = 'ing_lime'
        ..recipeSupabaseId = 'recipe_1'
        ..name = 'Lime');
      // A garnish should never be counted as missing.
      await repo.addIngredient(RecipeIngredient()
        ..supabaseId = 'ing_mint'
        ..recipeSupabaseId = 'recipe_1'
        ..name = 'Mint'
        ..isGarnish = true);

      await db.into(db.barIngredients).insert(BarIngredientsCompanion.insert(
            supabaseId: const Value('bar_rum'),
            name: const Value('White Rum'),
            inMyBar: const Value(true),
          ));

      await repo.syncMissingIngredientCounts();

      final recipe = (await repo.watchRecipes().first).single;
      expect(recipe.missingIngredientCount, 1); // only Lime is missing
    });
  });
}
