import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/inventory_item_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

import '../test_helpers/db_test_helper.dart';

// InventoryItem on Drift (S1), sync-participating.
void main() {
  late AppDatabase db;
  late InventoryItemRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = InventoryItemRepositoryImpl(db, testSyncService());
  });

  tearDown(() async => db.close());

  group('InventoryItemRepositoryImpl (Drift) CRUD', () {
    test('Create: addInventoryItem persists a new item', () async {
      await repo.addInventoryItem(InventoryItem()
        ..supabaseId = 'inv_1'
        ..name = 'Fenders'
        ..location = 'Lazarette'
        ..quantity = 4
        ..unit = 'pcs');

      final all = await repo.watchInventoryItems().first;
      expect(all, hasLength(1));
      expect(all.single.name, 'Fenders');
      expect(all.single.quantity, 4);
      expect(all.single.location, 'Lazarette');
    });

    test('Read: watchInventoryItems emits items sorted by name', () async {
      await repo.addInventoryItem(InventoryItem()
        ..supabaseId = 'inv_z'
        ..name = 'Winch handle');
      await repo.addInventoryItem(InventoryItem()
        ..supabaseId = 'inv_a'
        ..name = 'Anchor chain');

      final items = await repo.watchInventoryItems().first;
      expect(items.map((i) => i.name), ['Anchor chain', 'Winch handle']);
    });

    test('Update: updateInventoryItem persists field changes', () async {
      final item = InventoryItem()
        ..supabaseId = 'inv_1'
        ..name = 'Flares'
        ..quantity = 6;
      await repo.addInventoryItem(item);

      item
        ..quantity = 3
        ..serialNumber = 'SN-99';
      await repo.updateInventoryItem(item);

      final all = await repo.watchInventoryItems().first;
      expect(all, hasLength(1));
      expect(all.single.quantity, 3);
      expect(all.single.serialNumber, 'SN-99');
    });

    test('#320: updateInventoryItem appends quantityHistory when qty changes',
        () async {
      final item = InventoryItem()
        ..supabaseId = 'inv_1'
        ..name = 'Flares'
        ..quantity = 6;
      await repo.addInventoryItem(item);

      item.quantity = 3;
      await repo.updateInventoryItem(item);

      var all = await repo.watchInventoryItems().first;
      expect(all.single.quantity, 3);
      expect(all.single.quantityHistory, hasLength(1));
      expect(all.single.quantityHistory.single.from, 6);
      expect(all.single.quantityHistory.single.to, 3);

      item.quantity = 8;
      await repo.updateInventoryItem(item);
      all = await repo.watchInventoryItems().first;
      expect(all.single.quantityHistory, hasLength(2));
      expect(all.single.quantityHistory.last.from, 3);
      expect(all.single.quantityHistory.last.to, 8);
      expect(all.single.quantityHistory.last.isRestock, isTrue);

      // Name-only edit must not grow the log.
      item.name = 'Handheld flares';
      await repo.updateInventoryItem(item);
      all = await repo.watchInventoryItems().first;
      expect(all.single.quantityHistory, hasLength(2));
    });

    test('#319: linkedMaintenanceItemSupabaseId round-trips through add and update',
        () async {
      final item = InventoryItem()
        ..supabaseId = 'inv_1'
        ..name = 'Spare impeller'
        ..linkedMaintenanceItemSupabaseId = 'maint_impeller';
      await repo.addInventoryItem(item);

      var all = await repo.watchInventoryItems().first;
      expect(all.single.linkedMaintenanceItemSupabaseId, 'maint_impeller');

      item.linkedMaintenanceItemSupabaseId = null;
      await repo.updateInventoryItem(item);

      all = await repo.watchInventoryItems().first;
      expect(all.single.linkedMaintenanceItemSupabaseId, isNull);
    });

    test('#318: barcode round-trips through add and update', () async {
      final item = InventoryItem()
        ..supabaseId = 'inv_1'
        ..name = 'Raw water impeller'
        ..barcode = '012345678905';
      await repo.addInventoryItem(item);

      var all = await repo.watchInventoryItems().first;
      expect(all.single.barcode, '012345678905');

      item.barcode = '098765432109';
      await repo.updateInventoryItem(item);

      all = await repo.watchInventoryItems().first;
      expect(all.single.barcode, '098765432109');
    });

    test('Delete: deleteInventoryItem removes it', () async {
      final item = InventoryItem()
        ..supabaseId = 'inv_1'
        ..name = 'To Be Deleted';
      await repo.addInventoryItem(item);
      expect(await repo.watchInventoryItems().first, hasLength(1));

      await repo.deleteInventoryItem(item);
      expect(await repo.watchInventoryItems().first, isEmpty);
    });
  });
}
