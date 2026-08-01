import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/core/factory_reset.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/providers/shopping_provider.dart';
import 'package:sisu_mate/services/database_service.dart';

/// TEST29 — factory reset wipes user data, reseeds catalog, and call sites
/// invalidate FutureProviders that would otherwise keep pre-wipe rows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.setInstanceForTesting(db);
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
  });

  Future<void> seedThenDirty() async {
    await DatabaseService().init();
    // User shopping line (trip list is empty after seed).
    await db.into(db.shoppingCategories).insert(
          ShoppingCategoriesCompanion.insert(
            supabaseId: const Value('cat_user'),
            name: const Value('User Stuff'),
          ),
        );
    await db.into(db.shoppingItems).insert(
          ShoppingItemsCompanion.insert(
            supabaseId: const Value('user_item_1'),
            categorySupabaseId: const Value('cat_user'),
            name: const Value('My custom fender'),
          ),
        );
    await db.into(db.captainLogEntries).insert(
          CaptainLogEntriesCompanion.insert(
            supabaseId: const Value('log_user_1'),
            title: const Value('User passage note'),
          ),
        );
    // Bump free edits so settings row is dirty.
    final settings = await db.select(db.userSettingsTable).getSingle();
    await (db.update(db.userSettingsTable)
          ..where((t) => t.id.equals(settings.id)))
        .write(const UserSettingsTableCompanion(freeEditsUsed: Value(3)));
  }

  group('DatabaseService.factoryReset (TEST29)', () {
    test('wipes user rows then reseeds default boat + checklists', () async {
      await seedThenDirty();
      expect(
        (await db.select(db.shoppingItems).get())
            .any((r) => r.name == 'My custom fender'),
        isTrue,
      );
      expect((await db.select(db.captainLogEntries).get()), isNotEmpty);

      await DatabaseService().factoryReset();

      // User content gone.
      expect(
        (await db.select(db.shoppingItems).get())
            .any((r) => r.name == 'My custom fender'),
        isFalse,
      );
      expect((await db.select(db.captainLogEntries).get()), isEmpty);

      // Factory catalog back.
      expect((await db.select(db.checklistGroups).get()), isNotEmpty);
      expect((await db.select(db.boats).get()), isNotEmpty);
      final settings = await db.select(db.userSettingsTable).getSingle();
      expect(settings.freeEditsUsed, 0);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('second factoryReset is stable (idempotent catalog)', () async {
      await DatabaseService().init();
      final groups1 = (await db.select(db.checklistGroups).get()).length;
      await DatabaseService().factoryReset();
      final groups2 = (await db.select(db.checklistGroups).get()).length;
      await DatabaseService().factoryReset();
      final groups3 = (await db.select(db.checklistGroups).get()).length;
      expect(groups2, groups1);
      expect(groups3, groups1);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('factory baseline stamps after reseed', () async {
      await DatabaseService().init();
      await DatabaseService().factoryReset();
      final items = await db.select(db.checklistItems).get();
      expect(items, isNotEmpty);
      // All factory-stamped to epoch (or at least not "user now" for bulk).
      final epoch = DatabaseService.factoryEpoch;
      final nonFactory =
          items.where((i) => i.lastModified.isAfter(epoch)).length;
      // Allow zero user-touched rows after pure reseed.
      expect(nonFactory, 0);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('invalidateAfterFactoryReset (TEST29)', () {
    test('invalidates FutureProviders so they reload post-wipe', () async {
      await seedThenDirty();
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ]);
      addTearDown(container.dispose);

      // Cache settings FutureProvider with dirty freeEditsUsed.
      final before = await container.read(userSettingsProvider.future);
      expect(before?.freeEditsUsed, 3);

      await DatabaseService().factoryReset();
      // Without invalidate, a cached FutureProvider would still show 3.
      invalidateAfterFactoryResetContainer(container);
      final after = await container.read(userSettingsProvider.future);
      expect(after?.freeEditsUsed, 0);

      final boats = await container.read(boatsProvider.future);
      expect(boats, isNotEmpty);

      // activeBoat may be null after wipe until user picks a boat.
      await container.read(activeBoatProvider.future);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('UI call sites wire invalidate (TEST29 contract)', () {
    test('settings / checklist / safety / drawer import factory_reset helper',
        () {
      for (final path in [
        'lib/ui/settings/settings_screen.dart',
        'lib/ui/checklists/checklist_items_screen.dart',
        'lib/ui/safety/safety_briefing_screen.dart',
        'lib/ui/components/common_drawer.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src, contains('invalidateAfterFactoryReset'), reason: path);
        expect(src, contains('factory_reset.dart'), reason: path);
      }
    });
  });
}
