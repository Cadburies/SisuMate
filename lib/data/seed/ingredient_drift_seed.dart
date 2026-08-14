import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';

/// Helpers that persist bundled BarIngredient/PantryIngredient domain objects
/// (built by the seeders) into their Drift tables.
///
/// SEED-PATCH: every row these helpers insert - whether the initial full seed
/// or a later catalog patch (`insertMissing*`, run via `runDeferredSeeds` on
/// an already-used install) - is stamped `lastModified = _factoryEpoch` /
/// `isSynced = true` at creation. Bundled content is by definition older than
/// any user change, so this must hold regardless of whether the *rest* of the
/// DB is pristine, which a whole-database check (`DatabaseService._isPristine`)
/// cannot guarantee for content added well after first install.
final _factoryEpoch = DateTime.utc(2000);
Future<int> barIngredientCountInDrift() async {
  final db = AppDatabase.instance;
  return (await db.select(db.barIngredients).get()).length;
}

Future<int> pantryIngredientCountInDrift() async {
  final db = AppDatabase.instance;
  return (await db.select(db.pantryIngredients).get()).length;
}

Future<void> seedBarIngredientsToDrift(List<BarIngredient> ingredients) async {
  final db = AppDatabase.instance;
  await db.batch((b) {
    for (final i in ingredients) {
      b.insert(
        db.barIngredients,
        BarIngredientsCompanion(
          supabaseId: Value(i.supabaseId),
          name: Value(i.name),
          inMyBar: Value(i.inMyBar),
          sortOrder: Value(i.sortOrder),
          isBundled: Value(i.isBundled),
          category: Value(i.category),
          flavorProfiles: Value(jsonEncode(i.flavorProfiles)),
          allergenTags: Value(jsonEncode(i.allergenTags)),
          alcoholByVolume: Value(i.alcoholByVolume),
          substitute1: Value(i.substitute1),
          substitute2: Value(i.substitute2),
          imageUrl: Value(i.imageUrl),
          lastKnownPrice: Value(i.lastKnownPrice),
          priceCurrency: Value(i.priceCurrency),
          lastKnownPriceUnit: Value(i.lastKnownPriceUnit),
          purchaseSizeBase: Value(i.purchaseSizeBase),
          purchaseBaseUnit: Value(i.purchaseBaseUnit),
          purchaseNoun: Value(i.purchaseNoun),
          unitsPerPurchase: Value(i.unitsPerPurchase),
          innerSizeBase: Value(i.innerSizeBase),
          onHandBase: Value(i.onHandBase),
          onHandUnit: Value(i.onHandUnit),
          lastModified: Value(_factoryEpoch),
          isSynced: const Value(true),
        ),
      );
    }
  });
}

Future<void> seedPantryIngredientsToDrift(
    List<PantryIngredient> ingredients) async {
  final db = AppDatabase.instance;
  await db.batch((b) {
    for (final i in ingredients) {
      b.insert(
        db.pantryIngredients,
        PantryIngredientsCompanion(
          supabaseId: Value(i.supabaseId),
          name: Value(i.name),
          inMyPantry: Value(i.inMyPantry),
          quantity: Value(i.quantity),
          unit: Value(i.unit),
          sortOrder: Value(i.sortOrder),
          isBundled: Value(i.isBundled),
          category: Value(i.category),
          flavorProfiles: Value(jsonEncode(i.flavorProfiles)),
          cuisineTypes: Value(jsonEncode(i.cuisineTypes)),
          allergenTags: Value(jsonEncode(i.allergenTags)),
          dietaryTags: Value(jsonEncode(i.dietaryTags)),
          substitute1: Value(i.substitute1),
          substitute2: Value(i.substitute2),
          imageUrl: Value(i.imageUrl),
          lastKnownPrice: Value(i.lastKnownPrice),
          priceCurrency: Value(i.priceCurrency),
          lastKnownPriceUnit: Value(i.lastKnownPriceUnit),
          purchaseSizeBase: Value(i.purchaseSizeBase),
          purchaseBaseUnit: Value(i.purchaseBaseUnit),
          purchaseNoun: Value(i.purchaseNoun),
          unitsPerPurchase: Value(i.unitsPerPurchase),
          innerSizeBase: Value(i.innerSizeBase),
          caloriesPer100g: Value(i.caloriesPer100g),
          proteinPer100g: Value(i.proteinPer100g),
          fatPer100g: Value(i.fatPer100g),
          carbsPer100g: Value(i.carbsPer100g),
          lastModified: Value(_factoryEpoch),
          isSynced: const Value(true),
        ),
      );
    }
  });
}

/// Inserts only rows whose [BarIngredient.supabaseId] is not already present.
/// Does not touch existing stock flags.
Future<int> insertMissingBarIngredientsToDrift(
    List<BarIngredient> ingredients) async {
  final db = AppDatabase.instance;
  final existing = {
    for (final r in await db.select(db.barIngredients).get()) r.supabaseId
  };
  final missing =
      ingredients.where((i) => !existing.contains(i.supabaseId)).toList();
  if (missing.isEmpty) return 0;
  await seedBarIngredientsToDrift(missing);
  return missing.length;
}

/// Inserts only rows whose [PantryIngredient.supabaseId] is not already present.
Future<int> insertMissingPantryIngredientsToDrift(
    List<PantryIngredient> ingredients) async {
  final db = AppDatabase.instance;
  final existing = {
    for (final r in await db.select(db.pantryIngredients).get()) r.supabaseId
  };
  final missing =
      ingredients.where((i) => !existing.contains(i.supabaseId)).toList();
  if (missing.isEmpty) return 0;
  await seedPantryIngredientsToDrift(missing);
  return missing.length;
}

/// Fills null calorie/macro fields on existing pantry rows from [byName].
/// Does not overwrite user-edited non-null macros.
Future<int> patchMissingPantryMacrosInDrift(
    Map<String, (double, double, double, double)> byName) async {
  final db = AppDatabase.instance;
  final rows = await db.select(db.pantryIngredients).get();
  var n = 0;
  for (final row in rows) {
    if (row.caloriesPer100g != null) continue;
    final m = byName[row.name];
    if (m == null) continue;
    await (db.update(db.pantryIngredients)..where((t) => t.id.equals(row.id)))
        .write(PantryIngredientsCompanion(
      caloriesPer100g: Value(m.$1),
      proteinPer100g: Value(m.$2),
      fatPer100g: Value(m.$3),
      carbsPer100g: Value(m.$4),
    ));
    n++;
  }
  return n;
}

/// Updates substitute1/substitute2 on existing bar rows (by name) without
/// touching `inMyBar` state - mirrors the old `_syncBarSubstitutes`.
Future<void> syncBarSubstitutesInDrift(
    Map<String, (String?, String?)> substitutes) async {
  final db = AppDatabase.instance;
  final rows = await db.select(db.barIngredients).get();
  for (final row in rows) {
    final subs = substitutes[row.name];
    if (subs == null) continue;
    if (row.substitute1 == subs.$1 && row.substitute2 == subs.$2) continue;
    await (db.update(db.barIngredients)..where((t) => t.id.equals(row.id)))
        .write(BarIngredientsCompanion(
      substitute1: Value(subs.$1),
      substitute2: Value(subs.$2),
    ));
  }
}
