import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di.dart';
import '../core/supabase_client.dart';
import '../data/drift/app_database.dart';
import '../models/models.dart';
import 'conflict_resolution_service.dart';
import 'error_log_service.dart';
import 'inbound_sync_applier.dart';
import 'supabase_remote.dart';
import 'wire_prefix.dart';

class SyncService {
  final Ref ref;
  final List<StreamSubscription> _subscriptions = [];
  bool _isProcessingQueue = false;
  bool _started = false;
  Timer? _retryTimer;
  Timer? _queueMonitorTimer;

  // Queue statistics
  int _processedCount = 0;
  int _failedCount = 0;
  DateTime? _lastSyncSuccess;
  DateTime? _lastSyncFailure;

  bool _disposed = false;

  final ConflictResolutionService _conflicts =
      const ConflictResolutionService();

  /// TEST2 optional override — when null, uses [supabaseRemoteProvider].
  final SupabaseRemote? _remoteOverride;

  SyncService(this.ref, {SupabaseRemote? remote}) : _remoteOverride = remote {
    ref.onDispose(() => _disposed = true);
    _init();
  }

  // Offline sync outbox moved to Drift (S1).
  AppDatabase get _db => ref.read(appDatabaseProvider);

  InboundSyncApplier get _applier => InboundSyncApplier(_db);

  SupabaseRemote get _remote =>
      _remoteOverride ?? ref.read(supabaseRemoteProvider);

  // Public getters for monitoring
  Future<int> pendingQueueSize() =>
      _db.syncOutboxItems.count().getSingle();
  int get processedCount => _processedCount;
  int get failedCount => _failedCount;
  DateTime? get lastSyncSuccess => _lastSyncSuccess;
  DateTime? get lastSyncFailure => _lastSyncFailure;

  /// Pending concurrent-edit conflicts (for drawer badge / resolution UI).
  Stream<List<ConflictLog>> watchPendingConflicts() {
    return (_db.select(_db.conflictLogs)
          ..where((t) => t.resolution.equals('pending'))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch()
        .map((rows) => rows.map(_conflictFromRow).toList());
  }

  Future<int> pendingConflictCount() async {
    final rows = await (_db.select(_db.conflictLogs)
          ..where((t) => t.resolution.equals('pending')))
        .get();
    return rows.length;
  }

  /// Sync is enabled for Pro owners and for anonymous crew members (who ride on
  /// the boat owner's Pro, having joined via a share code). Guarded so a test
  /// process — where Supabase is not initialised — never throws and stays offline.
  Future<bool> _syncAllowed() async {
    if (await ref.read(revenueCatProvider).isPro()) return true;
    try {
      final user = SupabaseClientWrapper.instance.auth.currentUser;
      return user != null && user.isAnonymous;
    } catch (_) {
      return false;
    }
  }

  /// Active boat GUID = the wire-prefix (owner's enrolled GUID, or a crew's
  /// joined boat GUID). Empty when not enrolled/joined → no prefixing.
  Future<String> _boatGuid() async {
    final s = await ref.read(userSettingsProvider.future);
    return s?.activeBoatSupabaseId ?? '';
  }

  Future<void> _init() => ensureStarted();

  /// Start queue monitor + realtime subscriptions once the user becomes
  /// sync-eligible. Idempotent — safe to call again after a Pro purchase or a
  /// crew member joining a boat (which flips [_syncAllowed] to true).
  Future<void> ensureStarted() async {
    if (_started || _disposed) return;
    final settings = await ref.read(userSettingsProvider.future);
    if (_disposed) return;
    final allowed = await _syncAllowed();
    if (_disposed || !allowed || settings == null) return;

    _started = true;
    _startQueueMonitor();

    // Monitor connectivity to flush queue when back online. Best-effort:
    // tests and desktop without the plugin must not crash crew join.
    try {
      Connectivity().onConnectivityChanged.listen((results) {
        if (results.contains(ConnectivityResult.mobile) ||
            results.contains(ConnectivityResult.wifi) ||
            results.contains(ConnectivityResult.ethernet)) {
          _processOutgoingQueue();
        }
      });
    } catch (_) {}

    try {
      await _subscribeToTables();
    } catch (e) {
      // Offline / Supabase not initialised (unit tests, cold crew join) —
      // outbox monitor still runs; realtime attaches on a later ensureStarted.
      unawaited(ErrorLogService().logWarning(
        'realtime subscribe failed: $e',
        context: 'sync_service: ensureStarted',
      ));
    }
  }

  Future<void> _subscribeToTables() async {
    // Two-way real-time for every table that participates in outbound sync.
    final tables = InboundSyncApplier.syncedTables.toList();

    for (final table in tables) {
      final sub = SupabaseClientWrapper.instance
          .from(table)
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> data) async {
            await processIncomingChanges(table, data);
          });
      _subscriptions.add(sub);
    }
  }

  /// Public entry for inbound realtime / tests (T5).
  ///
  /// Supabase `.stream()` emits the **current snapshot** of rows (delete events
  /// drop the row from the list). We upsert/merge every present row, then
  /// hard-delete local `isSynced` rows that vanished from the snapshot so
  /// peer hard-deletes clear on the mirror (LT2 inv/crew/docs residual).
  Future<void> processIncomingChanges(
    String table,
    List<Map<String, dynamic>> records,
  ) async {
    if (!_applier.supports(table)) return;

    final remoteIds = <String>{};
    for (final raw in records) {
      try {
        final decoded = WirePrefix.decode(table, raw);
        final id = _applier.recordId(decoded);
        if (id.isNotEmpty) remoteIds.add(id);
        await _handleOneIncoming(table, decoded);
      } catch (e) {
        // One bad row must not stop the rest of the batch.
        unawaited(ErrorLogService().logWarning(
          '$table: bad inbound row skipped: $e',
          context: 'sync_service: processIncomingChanges',
        ));
      }
    }
    await _reconcileRemoteDeletes(table, remoteIds);
  }

  /// Drop local cloud-accepted rows that are no longer in the remote snapshot.
  /// Skips unsynced local-only creates and rows with a pending outbox op.
  Future<void> _reconcileRemoteDeletes(
    String table,
    Set<String> remoteIds,
  ) async {
    final localIds = await _applier.listLocalSyncedIds(table);
    for (final id in localIds) {
      if (remoteIds.contains(id)) continue;
      if (await _hasPendingOutbox(table, id)) continue;
      try {
        await _applier.deleteLocal(table, id);
        await _deleteOutboxFor(table, id);
      } catch (e) {
        // Best-effort; next snapshot will retry.
        unawaited(ErrorLogService().logWarning(
          '$table: remote-delete reconcile failed for $id: $e',
          context: 'sync_service: _reconcileRemoteDeletes',
        ));
      }
    }
  }

  Future<void> _handleOneIncoming(
    String table,
    Map<String, dynamic> raw,
  ) async {
    final remote = _applier.normalizeRemote(raw);
    final id = _applier.recordId(remote);
    if (id.isEmpty) return;

    final local = await _applier.getLocal(table, id);
    final pendingOutbox = await _hasPendingOutbox(table, id);
    final localDirty = local != null && (!local.isSynced || pendingOutbox);
    final remoteLm = _applier.remoteLastModified(remote);

    final action = _conflicts.evaluate(
      localExists: local != null,
      localDirty: localDirty,
      localLastModified: local?.lastModified,
      remoteLastModified: remoteLm,
    );

    switch (action) {
      case InboundAction.applyRemote:
        await _applier.applyRemote(table, remote);
        // Drop stale outbox for this id if remote won on a clean local.
        await _deleteOutboxFor(table, id);
      case InboundAction.skip:
        return;
      case InboundAction.conflict:
        // S6: try field-level auto-merge before forcing Keep mine/cloud.
        final merge = _conflicts.tryFieldMerge(local!.json, remote);
        if (merge != null) {
          await _applier.applyRemote(table, merge.merged);
          await _markUnsynced(table, id);
          final after = await _applier.getLocal(table, id);
          if (after != null) {
            final push = Map<String, dynamic>.from(after.json)
              ..['isSynced'] = false
              ..['lastModified'] = DateTime.now().toUtc().toIso8601String();
            await queueOutgoingChange(table, push, priority: 2);
          }
          return;
        }
        await _recordConflict(
          table: table,
          supabaseId: id,
          localJson: local.json,
          remoteJson: remote,
        );
      case InboundAction.applyMerged:
        // Reserved for callers that already computed a merge.
        return;
    }
  }

  Future<bool> _hasPendingOutbox(String table, String recordId) async {
    final items = await (_db.select(_db.syncOutboxItems)
          ..where((t) =>
              t.targetTable.equals(table) & t.recordId.equals(recordId)))
        .get();
    return items.isNotEmpty;
  }

  Future<void> _deleteOutboxFor(String table, String recordId) async {
    await (_db.delete(_db.syncOutboxItems)
          ..where((t) =>
              t.targetTable.equals(table) & t.recordId.equals(recordId)))
        .go();
  }

  Future<void> _recordConflict({
    required String table,
    required String supabaseId,
    required Map<String, dynamic> localJson,
    required Map<String, dynamic> remoteJson,
  }) async {
    // Upsert-style: one pending row per table+id.
    final existing = await (_db.select(_db.conflictLogs)
          ..where((t) =>
              t.targetTable.equals(table) &
              t.localSupabaseId.equals(supabaseId) &
              t.resolution.equals('pending')))
        .getSingleOrNull();

    final companion = ConflictLogsCompanion(
      targetTable: Value(table),
      localSupabaseId: Value(supabaseId),
      remoteSupabaseId: Value(supabaseId),
      conflictType: const Value('concurrent_edit'),
      resolution: const Value('pending'),
      localData: Value(jsonEncode(localJson)),
      remoteData: Value(jsonEncode(remoteJson)),
      timestamp: Value(DateTime.now()),
    );

    if (existing == null) {
      await _db.into(_db.conflictLogs).insert(companion);
    } else {
      await (_db.update(_db.conflictLogs)
            ..where((t) => t.id.equals(existing.id)))
          .write(companion);
    }
  }

  /// Checks the remote row before an outbox push lands, so a stale queued
  /// edit (e.g. made offline) doesn't silently clobber a newer remote write.
  /// Records a conflict and returns true if the push should be held back.
  Future<bool> _outboxItemConflicts(
    String table,
    String recordId,
    Map<String, dynamic> localData,
    String guid,
  ) async {
    if (!_applier.supports(table)) return false;

    final wireId = WirePrefix.encodeRecordId(table, recordId, guid);
    final row = await _remote.fetchBySupabaseId(table, wireId);
    if (row == null) return false;

    final remote = WirePrefix.decode(table, row);
    final remoteLm = _applier.remoteLastModified(remote);
    final localLm = DateTime.tryParse(localData['lastModified'] as String? ?? '');
    if (remoteLm == null || localLm == null || !remoteLm.isAfter(localLm)) {
      return false;
    }

    // S6: auto-merge non-overlapping field edits instead of blocking the push.
    final merge = _conflicts.tryFieldMerge(localData, remote);
    if (merge != null) {
      await _applier.applyRemote(table, merge.merged);
      await _markUnsynced(table, recordId);
      // Allow the (updated) local push to proceed with the merged payload.
      localData
        ..clear()
        ..addAll(merge.merged)
        ..['isSynced'] = false
        ..['lastModified'] = DateTime.now().toUtc().toIso8601String();
      return false;
    }

    await _recordConflict(
      table: table,
      supabaseId: recordId,
      localJson: localData,
      remoteJson: remote,
    );
    return true;
  }

  /// User chose keep local, keep remote, or S6 field-merge for a pending conflict.
  Future<void> resolveConflict({
    required int conflictId,
    required bool keepLocal,
    bool tryMerge = false,
  }) async {
    final row = await (_db.select(_db.conflictLogs)
          ..where((t) => t.id.equals(conflictId)))
        .getSingleOrNull();
    if (row == null || row.resolution != 'pending') return;

    final table = row.targetTable;
    final id = row.localSupabaseId;
    var resolution = keepLocal ? 'keep_local' : 'keep_remote';

    if (tryMerge) {
      final localMap = jsonDecode(row.localData) as Map<String, dynamic>;
      final remoteMap = jsonDecode(row.remoteData) as Map<String, dynamic>;
      final merge = _conflicts.tryFieldMerge(localMap, remoteMap);
      if (merge == null) {
        // Fall through to keepLocal/keepRemote below if merge impossible —
        // caller should only enable Merge when tryFieldMerge succeeds.
        return;
      }
      await _applier.applyRemote(table, merge.merged);
      await _markUnsynced(table, id);
      final after = await _applier.getLocal(table, id);
      if (after != null) {
        final push = Map<String, dynamic>.from(after.json)
          ..['isSynced'] = false
          ..['lastModified'] = DateTime.now().toUtc().toIso8601String();
        await queueOutgoingChange(table, push, priority: 2);
      }
      resolution = 'merged';
    } else if (keepLocal) {
      final localMap = jsonDecode(row.localData) as Map<String, dynamic>;
      await _applier.applyRemote(table, localMap);
      await _markUnsynced(table, id);
      final after = await _applier.getLocal(table, id);
      if (after != null) {
        final push = Map<String, dynamic>.from(after.json)
          ..['isSynced'] = false
          ..['lastModified'] = DateTime.now().toUtc().toIso8601String();
        await queueOutgoingChange(table, push, priority: 2);
      }
    } else {
      final remoteMap = jsonDecode(row.remoteData) as Map<String, dynamic>;
      await _applier.applyRemote(table, remoteMap);
      await _deleteOutboxFor(table, id);
    }

    await (_db.update(_db.conflictLogs)..where((t) => t.id.equals(conflictId)))
        .write(ConflictLogsCompanion(
      resolution: Value(resolution),
      resolvedAt: Value(DateTime.now()),
    ));
  }

  Future<void> _markUnsynced(String table, String supabaseId) async {
    final now = DateTime.now().toUtc();
    switch (table) {
      case 'boats':
        await (_db.update(_db.boats)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(BoatsCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'checklist_groups':
        await (_db.update(_db.checklistGroups)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(ChecklistGroupsCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'checklist_items':
        await (_db.update(_db.checklistItems)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(ChecklistItemsCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'shopping_categories':
        await (_db.update(_db.shoppingCategories)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(ShoppingCategoriesCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'shopping_items':
        await (_db.update(_db.shoppingItems)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(ShoppingItemsCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'captain_logs':
        await (_db.update(_db.captainLogEntries)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(CaptainLogEntriesCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'maintenance_tasks':
        await (_db.update(_db.maintenanceTasks)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(MaintenanceTasksCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'documents':
        await (_db.update(_db.documents)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(DocumentsCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'crew_members':
        await (_db.update(_db.crewMembers)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(CrewMembersCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'inventory_items':
        await (_db.update(_db.inventoryItems)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(InventoryItemsCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'fuel_logs':
        await (_db.update(_db.fuelLogEntries)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(FuelLogEntriesCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'recipes':
        await (_db.update(_db.recipes)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(RecipesCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'recipe_ingredients':
        await (_db.update(_db.recipeIngredients)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(RecipeIngredientsCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'bar_ingredients':
        await (_db.update(_db.barIngredients)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(BarIngredientsCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'pantry_ingredients':
        await (_db.update(_db.pantryIngredients)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(PantryIngredientsCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
      case 'sailing_polar_samples':
        await (_db.update(_db.sailingPolarSamples)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(SailingPolarSamplesCompanion(
          isSynced: const Value(false),
          lastModified: Value(now),
        ));
    }
  }

  /// Mirrors [_markUnsynced], inverted: marks a row synced after its
  /// outbound push succeeds. Deliberately does not touch `lastModified` —
  /// this confirms an already-pushed edit, not a new local change.
  Future<void> _markSynced(String table, String supabaseId) async {
    switch (table) {
      case 'boats':
        await (_db.update(_db.boats)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const BoatsCompanion(isSynced: Value(true)));
      case 'checklist_groups':
        await (_db.update(_db.checklistGroups)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const ChecklistGroupsCompanion(isSynced: Value(true)));
      case 'checklist_items':
        await (_db.update(_db.checklistItems)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const ChecklistItemsCompanion(isSynced: Value(true)));
      case 'shopping_categories':
        await (_db.update(_db.shoppingCategories)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const ShoppingCategoriesCompanion(isSynced: Value(true)));
      case 'shopping_items':
        await (_db.update(_db.shoppingItems)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const ShoppingItemsCompanion(isSynced: Value(true)));
      case 'captain_logs':
        await (_db.update(_db.captainLogEntries)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const CaptainLogEntriesCompanion(isSynced: Value(true)));
      case 'maintenance_tasks':
        await (_db.update(_db.maintenanceTasks)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const MaintenanceTasksCompanion(isSynced: Value(true)));
      case 'documents':
        await (_db.update(_db.documents)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const DocumentsCompanion(isSynced: Value(true)));
      case 'crew_members':
        await (_db.update(_db.crewMembers)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const CrewMembersCompanion(isSynced: Value(true)));
      case 'inventory_items':
        await (_db.update(_db.inventoryItems)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const InventoryItemsCompanion(isSynced: Value(true)));
      case 'fuel_logs':
        await (_db.update(_db.fuelLogEntries)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const FuelLogEntriesCompanion(isSynced: Value(true)));
      case 'recipes':
        await (_db.update(_db.recipes)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const RecipesCompanion(isSynced: Value(true)));
      case 'recipe_ingredients':
        await (_db.update(_db.recipeIngredients)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const RecipeIngredientsCompanion(isSynced: Value(true)));
      case 'bar_ingredients':
        await (_db.update(_db.barIngredients)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const BarIngredientsCompanion(isSynced: Value(true)));
      case 'pantry_ingredients':
        await (_db.update(_db.pantryIngredients)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(const PantryIngredientsCompanion(isSynced: Value(true)));
      case 'sailing_polar_samples':
        await (_db.update(_db.sailingPolarSamples)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .write(
                const SailingPolarSamplesCompanion(isSynced: Value(true)));
    }
  }

  ConflictLog _conflictFromRow(ConflictLogRow r) => ConflictLog.fromRow(
        id: r.id,
        targetTable: r.targetTable,
        localSupabaseId: r.localSupabaseId,
        remoteSupabaseId: r.remoteSupabaseId,
        conflictType: r.conflictType,
        resolution: r.resolution,
        localData: r.localData,
        remoteData: r.remoteData,
        timestamp: r.timestamp,
        resolvedAt: r.resolvedAt,
      );

  // Call this every time user edits anything locally
  Future<void> queueOutgoingChange(
    String table,
    Map<String, dynamic> record, {
    int priority = 0,
    bool isDelete = false,
  }) async {
    if (!await _syncAllowed()) return; // Free/offline users never sync

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      // Queue for offline sync
      await _addToOutbox(table, record, priority: priority, isDelete: isDelete);
      return;
    }

    try {
      if (isDelete) {
        final id = record['supabaseId'] as String? ?? record['id'] as String? ?? '';
        await _remote.deleteBySupabaseId(
          table,
          WirePrefix.encodeRecordId(table, id, await _boatGuid()),
        );
      } else {
        final wire = WirePrefix.encode(table, record, await _boatGuid());
        await _remote.upsert(table, wire);
        // Same reset as the outbox success path (#180) — an immediate
        // online push also leaves the row permanently "dirty" otherwise.
        final id =
            record['id'] as String? ?? record['supabaseId'] as String? ?? '';
        await _markSynced(table, id);
      }
    } catch (e) {
      // Failed to push, queue for later
      unawaited(ErrorLogService().logWarning(
        '$table: push failed, queued for retry: $e',
        context: 'sync_service: queueOutgoingChange',
      ));
      await _addToOutbox(table, record, priority: priority, isDelete: isDelete);
    }
  }

  Future<void> _addToOutbox(String table, Map<String, dynamic> record,
      {int priority = 0, bool isDelete = false}) async {
    await _db.into(_db.syncOutboxItems).insert(SyncOutboxItemsCompanion.insert(
          targetTable: Value(table),
          recordId: Value((record['id'] as String?) ??
              (record['supabaseId'] as String?) ??
              ''),
          operation: Value(isDelete ? 'delete' : 'upsert'),
          data: Value(jsonEncode(record)),
          priority: Value(priority),
          isDelete: Value(isDelete),
        ));
  }

  void _startQueueMonitor() {
    // Monitor queue health every 30 seconds
    _queueMonitorTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _monitorQueueHealth();
    });
  }

  Future<void> _monitorQueueHealth() async {
    try {
      final queueSize = await pendingQueueSize();
      final allowed = await _syncAllowed();

      // Auto-process queue if we're online and have items
      if (allowed && queueSize > 0 && await _isCurrentlyOnline()) {
        await _processOutgoingQueue();
      }

      // Clean up old failed items (older than 24 hours with max retries)
      await _cleanupOldFailedItems();
    } catch (e) {
      // Fingerprint-deduped (runs every 30s) — won't spam rows if offline
      // for a long stretch, just increments occurrences on the one row.
      unawaited(ErrorLogService()
          .logWarning('queue health check failed: $e', context: 'sync_service: _monitorQueueHealth'));
    }
  }

  Future<void> _cleanupOldFailedItems() async {
    final cutoffDate = DateTime.now().subtract(const Duration(hours: 24));

    // Find all items and filter in memory (simpler approach)
    final allItems = await _db.select(_db.syncOutboxItems).get();
    final oldItems = allItems.where((item) =>
        item.retryCount >= 5 && item.createdAt.isBefore(cutoffDate));

    for (final item in oldItems) {
      await (_db.delete(_db.syncOutboxItems)
            ..where((t) => t.id.equals(item.id)))
          .go();
      _failedCount++;
    }
  }

  Future<bool> _isCurrentlyOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'connectivity check failed, treating as offline: $e',
        context: 'sync_service: _isCurrentlyOnline',
      ));
      return false;
    }
  }

  Future<void> _processOutgoingQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    // Process items in priority order (highest first)
    final outboxItems = await (_db.select(_db.syncOutboxItems)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.priority, mode: OrderingMode.desc)
          ]))
        .get();

    // Limit batch size to prevent overwhelming the server
    const batchSize = 10;
    final itemsToProcess = outboxItems.take(batchSize);

    final guid = await _boatGuid();
    for (final item in itemsToProcess) {
      try {
        if (item.isDelete) {
          await _remote.deleteBySupabaseId(
            item.targetTable,
            WirePrefix.encodeRecordId(item.targetTable, item.recordId, guid),
          );
        } else {
          final localData = jsonDecode(item.data) as Map<String, dynamic>;
          if (await _outboxItemConflicts(
              item.targetTable, item.recordId, localData, guid)) {
            // Remote moved on while this edit sat in the outbox (e.g. it was
            // queued offline): hold for user resolution instead of the
            // upsert silently clobbering the newer remote value (T5).
            await (_db.delete(_db.syncOutboxItems)
                  ..where((t) => t.id.equals(item.id)))
                .go();
            _processedCount++;
            continue;
          }
          await _remote.upsert(
            item.targetTable,
            WirePrefix.encode(item.targetTable, localData, guid),
          );
        }

        // Success, remove from outbox and update stats
        await (_db.delete(_db.syncOutboxItems)
              ..where((t) => t.id.equals(item.id)))
            .go();
        if (!item.isDelete) {
          // Mirrors InboundSyncApplier.applyRemote's isSynced=true reset —
          // without this, every successful outbound push leaves the local
          // row permanently "dirty", which resurrects resolved conflicts
          // (#180).
          await _markSynced(item.targetTable, item.recordId);
        }

        _processedCount++;
        _lastSyncSuccess = DateTime.now();
      } catch (e) {
        // Failed, increment retry count and update stats
        final newRetryCount = item.retryCount + 1;
        _lastSyncFailure = DateTime.now();
        _failedCount++;
        unawaited(ErrorLogService().logWarning(
          '${item.targetTable} outbox push failed (retry $newRetryCount/5): $e',
          context: 'sync_service: _processOutgoingQueue',
        ));

        if (newRetryCount < 5) {
          // Max 5 retries
          await (_db.update(_db.syncOutboxItems)
                ..where((t) => t.id.equals(item.id)))
              .write(SyncOutboxItemsCompanion(
            retryCount: Value(newRetryCount),
            lastAttemptAt: Value(DateTime.now()),
            lastError: Value(e.toString()),
          ));

          // Schedule retry with exponential backoff: 2^retryCount seconds
          final delaySeconds = pow(2, newRetryCount).toInt().clamp(1, 300);
          final delay = Duration(seconds: delaySeconds);
          _retryTimer?.cancel();
          _retryTimer = Timer(delay, _processOutgoingQueue);
        } else {
          // Give up after 5 retries
          await (_db.delete(_db.syncOutboxItems)
                ..where((t) => t.id.equals(item.id)))
              .go();
        }
      }
    }

    _isProcessingQueue = false;
  }

  /// RESET-SYNC: delete a boat's content rows from Supabase (all wire-prefixed
  /// `<guid>::…` rows across the synced tables), keeping the `boats` row + its
  /// `boat_members` so crew stay linked. Called during a Pro factory reset so
  /// stale remote rows don't sync back and undo the reset.
  Future<void> wipeRemoteBoatContent(String boatGuid) async {
    if (boatGuid.isEmpty) return;
    for (final table in InboundSyncApplier.syncedTables) {
      if (table == 'boats') continue; // keep the boat identity + shareCode
      try {
        await SupabaseClientWrapper.instance
            .from(table)
            .delete()
            .like('supabaseId', '$boatGuid::%');
      } catch (e) {
        // Offline / transient — best effort. Worth surfacing: a stale remote
        // row that fails to clear here can sync back and undo the reset.
        unawaited(ErrorLogService().logWarning(
          '$table: wipeRemoteBoatContent failed for boat $boatGuid: $e',
          context: 'sync_service: wipeRemoteBoatContent',
        ));
      }
    }
  }

  // Public method to force queue processing (for debugging/testing)
  Future<void> forceProcessQueue() async {
    if (await _syncAllowed()) {
      await _processOutgoingQueue();
    }
  }

  // Public method to get queue status
  Future<Map<String, dynamic>> getQueueStatus() async {
    final allItems = await _db.select(_db.syncOutboxItems).get();

    final byTable = <String, int>{};
    for (final item in allItems) {
      byTable[item.targetTable] = (byTable[item.targetTable] ?? 0) + 1;
    }

    final conflictCount = await pendingConflictCount();

    final stats = {
      'totalPending': allItems.length,
      'pendingConflicts': conflictCount,
      'byPriority': {
        0: allItems.where((item) => item.priority == 0).length,
        1: allItems.where((item) => item.priority == 1).length,
        2: allItems.where((item) => item.priority == 2).length,
      },
      'byTable': byTable,
      'deleteOperations': allItems.where((item) => item.isDelete).length,
      'oldestItem': allItems.isNotEmpty
          ? allItems
              .map((item) => item.createdAt)
              .reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'processedToday': _processedCount,
      'failedToday': _failedCount,
      'lastSuccess': _lastSyncSuccess,
      'lastFailure': _lastSyncFailure,
      'isOnline': await _isCurrentlyOnline(),
    };

    return stats;
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _retryTimer?.cancel();
    _queueMonitorTimer?.cancel();
  }
}
