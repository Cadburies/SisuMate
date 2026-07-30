import 'package:drift/drift.dart';
import '../data/drift/app_database.dart';
import '../data/seed/bundled_data_seeder.dart';
import '../data/seed/seed_expansion_catalog.dart';

enum DbInitResult { healthy, seeded, corrupted }

/// The app's local-database lifecycle service, backed by Drift (SQLite).
/// Handles first-run seeding, health checks, and factory/hard resets.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const _defaultBoatSupabaseId =
      '00000000-0000-0000-0000-000000000000';

  AppDatabase get _db => AppDatabase.instance;

  /// Opens the DB and, if empty, runs a full first-install seed.
  ///
  /// Bar/pantry ingredient catch-up is **not** run here — call
  /// [runDeferredSeeds] after the first frame / home navigation (RT1) so
  /// restarts don't block the splash on that diff/sync work.
  Future<DbInitResult> init() async {
    try {
      // Seed sentinel: an empty checklist-groups table means a fresh install.
      // The first query also forces Drift to open the file, surfacing any
      // corruption here so we can offer a reset.
      final groupCount = (await _db.select(_db.checklistGroups).get()).length;
      if (groupCount == 0) {
        await _seedFresh();
        return DbInitResult.seeded;
      }
      return DbInitResult.healthy;
    } catch (_) {
      return DbInitResult.corrupted;
    }
  }

  /// Additive catalog work safe on every launch (no wipe of user flags).
  /// Delegates to [seedExpansionCatalog] — the single call site for bar/pantry
  /// ingredients, which diff-insert any newly-added hardcoded rows on every
  /// launch. Recipe expansion packs (cocktails/menus import, coverage
  /// cocktails) are NOT here — they're seeded once, first-install only, from
  /// inside `seed_recipes.dart`.
  Future<void> runDeferredSeeds() async {
    try {
      // Pristine = no user activity yet (everything still at the factory
      // baseline), i.e. this is the first launch after a fresh seed.
      final pristine = await _isPristine();
      await seedExpansionCatalog(_defaultBoatSupabaseId);
      if (pristine) await markFactoryBaseline();
    } catch (_) {
      // Non-fatal: app remains usable with existing local data.
    }
  }

  /// Factory rows are "older than any user change and have nothing to push":
  /// `lastModified` = epoch, `isSynced` = true. Without this, a crew member's
  /// freshly-seeded rows (dirty + now-timestamps) beat the owner's earlier
  /// changes in the inbound LWW/conflict logic, masking shared boat progress.
  /// Only call when every content row is factory (fresh seed / pristine DB).
  ///
  /// SEED-PATCH: `BarIngredients`/`PantryIngredients` are NOT re-stamped here —
  /// `ingredient_drift_seed.dart`'s insert helpers stamp the epoch directly at
  /// row-creation time (fresh seed AND later catalog patches alike), which is
  /// correct regardless of whether the rest of the DB is pristine. Re-stamping
  /// the whole table here would be redundant, and worse, would be the ONLY
  /// thing correctly baselining a later-patched row if that logic ever drifted
  /// — the fix belongs at the single point where these rows are created.
  static final factoryEpoch = DateTime.utc(2000);

  Future<void> markFactoryBaseline() async {
    final lm = Value(factoryEpoch);
    const synced = Value(true);
    await _db.update(_db.checklistGroups)
        .write(ChecklistGroupsCompanion(lastModified: lm, isSynced: synced));
    await _db.update(_db.checklistItems)
        .write(ChecklistItemsCompanion(lastModified: lm, isSynced: synced));
    await _db.update(_db.shoppingCategories)
        .write(ShoppingCategoriesCompanion(lastModified: lm, isSynced: synced));
    await _db.update(_db.shoppingItems)
        .write(ShoppingItemsCompanion(lastModified: lm, isSynced: synced));
    await _db.update(_db.recipes)
        .write(RecipesCompanion(lastModified: lm, isSynced: synced));
    await _db.update(_db.recipeIngredients)
        .write(RecipeIngredientsCompanion(lastModified: lm, isSynced: synced));
  }

  Future<bool> _isPristine() async {
    final row = await (_db.select(_db.checklistItems)
          ..where((t) => t.lastModified.isBiggerThanValue(factoryEpoch))
          ..limit(1))
        .getSingleOrNull();
    return row == null;
  }

  /// Normal reset: wipes all data and re-seeds. Requires the database to open.
  Future<void> factoryReset() async {
    await _db.transaction(() async {
      for (final table in _db.allTables) {
        await _db.delete(table).go();
      }
    });
    await _seedFresh();
  }

  /// Hard reset: deletes the database file on disk and re-initialises from
  /// scratch. Used when the database is corrupted and cannot be opened.
  Future<DbInitResult> hardReset() async {
    await AppDatabase.deleteAndRecreate();
    return await init();
  }

  Future<void> _seedFresh() async {
    await _seedInitialUserSettings();
    await seedBundledData();
    await markFactoryBaseline();
  }

  Future<void> _seedInitialUserSettings() async {
    // Seed the default singleton settings row (id=1) if none exists.
    await _db.into(_db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(id: const Value(1)),
          mode: InsertMode.insertOrIgnore,
        );
  }
}
