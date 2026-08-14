import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../seed/checklist_drift_seed.dart';
import '../../services/community_merge.dart';
import '../../services/error_log_service.dart';
import '../../services/sync_service.dart';
import '../../services/community_offline_store.dart';
import '../../services/community_share.dart';
import '../../services/supabase_remote.dart';
import '../../domain/repositories/community_repository.dart';
import 'anchor_spot_repository_impl.dart';
import 'collection_repository_impl.dart';
import 'recipe_repository_impl.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final AppDatabase db;
  // Nullable so tests can construct the impl without a live Riverpod stack.
  // In production di.dart always passes the real SyncService.
  final SyncService? syncService;
  /// TEST2 seam — defaults to live Supabase; tests inject a fake.
  final SupabaseRemote remote;
  /// #322 — file-backed last-browse + keep-on-device. Defaults to the
  /// documents-dir store; tests inject a temp file.
  final CommunityOfflineStore offlineStore;

  CommunityRepositoryImpl(
    this.db, [
    this.syncService,
    SupabaseRemote? remote,
    CommunityOfflineStore? offlineStore,
  ])  : remote = remote ?? const LiveSupabaseRemote(),
        offlineStore = offlineStore ?? CommunityOfflineStore();

  @override
  Future<CommunityBrowseResult> browseCommunity({
    String? category,
    String? subcategory,
    bool onlyApproved = true,
    CommunitySortOrder sortBy = CommunitySortOrder.recent,
    List<String> interests = const [],
  }) async {
    final key = CommunityOfflineStore.browseKey(
      category: category,
      sortBy: sortBy,
      interests: interests,
    );
    try {
      final orderColumn = sortBy == CommunitySortOrder.mostDownloaded
          ? 'download_count'
          : 'last_modified';
      // Interests are a client-side OR-of-phrases (Yanmar 4HJ45 AND
      // Northern Light 4.5kW). Don't also send a single subcategory —
      // that would drop the generator while filtering for the engine.
      final rows = await remote.communityBrowse(
        category: category,
        subcategory: interests.isEmpty ? subcategory : null,
        onlyApproved: onlyApproved,
        orderColumn: orderColumn,
      );
      var templates = rows.map(CommunityTemplate.fromJson).toList();
      if (interests.isNotEmpty) {
        templates = templates
            .where((t) => communityTemplateMatchesInterests(t, interests))
            .toList();
      }
      final fetchedAt = DateTime.now().toUtc();
      try {
        await offlineStore.saveBrowseSnapshot(
          key: key,
          fetchedAt: fetchedAt,
          templates: templates,
        );
      } catch (e) {
        // Cache is best-effort — a missing documents dir in tests or a
        // full disk must not fail the live browse.
        unawaited(ErrorLogService().logWarning(
          'browse snapshot save failed: $e',
          context: 'community_repository: browseCommunity',
        ));
      }
      return CommunityBrowseResult(
        templates: templates,
        fetchedAt: fetchedAt,
      );
    } catch (e, st) {
      unawaited(ErrorLogService()
          .logException(e, st, context: 'community_repository: browseCommunity'));
      try {
        final snap = await offlineStore.loadBrowseSnapshot(key);
        if (snap != null) {
          return CommunityBrowseResult(
            templates: snap.templates,
            fromCache: true,
            fetchedAt: snap.fetchedAt,
          );
        }
        final kept = (await offlineStore.keptTemplates())
            .where((t) =>
                (category == null ||
                    category == 'all' ||
                    t.category == category) &&
                communityTemplateMatchesInterests(t, interests))
            .toList();
        if (kept.isNotEmpty) {
          return CommunityBrowseResult(
            templates: kept,
            fromCache: true,
            fromKept: true,
          );
        }
      } catch (_) {
        // Missing/unreadable cache — fall through to empty.
      }
      return const CommunityBrowseResult(templates: []);
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
  Future<bool> reportTemplate(
    String templateId, {
    required String reason,
    String? note,
  }) async {
    try {
      final uid = remote.currentUserId;
      if (uid == null || uid.isEmpty) return false;
      await remote.communityReport(
        templateId: templateId,
        userId: uid,
        reason: reason,
        note: note,
      );
      return true;
    } catch (e, st) {
      unawaited(ErrorLogService()
          .logException(e, st, context: 'community_repository: reportTemplate'));
      return false;
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
      CommunityTemplate template;
      try {
        final row = await remote.communityFetchTemplate(templateId);
        template = CommunityTemplate.fromJson(row);
      } catch (_) {
        // #322 — a template the user kept on this device can import
        // offline; listing-only browse rows cannot (no body).
        final kept = await offlineStore.keptTemplate(templateId);
        if (kept == null || kept.content.isEmpty) rethrow;
        template = kept;
      }

      final Map<String, dynamic> parsed =
          jsonDecode(template.content) as Map<String, dynamic>;
      final kind = communityShareKindOf(parsed);
      final stamp = DateTime.now().millisecondsSinceEpoch;

      switch (kind) {
        case CommunityShareKind.recipe:
        case CommunityShareKind.cocktail:
          await _importSharedRecipe(
            parsed,
            boatId: boatId,
            recipeSupabaseId: 'community_${templateId}_$stamp',
          );
        case CommunityShareKind.collection:
          await _importSharedCollection(
            parsed,
            boatId: boatId,
            prefix: 'community_${templateId}_$stamp',
          );
        case CommunityShareKind.shopping:
          await _importSharedShopping(
            parsed,
            template: template,
            boatId: boatId,
            prefix: 'community_${templateId}_$stamp',
          );
        case CommunityShareKind.anchorage:
          await _importSharedAnchorage(parsed);
        default:
          await _importSharedChecklist(
            parsed,
            template: template,
            boatId: boatId,
            groupId: 'community_${templateId}_$stamp',
          );
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

  Future<void> _importSharedChecklist(
    Map<String, dynamic> parsed, {
    required CommunityTemplate template,
    required String boatId,
    required String groupId,
  }) async {
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

    await db.into(db.checklistGroups).insert(ChecklistGroupsCompanion(
          supabaseId: Value(group.supabaseId),
          boatSupabaseId: Value(group.boatSupabaseId),
          appType: Value(group.appType),
          title: Value(group.title),
          iconName: Value(group.iconName),
          isBundled: Value(group.isBundled),
          origin: Value(group.origin),
          communityTemplateId: Value(group.communityTemplateId),
          communityTemplateVersion: Value(group.communityTemplateVersion),
          lastModified: Value(group.lastModified),
        ));
    await db.batch((b) {
      for (final i in items) {
        b.insert(
          db.checklistItems,
          ChecklistItemsCompanion(
            supabaseId: Value(i.supabaseId),
            boatSupabaseId: Value(i.boatSupabaseId),
            groupSupabaseId: Value(i.groupSupabaseId),
            name: Value(i.name),
            title: Value(i.title),
            description: Value(i.description),
            isBundled: Value(i.isBundled),
            createdAt: Value(i.createdAt),
            lastModified: Value(i.lastModified),
            sortOrder: Value(i.sortOrder),
          ),
        );
      }
    });
    await syncService?.queueOutgoingChange('checklist_groups', group.toJson());
    for (final item in items) {
      await syncService?.queueOutgoingChange('checklist_items', item.toJson());
    }
  }

  Future<void> _importSharedRecipe(
    Map<String, dynamic> parsed, {
    required String boatId,
    required String recipeSupabaseId,
  }) async {
    final decoded = decodeSharedRecipe(
      parsed,
      recipeSupabaseId: recipeSupabaseId,
      boatId: boatId,
    );
    final recipes = RecipeRepositoryImpl(db, syncService);
    await recipes.addRecipe(decoded.recipe);
    for (final ing in decoded.ingredients) {
      await recipes.addIngredient(ing);
    }
  }

  Future<void> _importSharedCollection(
    Map<String, dynamic> parsed, {
    required String boatId,
    required String prefix,
  }) async {
    final rawRecipes = parsed['recipes'];
    final ids = <String>[];
    if (rawRecipes is List) {
      for (var i = 0; i < rawRecipes.length; i++) {
        final raw = rawRecipes[i];
        if (raw is! Map) continue;
        final id = '${prefix}_r$i';
        await _importSharedRecipe(
          Map<String, dynamic>.from(raw),
          boatId: boatId,
          recipeSupabaseId: id,
        );
        ids.add(id);
      }
    }
    final collection = RecipeCollection()
      ..name = (parsed['name'] as String?) ?? 'Community collection'
      ..recipeSupabaseIds = ids
      ..createdAt = DateTime.now()
      ..lastModified = DateTime.now().toUtc();
    await CollectionRepositoryImpl(db).addCollection(collection);
  }

  Future<void> _importSharedShopping(
    Map<String, dynamic> parsed, {
    required CommunityTemplate template,
    required String boatId,
    required String prefix,
  }) async {
    final catId = '${prefix}_cat';
    final category = ShoppingCategory()
      ..supabaseId = catId
      ..boatSupabaseId = boatId
      ..name = (parsed['title'] as String?) ?? template.title
      ..sortOrder = 0
      ..lastModified = DateTime.now().toUtc();
    await db.into(db.shoppingCategories).insert(ShoppingCategoriesCompanion(
          supabaseId: Value(category.supabaseId),
          boatSupabaseId: Value(category.boatSupabaseId),
          name: Value(category.name),
          sortOrder: Value(category.sortOrder),
          lastModified: Value(category.lastModified),
        ));
    await syncService?.queueOutgoingChange(
        'shopping_categories', category.toJson());

    final rawItems = parsed['items'];
    if (rawItems is! List) return;
    for (var i = 0; i < rawItems.length; i++) {
      final raw = rawItems[i];
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final item = ShoppingItem()
        ..supabaseId = '${prefix}_i$i'
        ..boatSupabaseId = boatId
        ..categorySupabaseId = catId
        ..name = (m['name'] as String?) ?? ''
        ..quantity = (m['quantity'] as num?)?.toInt() ?? 1
        ..unit = m['unit'] as String?
        ..origin = (m['origin'] as String?) ?? 'pantry'
        ..notes = m['notes'] as String?
        ..lastModified = DateTime.now().toUtc();
      await db.into(db.shoppingItems).insert(ShoppingItemsCompanion(
            supabaseId: Value(item.supabaseId),
            boatSupabaseId: Value(item.boatSupabaseId),
            categorySupabaseId: Value(item.categorySupabaseId),
            name: Value(item.name),
            quantity: Value(item.quantity),
            unit: Value(item.unit),
            origin: Value(item.origin),
            notes: Value(item.notes),
            lastModified: Value(item.lastModified),
          ));
      await syncService?.queueOutgoingChange('shopping_items', item.toJson());
    }
  }

  Future<void> _importSharedAnchorage(Map<String, dynamic> parsed) async {
    final spot = decodeSharedAnchorSpot(parsed);
    spot.id = 0;
    await AnchorSpotRepositoryImpl(db).save(spot);
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

  @override
  Future<List<String>> loadOfflineInterests() => offlineStore.loadInterests();

  @override
  Future<void> saveOfflineInterests(List<String> interests) =>
      offlineStore.saveInterests(interests);

  @override
  Future<bool> keepTemplateOffline(CommunityTemplate template) async {
    try {
      var toKeep = template;
      if (toKeep.content.isEmpty && toKeep.supabaseId.isNotEmpty) {
        final row = await remote.communityFetchTemplate(toKeep.supabaseId);
        toKeep = CommunityTemplate.fromJson(row);
      }
      if (toKeep.content.isEmpty || toKeep.supabaseId.isEmpty) return false;
      await offlineStore.keepTemplate(toKeep);
      return true;
    } catch (e, st) {
      unawaited(ErrorLogService().logException(
        e,
        st,
        context: 'community_repository: keepTemplateOffline',
      ));
      return false;
    }
  }

  @override
  Future<void> removeKeptTemplate(String templateId) =>
      offlineStore.unkeepTemplate(templateId);

  @override
  Future<Set<String>> keptTemplateIds() => offlineStore.keptIds();

  @override
  Future<List<CommunityTemplate>> keptTemplates() =>
      offlineStore.keptTemplates();
}
