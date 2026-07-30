import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/services/sync_service.dart';

import 'test_helpers/fake_supabase_remote.dart';

// Stubs the connectivity_plus method channel — with no platform binding,
// checkConnectivity() throws MissingPluginException uncaught, since that call
// in queueOutgoingChange sits outside any try/catch.
void _mockConnectivity(bool online) {
  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'check') {
      return <String>[online ? 'wifi' : 'none'];
    }
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncService outbox / queue status (T6)', () {
    late AppDatabase db;
    late ProviderContainer container;
    late SyncService sync;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      sync = container.read(syncServiceProvider);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('getQueueStatus reports empty outbox', () async {
      final status = await sync.getQueueStatus();
      expect(status['totalPending'], 0);
      expect(status['pendingConflicts'], 0);
      expect(status['byTable'], isA<Map>());
      expect(status['processedToday'], 0);
      expect(status.containsKey('isOnline'), isTrue);
    });

    test('queueOutgoingChange is a no-op without Pro (Free gate)', () async {
      // In tests RevenueCat is not Pro — queue must not write outbox rows.
      await sync.queueOutgoingChange('boats', {
        'supabaseId': 'boat-test',
        'name': 'Test',
        'lastModified': DateTime.now().toIso8601String(),
      });
      final n = await sync.pendingQueueSize();
      expect(n, 0);
    });

    test('getQueueStatus counts seeded outbox rows', () async {
      await db.into(db.syncOutboxItems).insert(SyncOutboxItemsCompanion.insert(
            targetTable: const Value('boats'),
            recordId: const Value('b1'),
            operation: const Value('upsert'),
            data: const Value('{}'),
            priority: const Value(2),
          ));
      await db.into(db.syncOutboxItems).insert(SyncOutboxItemsCompanion.insert(
            targetTable: const Value('boats'),
            recordId: const Value('b2'),
            operation: const Value('delete'),
            data: const Value('{}'),
            isDelete: const Value(true),
          ));
      await db.into(db.syncOutboxItems).insert(SyncOutboxItemsCompanion.insert(
            targetTable: const Value('checklist_items'),
            recordId: const Value('c1'),
            data: const Value('{}'),
          ));

      final status = await sync.getQueueStatus();
      expect(status['totalPending'], 3);
      expect(status['deleteOperations'], 1);
      final byTable = status['byTable'] as Map;
      expect(byTable['boats'], 2);
      expect(byTable['checklist_items'], 1);
      final byPriority = status['byPriority'] as Map;
      expect(byPriority[2], 1);
    });

    test('pendingConflictCount is zero with empty ConflictLogs', () async {
      expect(await sync.pendingConflictCount(), 0);
    });
  });

  group('SyncService outbox — Pro-mocked push/retry (TEST1b)', () {
    late AppDatabase db;
    late ProviderContainer container;
    late SyncService sync;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      sync = container.read(syncServiceProvider);
      RevenueCatService.debugProOverrideForTests = true;
    });

    tearDown(() async {
      RevenueCatService.debugProOverrideForTests = null;
      container.dispose();
      await db.close();
    });

    test('Pro + offline: queues directly without attempting a push', () async {
      _mockConnectivity(false);
      await sync.queueOutgoingChange('boats', {
        'supabaseId': 'boat-test',
        'name': 'Test',
        'lastModified': DateTime.now().toUtc().toIso8601String(),
      });
      expect(await sync.pendingQueueSize(), 1);
    });

    test(
        'Pro + online: a push with no real backend fails safely and queues '
        'for retry (rather than throwing or silently dropping the edit)',
        () async {
      _mockConnectivity(true);
      await sync.queueOutgoingChange('boats', {
        'supabaseId': 'boat-test',
        'name': 'Test',
        'lastModified': DateTime.now().toUtc().toIso8601String(),
      });
      expect(await sync.pendingQueueSize(), 1);
    });

    test('Pro + online: retryCount increments on repeated failure, item '
        'persists under the 5-retry cap', () async {
      _mockConnectivity(true);
      await db.into(db.syncOutboxItems).insert(SyncOutboxItemsCompanion.insert(
            targetTable: const Value('boats'),
            recordId: const Value('boat-1'),
            data: const Value(
                '{"supabaseId":"boat-1","name":"Test","lastModified":"2026-01-01T00:00:00.000Z"}'),
            retryCount: const Value(2),
          ));

      await sync.forceProcessQueue();

      final row =
          (await db.select(db.syncOutboxItems).get()).single;
      expect(row.retryCount, 3);
      expect(row.lastError != null, isTrue);
      expect(sync.failedCount, 1);
    });

    test('Pro + online: item is dropped once retries exceed the 5-retry cap',
        () async {
      _mockConnectivity(true);
      await db.into(db.syncOutboxItems).insert(SyncOutboxItemsCompanion.insert(
            targetTable: const Value('boats'),
            recordId: const Value('boat-1'),
            data: const Value(
                '{"supabaseId":"boat-1","name":"Test","lastModified":"2026-01-01T00:00:00.000Z"}'),
            retryCount: const Value(4),
          ));

      await sync.forceProcessQueue();

      expect(await sync.pendingQueueSize(), 0,
          reason: 'give up after 5 retries — must not retry forever');
    });
  });

  // TEST2 — success paths with injectable FakeSupabaseRemote.
  group('SyncService outbox — network succeeds (TEST2)', () {
    late AppDatabase db;
    late ProviderContainer container;
    late SyncService sync;
    late FakeSupabaseRemote remote;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      remote = FakeSupabaseRemote();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          supabaseRemoteProvider.overrideWithValue(remote),
        ],
      );
      sync = container.read(syncServiceProvider);
      RevenueCatService.debugProOverrideForTests = true;
    });

    tearDown(() async {
      RevenueCatService.debugProOverrideForTests = null;
      container.dispose();
      await db.close();
    });

    test(
        'Pro + online: successful upsert leaves outbox empty and records push',
        () async {
      _mockConnectivity(true);
      await sync.queueOutgoingChange('boats', {
        'supabaseId': 'boat-ok',
        'name': 'Sisu',
        'lastModified': DateTime.now().toUtc().toIso8601String(),
      });

      expect(await sync.pendingQueueSize(), 0,
          reason: 'successful online push must not queue for retry');
      expect(remote.upserts, hasLength(1));
      expect(remote.upserts.single.$1, 'boats');
      expect(
        remote.upserts.single.$2['supabaseId'],
        contains('boat-ok'),
      );
    });

    test(
        'Pro + online: forceProcessQueue drains outbox on successful upsert',
        () async {
      _mockConnectivity(true);
      await db.into(db.syncOutboxItems).insert(SyncOutboxItemsCompanion.insert(
            targetTable: const Value('boats'),
            recordId: const Value('boat-queued'),
            data: const Value(
                '{"supabaseId":"boat-queued","name":"Queued","lastModified":"2026-07-01T00:00:00.000Z"}'),
          ));

      await sync.forceProcessQueue();

      expect(await sync.pendingQueueSize(), 0);
      expect(sync.processedCount, 1);
      expect(remote.upserts, hasLength(1));
      expect(remote.upserts.single.$2['supabaseId'], contains('boat-queued'));
    });

    test(
        'Pro + online: successful delete leaves outbox empty and records delete',
        () async {
      _mockConnectivity(true);
      await sync.queueOutgoingChange(
        'boats',
        {
          'supabaseId': 'boat-del',
          'name': 'Gone',
          'lastModified': DateTime.now().toUtc().toIso8601String(),
        },
        isDelete: true,
      );

      expect(await sync.pendingQueueSize(), 0);
      expect(remote.deletes, hasLength(1));
      expect(remote.deletes.single.$1, 'boats');
      expect(remote.deletes.single.$2, contains('boat-del'));
    });
  });
}
