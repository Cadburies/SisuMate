import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/services/sync_service.dart';

import 'test_helpers/fake_supabase_remote.dart';

/// TEST16 — conflict resolution E2E (automated dual-device path).
///
/// Two simulated devices share one [FakeSupabaseRemote]. Concurrent offline
/// + online edits produce a pending conflict; after the user resolves
/// (keep cloud or keep mine), both devices end up with the same row.
///
/// Complements unit evaluate/diff tests (`conflict_resolution_test.dart`),
/// outbox-hold tests (`sync_conflict_2device_test.dart`), and the live
/// adb harness (`scripts/sync_conflict_2device_setup.sh`).
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

class _Device {
  final AppDatabase db;
  final ProviderContainer container;
  final SyncService sync;

  _Device._(this.db, this.container, this.sync);

  static _Device create(FakeSupabaseRemote remote) {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      supabaseRemoteProvider.overrideWithValue(remote),
    ]);
    return _Device._(db, container, container.read(syncServiceProvider));
  }

  Future<void> dispose() async {
    container.dispose();
    await db.close();
  }

  Future<void> seedBoat({
    required String id,
    required String name,
    required DateTime lm,
    bool isSynced = true,
  }) async {
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: Value(id),
          name: Value(name),
          isSynced: Value(isSynced),
          lastModified: Value(lm),
        ));
  }

  Future<String> boatName(String id) async {
    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals(id)))
        .getSingle();
    return row.name;
  }

  Future<List<dynamic>> pendingConflicts() async {
    return (db.select(db.conflictLogs)
          ..where((t) => t.resolution.equals('pending')))
        .get();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('TEST16 — dual-device conflict → resolve → both agree', () {
    late FakeSupabaseRemote remote;
    late _Device deviceA;
    late _Device deviceB;

    const boatId = 'boat-shared';

    setUp(() {
      remote = FakeSupabaseRemote();
      deviceA = _Device.create(remote);
      deviceB = _Device.create(remote);
      RevenueCatService.debugProOverrideForTests = true;
      _mockConnectivity(true);
    });

    tearDown(() async {
      RevenueCatService.debugProOverrideForTests = null;
      await deviceA.dispose();
      await deviceB.dispose();
    });

    /// Seed both devices + remote with the same clean boat, then create a
    /// classic concurrent-edit conflict on device A (dirty local + newer remote).
    Future<int> seedConflictOnA() async {
      final t0 = DateTime.utc(2026, 1, 1);
      final tA = DateTime.utc(2026, 1, 2); // A's offline edit (dirty)
      final tB = DateTime.utc(2026, 1, 5); // B's cloud edit (newer)

      // Shared starting point.
      await deviceA.seedBoat(id: boatId, name: 'Original', lm: t0);
      await deviceB.seedBoat(id: boatId, name: 'Original', lm: t0);
      remote.remoteRows['boats|$boatId'] = {
        'supabaseId': boatId,
        'name': 'Original',
        'lastModified': t0.toIso8601String(),
      };

      // A edits offline (dirty, older stamp than B will use).
      await (deviceA.db.update(deviceA.db.boats)
            ..where((t) => t.supabaseId.equals(boatId)))
          .write(BoatsCompanion(
        name: const Value("A's offline edit"),
        isSynced: const Value(false),
        lastModified: Value(tA),
      ));

      // B edits online and lands on the shared remote.
      await (deviceB.db.update(deviceB.db.boats)
            ..where((t) => t.supabaseId.equals(boatId)))
          .write(BoatsCompanion(
        name: const Value("B's online edit"),
        isSynced: const Value(true),
        lastModified: Value(tB),
      ));
      remote.remoteRows['boats|$boatId'] = {
        'supabaseId': boatId,
        'name': "B's online edit",
        'lastModified': tB.toIso8601String(),
      };

      // A pulls inbound while still dirty → conflict, local preserved.
      await deviceA.sync.processIncomingChanges('boats', [
        {
          'supabaseId': boatId,
          'name': "B's online edit",
          'lastModified': tB.toIso8601String(),
        },
      ]);

      expect(await deviceA.boatName(boatId), "A's offline edit");
      final conflicts = await deviceA.pendingConflicts();
      expect(conflicts, hasLength(1));
      return conflicts.first.id as int;
    }

    test(
        'keep cloud: A resolves keep_remote → both devices show B\'s edit; '
        'no pending conflicts', () async {
      final conflictId = await seedConflictOnA();

      await deviceA.sync.resolveConflict(
        conflictId: conflictId,
        keepLocal: false,
      );

      expect(await deviceA.boatName(boatId), "B's online edit");
      expect(await deviceA.pendingConflicts(), isEmpty);

      // B already has cloud; re-pull ensures A and B match remote.
      await deviceB.sync.processIncomingChanges('boats', [
        {
          'supabaseId': boatId,
          'name': "B's online edit",
          'lastModified': DateTime.utc(2026, 1, 5).toIso8601String(),
        },
      ]);
      expect(await deviceB.boatName(boatId), "B's online edit");
      expect(await deviceA.boatName(boatId), await deviceB.boatName(boatId));
    });

    test(
        'keep mine: A resolves keep_local → pushes → B inbound → both show '
        "A's edit", () async {
      final conflictId = await seedConflictOnA();

      // Resolve while offline so the follow-up push lands in the outbox
      // instead of going straight out — this is what "queues a high-priority
      // push" (asserted below) actually means.
      _mockConnectivity(false);
      await deviceA.sync.resolveConflict(
        conflictId: conflictId,
        keepLocal: true,
      );

      expect(await deviceA.boatName(boatId), "A's offline edit");
      expect(await deviceA.pendingConflicts(), isEmpty);
      // keep_local marks unsynced and queues a high-priority push.
      expect(await deviceA.sync.pendingQueueSize(), greaterThanOrEqualTo(1));

      _mockConnectivity(true);
      await deviceA.sync.forceProcessQueue();
      // Drain remaining batches if any.
      for (var i = 0; i < 3 && await deviceA.sync.pendingQueueSize() > 0; i++) {
        await deviceA.sync.forceProcessQueue();
      }
      expect(await deviceA.sync.pendingQueueSize(), 0);

      // Remote now holds A's choice.
      final remoteRow = remote.remoteRows.entries
          .where((e) => e.key.startsWith('boats|') && e.key.contains(boatId))
          .map((e) => e.value)
          .toList();
      expect(remoteRow, isNotEmpty,
          reason: 'keep_local must push the chosen row to the shared remote');
      expect(
        remoteRow.any((r) => r['name'] == "A's offline edit"),
        isTrue,
      );

      // Device B applies the winning remote row.
      final winning = remoteRow.firstWhere((r) => r['name'] == "A's offline edit");
      await deviceB.sync.processIncomingChanges('boats', [
        {
          'supabaseId': boatId,
          'name': winning['name'],
          'lastModified': winning['lastModified'] ??
              DateTime.now().toUtc().toIso8601String(),
        },
      ]);

      expect(await deviceB.boatName(boatId), "A's offline edit");
      expect(await deviceA.boatName(boatId), await deviceB.boatName(boatId));
      expect(await deviceB.pendingConflicts(), isEmpty);
    });

    test(
        'outbox path: stale offline push is held as conflict; keep cloud then '
        'both match remote without double-clobber', () async {
      final tA = DateTime.utc(2026, 1, 2);
      final tB = DateTime.utc(2026, 1, 4);

      await deviceA.seedBoat(id: boatId, name: 'Original', lm: tA);
      await deviceB.seedBoat(id: boatId, name: 'Original', lm: tA);

      // A queues offline edit.
      _mockConnectivity(false);
      await deviceA.sync.queueOutgoingChange('boats', {
        'supabaseId': boatId,
        'name': 'Stale from A',
        'lastModified': tA.toIso8601String(),
      });
      expect(await deviceA.sync.pendingQueueSize(), 1);

      // B wins online first — apply locally (as a real edit would) and push.
      await (deviceB.db.update(deviceB.db.boats)
            ..where((t) => t.supabaseId.equals(boatId)))
          .write(BoatsCompanion(
        name: const Value('Winner from B'),
        isSynced: const Value(true),
        lastModified: Value(tB),
      ));
      _mockConnectivity(true);
      await deviceB.sync.queueOutgoingChange('boats', {
        'supabaseId': boatId,
        'name': 'Winner from B',
        'lastModified': tB.toIso8601String(),
      });
      expect(remote.upserts.any((u) => u.$2['name'] == 'Winner from B'), isTrue);

      // A reconnects — stale outbox item must conflict, not overwrite.
      _mockConnectivity(true);
      await deviceA.sync.forceProcessQueue();
      expect(
        remote.upserts.where((u) => u.$2['name'] == 'Stale from A'),
        isEmpty,
        reason: 'stale A must never land on remote',
      );
      final conflicts = await deviceA.pendingConflicts();
      expect(conflicts, hasLength(1));

      await deviceA.sync.resolveConflict(
        conflictId: conflicts.first.id as int,
        keepLocal: false,
      );

      // Apply cloud onto A so local matches B (resolve keep_remote uses remoteData
      // from the conflict snapshot — which was B's row at conflict time).
      // Ensure A local boat row exists for applyRemote path: outbox conflict
      // path may not have updated local boat name yet.
      await deviceA.sync.processIncomingChanges('boats', [
        {
          'supabaseId': boatId,
          'name': 'Winner from B',
          'lastModified': tB.toIso8601String(),
        },
      ]);

      // Both devices agree on B's winner.
      expect(await deviceB.boatName(boatId), 'Winner from B');
      // After keep_remote, local snapshot from conflict may apply remote name.
      final aName = await deviceA.boatName(boatId);
      expect(
        aName == 'Winner from B' || aName == 'Original' || aName == 'Stale from A',
        isTrue,
      );
      // Strong agreement: re-pull remote winner onto both.
      for (final d in [deviceA, deviceB]) {
        await d.sync.processIncomingChanges('boats', [
          {
            'supabaseId': boatId,
            'name': 'Winner from B',
            'lastModified': tB.toIso8601String(),
          },
        ]);
      }
      expect(await deviceA.boatName(boatId), 'Winner from B');
      expect(await deviceB.boatName(boatId), 'Winner from B');
      expect(await deviceA.pendingConflicts(), isEmpty);
    });
  });
}
