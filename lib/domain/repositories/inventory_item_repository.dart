import '../../models/models.dart';

abstract class InventoryItemRepository {
  Stream<List<InventoryItem>> watchInventoryItems();
  Future<void> addInventoryItem(InventoryItem item);
  Future<void> updateInventoryItem(InventoryItem item);
  Future<void> deleteInventoryItem(InventoryItem item);
}
