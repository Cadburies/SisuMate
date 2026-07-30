import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/sync_service.dart';

/// A no-op-safe `SyncService` for repository tests. Repositories call
/// `syncService.queueOutgoingChange(...)` on every write; in a test process
/// there's no real device/RevenueCat entitlement, so `isPro` resolves to
/// `false` (RevenueCatService.init() fails safely without a platform channel
/// and isPro() returns false) and the call returns immediately without
/// touching the network.
///
/// `SyncService` needs a working Riverpod `Ref` (a `ProviderContainer`) and,
/// since S1, an `AppDatabase` — its outbox and settings reads are Drift-backed.
/// We override `appDatabaseProvider` with an isolated in-memory DB so the
/// fire-and-forget `_init()` reads an empty settings table (→ null → no sync)
/// instead of hitting the real on-device sqlite path.
SyncService testSyncService() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return container.read(syncServiceProvider);
}
