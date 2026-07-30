import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../services/sync_service.dart';
import '../../domain/repositories/checklist_repository.dart';

/// Checklist (groups + items) on Drift (S1); sync-participating.
class ChecklistRepositoryImpl implements ChecklistRepository {
  final AppDatabase db;
  final SyncService syncService;

  ChecklistRepositoryImpl(this.db, this.syncService);

  ChecklistGroup _groupToDomain(ChecklistGroupRow r) => ChecklistGroup()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..appType = r.appType
    ..title = r.title
    ..description = r.description
    ..iconName = r.iconName
    ..isBought = r.isBought
    ..isBundled = r.isBundled
    ..isExpanded = r.isExpanded
    ..isHidden = r.isHidden
    ..isSynced = r.isSynced
    ..lastPurchasePrice = r.lastPurchasePrice
    ..notes = r.notes
    ..origin = r.origin
    ..sortOrder = r.sortOrder
    ..lastModified = r.lastModified
    ..communityTemplateId = r.communityTemplateId
    ..communityTemplateVersion = r.communityTemplateVersion;

  ChecklistGroupsCompanion _groupCompanion(ChecklistGroup g) =>
      ChecklistGroupsCompanion(
        supabaseId: Value(g.supabaseId),
        boatSupabaseId: Value(g.boatSupabaseId),
        appType: Value(g.appType),
        title: Value(g.title),
        description: Value(g.description),
        iconName: Value(g.iconName),
        isBought: Value(g.isBought),
        isBundled: Value(g.isBundled),
        isExpanded: Value(g.isExpanded),
        isHidden: Value(g.isHidden),
        isSynced: Value(g.isSynced),
        lastPurchasePrice: Value(g.lastPurchasePrice),
        notes: Value(g.notes),
        origin: Value(g.origin),
        sortOrder: Value(g.sortOrder),
        lastModified: Value(g.lastModified),
        communityTemplateId: Value(g.communityTemplateId),
        communityTemplateVersion: Value(g.communityTemplateVersion),
      );

  ChecklistItem _itemToDomain(ChecklistItemRow r) => ChecklistItem()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..groupSupabaseId = r.groupSupabaseId
    ..title = r.title
    ..name = r.name
    ..description = r.description
    ..assetName = r.assetName
    ..photoUrl = r.photoUrl
    ..userPhotoUrl = r.userPhotoUrl
    ..userPhotoPath = r.userPhotoPath
    ..notes = r.notes
    ..isCompleted = r.isCompleted
    ..completedAt = r.completedAt
    ..completionHistory =
        (jsonDecode(r.completionHistory) as List).cast<String>()
    ..isBundled = r.isBundled
    ..isHidden = r.isHidden
    ..isPermanentlyDeleted = r.isPermanentlyDeleted
    ..isSynced = r.isSynced
    ..createdAt = r.createdAt
    ..sortOrder = r.sortOrder
    ..lastModified = r.lastModified;

  ChecklistItemsCompanion _itemCompanion(ChecklistItem i) =>
      ChecklistItemsCompanion(
        supabaseId: Value(i.supabaseId),
        boatSupabaseId: Value(i.boatSupabaseId),
        groupSupabaseId: Value(i.groupSupabaseId),
        title: Value(i.title),
        name: Value(i.name),
        description: Value(i.description),
        assetName: Value(i.assetName),
        photoUrl: Value(i.photoUrl),
        userPhotoUrl: Value(i.userPhotoUrl),
        userPhotoPath: Value(i.userPhotoPath),
        notes: Value(i.notes),
        isCompleted: Value(i.isCompleted),
        completedAt: Value(i.completedAt),
        completionHistory: Value(jsonEncode(i.completionHistory)),
        isBundled: Value(i.isBundled),
        isHidden: Value(i.isHidden),
        isPermanentlyDeleted: Value(i.isPermanentlyDeleted),
        isSynced: Value(i.isSynced),
        createdAt: Value(i.createdAt),
        sortOrder: Value(i.sortOrder),
        lastModified: Value(i.lastModified),
      );

  @override
  Stream<List<ChecklistItem>> watchItems(String groupSupabaseId) {
    return db.select(db.checklistItems).watch().map((rows) => rows
        .map(_itemToDomain)
        .where((item) =>
            item.groupSupabaseId == groupSupabaseId &&
            !item.isPermanentlyDeleted)
        .toList());
  }

  @override
  Future<List<ChecklistItem>> getItemsByGroup(String groupSupabaseId) async {
    final rows = await db.select(db.checklistItems).get();
    return rows
        .map(_itemToDomain)
        .where((item) =>
            item.groupSupabaseId == groupSupabaseId &&
            !item.isPermanentlyDeleted)
        .toList();
  }

  @override
  Stream<List<ChecklistGroup>> watchGroups({String? appType}) {
    return db.select(db.checklistGroups).watch().map((rows) {
      final groups = rows.map(_groupToDomain);
      if (appType == null) return groups.where((g) => !g.isHidden).toList();
      return groups.where((g) => g.appType == appType && !g.isHidden).toList();
    });
  }

  @override
  Future<void> resetToFactoryDefaults(String appType) async {
    final targetGroups = (await db.select(db.checklistGroups).get())
        .map(_groupToDomain)
        .where((g) => g.appType == appType)
        .toList();
    final targetGroupIds = targetGroups.map((g) => g.supabaseId).toSet();

    await (db.delete(db.checklistGroups)
          ..where((t) => t.appType.equals(appType)))
        .go();

    final items = (await db.select(db.checklistItems).get()).map(_itemToDomain);
    for (final item in items
        .where((i) => targetGroupIds.contains(i.groupSupabaseId))) {
      await (db.delete(db.checklistItems)
            ..where((t) => t.id.equals(item.id)))
          .go();
    }
  }

  Future<void> _putItem(ChecklistItem item) async {
    final updated = await (db.update(db.checklistItems)
          ..where((t) => t.supabaseId.equals(item.supabaseId)))
        .write(_itemCompanion(item));
    if (updated == 0) {
      await db.into(db.checklistItems).insert(_itemCompanion(item));
    }
  }

  @override
  Future<void> toggleComplete(ChecklistItem item) async {
    item.isCompleted = !item.isCompleted;
    item.lastModified = DateTime.now().toUtc();
    if (item.isCompleted) {
      final now = DateTime.now();
      item.completedAt = now;
      // Append for UX5 history pane (oldest → newest; UI reverses for display).
      item.completionHistory = [...item.completionHistory, now.toIso8601String()];
    }
    await _putItem(item);
    await syncService.queueOutgoingChange('checklist_items', item.toJson());
  }

  @override
  Future<void> hideItem(ChecklistItem item) async {
    item.isHidden = true;
    item.lastModified = DateTime.now().toUtc();
    await _putItem(item);
    await syncService.queueOutgoingChange('checklist_items', item.toJson());
  }

  @override
  Future<void> unhideItem(ChecklistItem item) async {
    item.isHidden = false;
    item.lastModified = DateTime.now().toUtc();
    await _putItem(item);
    await syncService.queueOutgoingChange('checklist_items', item.toJson());
  }

  @override
  Future<void> permanentlyDelete(ChecklistItem item) async {
    item.isPermanentlyDeleted = true;
    item.lastModified = DateTime.now().toUtc();
    await _putItem(item);
    await syncService.queueOutgoingChange('checklist_items', item.toJson());
  }

  // add and update are the same upsert; kept as distinct names for a uniform
  // add/update/delete surface across all repositories (see S1 plan).
  @override
  Future<void> addItem(ChecklistItem item) => updateItem(item);

  @override
  Future<void> updateItem(ChecklistItem item) async {
    item.lastModified = DateTime.now().toUtc();
    await _putItem(item);
    await syncService.queueOutgoingChange('checklist_items', item.toJson());
  }

  @override
  Future<void> createGroup(ChecklistGroup group) async {
    group.lastModified = DateTime.now().toUtc();
    final updated = await (db.update(db.checklistGroups)
          ..where((t) => t.supabaseId.equals(group.supabaseId)))
        .write(_groupCompanion(group));
    if (updated == 0) {
      await db.into(db.checklistGroups).insert(_groupCompanion(group));
    }
    await syncService.queueOutgoingChange('checklist_groups', group.toJson());
  }
}
