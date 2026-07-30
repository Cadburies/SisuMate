import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../services/sync_service.dart';

/// Recipes + ingredients on Drift (S1). Sync-participating when [syncService] set (SYN2).
class RecipeRepositoryImpl implements RecipeRepository {
  final AppDatabase db;
  final SyncService? syncService;

  RecipeRepositoryImpl(this.db, [this.syncService]);

  Recipe _recipeToDomain(RecipeRow r) => Recipe()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..name = r.name
    ..description = r.description
    ..instructions = r.instructions
    ..recipeType = r.recipeType
    ..createdAt = r.createdAt
    ..isBundled = r.isBundled
    ..isSynced = r.isSynced
    ..missingIngredientCount = r.missingIngredientCount
    ..isFavourite = r.isFavourite
    ..glassware = r.glassware
    ..prepMinutes = r.prepMinutes
    ..cookMinutes = r.cookMinutes
    ..story = r.story
    ..tastingLog = (jsonDecode(r.tastingLog) as List)
        .map((e) => TastingRecord.fromJson(e as Map<String, dynamic>))
        .toList()
    ..cuisine = _decodeStringList(r.cuisine)
    ..flavorProfiles = _decodeStringList(r.flavorProfiles)
    ..cookingMethod = r.cookingMethod
    ..imageAsset = r.imageAsset
    ..localPath = r.localPath
    ..lastModified = r.lastModified;

  RecipesCompanion _recipeCompanion(Recipe r) => RecipesCompanion(
        supabaseId: Value(r.supabaseId),
        boatSupabaseId: Value(r.boatSupabaseId),
        name: Value(r.name),
        description: Value(r.description),
        instructions: Value(r.instructions),
        recipeType: Value(r.recipeType),
        createdAt: Value(r.createdAt),
        isBundled: Value(r.isBundled),
        isSynced: Value(r.isSynced),
        missingIngredientCount: Value(r.missingIngredientCount),
        isFavourite: Value(r.isFavourite),
        glassware: Value(r.glassware),
        prepMinutes: Value(r.prepMinutes),
        cookMinutes: Value(r.cookMinutes),
        story: Value(r.story),
        tastingLog: Value(jsonEncode(r.tastingLog.map((t) => t.toJson()).toList())),
        cuisine: Value(jsonEncode(r.cuisine)),
        flavorProfiles: Value(jsonEncode(r.flavorProfiles)),
        cookingMethod: Value(r.cookingMethod),
        imageAsset: Value(r.imageAsset),
        localPath: Value(r.localPath),
        lastModified: Value(r.lastModified),
      );

  /// Cuisine/flavorProfiles columns store JSON lists; pre-v2 cuisine may be a
  /// plain string (or empty/null-ish).
  static List<String> _decodeStringList(String raw) {
    if (raw.trim().isEmpty) return [];
    final t = raw.trim();
    if (t.startsWith('[')) {
      try {
        return stringListFromJson(jsonDecode(t));
      } catch (_) {
        return [t];
      }
    }
    return [t];
  }

  RecipeIngredient _ingToDomain(RecipeIngredientRow r) => RecipeIngredient()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..recipeSupabaseId = r.recipeSupabaseId
    ..name = r.name
    ..quantity = r.quantity
    ..unit = r.unit
    ..substitute = r.substitute
    ..isGarnish = r.isGarnish
    ..garnishNotes = r.garnishNotes
    ..isOptional = r.isOptional
    ..photoUrl = r.photoUrl
    ..sortOrder = r.sortOrder
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  RecipeIngredientsCompanion _ingCompanion(RecipeIngredient i) =>
      RecipeIngredientsCompanion(
        supabaseId: Value(i.supabaseId),
        recipeSupabaseId: Value(i.recipeSupabaseId),
        name: Value(i.name),
        quantity: Value(i.quantity),
        unit: Value(i.unit),
        substitute: Value(i.substitute),
        isGarnish: Value(i.isGarnish),
        garnishNotes: Value(i.garnishNotes),
        isOptional: Value(i.isOptional),
        photoUrl: Value(i.photoUrl),
        sortOrder: Value(i.sortOrder),
        isSynced: Value(i.isSynced),
        lastModified: Value(i.lastModified),
      );

  @override
  Stream<List<Recipe>> watchRecipes() {
    return db.select(db.recipes).watch().map((rows) =>
        rows.map(_recipeToDomain).toList());
  }

  @override
  Stream<List<RecipeIngredient>> watchIngredients(String recipeId) {
    return db.select(db.recipeIngredients).watch().map((rows) => rows
        .map(_ingToDomain)
        .where((i) => i.recipeSupabaseId == recipeId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
  }

  @override
  Future<List<RecipeIngredient>> getIngredientsOnce(String recipeId) async {
    final rows = await db.select(db.recipeIngredients).get();
    return rows
        .map(_ingToDomain)
        .where((i) => i.recipeSupabaseId == recipeId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> _putRecipe(Recipe recipe) async {
    final updated = await (db.update(db.recipes)
          ..where((t) => t.supabaseId.equals(recipe.supabaseId)))
        .write(_recipeCompanion(recipe));
    if (updated == 0) {
      await db.into(db.recipes).insert(_recipeCompanion(recipe));
    }
  }

  Future<void> _putIngredient(RecipeIngredient ingredient) async {
    final updated = await (db.update(db.recipeIngredients)
          ..where((t) => t.supabaseId.equals(ingredient.supabaseId)))
        .write(_ingCompanion(ingredient));
    if (updated == 0) {
      await db.into(db.recipeIngredients).insert(_ingCompanion(ingredient));
    }
  }

  @override
  Future<void> addRecipe(Recipe recipe) async {
    recipe.lastModified = DateTime.now().toUtc();
    await _putRecipe(recipe);
    await syncService?.queueOutgoingChange('recipes', recipe.toJson());
  }

  @override
  Future<void> updateRecipe(Recipe recipe) async {
    recipe.lastModified = DateTime.now().toUtc();
    await _putRecipe(recipe);
    await syncService?.queueOutgoingChange('recipes', recipe.toJson());
  }

  @override
  Future<void> deleteRecipe(Recipe recipe) async {
    await (db.delete(db.recipes)
          ..where((t) => t.supabaseId.equals(recipe.supabaseId)))
        .go();
    await syncService?.queueOutgoingChange(
      'recipes',
      {'supabaseId': recipe.supabaseId},
      isDelete: true,
    );
  }

  @override
  Future<void> addIngredient(RecipeIngredient ingredient) async {
    ingredient.lastModified = DateTime.now().toUtc();
    await _putIngredient(ingredient);
    await syncService?.queueOutgoingChange(
        'recipe_ingredients', ingredient.toJson());
  }

  @override
  Future<void> updateIngredient(RecipeIngredient ingredient) async {
    ingredient.lastModified = DateTime.now().toUtc();
    await _putIngredient(ingredient);
    await syncService?.queueOutgoingChange(
        'recipe_ingredients', ingredient.toJson());
  }

  @override
  Future<void> deleteIngredient(RecipeIngredient ingredient) async {
    await (db.delete(db.recipeIngredients)
          ..where((t) => t.supabaseId.equals(ingredient.supabaseId)))
        .go();
    await syncService?.queueOutgoingChange(
      'recipe_ingredients',
      {'supabaseId': ingredient.supabaseId},
      isDelete: true,
    );
  }

  @override
  Future<void> syncMissingIngredientCounts() async {
    final recipes =
        (await db.select(db.recipes).get()).map(_recipeToDomain).toList();
    final allIngs =
        (await db.select(db.recipeIngredients).get()).map(_ingToDomain).toList();
    final barIngs = await db.select(db.barIngredients).get();
    final pantryIngs = await db.select(db.pantryIngredients).get();

    // Expand stocked sets to include what each stocked ingredient can substitute for
    final barStocked = <String>{};
    for (final b in barIngs.where((b) => b.inMyBar)) {
      barStocked.add(b.name.toLowerCase().trim());
      if (b.substitute1 != null) barStocked.add(b.substitute1!.toLowerCase().trim());
      if (b.substitute2 != null) barStocked.add(b.substitute2!.toLowerCase().trim());
    }
    final pantryStocked = <String>{};
    for (final p in pantryIngs.where((p) => p.inMyPantry)) {
      pantryStocked.add(p.name.toLowerCase().trim());
      if (p.substitute1 != null) pantryStocked.add(p.substitute1!.toLowerCase().trim());
      if (p.substitute2 != null) pantryStocked.add(p.substitute2!.toLowerCase().trim());
    }

    for (final recipe in recipes) {
      final ings = allIngs.where((i) =>
          i.recipeSupabaseId == recipe.supabaseId && !i.isGarnish && !i.isOptional).toList();
      final stocked = (recipe.recipeType == 'cocktail' || recipe.recipeType == 'syrup')
          ? barStocked
          : pantryStocked;
      final missing = ings.where((i) => !stocked.contains(i.name.toLowerCase().trim())).length;
      await (db.update(db.recipes)..where((t) => t.id.equals(recipe.id)))
          .write(RecipesCompanion(missingIngredientCount: Value(missing)));
    }
  }
}
