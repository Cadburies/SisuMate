import '../../models/models.dart';

abstract class ChecklistRepository {
  Stream<List<ChecklistItem>> watchItems(String groupSupabaseId);
  Stream<List<ChecklistGroup>> watchGroups({String? appType});
  /// All items across every non-hidden group of [appType], in one query/
  /// subscription — for callers that would otherwise fan out into N
  /// per-group `watchItems` watches (#207: that pattern caused a cascade of
  /// simultaneous provider dispose/rebuild events fragile enough to race a
  /// screen's build, since each per-group watch redundantly re-filters the
  /// same whole-table stream instead of a single scoped query).
  Stream<List<ChecklistItem>> watchItemsForAppType(String appType);
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
