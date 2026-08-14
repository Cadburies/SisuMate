import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../services/sync_service.dart';
import '../../domain/repositories/shopping_repository.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../services/quantity_model.dart';
import 'recipe_repository_impl.dart';

/// Shopping (categories + items) on Drift (S1); sync-participating.
///
/// When an item is marked **bought**, matching Bar / Pantry rows are stocked
/// (by name) and recipe `missingIngredientCount` is resynced so cocktail/menu
/// lists update via Drift streams.
class ShoppingRepositoryImpl implements ShoppingRepository {
  final AppDatabase db;
  final SyncService syncService;
  late final RecipeRepository _recipeRepo = RecipeRepositoryImpl(db);

  ShoppingRepositoryImpl(this.db, this.syncService);

  ShoppingCategory _catToDomain(ShoppingCategoryRow r) => ShoppingCategory()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..name = r.name
    ..sortOrder = r.sortOrder
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  ShoppingItem _itemToDomain(ShoppingItemRow r) => ShoppingItem()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..categorySupabaseId = r.categorySupabaseId
    ..name = r.name
    ..quantity = r.quantity
    ..unit = r.unit
    ..isBought = r.isBought
    ..isBundled = r.isBundled
    ..isSynced = r.isSynced
    ..isHidden = r.isHidden
    ..notes = r.notes
    ..origin = r.origin
    ..lastPurchasePrice = r.lastPurchasePrice
    ..lastPurchasePlace = r.lastPurchasePlace
    ..userPhotoUrl = r.userPhotoUrl
    ..lastModified = r.lastModified;

  ShoppingItemsCompanion _itemCompanion(ShoppingItem i) => ShoppingItemsCompanion(
        supabaseId: Value(i.supabaseId),
        boatSupabaseId: Value(i.boatSupabaseId),
        categorySupabaseId: Value(i.categorySupabaseId),
        name: Value(i.name),
        quantity: Value(i.quantity),
        unit: Value(i.unit),
        isBought: Value(i.isBought),
        isBundled: Value(i.isBundled),
        isSynced: Value(i.isSynced),
        isHidden: Value(i.isHidden),
        notes: Value(i.notes),
        origin: Value(i.origin),
        lastPurchasePrice: Value(i.lastPurchasePrice),
        lastPurchasePlace: Value(i.lastPurchasePlace),
        userPhotoUrl: Value(i.userPhotoUrl),
        lastModified: Value(i.lastModified),
      );

  /// Bar first, then pantry — seed/default lastKnownPrice + place.
  Future<({double? price, String? place})> _catalogPricePlace(
      String name) async {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return (price: null, place: null);
    final bar = await db.select(db.barIngredients).get();
    for (final r in bar) {
      if (r.name.toLowerCase().trim() == lower) {
        return (price: r.lastKnownPrice, place: r.lastPurchasePlace);
      }
    }
    final pantry = await db.select(db.pantryIngredients).get();
    for (final r in pantry) {
      if (r.name.toLowerCase().trim() == lower) {
        return (price: r.lastKnownPrice, place: r.lastPurchasePlace);
      }
    }
    return (price: null, place: null);
  }

  /// Push price/place from a shopping edit onto matching bar + pantry rows.
  Future<void> _syncCatalogFromShopping(ShoppingItem item) async {
    final lower = item.name.toLowerCase().trim();
    if (lower.isEmpty) return;
    final barRows = await db.select(db.barIngredients).get();
    for (final r in barRows) {
      if (r.name.toLowerCase().trim() != lower) continue;
      await (db.update(db.barIngredients)..where((t) => t.id.equals(r.id)))
          .write(BarIngredientsCompanion(
        lastKnownPrice: Value(item.lastPurchasePrice),
        lastPurchasePlace: Value(item.lastPurchasePlace),
        lastModified: Value(DateTime.now().toUtc()),
      ));
    }
    final pantryRows = await db.select(db.pantryIngredients).get();
    for (final r in pantryRows) {
      if (r.name.toLowerCase().trim() != lower) continue;
      await (db.update(db.pantryIngredients)..where((t) => t.id.equals(r.id)))
          .write(PantryIngredientsCompanion(
        lastKnownPrice: Value(item.lastPurchasePrice),
        lastPurchasePlace: Value(item.lastPurchasePlace),
        lastModified: Value(DateTime.now().toUtc()),
      ));
    }
  }

  @override
  Stream<List<ShoppingCategory>> watchCategories() {
    return db.select(db.shoppingCategories).watch().map((rows) {
      final all = rows.map(_catToDomain).toList();
      return all..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    });
  }

  @override
  Stream<List<ShoppingItem>> watchItems(String categoryId) {
    // Include hidden (soft-deleted) rows so UI can honor showHiddenItems.
    // Callers filter: trip estimates / export / cart-name set still exclude them.
    return db.select(db.shoppingItems).watch().map((rows) => rows
        .map(_itemToDomain)
        .where((i) => i.categorySupabaseId == categoryId)
        .toList());
  }

  @override
  Stream<Set<String>> watchAllItemNames() {
    // Pending cart only — bought items leave the blue "in shopping" state.
    return db.select(db.shoppingItems).watch().map((rows) => rows
        .map(_itemToDomain)
        .where((i) => !i.isHidden && !i.isBought)
        .map((i) => i.name.toLowerCase().trim())
        .toSet());
  }

  Future<void> _putItem(ShoppingItem item) async {
    final updated = await (db.update(db.shoppingItems)
          ..where((t) => t.supabaseId.equals(item.supabaseId)))
        .write(_itemCompanion(item));
    if (updated == 0) {
      await db.into(db.shoppingItems).insert(_itemCompanion(item));
    }
  }

  @override
  Future<void> toggleBought(ShoppingItem item) async {
    item.isBought = !item.isBought;
    item.lastModified = DateTime.now().toUtc();
    await _putItem(item);
    await syncService.queueOutgoingChange('shopping_items', item.toJson());
    // Buying stocks matching bar/pantry ingredients → cocktail/menu counts refresh.
    if (item.isBought) {
      await _stockIngredientsMatching(item.name, item: item);
    }
  }

  /// Mark matching Bar + Pantry rows in-stock and increment on-hand by
  /// packs × catalog [purchaseSizeBase] (never by current on-hand).
  /// Protein trip lines (unit `2.4kg`) add that trip weight instead.
  Future<void> _stockIngredientsMatching(String name, {ShoppingItem? item}) async {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return;

    const model = QuantityModel();
    final packs = item == null ? 1 : (item.quantity < 1 ? 1 : item.quantity);
    final tripFromUnit = model.measureFromLabel(item?.unit);

    final barRows = await db.select(db.barIngredients).get();
    var barChanged = false;
    for (final row in barRows) {
      if (row.name.toLowerCase().trim() != lower) continue;
      final packSize = row.purchaseSizeBase;
      final add = tripFromUnit ??
          ((packSize != null && packSize > 0) ? packSize * packs : null);
      final current = row.inMyBar ? (row.onHandBase ?? 0) : 0.0;
      final onHand = add == null ? row.onHandBase : current + add;
      await (db.update(db.barIngredients)
            ..where((t) => t.supabaseId.equals(row.supabaseId)))
          .write(BarIngredientsCompanion(
            inMyBar: const Value(true),
            onHandBase: onHand == null ? const Value.absent() : Value(onHand),
            onHandUnit: Value(row.onHandUnit ?? row.purchaseBaseUnit),
            lastModified: Value(DateTime.now().toUtc()),
          ));
      barChanged = true;
    }

    final pantryRows = await db.select(db.pantryIngredients).get();
    var pantryChanged = false;
    for (final row in pantryRows) {
      if (row.name.toLowerCase().trim() != lower) continue;
      final packSize = row.purchaseSizeBase;
      final add = tripFromUnit ??
          ((packSize != null && packSize > 0) ? packSize * packs : null);
      final current = row.inMyPantry ? (row.quantity ?? 0) : 0.0;
      final onHand = add == null ? row.quantity : current + add;
      await (db.update(db.pantryIngredients)
            ..where((t) => t.supabaseId.equals(row.supabaseId)))
          .write(PantryIngredientsCompanion(
            inMyPantry: const Value(true),
            quantity: onHand == null ? const Value.absent() : Value(onHand),
            unit: Value(row.unit ?? row.purchaseBaseUnit),
            lastModified: Value(DateTime.now().toUtc()),
          ));
      pantryChanged = true;
    }

    if (barChanged || pantryChanged) {
      await _recipeRepo.syncMissingIngredientCounts();
    }
  }

  @override
  Future<bool> ensureInShopping({
    required String name,
    required String origin,
    int quantity = 1,
    String? unit,
    String categorySupabaseId = 'cat-misc',
  }) async {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return false;

    final existing = await db.select(db.shoppingItems).get();
    final pending = existing
        .map(_itemToDomain)
        .where((i) =>
            !i.isHidden &&
            !i.isBought &&
            i.name.toLowerCase().trim() == lower)
        .toList();
    if (pending.isNotEmpty) {
      return false;
    }

    final catalog = await _catalogPricePlace(name);
    final slug = lower.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final item = ShoppingItem()
      ..supabaseId =
          'shop_${origin}_${slug}_${DateTime.now().millisecondsSinceEpoch}'
      ..categorySupabaseId = categorySupabaseId
      ..name = name.trim()
      ..quantity = quantity < 1 ? 1 : quantity
      ..unit = unit
      ..origin = origin
      ..lastPurchasePrice = catalog.price
      ..lastPurchasePlace = catalog.place
      ..isBundled = false;
    await addItem(item);
    return true;
  }

  @override
  Future<bool> ensurePacksInShopping({
    required String name,
    required String origin,
    int packs = 1,
    ShopPackMerge merge = ShopPackMerge.setMin,
    String? note,
    String? unitOverride,
    double? priceOverride,
  }) async {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return false;
    final requested = packs < 1 ? 1 : packs;

    PurchaseSpec spec = const PurchaseSpec(noun: 'pack');
    final bar = await db.select(db.barIngredients).get();
    for (final r in bar) {
      if (r.name.toLowerCase().trim() == lower) {
        spec = PurchaseSpec.fromFields(
          purchaseSizeBase: r.purchaseSizeBase,
          purchaseBaseUnit: r.purchaseBaseUnit,
          purchaseNoun: r.purchaseNoun,
          unitsPerPurchase: r.unitsPerPurchase,
          innerSizeBase: r.innerSizeBase,
          price: r.lastKnownPrice,
        );
        break;
      }
    }
    if (!spec.hasSize) {
      final pantry = await db.select(db.pantryIngredients).get();
      for (final r in pantry) {
        if (r.name.toLowerCase().trim() == lower) {
          spec = PurchaseSpec.fromFields(
            purchaseSizeBase: r.purchaseSizeBase,
            purchaseBaseUnit: r.purchaseBaseUnit,
            purchaseNoun: r.purchaseNoun,
            unitsPerPurchase: r.unitsPerPurchase,
            innerSizeBase: r.innerSizeBase,
            price: r.lastKnownPrice,
          );
          break;
        }
      }
    }

    final unit = (unitOverride != null && unitOverride.trim().isNotEmpty)
        ? unitOverride.trim()
        : spec.unitLabel;
    final price = priceOverride ?? spec.pricePerUnit;
    final catalog = await _catalogPricePlace(name);

    final existing = await db.select(db.shoppingItems).get();
    final pending = existing
        .map(_itemToDomain)
        .where((i) =>
            !i.isHidden &&
            !i.isBought &&
            i.name.toLowerCase().trim() == lower)
        .toList();
    if (pending.isNotEmpty) {
      final line = pending.first;
      final next = merge == ShopPackMerge.increment
          ? line.quantity + requested
          : (line.quantity > requested ? line.quantity : requested);
      if (next == line.quantity &&
          (note == null || note == line.notes) &&
          (line.unit == unit)) {
        return false;
      }
      line
        ..quantity = next
        ..unit = unit
        ..lastPurchasePrice = price ?? line.lastPurchasePrice
        ..notes = note ?? line.notes
        ..lastModified = DateTime.now().toUtc();
      await updateItem(line);
      return true;
    }

    final slug = lower.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final item = ShoppingItem()
      ..supabaseId =
          'shop_${origin}_${slug}_${DateTime.now().millisecondsSinceEpoch}'
      ..categorySupabaseId = 'cat-misc'
      ..name = name.trim()
      ..quantity = requested
      ..unit = unit
      ..origin = origin
      ..notes = note
      ..lastPurchasePrice = price ?? catalog.price
      ..lastPurchasePlace = catalog.place
      ..isBundled = false;
    await addItem(item);
    return true;
  }

  @override
  Future<int> markPendingBoughtByName(String name) async {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return 0;
    final pending = (await db.select(db.shoppingItems).get())
        .map(_itemToDomain)
        .where((i) =>
            !i.isHidden &&
            !i.isBought &&
            i.name.toLowerCase().trim() == lower)
        .toList();
    for (final item in pending) {
      // toggleBought handles stock sync when becoming bought.
      if (!item.isBought) await toggleBought(item);
    }
    return pending.length;
  }

  @override
  Future<int> clearBoughtItems() async {
    final bought = (await db.select(db.shoppingItems).get())
        .map(_itemToDomain)
        .where((i) => i.isBought && !i.isHidden)
        .toList();
    for (final item in bought) {
      await permanentlyDelete(item);
    }
    return bought.length;
  }

  @override
  Future<void> hideItem(ShoppingItem item) async {
    item.isHidden = true;
    item.lastModified = DateTime.now().toUtc();
    await _putItem(item);
    await syncService.queueOutgoingChange('shopping_items', item.toJson());
  }

  @override
  Future<void> unhideItem(ShoppingItem item) async {
    item.isHidden = false;
    item.lastModified = DateTime.now().toUtc();
    await _putItem(item);
    await syncService.queueOutgoingChange('shopping_items', item.toJson());
  }

  @override
  Future<void> permanentlyDelete(ShoppingItem item) async {
    await (db.delete(db.shoppingItems)
          ..where((t) => t.supabaseId.equals(item.supabaseId)))
        .go();
    await syncService.queueOutgoingChange(
      'shopping_items',
      {'supabaseId': item.supabaseId},
      isDelete: true,
    );
  }

  /// Ensures [preferredId] (or `cat-misc`) exists so list UI can find the item.
  Future<String> _resolveCategoryId(String preferredId) async {
    final cats = await db.select(db.shoppingCategories).get();
    if (cats.any((c) => c.supabaseId == preferredId)) return preferredId;
    if (cats.any((c) => c.supabaseId == 'cat-misc')) return 'cat-misc';
    // Empty DB or missing seed — create a catch-all category.
    const miscId = 'cat-misc';
    await db.into(db.shoppingCategories).insert(
          ShoppingCategoriesCompanion.insert(
            supabaseId: const Value(miscId),
            boatSupabaseId:
                const Value('00000000-0000-0000-0000-000000000000'),
            name: const Value('Miscellaneous'),
            sortOrder: const Value(0),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return miscId;
  }

  @override
  Future<void> addItem(ShoppingItem item) async {
    // Manual add used a non-existent `default_category` id → item saved but
    // invisible (UI only loads items under real category ids).
    final preferred = item.categorySupabaseId.trim().isEmpty ||
            item.categorySupabaseId == 'default_category'
        ? 'cat-misc'
        : item.categorySupabaseId;
    item.categorySupabaseId = await _resolveCategoryId(preferred);
    item.lastModified = DateTime.now().toUtc();
    await db.into(db.shoppingItems).insert(_itemCompanion(item));
    await syncService.queueOutgoingChange('shopping_items', item.toJson());
  }

  @override
  Future<void> updateItem(ShoppingItem item) async {
    item.lastModified = DateTime.now().toUtc();
    await _putItem(item);
    await syncService.queueOutgoingChange('shopping_items', item.toJson());
    // Keep bar/pantry catalog price & place in sync for future trips.
    await _syncCatalogFromShopping(item);
  }

  @override
  Future<int> applyPricePlaceToPendingByName({
    required String name,
    double? price,
    String? place,
  }) async {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return 0;
    final pending = (await db.select(db.shoppingItems).get())
        .map(_itemToDomain)
        .where((i) =>
            !i.isHidden &&
            !i.isBought &&
            i.name.toLowerCase().trim() == lower)
        .toList();
    for (final item in pending) {
      item
        ..lastPurchasePrice = price
        ..lastPurchasePlace = place;
      await updateItem(item);
    }
    return pending.length;
  }

  @override
  Future<int> backfillMissingPricesFromCatalog() async {
    final rows = (await db.select(db.shoppingItems).get()).map(_itemToDomain);
    var n = 0;
    for (final item in rows) {
      if (item.lastPurchasePrice != null &&
          (item.lastPurchasePlace != null &&
              item.lastPurchasePlace!.isNotEmpty)) {
        continue;
      }
      final catalog = await _catalogPricePlace(item.name);
      var changed = false;
      if (item.lastPurchasePrice == null && catalog.price != null) {
        item.lastPurchasePrice = catalog.price;
        changed = true;
      }
      if ((item.lastPurchasePlace == null ||
              item.lastPurchasePlace!.isEmpty) &&
          catalog.place != null) {
        item.lastPurchasePlace = catalog.place;
        changed = true;
      }
      if (changed) {
        item.lastModified = DateTime.now().toUtc();
        await _putItem(item);
        n++;
      }
    }
    return n;
  }

  @override
  Future<void> addCategory(ShoppingCategory category) async {
    category.lastModified = DateTime.now().toUtc();
    await db.into(db.shoppingCategories).insert(ShoppingCategoriesCompanion(
          supabaseId: Value(category.supabaseId),
          boatSupabaseId: Value(category.boatSupabaseId),
          name: Value(category.name),
          sortOrder: Value(category.sortOrder),
          isSynced: Value(category.isSynced),
          lastModified: Value(category.lastModified),
        ));
    await syncService.queueOutgoingChange(
        'shopping_categories', category.toJson());
  }
}
