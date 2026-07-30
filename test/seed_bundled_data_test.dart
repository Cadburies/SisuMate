import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/seed/bundled_data_seeder.dart';
import 'package:sisu_mate/data/seed/seed_expansion_catalog.dart';

/// TEST1b — full-seed row counts + referential integrity + idempotency.
/// Guards against the recurring class of seed bugs in this project (items
/// pointing at missing groups, empty catalogs, double-seeding).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.setInstanceForTesting(db);
    await seedBundledData();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> count(dynamic table) async => (await db.select(table).get()).length;

  test('seeds exactly one default boat', () async {
    expect(await count(db.boats), 1);
  });

  test('seeds a non-empty catalog for every core module', () async {
    expect(await count(db.checklistGroups), greaterThan(0));
    expect(await count(db.checklistItems), greaterThan(0));
    expect(await count(db.shoppingCategories), greaterThan(0));
    // Note: the trip list (shoppingItems) is intentionally seeded empty —
    // only categories ship; the user adds items.
    expect(await count(db.recipes), greaterThan(0));
    // Bar/pantry ingredients are NOT part of seedBundledData() — they're
    // seedExpansionCatalog()'s job (deferred, after first navigation). See
    // the group below. Cocktails/menus import + coverage cocktails ARE part
    // of the base recipe count above — they're seeded inside seedRecipes()
    // itself, not deferred.
  });

  group('seedExpansionCatalog (deferred catalog packs)', () {
    test('seeds bar and pantry ingredients', () async {
      expect(await count(db.barIngredients), 0);
      expect(await count(db.pantryIngredients), 0);

      await seedExpansionCatalog(
          '00000000-0000-0000-0000-000000000000');

      expect(await count(db.barIngredients), greaterThan(0));
      expect(await count(db.pantryIngredients), greaterThan(0));
    });

    test('is idempotent (no duplicate rows on a second call)', () async {
      await seedExpansionCatalog(
          '00000000-0000-0000-0000-000000000000');
      final barBefore = await count(db.barIngredients);
      final pantryBefore = await count(db.pantryIngredients);

      await seedExpansionCatalog(
          '00000000-0000-0000-0000-000000000000');

      expect(await count(db.barIngredients), barBefore);
      expect(await count(db.pantryIngredients), pantryBefore);
    });
  });

  test('every checklist item references an existing group', () async {
    final groupIds =
        (await db.select(db.checklistGroups).get()).map((g) => g.supabaseId).toSet();
    final items = await db.select(db.checklistItems).get();
    final orphans =
        items.where((i) => !groupIds.contains(i.groupSupabaseId)).toList();
    expect(orphans, isEmpty,
        reason: 'orphaned items: ${orphans.map((o) => o.supabaseId).toList()}');
  });

  test('seeds exactly one checklist group per bundled seed source (TEST1b)',
      () async {
    // 15 seed_*_checks.dart calls in bundled_data_seeder.dart, one group
    // each. A regression here means a seed source silently stopped creating
    // its group (or started creating more than one).
    expect(await count(db.checklistGroups), 15);
  });

  test('seeds the expected shopping category count (TEST1b)', () async {
    expect(await count(db.shoppingCategories), 12);
  });

  test(
      'user-only modules start empty — never bundle-seeded (TEST1b)',
      () async {
    expect(await count(db.crewMembers), 0);
    expect(await count(db.documents), 0);
    expect(await count(db.maintenanceTasks), 0);
    expect(await count(db.inventoryItems), 0);
    expect(await count(db.fuelLogEntries), 0);
    expect(await count(db.captainLogEntries), 0);
  });

  test('re-running the seeder is idempotent (no duplicate rows)', () async {
    final before = await count(db.checklistGroups);
    final itemsBefore = await count(db.checklistItems);
    await seedBundledData();
    expect(await count(db.checklistGroups), before);
    expect(await count(db.checklistItems), itemsBefore);
  });
}
