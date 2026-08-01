import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../seed/checklist_drift_seed.dart';
import '../../services/community_merge.dart';
import '../../services/error_log_service.dart';
import '../../services/sync_service.dart';
import '../../services/supabase_remote.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final AppDatabase db;
  // Nullable so tests can construct the impl without a live Riverpod stack.
  // In production di.dart always passes the real SyncService.
  final SyncService? syncService;
  /// TEST2 seam — defaults to live Supabase; tests inject a fake.
  final SupabaseRemote remote;

  CommunityRepositoryImpl(
    this.db, [
    this.syncService,
    SupabaseRemote? remote,
  ]) : remote = remote ?? const LiveSupabaseRemote();

  @override
  Future<List<CommunityTemplate>> browseCommunity({
    String? category,
    String? subcategory,
    bool onlyApproved = true,
    CommunitySortOrder sortBy = CommunitySortOrder.recent,
  }) async {
    try {
      final orderColumn = sortBy == CommunitySortOrder.mostDownloaded
          ? 'download_count'
          : 'last_modified';
      final rows = await remote.communityBrowse(
        category: category,
        subcategory: subcategory,
        onlyApproved: onlyApproved,
        orderColumn: orderColumn,
      );
      return rows.map(CommunityTemplate.fromJson).toList();
    } catch (e, st) {
      unawaited(ErrorLogService()
          .logException(e, st, context: 'community_repository: browseCommunity'));
      return [];
    }
  }

  @override
  Future<CommunityTemplate> publishTemplate(CommunityTemplate template) async {
    try {
      // RLS requires author_id = the real auth uid (SHARE5); the UI's local
      // settings id is not the server identity.
      final uid = remote.currentUserId;
      if (uid != null && uid.isNotEmpty) template.authorId = uid;
      // Open community (owner's vision): publishes are live immediately.
      // Flip to false if/when moderation lands (S5).
      template.isApproved = true;

      final row = await remote.communityInsert(template.toJson());

      final saved = CommunityTemplate.fromJson(row);

      // Cache locally (Drift, S1).
      await db.into(db.communityTemplates).insert(
            CommunityTemplatesCompanion(
              supabaseId: Value(saved.supabaseId),
              name: Value(saved.name),
              description: Value(saved.description),
              isApproved: Value(saved.isApproved),
              authorId: Value(saved.authorId),
              title: Value(saved.title),
              category: Value(saved.category),
              subcategory: Value(saved.subcategory),
              content: Value(saved.content),
              isSynced: Value(saved.isSynced),
              lastModified: Value(saved.lastModified),
              downloadCount: Value(saved.downloadCount),
              avgRating: Value(saved.avgRating),
              ratingCount: Value(saved.ratingCount),
              version: Value(saved.version),
            ),
          );

      return saved;
    } catch (e, st) {
      unawaited(ErrorLogService()
          .logException(e, st, context: 'community_repository: publishTemplate'));
      return template;
    }
  }

  @override
  Future<CommunityTemplate> updateTemplate(CommunityTemplate template) async {
    try {
      final uid = remote.currentUserId;
      if (uid != null && uid.isNotEmpty) template.authorId = uid;
      // Open community (owner's vision): stays live through republish, same
      // as a fresh publish. Without this, a freshly-built CommunityTemplate
      // (isApproved defaults to false) overwrites the existing true value on
      // every update, silently pulling the template out of everyone's
      // browse/import list (found live, 2026-07).
      template.isApproved = true;

      final existingVersion =
          await remote.communityFetchVersion(template.supabaseId);
      template.version = existingVersion + 1;

      final row =
          await remote.communityUpdate(template.supabaseId, template.toJson());

      final saved = CommunityTemplate.fromJson(row);

      await (db.update(db.communityTemplates)
            ..where((t) => t.supabaseId.equals(saved.supabaseId)))
          .write(CommunityTemplatesCompanion(
        title: Value(saved.title),
        description: Value(saved.description),
        content: Value(saved.content),
        subcategory: Value(saved.subcategory),
        version: Value(saved.version),
        lastModified: Value(saved.lastModified),
      ));

      return saved;
    } catch (e, st) {
      unawaited(ErrorLogService()
          .logException(e, st, context: 'community_repository: updateTemplate'));
      return template;
    }
  }

  @override
  Future<bool> rateTemplate(String templateId, int rating) async {
    try {
      final uid = remote.currentUserId;
      if (uid == null || uid.isEmpty) return false;
      await remote.communityRate(
        templateId: templateId,
        userId: uid,
        rating: rating,
      );
      return true;
    } catch (e, st) {
      unawaited(
          ErrorLogService().logException(e, st, context: 'community_repository: rateTemplate'));
      return false;
    }
  }

  @override
  Future<int?> getMyRating(String templateId) async {
    try {
      final uid = remote.currentUserId;
      if (uid == null || uid.isEmpty) return null;
      return remote.communityMyRating(templateId: templateId, userId: uid);
    } catch (e) {
      unawaited(ErrorLogService()
          .logWarning('getMyRating failed: $e', context: 'community_repository: getMyRating'));
      return null;
    }
  }

  @override
  Future<bool> applyCommunityUpdate({
    required ChecklistGroup localGroup,
    required String boatId,
  }) async {
    try {
      final templateId = localGroup.communityTemplateId;
      if (templateId == null) return false;

      final row = await remote.communityFetchTemplate(templateId);
      final template = CommunityTemplate.fromJson(row);
      final parsed = jsonDecode(template.content) as Map<String, dynamic>;

      final localItemRows = await (db.select(db.checklistItems)
            ..where((t) => t.groupSupabaseId.equals(localGroup.supabaseId)))
          .get();
      final localItems = localItemRows.map(_itemRowToDomain).toList();

      final diff = computeCommunityMergeDiff(
        localItems: localItems,
        parsedContent: parsed,
        groupSupabaseId: localGroup.supabaseId,
        boatSupabaseId: boatId,
      );

      if (diff.toAdd.isNotEmpty) {
        await seedChecklistItemsToDrift(diff.toAdd);
        for (final item in diff.toAdd) {
          await syncService?.queueOutgoingChange('checklist_items', item.toJson());
        }
      }

      for (final u in diff.toUpdate) {
        await (db.update(db.checklistItems)
              ..where((t) => t.supabaseId.equals(u.local.supabaseId)))
            .write(ChecklistItemsCompanion(
          title: Value(u.newTitle),
          description: Value(u.newDescription),
          lastModified: Value(DateTime.now().toUtc()),
        ));
        final updatedRow = await (db.select(db.checklistItems)
              ..where((t) => t.supabaseId.equals(u.local.supabaseId)))
            .getSingle();
        await syncService?.queueOutgoingChange(
            'checklist_items', _itemRowToDomain(updatedRow).toJson());
      }

      final newTitle = parsed['title'] as String? ?? localGroup.title;
      await (db.update(db.checklistGroups)
            ..where((t) => t.supabaseId.equals(localGroup.supabaseId)))
          .write(ChecklistGroupsCompanion(
        title: Value(newTitle),
        communityTemplateVersion: Value(template.version),
        lastModified: Value(DateTime.now().toUtc()),
      ));
      final updatedGroup = await (db.select(db.checklistGroups)
            ..where((t) => t.supabaseId.equals(localGroup.supabaseId)))
          .getSingle();
      await syncService?.queueOutgoingChange(
          'checklist_groups', _groupRowToDomain(updatedGroup).toJson());

      return true;
    } catch (e, st) {
      unawaited(ErrorLogService()
          .logException(e, st, context: 'community_repository: applyCommunityUpdate'));
      return false;
    }
  }

  ChecklistItem _itemRowToDomain(ChecklistItemRow r) => ChecklistItem()
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
    ..completionHistory = (jsonDecode(r.completionHistory) as List).cast<String>()
    ..isBundled = r.isBundled
    ..isHidden = r.isHidden
    ..isPermanentlyDeleted = r.isPermanentlyDeleted
    ..isSynced = r.isSynced
    ..createdAt = r.createdAt
    ..lastModified = r.lastModified
    ..sortOrder = r.sortOrder;

  ChecklistGroup _groupRowToDomain(ChecklistGroupRow r) => ChecklistGroup()
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

  @override
  Future<bool> importTemplate(String templateId, String boatId) async {
    try {
      // Fetch full template from Supabase
      final row = await remote.communityFetchTemplate(templateId);

      final template = CommunityTemplate.fromJson(row);

      // Parse content JSON — expected shape:
      // { "title": "...", "appType": "checklist", "iconName": "...",
      //   "items": [{ "name": "...", "title": "...", "description": "..." }, ...] }
      final Map<String, dynamic> parsed =
          jsonDecode(template.content) as Map<String, dynamic>;

      final groupId = 'community_${templateId}_${DateTime.now().millisecondsSinceEpoch}';
      final group = ChecklistGroup()
        ..supabaseId = groupId
        ..boatSupabaseId = boatId
        ..title = parsed['title'] as String? ?? template.title
        ..appType = parsed['appType'] as String? ?? 'checklist'
        ..iconName = parsed['iconName'] as String? ?? 'checklist'
        ..isBundled = false
        ..origin = 'community'
        ..communityTemplateId = template.supabaseId
        ..communityTemplateVersion = template.version
        ..lastModified = DateTime.now().toUtc();

      final rawItems = parsed['items'] as List<dynamic>? ?? [];
      final items = rawItems.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value as Map<String, dynamic>;
        return ChecklistItem()
          ..supabaseId = '${groupId}_item_$idx'
          ..boatSupabaseId = boatId
          ..groupSupabaseId = groupId
          ..name = item['name'] as String? ?? ''
          ..title = item['title'] as String? ?? ''
          ..description = item['description'] as String?
          ..isBundled = false
          ..createdAt = DateTime.now()
          ..lastModified = DateTime.now().toUtc()
          ..sortOrder = idx;
      }).toList();

      // ChecklistGroup/ChecklistItem moved to Drift (S1).
      await seedChecklistGroupToDrift(group);
      await seedChecklistItemsToDrift(items);

      // Queue sync for the imported items
      await syncService?.queueOutgoingChange('checklist_groups', group.toJson());
      for (final item in items) {
        await syncService?.queueOutgoingChange('checklist_items', item.toJson());
      }

      // Record the download (best-effort — table may not exist yet)
      try {
        await remote.communityRecordDownload(templateId);
      } catch (_) {
        // Genuinely optional bookkeeping — table may not exist yet; the
        // import itself already succeeded by this point.
      }

      return true;
    } catch (e, st) {
      unawaited(ErrorLogService()
          .logException(e, st, context: 'community_repository: importTemplate'));
      return false;
    }
  }

  @override
  Future<int> getDownloadCount(String templateId) async {
    try {
      return await remote.communityDownloadCount(templateId);
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'getDownloadCount failed: $e',
        context: 'community_repository: getDownloadCount',
      ));
      return 0;
    }
  }

  @override
  Future<void> linkGroupToTemplate({
    required String groupSupabaseId,
    required String templateId,
    required int version,
  }) async {
    await (db.update(db.checklistGroups)
          ..where((t) => t.supabaseId.equals(groupSupabaseId)))
        .write(ChecklistGroupsCompanion(
      communityTemplateId: Value(templateId),
      communityTemplateVersion: Value(version),
    ));
    final updated = await (db.select(db.checklistGroups)
          ..where((t) => t.supabaseId.equals(groupSupabaseId)))
        .getSingleOrNull();
    if (updated != null) {
      await syncService?.queueOutgoingChange(
          'checklist_groups', _groupRowToDomain(updated).toJson());
    }
  }

  @override
  Future<CommunityTemplate?> getCachedTemplate(String templateId) async {
    final row = await (db.select(db.communityTemplates)
          ..where((t) => t.supabaseId.equals(templateId)))
        .getSingleOrNull();
    if (row == null) return null;
    return CommunityTemplate()
      ..supabaseId = row.supabaseId
      ..name = row.name
      ..title = row.title
      ..description = row.description
      ..category = row.category
      ..subcategory = row.subcategory
      ..authorId = row.authorId
      ..content = row.content
      ..isApproved = row.isApproved
      ..isSynced = row.isSynced
      ..lastModified = row.lastModified
      ..downloadCount = row.downloadCount
      ..avgRating = row.avgRating
      ..ratingCount = row.ratingCount
      ..version = row.version;
  }
}
