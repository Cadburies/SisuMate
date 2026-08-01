import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/inventory_item_repository_impl.dart';
import 'package:sisu_mate/data/repositories/shopping_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/import_service.dart';
import 'package:sisu_mate/ui/components/import_export.dart';

import 'test_helpers/db_test_helper.dart';

/// TEST14 — export → empty-DB re-import round-trip (shopping + inventory) and
/// safe rejection of bad JSON / future format versions.
///
/// Persist paths mirror the screens (`ShoppingScreen._importShopping` and
/// inventory `ModuleImportExport.persist`) so a green suite means the real
/// repository write path, not only pure parse/export.
void main() {
  group('TEST14 — pure export → parse round-trip (names/counts)', () {
    test('shopping sample export re-imports same names and quantities', () {
      final original =
          ImportService.parse(ImportService.sampleFor(ImportService.kindShopping));
      final json = ImportService.exportShopping(original.shoppingItems);
      final round = ImportService.parse(json);

      expect(round.kind, ImportService.kindShopping);
      expect(round.count, original.count);
      expect(
        round.shoppingItems.map((s) => s.item.name).toList(),
        original.shoppingItems.map((s) => s.item.name).toList(),
      );
      expect(
        round.shoppingItems.map((s) => s.item.quantity).toList(),
        original.shoppingItems.map((s) => s.item.quantity).toList(),
      );
    });

    test('inventory sample export re-imports same names and quantities', () {
      final original = ImportService.parse(
          ImportService.sampleFor(ImportService.kindInventory));
      final json = ImportService.exportInventory(original.inventoryItems);
      final round = ImportService.parse(json);

      expect(round.kind, ImportService.kindInventory);
      expect(round.count, original.count);
      expect(
        round.inventoryItems.map((i) => i.name).toList(),
        original.inventoryItems.map((i) => i.name).toList(),
      );
      expect(
        round.inventoryItems.map((i) => i.quantity).toList(),
        original.inventoryItems.map((i) => i.quantity).toList(),
      );
    });

    test('multi-item shopping JSON preserves count and category origin', () {
      final batch = ImportService.parse(jsonEncode({
        'sisuMateImport': 1,
        'kind': 'shopping',
        'items': [
          {'name': 'Fenders', 'category': 'Deck Gear', 'quantity': 4},
          {'name': 'Impeller', 'category': 'Engine', 'quantity': 1},
          {'name': 'Line', 'category': 'Deck Gear', 'quantity': 2, 'unit': 'm'},
        ],
      }));
      final json = ImportService.exportShopping(batch.shoppingItems);
      final round = ImportService.parse(json);
      expect(round.count, 3);
      expect(
        round.shoppingItems.map((s) => s.item.name).toSet(),
        {'Fenders', 'Impeller', 'Line'},
      );
      expect(
        round.shoppingItems.map((s) => s.item.origin).toSet(),
        {'Deck Gear', 'Engine'},
      );
    });
  });

  group('TEST14 — empty Drift DB: shopping export → import → export', () {
    late AppDatabase db;
    late ShoppingRepositoryImpl shop;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      shop = ShoppingRepositoryImpl(db, testSyncService());
    });

    tearDown(() async => db.close());

    Future<ImportPersistResult> persistShopping(ImportBatch batch) async {
      final existingCats = await shop.watchCategories().first;
      final byName = {
        for (final c in existingCats) c.name.toLowerCase(): c.supabaseId
      };
      final existingItems = <ShoppingItem>[];
      for (final cat in existingCats) {
        existingItems.addAll(
          (await shop.watchItems(cat.supabaseId).first)
              .where((i) => !i.isHidden),
        );
      }
      var inserted = 0;
      var updated = 0;
      for (final rec in batch.shoppingItems) {
        final catName =
            (rec.categoryName == null || rec.categoryName!.isEmpty)
                ? 'Imported'
                : rec.categoryName!;
        var catId = byName[catName.toLowerCase()];
        if (catId == null) {
          final cat = ShoppingCategory()
            ..supabaseId =
                'imp_cat_${DateTime.now().millisecondsSinceEpoch}_${byName.length}'
            ..name = catName
            ..sortOrder = existingCats.length + byName.length;
          await shop.addCategory(cat);
          catId = cat.supabaseId;
          byName[catName.toLowerCase()] = catId;
        }
        rec.item.categorySupabaseId = catId;
        final match = ImportService.matchExisting(
          existing: existingItems,
          incomingId: rec.item.supabaseId,
          idOf: (e) => e.supabaseId,
          contentKeyOf: ImportService.contentKeyShopping,
          incomingContentKey: ImportService.contentKeyShopping(rec.item),
        );
        if (match != null) {
          rec.item.supabaseId = match.supabaseId;
          rec.item.id = match.id;
          await shop.updateItem(rec.item);
          updated++;
        } else {
          await shop.addItem(rec.item);
          existingItems.add(rec.item);
          inserted++;
        }
      }
      return ImportPersistResult(inserted: inserted, updated: updated);
    }

    Future<String> exportShoppingFromDb() async {
      final cats = await shop.watchCategories().first;
      final items = <ImportedShoppingItem>[];
      for (final c in cats) {
        for (final it in await shop.watchItems(c.supabaseId).first) {
          if (it.isHidden) continue;
          items.add(ImportedShoppingItem(it, c.name));
        }
      }
      return ImportService.exportShopping(items);
    }

    test('empty DB import shopping then re-export matches names/counts',
        () async {
      // Empty DB precondition.
      expect(await shop.watchCategories().first, isEmpty);

      final source = ImportService.parse(jsonEncode({
        'sisuMateImport': 1,
        'kind': 'shopping',
        'items': [
          {'name': 'Winch Grease', 'category': 'Deck', 'quantity': 2},
          {'name': 'Zinc Anode', 'category': 'Engine', 'quantity': 3},
        ],
      }));
      final result = await persistShopping(source);
      expect(result.inserted, 2);
      expect(result.updated, 0);

      final cats = await shop.watchCategories().first;
      final allNames = <String>[];
      for (final c in cats) {
        allNames.addAll(
          (await shop.watchItems(c.supabaseId).first).map((i) => i.name),
        );
      }
      expect(allNames.toSet(), {'Winch Grease', 'Zinc Anode'});
      expect(allNames, hasLength(2));

      final reExported = await exportShoppingFromDb();
      final round = ImportService.parse(reExported);
      expect(round.count, 2);
      expect(
        round.shoppingItems.map((s) => s.item.name).toSet(),
        {'Winch Grease', 'Zinc Anode'},
      );
      final byName = {
        for (final s in round.shoppingItems) s.item.name: s.item.quantity
      };
      expect(byName['Winch Grease'], 2);
      expect(byName['Zinc Anode'], 3);
    });

    test('failed parse leaves shopping tables empty (no partial write)',
        () async {
      expect(
        () => ImportService.parse('{"sisuMateImport":1,"kind":"shopping"}'),
        throwsA(isA<ImportException>()),
      );
      // Callers never call persist on parse failure — DB stays empty.
      expect(await shop.watchCategories().first, isEmpty);
      final all = await db.select(db.shoppingItems).get();
      expect(all, isEmpty);
    });
  });

  group('TEST14 — empty Drift DB: inventory export → import → export', () {
    late AppDatabase db;
    late InventoryItemRepositoryImpl inv;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      inv = InventoryItemRepositoryImpl(db, testSyncService());
    });

    tearDown(() async => db.close());

    Future<ImportPersistResult> persistInventory(ImportBatch batch) async {
      final existing = await inv.watchInventoryItems().first;
      var inserted = 0;
      var updated = 0;
      for (final it in batch.inventoryItems) {
        final match = ImportService.matchExisting(
          existing: existing,
          incomingId: it.supabaseId,
          idOf: (e) => e.supabaseId,
          contentKeyOf: ImportService.contentKeyInventory,
          incomingContentKey: ImportService.contentKeyInventory(it),
        );
        if (match != null) {
          it.supabaseId = match.supabaseId;
          it.id = match.id;
          await inv.updateInventoryItem(it);
          updated++;
        } else {
          await inv.addInventoryItem(it);
          existing.add(it);
          inserted++;
        }
      }
      return ImportPersistResult(inserted: inserted, updated: updated);
    }

    test('empty DB import inventory then re-export matches names/counts',
        () async {
      expect(await inv.watchInventoryItems().first, isEmpty);

      final source = ImportService.parse(jsonEncode({
        'sisuMateImport': 1,
        'kind': 'inventory',
        'items': [
          {
            'name': 'Flares',
            'location': 'Grab bag',
            'quantity': 6,
            'unit': 'pcs',
          },
          {
            'name': 'Lifejackets',
            'location': 'Cabin',
            'quantity': 4,
            'unit': 'pcs',
          },
        ],
      }));
      final result = await persistInventory(source);
      expect(result.inserted, 2);
      expect(result.updated, 0);

      final stored = await inv.watchInventoryItems().first;
      expect(stored.map((i) => i.name).toSet(), {'Flares', 'Lifejackets'});
      expect(stored, hasLength(2));

      final reExported = ImportService.exportInventory(stored);
      final round = ImportService.parse(reExported);
      expect(round.count, 2);
      expect(
        round.inventoryItems.map((i) => i.name).toSet(),
        {'Flares', 'Lifejackets'},
      );
      final byName = {
        for (final i in round.inventoryItems) i.name: i.quantity
      };
      expect(byName['Flares'], 6);
      expect(byName['Lifejackets'], 4);
    });
  });

  group('TEST14 — bad JSON / future version → safe user-facing errors', () {
    test('non-JSON has display message for "Couldn\'t import" dialog', () {
      try {
        ImportService.parse('not json at all {{{');
        fail('expected ImportException');
      } on ImportException catch (e) {
        expect(e.display, isNotEmpty);
        expect(e.display, isNot(contains('Exception')));
        expect(e.display.toLowerCase(), contains('json'));
      }
    });

    test('future format version message is user-safe (no stack / type dump)',
        () {
      try {
        ImportService.parse(jsonEncode({
          'sisuMateImport': 999,
          'kind': 'shopping',
          'items': [
            {'name': 'x'},
          ],
        }));
        fail('expected ImportException');
      } on ImportException catch (e) {
        expect(e.display, contains('newer version'));
        expect(e.display, isNot(contains('FormatException')));
        expect(e.display, isNot(contains('#'))); // no stack frames
      }
    });

    test('malformed item does not parse — all-or-nothing (no batch returned)',
        () {
      expect(
        () => ImportService.parse(jsonEncode({
          'sisuMateImport': 1,
          'kind': 'inventory',
          'items': [
            {'name': 'Good'},
            {'quantity': 2}, // missing name
          ],
        })),
        throwsA(predicate((e) =>
            e is ImportException &&
            e.itemIndex == 1 &&
            e.display.startsWith('Item 2:'))),
      );
    });

    test('ImportPersistResult messages stay UI-safe for snackbars', () {
      expect(const ImportPersistResult(inserted: 2).snackbarMessage,
          'Imported 2 items');
      expect(const ImportPersistResult().snackbarMessage, 'Nothing to import');
    });
  });
}
