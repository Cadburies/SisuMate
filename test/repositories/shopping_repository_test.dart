import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/bar_ingredient_repository_impl.dart';
import 'package:sisu_mate/data/repositories/pantry_ingredient_repository_impl.dart';
import 'package:sisu_mate/data/repositories/shopping_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

import '../test_helpers/db_test_helper.dart';

// Shopping (categories + items) on Drift (S1), sync-participating.
void main() {
  late AppDatabase db;
  late ShoppingRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ShoppingRepositoryImpl(db, testSyncService());
  });

  tearDown(() async => db.close());

  Future<void> seedCategory(String id, {String name = 'Cat'}) async {
    await repo.addCategory(ShoppingCategory()
      ..supabaseId = id
      ..name = name
      ..sortOrder = 0);
  }

  group('ShoppingRepositoryImpl (Drift) CRUD', () {
    test('Create: addItem persists a new shopping item', () async {
      await seedCategory('cat_1');
      await repo.addItem(ShoppingItem()
        ..supabaseId = 'item_1'
        ..categorySupabaseId = 'cat_1'
        ..name = 'Engine Oil');

      final all = await repo.watchItems('cat_1').first;
      expect(all, hasLength(1));
      expect(all.single.name, 'Engine Oil');
    });

    test('Create: empty/default_category resolves to cat-misc so UI can show it',
        () async {
      await repo.addItem(ShoppingItem()
        ..supabaseId = 'item_orphan'
        ..categorySupabaseId = 'default_category'
        ..name = 'Orphan');
      await repo.addItem(ShoppingItem()
        ..supabaseId = 'item_empty'
        ..categorySupabaseId = ''
        ..name = 'Empty Cat');

      final items = await repo.watchItems('cat-misc').first;
      expect(items.map((i) => i.name).toSet(), {'Orphan', 'Empty Cat'});
      expect(items.every((i) => i.categorySupabaseId == 'cat-misc'), isTrue);
    });

    test('Read: watchItems filters by category and includes hidden items (SHOP1)',
        () async {
      await seedCategory('cat_1');
      await seedCategory('cat_2');
      await repo.addItem(ShoppingItem()
        ..supabaseId = 'item_a'
        ..categorySupabaseId = 'cat_1'
        ..name = 'In category, visible');
      await repo.addItem(ShoppingItem()
        ..supabaseId = 'item_b'
        ..categorySupabaseId = 'cat_1'
        ..name = 'In category, hidden'
        ..isHidden = true);
      await repo.addItem(ShoppingItem()
        ..supabaseId = 'item_c'
        ..categorySupabaseId = 'cat_2'
        ..name = 'Other category');

      final items = await repo.watchItems('cat_1').first;
      // UI filters with showHiddenItems; repo must surface soft-deleted rows.
      expect(items.map((i) => i.name).toSet(),
          {'In category, visible', 'In category, hidden'});
      expect(items.where((i) => i.isHidden).single.name, 'In category, hidden');
    });

    test('SHOP1: hide → unhide → permanentlyDelete', () async {
      await seedCategory('cat_1');
      final item = ShoppingItem()
        ..supabaseId = 'item_hide'
        ..categorySupabaseId = 'cat_1'
        ..name = 'Soft then hard';
      await repo.addItem(item);

      await repo.hideItem(item);
      var items = await repo.watchItems('cat_1').first;
      expect(items.single.isHidden, isTrue);

      await repo.unhideItem(item);
      items = await repo.watchItems('cat_1').first;
      expect(items.single.isHidden, isFalse);

      await repo.hideItem(item);
      await repo.permanentlyDelete(item);
      items = await repo.watchItems('cat_1').first;
      expect(items, isEmpty);
    });

    test('Update: toggleBought flips isBought and persists it', () async {
      await seedCategory('cat_1');
      final item = ShoppingItem()
        ..supabaseId = 'item_1'
        ..categorySupabaseId = 'cat_1'
        ..name = 'Engine Oil';
      await repo.addItem(item);
      expect(item.isBought, isFalse);

      await repo.toggleBought(item);

      final all = await repo.watchItems('cat_1').first;
      expect(all.single.isBought, isTrue);
    });

    test('Delete: permanentlyDelete removes it from the database', () async {
      await seedCategory('cat_1');
      final item = ShoppingItem()
        ..supabaseId = 'item_1'
        ..categorySupabaseId = 'cat_1'
        ..name = 'To remove';
      await repo.addItem(item);

      await repo.permanentlyDelete(item);

      final all = await repo.watchItems('cat_1').first;
      expect(all, isEmpty);
    });

    test('Category: addCategory persists and watchCategories emits sorted',
        () async {
      await repo.addCategory(ShoppingCategory()
        ..supabaseId = 'cat_b'
        ..name = 'Belts'
        ..sortOrder = 2);
      await repo.addCategory(ShoppingCategory()
        ..supabaseId = 'cat_a'
        ..name = 'Anodes'
        ..sortOrder = 1);

      final cats = await repo.watchCategories().first;
      expect(cats.map((c) => c.name), ['Anodes', 'Belts']);
    });

    test('ensureInShopping is idempotent by name (case-insensitive)', () async {
      final first = await repo.ensureInShopping(
        name: 'Dark Rum',
        origin: 'bar',
      );
      final second = await repo.ensureInShopping(
        name: 'dark rum',
        origin: 'bar',
      );
      expect(first, isTrue);
      expect(second, isFalse);

      final names = await repo.watchAllItemNames().first;
      expect(names, {'dark rum'});
      final items = await repo.watchItems('cat-misc').first;
      expect(items, hasLength(1));
    });

    test('ensureInShopping copies lastKnownPrice from bar catalog', () async {
      final barRepo = BarIngredientRepositoryImpl(db);
      await barRepo.addBarIngredient(BarIngredient()
        ..supabaseId = 'bar_rum'
        ..name = 'Aged Rum'
        ..lastKnownPrice = 32.0
        ..lastPurchasePlace = 'Duty Free');

      await repo.ensureInShopping(name: 'Aged Rum', origin: 'bar', quantity: 2);
      final items = await repo.watchItems('cat-misc').first;
      expect(items, hasLength(1));
      expect(items.single.lastPurchasePrice, 32.0);
      expect(items.single.lastPurchasePlace, 'Duty Free');
      expect(items.single.lineEstimate, 64.0);
    });

    test('#309 pantry package size must not multiply pack price', () async {
      // Seed shape: Aged Balsamic is 250 ml @ $12/bottle — qty must be 1 pack.
      final pantryRepo = PantryIngredientRepositoryImpl(db);
      await pantryRepo.addPantryIngredient(PantryIngredient()
        ..supabaseId = 'pantry_balsamic'
        ..name = 'Aged Balsamic Vinegar'
        ..quantity = 250
        ..unit = 'ml'
        ..lastKnownPrice = 12.0
        ..lastKnownPriceUnit = '250ml bottle');

      // Catalog add path (mirrors ingredient detail after #309): buy count 1,
      // unit = package label, not 250 × $12.
      await repo.ensureInShopping(
        name: 'Aged Balsamic Vinegar',
        origin: 'pantry',
        quantity: 1,
        unit: '250ml bottle',
      );
      final items = await repo.watchItems('cat-misc').first;
      final line = items.single;
      expect(line.quantity, 1);
      expect(line.unit, '250ml bottle');
      expect(line.lastPurchasePrice, 12.0);
      expect(line.lineEstimate, 12.0);

      // Couscous: 500 g pack @ $4.
      await pantryRepo.addPantryIngredient(PantryIngredient()
        ..supabaseId = 'pantry_couscous'
        ..name = 'Couscous'
        ..quantity = 500
        ..unit = 'g'
        ..lastKnownPrice = 4.0
        ..lastKnownPriceUnit = '500g pack');
      await repo.ensureInShopping(
        name: 'Couscous',
        origin: 'pantry',
        quantity: 1,
        unit: '500g pack',
      );
      final all = await repo.watchItems('cat-misc').first;
      final couscous = all.singleWhere((i) => i.name == 'Couscous');
      expect(couscous.quantity, 1);
      expect(couscous.lineEstimate, 4.0);
    });

    test('updateItem syncs price/place back to bar catalog', () async {
      final barRepo = BarIngredientRepositoryImpl(db);
      await barRepo.addBarIngredient(BarIngredient()
        ..supabaseId = 'bar_gin'
        ..name = 'Gin'
        ..lastKnownPrice = 20.0);

      await repo.ensureInShopping(name: 'Gin', origin: 'bar');
      final items = await repo.watchItems('cat-misc').first;
      final shop = items.single
        ..lastPurchasePrice = 25.5
        ..lastPurchasePlace = 'Marina Store';
      await repo.updateItem(shop);

      final bar = await barRepo.watchBarIngredients().first;
      final gin = bar.singleWhere((b) => b.name == 'Gin');
      expect(gin.lastKnownPrice, 25.5);
      expect(gin.lastPurchasePlace, 'Marina Store');
    });

    test('applyPricePlaceToPendingByName updates outstanding lines', () async {
      await repo.ensureInShopping(name: 'Lime', origin: 'bar', quantity: 3);
      final n = await repo.applyPricePlaceToPendingByName(
        name: 'Lime',
        price: 1.5,
        place: 'Market',
      );
      expect(n, 1);
      final items = await repo.watchItems('cat-misc').first;
      expect(items.single.lastPurchasePrice, 1.5);
      expect(items.single.lineEstimate, 4.5);
      expect(items.single.lastPurchasePlace, 'Market');
    });

    test('watchAllItemNames excludes bought items', () async {
      final item = ShoppingItem()
        ..supabaseId = 'item_1'
        ..categorySupabaseId = 'cat-misc'
        ..name = 'Lime';
      await repo.addItem(item);
      expect(await repo.watchAllItemNames().first, {'lime'});

      await repo.toggleBought(item);
      expect(await repo.watchAllItemNames().first, isEmpty);
    });

    test('markPendingBoughtByName completes cart lines and stocks bar/pantry',
        () async {
      final barRepo = BarIngredientRepositoryImpl(db);
      await barRepo.addBarIngredient(BarIngredient()
        ..supabaseId = 'bar_lime'
        ..name = 'Lime'
        ..inMyBar = false);
      await repo.ensureInShopping(name: 'Lime', origin: 'bar');
      final n = await repo.markPendingBoughtByName('Lime');
      expect(n, 1);
      expect(await repo.watchAllItemNames().first, isEmpty);
      final bar = await barRepo.watchBarIngredients().first;
      expect(bar.singleWhere((b) => b.name == 'Lime').inMyBar, isTrue);
    });

    test('clearBoughtItems removes only bought lines', () async {
      await repo.ensureInShopping(name: 'Rum', origin: 'bar');
      await repo.ensureInShopping(name: 'Sugar', origin: 'bar');
      await repo.markPendingBoughtByName('Rum');
      final cleared = await repo.clearBoughtItems();
      expect(cleared, 1);
      final names = await repo.watchAllItemNames().first;
      expect(names, {'sugar'});
    });

    test('toggleBought stocks matching bar + pantry ingredients by name',
        () async {
      final barRepo = BarIngredientRepositoryImpl(db);
      final pantryRepo = PantryIngredientRepositoryImpl(db);
      await barRepo.addBarIngredient(BarIngredient()
        ..supabaseId = 'bar_rum'
        ..name = 'Dark Rum'
        ..inMyBar = false);
      await pantryRepo.addPantryIngredient(PantryIngredient()
        ..supabaseId = 'pantry_rum'
        ..name = 'Dark Rum'
        ..inMyPantry = false);

      final item = ShoppingItem()
        ..supabaseId = 'shop_rum'
        ..categorySupabaseId = 'cat-misc'
        ..name = 'Dark Rum'
        ..origin = 'bar';
      await repo.addItem(item);
      await repo.toggleBought(item);

      final bar = await barRepo.watchBarIngredients().first;
      final pantry = await pantryRepo.watchPantryIngredients().first;
      expect(bar.singleWhere((b) => b.supabaseId == 'bar_rum').inMyBar, isTrue);
      expect(
          pantry.singleWhere((p) => p.supabaseId == 'pantry_rum').inMyPantry,
          isTrue);
    });
  });
}
