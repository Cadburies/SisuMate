import '../../models/models.dart';

/// How [ShoppingRepository.ensurePacksInShopping] merges into an existing line.
enum ShopPackMerge {
  /// Pending qty becomes max(existing, requested). Provision / add-missing.
  setMin,
  /// Pending qty += packs. Explicit "add another pack".
  increment,
}

abstract class ShoppingRepository {
  Stream<List<ShoppingCategory>> watchCategories();
  Stream<List<ShoppingItem>> watchItems(String categoryId);

  /// Lowercased names of **pending** (not bought, not hidden) shopping items.
  /// Used by Bar/Pantry/recipe tiles for the blue "in cart" state.
  Stream<Set<String>> watchAllItemNames();

  Future<void> toggleBought(ShoppingItem item);
  Future<void> hideItem(ShoppingItem item);
  /// Restore a soft-deleted (hidden) item so it appears in the normal list again.
  Future<void> unhideItem(ShoppingItem item);
  Future<void> permanentlyDelete(ShoppingItem item);
  Future<void> addItem(ShoppingItem item);

  /// Idempotent add: if a pending item with the same name (case-insensitive)
  /// already exists, does nothing and returns `false`. Otherwise inserts and
  /// returns `true`. Prevents swipe-spam duplicates.
  Future<bool> ensureInShopping({
    required String name,
    required String origin,
    int quantity = 1,
    String? unit,
    String categorySupabaseId = 'cat-misc',
  });

  /// Catalog-aware add. Looks up pantry/bar purchase spec for [name].
  /// [packs] is the buy count. See [ShopPackMerge] for existing-line behaviour.
  Future<bool> ensurePacksInShopping({
    required String name,
    required String origin,
    int packs = 1,
    ShopPackMerge merge = ShopPackMerge.setMin,
    String? note,
    String? unitOverride,
    double? priceOverride,
  });

  /// Mark all **pending** shopping lines with this name as bought (and stock
  /// matching bar/pantry). Returns how many lines were completed.
  Future<int> markPendingBoughtByName(String name);

  /// End-of-trip clear: permanently remove every bought (green) item.
  /// Returns how many were removed. Pending (blue) lines are kept.
  Future<int> clearBoughtItems();

  Future<void> updateItem(ShoppingItem item);

  /// Copy [price]/[place] onto all **pending** shopping lines with [name]
  /// (case-insensitive). Also syncs bar/pantry catalog via [updateItem].
  Future<int> applyPricePlaceToPendingByName({
    required String name,
    double? price,
    String? place,
  });

  /// Fill null shopping prices/places from bar/pantry seed catalog (by name).
  Future<int> backfillMissingPricesFromCatalog();

  Future<void> addCategory(ShoppingCategory category);
}
