import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/captain_log_repository_impl.dart';
import 'package:sisu_mate/data/repositories/checklist_repository_impl.dart';
import 'package:sisu_mate/data/repositories/fuel_log_repository_impl.dart';
import 'package:sisu_mate/data/repositories/recipe_repository_impl.dart';
import 'package:sisu_mate/data/repositories/shopping_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/services/sync_service.dart';

import 'test_helpers/fake_supabase_remote.dart';

/// TEST13 — airplane-mode / kill-relaunch persistence + outbox drain.
///
/// Simulates process death with a **file-backed** Drift DB (close → reopen
/// same path). Outbox drain uses Pro + FakeSupabaseRemote so reconnect does
/// not need a live network.
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

  group('TEST13 — kill/relaunch local persistence (file DB)', () {
    late Directory tempDir;
    late String dbPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sisu_test13_');
      dbPath = '${tempDir.path}/app.sqlite';
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<AppDatabase> openDb() async =>
        AppDatabase.forTesting(NativeDatabase(File(dbPath)));

    test(
        'checklist complete, shopping add, log entry, fuel fill, recipe '
        'favourite survive close + reopen (kill + relaunch)', () async {
      // ── Session 1: offline-style writes into file DB ───────────────────
      final db1 = await openDb();
      // Free/no Pro: writes still hit Drift; outbox is a no-op (fine here).
      final sync1 = _syncOn(db1);
      final checklists = ChecklistRepositoryImpl(db1, sync1);
      final shopping = ShoppingRepositoryImpl(db1, sync1);
      final logs = CaptainLogRepositoryImpl(db1, sync1);
      final fuel = FuelLogRepositoryImpl(db1, sync1);
      final recipes = RecipeRepositoryImpl(db1);

      await checklists.createGroup(ChecklistGroup()
        ..supabaseId = 'grp_dep'
        ..boatSupabaseId = 'boat_1'
        ..appType = 'checklist'
        ..title = 'Pre-departure');
      final checkItem = ChecklistItem()
        ..supabaseId = 'chk_bilge'
        ..groupSupabaseId = 'grp_dep'
        ..boatSupabaseId = 'boat_1'
        ..title = 'Check bilge'
        ..name = 'Check bilge';
      await checklists.addItem(checkItem);
      await checklists.toggleComplete(checkItem);

      await shopping.addCategory(ShoppingCategory()
        ..supabaseId = 'cat_deck'
        ..name = 'Deck'
        ..sortOrder = 0);
      await shopping.addItem(ShoppingItem()
        ..supabaseId = 'shop_fenders'
        ..categorySupabaseId = 'cat_deck'
        ..name = 'Fenders'
        ..quantity = 2
        ..origin = 'Deck');

      await logs.addLog(CaptainLogEntry()
        ..supabaseId = 'log_dep'
        ..title = 'Left marina'
        ..logDate = DateTime(2026, 7, 30)
        ..notes = 'Calm seas');

      await fuel.addEntry(FuelLogEntry()
        ..supabaseId = 'fuel_1'
        ..type = 'Fuel'
        ..date = DateTime(2026, 7, 30)
        ..liters = 42.5
        ..pricePerLiter = 1.9
        ..totalCost = 80.75);

      final recipe = Recipe()
        ..supabaseId = 'recipe_mai'
        ..boatSupabaseId = 'boat_1'
        ..name = 'Mai Tai'
        ..recipeType = 'cocktail'
        ..isFavourite = false;
      await recipes.addRecipe(recipe);
      recipe.isFavourite = true;
      await recipes.updateRecipe(recipe);

      await db1.close();

      // ── Session 2: "relaunch" — new process opens same file ────────────
      final db2 = await openDb();
      final sync2 = _syncOn(db2);
      final checklists2 = ChecklistRepositoryImpl(db2, sync2);
      final shopping2 = ShoppingRepositoryImpl(db2, sync2);
      final logs2 = CaptainLogRepositoryImpl(db2, sync2);
      final fuel2 = FuelLogRepositoryImpl(db2, sync2);
      final recipes2 = RecipeRepositoryImpl(db2);

      final items = await checklists2.watchItems('grp_dep').first;
      expect(items, hasLength(1));
      expect(items.single.title, 'Check bilge');
      expect(items.single.isCompleted, isTrue);
      expect(items.single.completedAt, isNotNull);

      final cart = await shopping2.watchItems('cat_deck').first;
      expect(cart.map((i) => i.name), ['Fenders']);
      expect(cart.single.quantity, 2);

      final logList = await logs2.watchLogs().first;
      expect(logList, hasLength(1));
      expect(logList.single.title, 'Left marina');
      expect(logList.single.notes, 'Calm seas');

      final fills = await fuel2.watchEntries().first;
      expect(fills, hasLength(1));
      expect(fills.single.liters, 42.5);
      expect(fills.single.type, 'Fuel');

      final favs = await recipes2.watchRecipes().first;
      expect(favs, hasLength(1));
      expect(favs.single.name, 'Mai Tai');
      expect(favs.single.isFavourite, isTrue);

      await db2.close();
    });
  });

  group('TEST13 — Pro offline outbox survives relaunch; reconnect drains once',
      () {
    late Directory tempDir;
    late String dbPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sisu_test13_outbox_');
      dbPath = '${tempDir.path}/app.sqlite';
      RevenueCatService.debugProOverrideForTests = true;
      _mockConnectivity(false);
    });

    tearDown(() async {
      RevenueCatService.debugProOverrideForTests = null;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<AppDatabase> openDb() async =>
        AppDatabase.forTesting(NativeDatabase(File(dbPath)));

    test(
        'offline writes land in outbox; after reopen, forceProcessQueue '
        'drains without lost local rows or double remote upserts', () async {
      final remote = FakeSupabaseRemote();

      // ── Offline Pro session: several module writes ─────────────────────
      final db1 = await openDb();
      final sync1 = _syncOn(db1, remote: remote);
      final shopping = ShoppingRepositoryImpl(db1, sync1);
      final fuel = FuelLogRepositoryImpl(db1, sync1);
      final logs = CaptainLogRepositoryImpl(db1, sync1);
      final checklists = ChecklistRepositoryImpl(db1, sync1);

      await shopping.addCategory(ShoppingCategory()
        ..supabaseId = 'cat_1'
        ..name = 'Spares');
      await shopping.addItem(ShoppingItem()
        ..supabaseId = 'item_impeller'
        ..categorySupabaseId = 'cat_1'
        ..name = 'Impeller'
        ..quantity = 1);

      await fuel.addEntry(FuelLogEntry()
        ..supabaseId = 'fuel_off'
        ..type = 'Fuel'
        ..liters = 20
        ..date = DateTime(2026, 7, 1));

      await logs.addLog(CaptainLogEntry()
        ..supabaseId = 'log_off'
        ..title = 'Anchored'
        ..logDate = DateTime(2026, 7, 1));

      await checklists.createGroup(ChecklistGroup()
        ..supabaseId = 'g1'
        ..title = 'Watch'
        ..appType = 'checklist');
      final chk = ChecklistItem()
        ..supabaseId = 'c1'
        ..groupSupabaseId = 'g1'
        ..title = 'Log position';
      await checklists.addItem(chk);
      await checklists.toggleComplete(chk);

      final pendingOffline = await sync1.pendingQueueSize();
      expect(pendingOffline, greaterThanOrEqualTo(4),
          reason: 'Pro offline should queue shopping/fuel/log/checklist ops');
      expect(remote.upserts, isEmpty,
          reason: 'offline must not call remote');

      final outboxBeforeClose =
          (await db1.select(db1.syncOutboxItems).get()).length;
      await db1.close();

      // ── Relaunch still offline — outbox must not vanish ────────────────
      final db2 = await openDb();
      final sync2 = _syncOn(db2, remote: remote);
      expect(await sync2.pendingQueueSize(), outboxBeforeClose);

      // Local rows still present after kill.
      expect(
        (await db2.select(db2.shoppingItems).get())
            .map((r) => r.name)
            .toSet(),
        contains('Impeller'),
      );
      expect(
        (await db2.select(db2.fuelLogEntries).get()).map((r) => r.supabaseId),
        contains('fuel_off'),
      );
      expect(
        (await db2.select(db2.captainLogEntries).get())
            .map((r) => r.supabaseId),
        contains('log_off'),
      );
      final chkRow = (await db2.select(db2.checklistItems).get())
          .firstWhere((r) => r.supabaseId == 'c1');
      expect(chkRow.isCompleted, isTrue);

      // ── Reconnect: drain once ──────────────────────────────────────────
      _mockConnectivity(true);
      final pendingBeforeDrain = await sync2.pendingQueueSize();
      await sync2.forceProcessQueue();

      // Batch size is 10 — may need a second pass if more rows queued
      // (categories + items + group + completes can exceed 10).
      var guard = 0;
      while (await sync2.pendingQueueSize() > 0 && guard < 5) {
        await sync2.forceProcessQueue();
        guard++;
      }

      expect(await sync2.pendingQueueSize(), 0,
          reason: 'reconnect must drain entire outbox');
      expect(remote.upserts.length, pendingBeforeDrain,
          reason: 'each outbox row becomes exactly one remote upsert');

      // Second drain must not re-send (no duplicates).
      final upsertsAfterFirst = remote.upserts.length;
      await sync2.forceProcessQueue();
      await sync2.forceProcessQueue();
      expect(remote.upserts.length, upsertsAfterFirst);

      // Local data still intact after drain (not lost).
      expect(
        (await db2.select(db2.shoppingItems).get())
            .map((r) => r.name)
            .toSet(),
        contains('Impeller'),
      );
      expect(
        (await db2.select(db2.fuelLogEntries).get()).map((r) => r.supabaseId),
        contains('fuel_off'),
      );

      // Distinct record ids among upserts for our keys — no lost IDs.
      final pushedIds = remote.upserts
          .map((u) => u.$2['supabaseId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      expect(pushedIds.any((id) => id.contains('item_impeller') || id.contains('Impeller') || id.contains('item_')),
          isTrue);
      // Wire prefix may wrap ids — assert by payload name where needed.
      final pushedNames = remote.upserts
          .map((u) => u.$2['name']?.toString())
          .whereType<String>()
          .toSet();
      expect(pushedNames, contains('Impeller'));

      await db2.close();
    });

    test('failed remote keeps outbox (no silent loss); later success drains',
        () async {
      final remote = FakeSupabaseRemote()..shouldFail = true;
      final db = await openDb();
      final sync = _syncOn(db, remote: remote);
      final fuel = FuelLogRepositoryImpl(db, sync);

      await fuel.addEntry(FuelLogEntry()
        ..supabaseId = 'fuel_retry'
        ..type = 'Water'
        ..liters = 100
        ..date = DateTime(2026, 7, 2));

      expect(await sync.pendingQueueSize(), greaterThanOrEqualTo(1));

      _mockConnectivity(true);
      await sync.forceProcessQueue();
      // Failure path increments retry but keeps the row (until cap).
      expect(await sync.pendingQueueSize(), greaterThanOrEqualTo(1),
          reason: 'failed push must not drop the outbox row');
      expect(remote.upserts, isEmpty);

      remote.shouldFail = false;
      // Clear retry timer noise — process until empty.
      for (var i = 0; i < 6; i++) {
        if (await sync.pendingQueueSize() == 0) break;
        await sync.forceProcessQueue();
      }
      expect(await sync.pendingQueueSize(), 0);
      expect(remote.upserts, isNotEmpty);

      final stillThere = await db.select(db.fuelLogEntries).get();
      expect(stillThere.map((r) => r.supabaseId), contains('fuel_retry'));

      await db.close();
    });
  });
}

/// SyncService wired to [db] (and optional fake remote) via Riverpod overrides.
SyncService _syncOn(AppDatabase db, {FakeSupabaseRemote? remote}) {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      if (remote != null) supabaseRemoteProvider.overrideWithValue(remote),
    ],
  );
  addTearDown(container.dispose);
  return container.read(syncServiceProvider);
}
