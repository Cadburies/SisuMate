import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/seed/ingredient_drift_seed.dart';
import 'package:sisu_mate/models/models.dart';

// Well before any real seed/test run, but not tied to a specific timezone's
// rendering of the exact UTC epoch instant (which can read back as Dec 1999
// in negative-offset local time) — a robust "this is the factory baseline"
// check.
final _wayInThePast = DateTime.utc(2005);

// SEED-PATCH: bar/pantry catalog rows must be baselined (epoch lastModified +
// isSynced true) at the point they're INSERTED, regardless of whether the
// rest of the database is pristine — a later catalog patch on an
// already-used install must not get a "now" timestamp that could beat an
// older, more meaningful remote change in the inbound LWW comparison.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.setInstanceForTesting(db);
  });

  tearDown(() async => db.close());

  test('seedBarIngredientsToDrift stamps factory epoch, not now', () async {
    await seedBarIngredientsToDrift([
      BarIngredient()
        ..supabaseId = 'bar_test_rum'
        ..name = 'Test Rum'
        ..lastModified = DateTime.now(), // domain default — must be ignored
    ]);

    final row = await db.select(db.barIngredients).getSingle();
    expect(row.lastModified.isBefore(_wayInThePast), isTrue,
        reason: 'must be the factory epoch, not "now"');
    expect(row.isSynced, isTrue);
  });

  test(
      'insertMissingBarIngredientsToDrift baselines a late catalog patch '
      'even when the DB already has real (non-pristine) activity', () async {
    // Simulate an already-used install: one bar ingredient with a real,
    // recent, dirty (unsynced) modification — nothing here is "pristine".
    await db.into(db.barIngredients).insert(BarIngredientsCompanion.insert(
          supabaseId: const drift.Value('bar_existing'),
          name: const drift.Value('Existing, user-touched'),
          lastModified: drift.Value(DateTime.now()),
          isSynced: const drift.Value(false),
        ));

    // A later app update adds a brand-new catalog item.
    final inserted = await insertMissingBarIngredientsToDrift([
      BarIngredient()
        ..supabaseId = 'bar_existing'
        ..name = 'Existing, user-touched', // already present — skipped
      BarIngredient()
        ..supabaseId = 'bar_new_patch_item'
        ..name = 'New Patch Item',
    ]);

    expect(inserted, 1, reason: 'only the genuinely new item is inserted');
    final patched = await (db.select(db.barIngredients)
          ..where((t) => t.supabaseId.equals('bar_new_patch_item')))
        .getSingle();
    expect(patched.lastModified.isBefore(_wayInThePast), isTrue,
        reason: 'new patch row must be baselined even though the DB is not '
            'globally pristine');
    expect(patched.isSynced, isTrue);
  });

  test('seedPantryIngredientsToDrift stamps factory epoch, not now', () async {
    await seedPantryIngredientsToDrift([
      PantryIngredient()
        ..supabaseId = 'pantry_test_salt'
        ..name = 'Test Salt'
        ..lastModified = DateTime.now(),
    ]);

    final row = await db.select(db.pantryIngredients).getSingle();
    expect(row.lastModified.isBefore(_wayInThePast), isTrue);
    expect(row.isSynced, isTrue);
  });
}
