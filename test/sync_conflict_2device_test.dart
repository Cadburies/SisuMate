import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/services/sync_service.dart';

import 'test_helpers/fake_supabase_remote.dart';

// Same connectivity-channel stub used by sync_service_test.dart — both
// simulated "devices" share one process, so this affects whichever device
// calls into sync next (tests set it immediately before each call).
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

/// One simulated device: its own local Drift DB + SyncService, talking to a
/// [FakeSupabaseRemote] that's shared across devices — the fake stands in for
/// the real Supabase backend both devices sync through.
class _Device {
  final AppDatabase db;
  final ProviderContainer container;
  final SyncService sync;

  _Device._(this.db, this.container, this.sync);

  static _Device create(FakeSupabaseRemote sharedRemote) {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      supabaseRemoteProvider.overrideWithValue(sharedRemote),
    ]);
    return _Device._(db, container, container.read(syncServiceProvider));
  }

  Future<void> dispose() async {
    container.dispose();
    await db.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Two devices intentionally means two AppDatabase instances alive at once.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('Two-device offline-edit sync conflict (SUG2 / T5)', () {
    late FakeSupabaseRemote remote;
    late _Device deviceA;
    late _Device deviceB;

    setUp(() {
      remote = FakeSupabaseRemote();
      deviceA = _Device.create(remote);
      deviceB = _Device.create(remote);
      RevenueCatService.debugProOverrideForTests = true;
    });

    tearDown(() async {
      RevenueCatService.debugProOverrideForTests = null;
      await deviceA.dispose();
      await deviceB.dispose();
    });

    test(
        'a stale offline edit never overwrites a newer remote edit — it is '
        'logged as a conflict and dropped instead', () async {
      final t1 = DateTime.utc(2026, 1, 2); // Device A's offline edit time.
      final t2 = DateTime.utc(2026, 1, 3); // Device B's online edit time (newer).

      // Device A edits the boat while offline — queues locally, no push.
      _mockConnectivity(false);
      await deviceA.sync.queueOutgoingChange('boats', {
        'supabaseId': 'b1',
        'name': 'From A (offline)',
        'lastModified': t1.toIso8601String(),
      });
      expect(await deviceA.sync.pendingQueueSize(), 1);

      // Device B edits the same boat while online — pushes immediately.
      _mockConnectivity(true);
      await deviceB.sync.queueOutgoingChange('boats', {
        'supabaseId': 'b1',
        'name': 'From B (online)',
        'lastModified': t2.toIso8601String(),
      });
      expect(remote.upserts, hasLength(1));

      // Device A reconnects and flushes its queue.
      _mockConnectivity(true);
      await deviceA.sync.forceProcessQueue();

      // A's stale edit must never have reached the shared remote.
      expect(remote.upserts, hasLength(1),
          reason: "device A's stale push must not overwrite B's newer edit");
      expect(remote.upserts.single.$2['name'], 'From B (online)');

      // The stale item is dropped from A's outbox, not retried forever.
      expect(await deviceA.sync.pendingQueueSize(), 0);

      // A conflict is logged locally on device A for the user to resolve.
      final conflicts = await (deviceA.db.select(deviceA.db.conflictLogs)
            ..where((t) => t.resolution.equals('pending')))
          .get();
      expect(conflicts, hasLength(1));
      expect(conflicts.first.targetTable, 'boats');
      expect(conflicts.first.localSupabaseId, 'b1');
    });

    test(
        'an offline edit made after the remote state was captured pushes '
        'normally with no conflict', () async {
      final t1 = DateTime.utc(2026, 1, 3); // Device B's online edit time.
      final t2 = DateTime.utc(2026, 1, 4); // Device A's offline edit — newer.

      _mockConnectivity(true);
      await deviceB.sync.queueOutgoingChange('boats', {
        'supabaseId': 'b1',
        'name': 'From B (online)',
        'lastModified': t1.toIso8601String(),
      });

      _mockConnectivity(false);
      await deviceA.sync.queueOutgoingChange('boats', {
        'supabaseId': 'b1',
        'name': 'From A (offline, but newer)',
        'lastModified': t2.toIso8601String(),
      });

      _mockConnectivity(true);
      await deviceA.sync.forceProcessQueue();

      expect(await deviceA.sync.pendingQueueSize(), 0);
      final conflicts = await (deviceA.db.select(deviceA.db.conflictLogs)
            ..where((t) => t.resolution.equals('pending')))
          .get();
      expect(conflicts, isEmpty);

      // A's newer edit did land on the shared remote.
      expect(remote.upserts, hasLength(2));
      expect(remote.upserts.last.$2['name'], 'From A (offline, but newer)');
    });
  });
}
