import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';

/// Helpers that persist bundled `ChecklistGroup`/`ChecklistItem` domain objects
/// (built by the checklist seeders) into their Drift tables.
Future<void> seedChecklistGroupToDrift(ChecklistGroup g) async {
  final db = AppDatabase.instance;
  await db.into(db.checklistGroups).insert(
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
        ),
      );
}

Future<void> seedChecklistItemsToDrift(List<ChecklistItem> items) async {
  final db = AppDatabase.instance;
  await db.batch((b) {
    for (final i in items) {
      b.insert(
        db.checklistItems,
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
        ),
      );
    }
  });
}
