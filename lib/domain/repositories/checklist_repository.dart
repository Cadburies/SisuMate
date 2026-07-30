import '../../models/models.dart';

abstract class ChecklistRepository {
  Stream<List<ChecklistItem>> watchItems(String groupSupabaseId);
  Stream<List<ChecklistGroup>> watchGroups({String? appType});
  Future<List<ChecklistItem>> getItemsByGroup(String groupSupabaseId);
  Future<void> toggleComplete(ChecklistItem item);
  Future<void> hideItem(ChecklistItem item);
  Future<void> unhideItem(ChecklistItem item);
  Future<void> permanentlyDelete(ChecklistItem item);
  Future<void> addItem(ChecklistItem item);
  Future<void> updateItem(ChecklistItem item);
  Future<void> resetToFactoryDefaults(String appType);
  Future<void> createGroup(ChecklistGroup group);
}
