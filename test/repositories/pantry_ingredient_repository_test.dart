import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/pantry_ingredient_repository_impl.dart';
import 'package:sisu_mate/data/repositories/recipe_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

// Pantry ingredients (My Pantry) on Drift (S1). Sync-participating (SYN2).
void main() {
  late AppDatabase db;
  late PantryIngredientRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PantryIngredientRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  group('PantryIngredientRepositoryImpl CRUD', () {
    // SHARE4: unscoped user writes are stamped with the active boat GUID.
    test('add stamps active boat GUID when boatSupabaseId is empty', () async {
      await db.into(db.userSettingsTable).insert(
            UserSettingsTableCompanion.insert(
              id: const Value(1),
              activeBoatSupabaseId: const Value('boat_guid_1'),
            ),
          );
      await repo.addPantryIngredient(PantryIngredient()
        ..supabaseId = 'pantry_new'
        ..name = 'Dill');

      final all = await repo.watchPantryIngredients().first;
      expect(all.single.boatSupabaseId, 'boat_guid_1');
    });

    test('Create: addPantryIngredient persists a new ingredient', () async {
      await repo.addPantryIngredient(PantryIngredient()
        ..supabaseId = 'pantry_1'
        ..name = 'Fresh Basil'
        ..category = 'herb'
        ..boatSupabaseId = 'boat_1'); // SHARE4 per-boat scope

      final all = await repo.watchPantryIngredients().first;
      expect(all, hasLength(1));
      expect(all.single.name, 'Fresh Basil');
      expect(all.single.boatSupabaseId, 'boat_1');
    });

    test('Read: watchPantryIngredients is alphabetical by name (stable)',
        () async {
      await repo.addPantryIngredient(PantryIngredient()
        ..supabaseId = 'pantry_a'
        ..name = 'Apples'
        ..inMyPantry = false);
      await repo.addPantryIngredient(PantryIngredient()
        ..supabaseId = 'pantry_z'
        ..name = 'Zucchini'
        ..inMyPantry = true);

      // Stock-first ordering is UI-only so toggling does not jump the list.
      final ingredients = await repo.watchPantryIngredients().first;
      expect(ingredients.map((i) => i.name), ['Apples', 'Zucchini']);
    });

    test('Update: toggleInMyPantry flips inMyPantry and persists it', () async {
      final ingredient = PantryIngredient()
        ..supabaseId = 'pantry_1'
        ..name = 'Fresh Basil';
      await repo.addPantryIngredient(ingredient);
      expect(ingredient.inMyPantry, isFalse);

      await repo.toggleInMyPantry(ingredient);

      final all = await repo.watchPantryIngredients().first;
      expect(all.single.inMyPantry, isTrue);
    });

    test('List/tag fields round-trip through JSON columns', () async {
      await repo.addPantryIngredient(PantryIngredient()
        ..supabaseId = 'pantry_1'
        ..name = 'Almonds'
        ..allergenTags = ['nuts']
        ..dietaryTags = ['vegan', 'gluten-free']
        ..flavorProfiles = ['nutty']);

      final saved = (await repo.watchPantryIngredients().first).single;
      expect(saved.allergenTags, ['nuts']);
      expect(saved.dietaryTags, ['vegan', 'gluten-free']);
      expect(saved.flavorProfiles, ['nutty']);
    });

    test('Delete: deletePantryIngredient removes it from the database',
        () async {
      final ingredient = PantryIngredient()
        ..supabaseId = 'pantry_1'
        ..name = 'To remove';
      await repo.addPantryIngredient(ingredient);

      await repo.deletePantryIngredient(ingredient);

      final all = await repo.watchPantryIngredients().first;
      expect(all, isEmpty);
    });

    test('menusUsingIngredient returns menu recipes that list the ingredient',
        () async {
      final recipeRepo = RecipeRepositoryImpl(db);
      final menu = Recipe()
        ..supabaseId = 'menu_pasta'
        ..name = 'Pasta Night'
        ..recipeType = RecipeType.menu.name;
      final cocktail = Recipe()
        ..supabaseId = 'cocktail_mojito'
        ..name = 'Mojito'
        ..recipeType = RecipeType.cocktail.name;
      await recipeRepo.addRecipe(menu);
      await recipeRepo.addRecipe(cocktail);
      await recipeRepo.addIngredient(RecipeIngredient()
        ..supabaseId = 'ri_basil_menu'
        ..recipeSupabaseId = menu.supabaseId
        ..name = 'Fresh Basil');
      await recipeRepo.addIngredient(RecipeIngredient()
        ..supabaseId = 'ri_basil_cocktail'
        ..recipeSupabaseId = cocktail.supabaseId
        ..name = 'Fresh Basil');

      final menus = await repo.menusUsingIngredient('fresh basil');
      expect(menus.map((r) => r.name), ['Pasta Night']);
      expect(await repo.recipeNamesForIngredient('Fresh Basil'),
          ['Pasta Night']);
    });
  });
}
