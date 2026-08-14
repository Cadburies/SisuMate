import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../domain/repositories/bar_ingredient_repository.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../services/sync_service.dart';
import 'recipe_repository_impl.dart';

/// Bar ingredients (My Bar) on Drift (S1). Sync-participating when [syncService] set (SYN2).
class BarIngredientRepositoryImpl implements BarIngredientRepository {
  final AppDatabase db;
  final SyncService? syncService;
  late final RecipeRepository _recipeRepo = RecipeRepositoryImpl(db);

  BarIngredientRepositoryImpl(this.db, [this.syncService]);

  BarIngredient _toDomain(BarIngredientRow r) => BarIngredient()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..name = r.name
    ..inMyBar = r.inMyBar
    ..sortOrder = r.sortOrder
    ..isBundled = r.isBundled
    ..isSynced = r.isSynced
    ..category = r.category
    ..flavorProfiles = (jsonDecode(r.flavorProfiles) as List).cast<String>()
    ..allergenTags = (jsonDecode(r.allergenTags) as List).cast<String>()
    ..alcoholByVolume = r.alcoholByVolume
    ..substitute1 = r.substitute1
    ..substitute2 = r.substitute2
    ..localPhotoPath = r.localPhotoPath
    ..imageUrl = r.imageUrl
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
    ..onHandBase = r.onHandBase
    ..onHandUnit = r.onHandUnit
    ..lastModified = r.lastModified;

  BarIngredientsCompanion _companion(BarIngredient i) => BarIngredientsCompanion(
        supabaseId: Value(i.supabaseId),
        boatSupabaseId: Value(i.boatSupabaseId),
        name: Value(i.name),
        inMyBar: Value(i.inMyBar),
        sortOrder: Value(i.sortOrder),
        isBundled: Value(i.isBundled),
        isSynced: Value(i.isSynced),
        category: Value(i.category),
        flavorProfiles: Value(jsonEncode(i.flavorProfiles)),
        allergenTags: Value(jsonEncode(i.allergenTags)),
        alcoholByVolume: Value(i.alcoholByVolume),
        substitute1: Value(i.substitute1),
        substitute2: Value(i.substitute2),
        localPhotoPath: Value(i.localPhotoPath),
        imageUrl: Value(i.imageUrl),
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
        onHandBase: Value(i.onHandBase),
        onHandUnit: Value(i.onHandUnit),
        lastModified: Value(i.lastModified),
      );

  Future<void> _put(BarIngredient ingredient) async {
    await _stampBoatScope(ingredient);
    final updated = await (db.update(db.barIngredients)
          ..where((t) => t.supabaseId.equals(ingredient.supabaseId)))
        .write(_companion(ingredient));
    if (updated == 0) {
      await db.into(db.barIngredients).insert(_companion(ingredient));
    }
  }

  /// SHARE4: user-touched rows carry the active boat GUID so per-boat scoping
  /// (and the RLS predicates) hold for bar ingredients too. Mutates the domain
  /// object before `_put`/`toJson`, so the outbound payload is stamped as well.
  Future<void> _stampBoatScope(BarIngredient i) async {
    if (i.boatSupabaseId.isNotEmpty) return;
    final s = await db.select(db.userSettingsTable).getSingleOrNull();
    i.boatSupabaseId = s?.activeBoatSupabaseId ?? '';
  }

  @override
  Stream<List<BarIngredient>> watchBarIngredients() {
    // Stable name order only — stock-based ranking is applied in the UI so
    // toggling "in bar" does not jump the list under the user's finger.
    return db.select(db.barIngredients).watch().map((rows) {
      final all = rows.map(_toDomain).toList();
      all.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return all;
    });
  }

  @override
  Future<void> toggleInMyBar(BarIngredient ingredient) async {
    ingredient.inMyBar = !ingredient.inMyBar;
    ingredient.lastModified = DateTime.now().toUtc();
    await _put(ingredient);
    await syncService?.queueOutgoingChange(
        'bar_ingredients', ingredient.toJson());
    await _recipeRepo.syncMissingIngredientCounts();
  }

  @override
  Future<void> addBarIngredient(BarIngredient ingredient) async {
    ingredient.lastModified = DateTime.now().toUtc();
    await _put(ingredient);
    await syncService?.queueOutgoingChange(
        'bar_ingredients', ingredient.toJson());
  }

  @override
  Future<void> updateBarIngredient(BarIngredient ingredient) async {
    ingredient.lastModified = DateTime.now().toUtc();
    await _put(ingredient);
    await syncService?.queueOutgoingChange(
        'bar_ingredients', ingredient.toJson());
  }

  @override
  Future<void> deleteBarIngredient(BarIngredient ingredient) async {
    await (db.delete(db.barIngredients)
          ..where((t) => t.supabaseId.equals(ingredient.supabaseId)))
        .go();
    await syncService?.queueOutgoingChange(
      'bar_ingredients',
      {'supabaseId': ingredient.supabaseId},
      isDelete: true,
    );
  }

  @override
  Future<List<String>> recipeNamesForIngredient(String ingredientName) async {
    final cocktails = await cocktailsUsingIngredient(ingredientName);
    return cocktails.map((r) => r.name).toList();
  }

  @override
  Future<List<Recipe>> cocktailsUsingIngredient(String ingredientName) async {
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
            recipeIds.contains(r.supabaseId) && r.recipeType == 'cocktail')
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
    BarIngredient ingredient, {
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
        'bar_ingredients', ingredient.toJson());
  }
}
