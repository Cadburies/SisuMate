import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/inbound_sync_applier.dart';
import 'package:sisu_mate/services/sync_service.dart';

void main() {
  group('InboundSyncApplier table coverage (SYN1/SYN2)', () {
    late AppDatabase db;
    late InboundSyncApplier applier;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      applier = InboundSyncApplier(db);
    });

    tearDown(() async => db.close());

    test('supports outbound-only tables that were missing inbound', () {
      for (final t in [
        'documents',
        'crew_members',
        'inventory_items',
        'fuel_logs',
        'recipes',
        'recipe_ingredients',
        'bar_ingredients',
        'pantry_ingredients',
      ]) {
        expect(applier.supports(t), isTrue, reason: t);
      }
    });

    test('applies remote document into Drift', () async {
      await applier.applyRemote('documents', {
        'supabaseId': 'doc-1',
        'title': 'Passport',
        'type': 'ID',
        'lastModified': '2026-07-09T12:00:00.000',
      });
      final local = await applier.getLocal('documents', 'doc-1');
      expect(local, isNotNull);
      expect(local!.json['title'], 'Passport');
      expect(local.isSynced, isTrue);
    });

    test('applies remote bar ingredient into Drift', () async {
      await applier.applyRemote('bar_ingredients', {
        'supabaseId': 'bar-1',
        'name': 'Gin',
        'inMyBar': true,
        'category': 'spirit',
        'flavorProfiles': ['botanical'],
        'purchaseHistory': [],
        'lastModified': '2026-07-09T12:00:00.000',
      });
      final local = await applier.getLocal('bar_ingredients', 'bar-1');
      expect(local, isNotNull);
      expect(local!.json['name'], 'Gin');
      expect(local.json['inMyBar'], isTrue);
      expect(local.json.containsKey('onHandBase'), isTrue);
      expect(local.json.containsKey('purchaseSizeBase'), isTrue);
    });

    test('applies remote recipe into Drift', () async {
      await applier.applyRemote('recipes', {
        'supabaseId': 'r-1',
        'name': 'Mai Tai',
        'recipeType': 'cocktail',
        'createdAt': '2026-07-01T00:00:00.000',
        'lastModified': '2026-07-09T12:00:00.000',
        'cuisine': ['Tiki'],
        'flavorProfiles': ['citrus'],
        'tastingLog': [],
      });
      final local = await applier.getLocal('recipes', 'r-1');
      expect(local, isNotNull);
      expect(local!.json['name'], 'Mai Tai');
    });
  });

  group('SyncService processIncomingChanges for new tables', () {
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

    test('inbound crew member is inserted', () async {
      await sync.processIncomingChanges('crew_members', [
        {
          'supabaseId': 'crew-1',
          'name': 'Alex',
          'role': 'Captain',
          'lastModified': '2026-07-09T00:00:00.000',
        },
      ]);
      final rows = await db.select(db.crewMembers).get();
      expect(rows, hasLength(1));
      expect(rows.single.name, 'Alex');
    });

    test(
        'inbound hard-delete: local isSynced row vanishes when absent from '
        'stream snapshot (LT2 mirror clear)', () async {
      await sync.processIncomingChanges('inventory_items', [
        {
          'supabaseId': 'inv-keep',
          'name': 'Keep',
          'lastModified': '2026-07-09T00:00:00.000',
        },
        {
          'supabaseId': 'inv-gone',
          'name': 'Gone',
          'lastModified': '2026-07-09T00:00:00.000',
        },
      ]);
      expect(await db.select(db.inventoryItems).get(), hasLength(2));

      // Stream re-emits without inv-gone (remote hard-delete).
      await sync.processIncomingChanges('inventory_items', [
        {
          'supabaseId': 'inv-keep',
          'name': 'Keep',
          'lastModified': '2026-07-09T01:00:00.000',
        },
      ]);
      final rows = await db.select(db.inventoryItems).get();
      expect(rows, hasLength(1));
      expect(rows.single.supabaseId, 'inv-keep');
      expect(rows.single.name, 'Keep');
    });

    test(
        'inbound hard-delete does not wipe unsynced local-only creates',
        () async {
      await db.into(db.crewMembers).insert(
            CrewMembersCompanion.insert(
              supabaseId: const Value('local-only'),
              name: const Value('Offline'),
              isSynced: const Value(false),
            ),
          );
      await sync.processIncomingChanges('crew_members', [
        {
          'supabaseId': 'crew-remote',
          'name': 'Remote',
          'lastModified': '2026-07-09T00:00:00.000',
        },
      ]);
      final ids =
          (await db.select(db.crewMembers).get()).map((r) => r.supabaseId);
      expect(ids, containsAll(['local-only', 'crew-remote']));
    });

    test('inbound hard-delete works for documents and crew_members', () async {
      await sync.processIncomingChanges('documents', [
        {
          'supabaseId': 'doc-1',
          'title': 'Pass',
          'lastModified': '2026-07-09T00:00:00.000',
        },
      ]);
      await sync.processIncomingChanges('crew_members', [
        {
          'supabaseId': 'crew-1',
          'name': 'Bo',
          'lastModified': '2026-07-09T00:00:00.000',
        },
      ]);
      await sync.processIncomingChanges('documents', []);
      await sync.processIncomingChanges('crew_members', []);
      expect(await db.select(db.documents).get(), isEmpty);
      expect(await db.select(db.crewMembers).get(), isEmpty);
    });

    test(
        'empty remote snapshot does not wipe bundled seed recipes/bar '
        '(SEED-SYNC factory isSynced + empty stream)', () async {
      // Simulates factory seed: bundled + isSynced true (markFactoryBaseline).
      await db.into(db.recipes).insert(
            RecipesCompanion.insert(
              supabaseId: const Value('cocktail_mai_tai'),
              name: const Value('Mai Tai'),
              recipeType: const Value('cocktail'),
              isBundled: const Value(true),
              isSynced: const Value(true),
            ),
          );
      await db.into(db.barIngredients).insert(
            BarIngredientsCompanion.insert(
              supabaseId: const Value('bar_gin'),
              name: const Value('Gin'),
              isBundled: const Value(true),
              isSynced: const Value(true),
            ),
          );
      await db.into(db.checklistGroups).insert(
            ChecklistGroupsCompanion.insert(
              supabaseId: const Value('group_watch'),
              title: const Value('Watch checks'),
              isBundled: const Value(true),
              isSynced: const Value(true),
            ),
          );

      // Pro realtime first snapshot is often empty for a boat that never
      // uploaded seed content — must not hard-delete factory rows.
      await sync.processIncomingChanges('recipes', []);
      await sync.processIncomingChanges('bar_ingredients', []);
      await sync.processIncomingChanges('checklist_groups', []);

      expect(await db.select(db.recipes).get(), hasLength(1));
      expect(await db.select(db.barIngredients).get(), hasLength(1));
      expect(await db.select(db.checklistGroups).get(), hasLength(1));
    });
  });
}
