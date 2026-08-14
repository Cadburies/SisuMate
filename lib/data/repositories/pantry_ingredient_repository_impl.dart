import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../domain/repositories/pantry_ingredient_repository.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../services/sync_service.dart';
import 'recipe_repository_impl.dart';

/// Pantry ingredients (My Pantry) on Drift (S1). Sync-participating when [syncService] set (SYN2).
class PantryIngredientRepositoryImpl implements PantryIngredientRepository {
  final AppDatabase db;
  final SyncService? syncService;
  late final RecipeRepository _recipeRepo = RecipeRepositoryImpl(db);

  PantryIngredientRepositoryImpl(this.db, [this.syncService]);

  PantryIngredient _toDomain(PantryIngredientRow r) => PantryIngredient()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..name = r.name
    ..inMyPantry = r.inMyPantry
    ..quantity = r.quantity
    ..unit = r.unit
    ..sortOrder = r.sortOrder
    ..isBundled = r.isBundled
    ..isSynced = r.isSynced
    ..category = r.category
    ..flavorProfiles = (jsonDecode(r.flavorProfiles) as List).cast<String>()
    ..cuisineTypes = (jsonDecode(r.cuisineTypes) as List).cast<String>()
    ..allergenTags = (jsonDecode(r.allergenTags) as List).cast<String>()
    ..dietaryTags = (jsonDecode(r.dietaryTags) as List).cast<String>()
    ..substitute1 = r.substitute1
    ..substitute2 = r.substitute2
    ..localPhotoPath = r.localPhotoPath
    ..imageUrl = r.imageUrl
    ..expiryDate = r.expiryDate
    ..lastKnownPrice = r.lastKnownPrice
    ..priceCurrency = r.priceCurrency
    ..lastKnownPriceUnit = r.lastKnownPriceUnit
    ..lastPurchasePlace = r.lastPurchasePlace
    ..purchaseHistory = (jsonDecode(r.purchaseHistory) as List)
        .map((e) => PurchaseRecord.fromJson(e as Map<String, dynamic>))
        .toList()
    ..purchaseSizeBase = r.purchaseSizeBase
    ..purchaseBaseUnit = r.purchaseBaseUnit
    ..purchaseNoun = r.purchaseNoun
    ..unitsPerPurchase = r.unitsPerPurchase
    ..innerSizeBase = r.innerSizeBase
    ..caloriesPer100g = r.caloriesPer100g
    ..proteinPer100g = r.proteinPer100g
    ..fatPer100g = r.fatPer100g
    ..carbsPer100g = r.carbsPer100g
    ..lastModified = r.lastModified;

  PantryIngredientsCompanion _companion(PantryIngredient i) =>
      PantryIngredientsCompanion(
        supabaseId: Value(i.supabaseId),
        boatSupabaseId: Value(i.boatSupabaseId),
        name: Value(i.name),
        inMyPantry: Value(i.inMyPantry),
        quantity: Value(i.quantity),
        unit: Value(i.unit),
        sortOrder: Value(i.sortOrder),
        isBundled: Value(i.isBundled),
        isSynced: Value(i.isSynced),
        category: Value(i.category),
        flavorProfiles: Value(jsonEncode(i.flavorProfiles)),
        cuisineTypes: Value(jsonEncode(i.cuisineTypes)),
        allergenTags: Value(jsonEncode(i.allergenTags)),
        dietaryTags: Value(jsonEncode(i.dietaryTags)),
        substitute1: Value(i.substitute1),
        substitute2: Value(i.substitute2),
        localPhotoPath: Value(i.localPhotoPath),
        imageUrl: Value(i.imageUrl),
        expiryDate: Value(i.expiryDate),
        lastKnownPrice: Value(i.lastKnownPrice),
        priceCurrency: Value(i.priceCurrency),
        lastKnownPriceUnit: Value(i.lastKnownPriceUnit),
        lastPurchasePlace: Value(i.lastPurchasePlace),
        purchaseHistory:
            Value(jsonEncode(i.purchaseHistory.map((p) => p.toJson()).toList())),
        purchaseSizeBase: Value(i.purchaseSizeBase),
        purchaseBaseUnit: Value(i.purchaseBaseUnit),
        purchaseNoun: Value(i.purchaseNoun),
        unitsPerPurchase: Value(i.unitsPerPurchase),
        innerSizeBase: Value(i.innerSizeBase),
        caloriesPer100g: Value(i.caloriesPer100g),
        proteinPer100g: Value(i.proteinPer100g),
        fatPer100g: Value(i.fatPer100g),
        carbsPer100g: Value(i.carbsPer100g),
        lastModified: Value(i.lastModified),
      );

  Future<void> _put(PantryIngredient ingredient) async {
    await _stampBoatScope(ingredient);
    final updated = await (db.update(db.pantryIngredients)
          ..where((t) => t.supabaseId.equals(ingredient.supabaseId)))
        .write(_companion(ingredient));
    if (updated == 0) {
      await db.into(db.pantryIngredients).insert(_companion(ingredient));
    }
  }

  /// SHARE4: user-touched rows carry the active boat GUID so per-boat scoping
  /// (and the RLS predicates) hold for pantry ingredients too. Mutates the
  /// domain object before `_put`/`toJson`, so the outbound payload is stamped.
  Future<void> _stampBoatScope(PantryIngredient i) async {
    if (i.boatSupabaseId.isNotEmpty) return;
    final s = await db.select(db.userSettingsTable).getSingleOrNull();
    i.boatSupabaseId = s?.activeBoatSupabaseId ?? '';
  }

  @override
  Stream<List<PantryIngredient>> watchPantryIngredients() {
    // Stable name order only — stock-based ranking is applied in the UI so
    // toggling "in pantry" does not jump the list under the user's finger.
    return db.select(db.pantryIngredients).watch().map((rows) {
      final all = rows.map(_toDomain).toList();
      all.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return all;
    });
  }

  @override
  Future<void> toggleInMyPantry(PantryIngredient ingredient) async {
    ingredient.inMyPantry = !ingredient.inMyPantry;
    ingredient.lastModified = DateTime.now().toUtc();
    await _put(ingredient);
    await syncService?.queueOutgoingChange(
        'pantry_ingredients', ingredient.toJson());
    await _recipeRepo.syncMissingIngredientCounts();
  }

  @override
  Future<void> addPantryIngredient(PantryIngredient ingredient) async {
    ingredient.lastModified = DateTime.now().toUtc();
    await _put(ingredient);
    await syncService?.queueOutgoingChange(
        'pantry_ingredients', ingredient.toJson());
  }

  @override
  Future<void> updatePantryIngredient(PantryIngredient ingredient) async {
    ingredient.lastModified = DateTime.now().toUtc();
    await _put(ingredient);
    await syncService?.queueOutgoingChange(
        'pantry_ingredients', ingredient.toJson());
  }

  @override
  Future<void> deletePantryIngredient(PantryIngredient ingredient) async {
    await (db.delete(db.pantryIngredients)
          ..where((t) => t.supabaseId.equals(ingredient.supabaseId)))
        .go();
    await syncService?.queueOutgoingChange(
      'pantry_ingredients',
      {'supabaseId': ingredient.supabaseId},
      isDelete: true,
    );
  }

  @override
  Future<List<String>> recipeNamesForIngredient(String ingredientName) async {
    final menus = await menusUsingIngredient(ingredientName);
    return menus.map((r) => r.name).toList();
  }

  @override
  Future<List<Recipe>> menusUsingIngredient(String ingredientName) async {
    final allIngredients = await db.select(db.recipeIngredients).get();
    final lowerName = ingredientName.toLowerCase().trim();
    final recipeIds = allIngredients
        .where((i) => i.name.toLowerCase().trim() == lowerName)
        .map((i) => i.recipeSupabaseId)
        .toSet();

    if (recipeIds.isEmpty) return [];

    final allRecipes = await db.select(db.recipes).get();
    return allRecipes
        .where((r) =>
            recipeIds.contains(r.supabaseId) && r.recipeType == 'menu')
        .map((r) => Recipe()
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
          ..imageAsset = r.imageAsset
          ..localPath = r.localPath
          ..lastModified = r.lastModified)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<void> recordPurchase(
    PantryIngredient ingredient, {
    required double price,
    required String place,
    String? priceUnit,
    String? notes,
  }) async {
    final record = PurchaseRecord()
      ..price = price
      ..currency = ingredient.priceCurrency
      ..place = place
      ..purchaseDate = DateTime.now()
      ..priceUnit = priceUnit
      ..notes = notes;

    ingredient
      ..lastKnownPrice = price
      ..lastKnownPriceUnit = priceUnit
      ..lastPurchasePlace = place
      ..purchaseHistory = [...ingredient.purchaseHistory, record]
      ..lastModified = DateTime.now().toUtc();

    await _put(ingredient);
    await syncService?.queueOutgoingChange(
        'pantry_ingredients', ingredient.toJson());
  }
}
