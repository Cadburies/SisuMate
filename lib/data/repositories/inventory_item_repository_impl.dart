import 'dart:convert';

import 'package:drift/drift.dart';
import '../../domain/repositories/inventory_item_repository.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../services/sync_service.dart';

/// InventoryItem on Drift (S1); sync-participating.
class InventoryItemRepositoryImpl implements InventoryItemRepository {
  final AppDatabase db;
  final SyncService syncService;

  InventoryItemRepositoryImpl(this.db, this.syncService);

  InventoryItem _toDomain(InventoryItemRow r) => InventoryItem()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..name = r.name
    ..location = r.location
    ..quantity = r.quantity
    ..unit = r.unit
    ..serialNumber = r.serialNumber
    ..notes = r.notes
    ..localPath = r.localPath
    ..barcode = r.barcode
    ..linkedMaintenanceItemSupabaseId = r.linkedMaintenanceItemSupabaseId
    ..quantityHistory = parseInventoryQtyHistory(r.quantityHistory)
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  InventoryItemsCompanion _toCompanion(InventoryItem i) =>
      InventoryItemsCompanion(
        supabaseId: Value(i.supabaseId),
        boatSupabaseId: Value(i.boatSupabaseId),
        name: Value(i.name),
        location: Value(i.location),
        quantity: Value(i.quantity),
        unit: Value(i.unit),
        serialNumber: Value(i.serialNumber),
        notes: Value(i.notes),
        localPath: Value(i.localPath),
        barcode: Value(i.barcode),
        linkedMaintenanceItemSupabaseId:
            Value(i.linkedMaintenanceItemSupabaseId),
        quantityHistory: Value(
            jsonEncode(i.quantityHistory.map((e) => e.toJson()).toList())),
        isSynced: Value(i.isSynced),
        lastModified: Value(i.lastModified),
      );

  @override
  Stream<List<InventoryItem>> watchInventoryItems() {
    return db.select(db.inventoryItems).watch().map((rows) {
      final all = rows.map(_toDomain).toList();
      return all
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
  }

  @override
  Future<void> addInventoryItem(InventoryItem item) async {
    item.lastModified = DateTime.now().toUtc();
    await db.into(db.inventoryItems).insert(_toCompanion(item));
    await syncService.queueOutgoingChange('inventory_items', item.toJson());
  }

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {
    final existing = await (db.select(db.inventoryItems)
          ..where((t) => t.supabaseId.equals(item.supabaseId)))
        .getSingleOrNull();
    if (existing != null && existing.quantity != item.quantity) {
      final prior = parseInventoryQtyHistory(existing.quantityHistory);
      item.quantityHistory = [
        ...prior,
        InventoryQtyChange(
          at: DateTime.now().toUtc(),
          from: existing.quantity,
          to: item.quantity,
        ),
      ];
    }
    item.lastModified = DateTime.now().toUtc();
    await (db.update(db.inventoryItems)
          ..where((t) => t.supabaseId.equals(item.supabaseId)))
        .write(_toCompanion(item));
    await syncService.queueOutgoingChange('inventory_items', item.toJson());
  }

  @override
  Future<void> deleteInventoryItem(InventoryItem item) async {
    await (db.delete(db.inventoryItems)
          ..where((t) => t.supabaseId.equals(item.supabaseId)))
        .go();
    await syncService.queueOutgoingChange(
      'inventory_items',
      {'supabaseId': item.supabaseId},
      isDelete: true,
    );
  }
}
