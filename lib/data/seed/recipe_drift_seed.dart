import 'dart:convert';
import 'package:drift/drift.dart';
import '../../core/units.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';

/// Helpers that persist the bundled `Recipe`/`RecipeIngredient` domain objects
/// (built by `seed_recipes.dart`) into their Drift tables.

Future<void> purgeSeededRecipeIngredientsFromDrift(
    List<String> recipeSupabaseIds) async {
  if (recipeSupabaseIds.isEmpty) return;
  final db = AppDatabase.instance;
  await (db.delete(db.recipeIngredients)
        ..where((t) => t.recipeSupabaseId.isIn(recipeSupabaseIds)))
      .go();
}

/// Deletes recipes whose `supabaseId` is in [recipeSupabaseIds].
Future<void> purgeSeededRecipesFromDrift(List<String> recipeSupabaseIds) async {
  if (recipeSupabaseIds.isEmpty) return;
  final db = AppDatabase.instance;
  await (db.delete(db.recipes)
        ..where((t) => t.supabaseId.isIn(recipeSupabaseIds)))
      .go();
}

/// Deletes every recipe (and its ingredients) whose id matches [prefix]%.
Future<void> purgeRecipesByIdPrefix(String prefix) async {
  final db = AppDatabase.instance;
  final rows = await (db.select(db.recipes)
        ..where((t) => t.supabaseId.like('$prefix%')))
      .get();
  if (rows.isEmpty) return;
  final ids = rows.map((r) => r.supabaseId).toList();
  await purgeSeededRecipeIngredientsFromDrift(ids);
  await purgeSeededRecipesFromDrift(ids);
}

/// Insert recipes. Caller must purge first when re-seeding the same ids.
Future<void> seedRecipesToDrift(List<Recipe> recipes) async {
  if (recipes.isEmpty) return;
  final db = AppDatabase.instance;
  await db.batch((b) {
    for (final r in recipes) {
      b.insert(
        db.recipes,
        RecipesCompanion(
          supabaseId: Value(r.supabaseId),
          boatSupabaseId: Value(r.boatSupabaseId),
          name: Value(r.name),
          description: Value(r.description),
          instructions: Value(r.instructions),
          recipeType: Value(r.recipeType),
          isBundled: Value(r.isBundled),
          isFavourite: Value(r.isFavourite),
          glassware: Value(r.glassware),
          prepMinutes: Value(r.prepMinutes),
          cookMinutes: Value(r.cookMinutes),
          story: Value(r.story),
          tastingLog:
              Value(jsonEncode(r.tastingLog.map((t) => t.toJson()).toList())),
          cuisine: Value(jsonEncode(r.cuisine)),
          flavorProfiles: Value(jsonEncode(r.flavorProfiles)),
          cookingMethod: Value(r.cookingMethod),
          imageAsset: Value(r.imageAsset),
          localPath: Value(r.localPath),
        ),
      );
    }
  });
}

/// Insert ingredients, always normalizing qty/unit to metric storage.
Future<void> seedRecipeIngredientsToDrift(
    List<RecipeIngredient> ingredients) async {
  if (ingredients.isEmpty) return;
  final db = AppDatabase.instance;
  await db.batch((b) {
    for (final i in ingredients) {
      final (qty, unit) = UnitConverter.normalizePair(i.quantity, i.unit);
      b.insert(
        db.recipeIngredients,
        RecipeIngredientsCompanion(
          supabaseId: Value(i.supabaseId),
          recipeSupabaseId: Value(i.recipeSupabaseId),
          name: Value(i.name),
          quantity: Value(qty),
          unit: Value(unit),
          substitute: Value(i.substitute),
          isGarnish: Value(i.isGarnish),
          garnishNotes: Value(i.garnishNotes),
          isOptional: Value(i.isOptional),
          sortOrder: Value(i.sortOrder),
        ),
      );
    }
  });
}
