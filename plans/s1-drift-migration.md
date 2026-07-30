# S1 — Migrate from isar_community to Drift (plan / teed-up)

> Status: **COMPLETE (2026-07-06)** — Isar fully retired; the local DB is 100% Drift (SQLite). All 20 collections migrated (GuestProfile, RecipeCollection, CrewMember, InventoryItem, FuelLogEntry, Document, MealPlan, Boat, CaptainLogEntry, MaintenanceTask, ShoppingCategory/Item, ChecklistGroup/Item, Recipe/RecipeIngredient, BarIngredient, PantryIngredient, UserSettings, CommunityTemplate) + sync infra (SyncOutbox→`SyncOutboxItems`; SyncInbox/ConflictLog→reserved tables). `IsarService`→`DatabaseService`; `SyncService` outbox is Drift; embedded types (`MealPlanSlot`, `TastingRecord`, `PurchaseRecord`) are JSON columns; `models.g.dart` deleted; `isar_community*` removed from pubspec. No data migration (fresh-start, per user). **Verified:** analyze clean · test 530/530 · `flutter build apk --debug` succeeds. See `.ai_context/changelog.md` (2026-07-06 entries) for the full breakdown.
> Related: outstanding.md S2 (freezed/json), T4 (models lack copyWith/equality), IMP1 (uniform CRUD).

## Why

`isar_community` is a community fork of an abandoned package. Its `buildQuery()` workaround
(used everywhere instead of `where().findAll()`) is marked experimental and could break on a
dependency bump. Drift (SQLite, maintained by the Flutter/Dart ecosystem, true reactive streams)
is the intended destination. Do it when a major feature next touches the data layer — **not** as a
big-bang rewrite.

## What makes this tractable now (and how to keep it that way)

The app already funnels **all** data access through the repository layer
(`domain/repositories/*` interfaces + `data/repositories/*_impl`), wired in `lib/core/di.dart`.
UI never touches Isar directly (guardrail in CLAUDE.md). So the migration is contained **below the
repository interfaces** — swap each `*_impl` from Isar to Drift, leave the interfaces and every
caller unchanged.

**Uniform CRUD (IMP1 groundwork).** Repositories are being normalized to a consistent
`add* / update* / delete* / watch*` surface. Reality worth knowing: with Isar, `addX` and `updateX`
are *identical* (`isar.put()` is an upsert) — several repos even alias one to the other
(e.g. `ChecklistRepositoryImpl.addItem => updateItem`). Under Drift these split into a real
`insert` vs `update`, so a uniform surface now means the split later is a one-file change per repo,
not a caller hunt. **Action item:** finish auditing every repo for the full triad before migrating.

## Migration order (incremental, one collection at a time)

1. Add `drift` + `drift_flutter` (or `sqlite3_flutter_libs`) alongside Isar — both can coexist during
   the transition.
2. Define Drift tables mirroring each `@collection` model's fields (see `data_models.md §Models`).
   The hand-written `fromJson`/`toJson` on every model map almost 1:1 to Drift row companions — and
   are the same ones IMP1's importer and the sync outbox already use, so keep them.
3. Migrate the **leaf, non-synced** collections first (lowest blast radius): `GuestProfile`,
   `MealPlan`, `RecipeCollection`, `Document`, `CrewMember`, `InventoryItem`, `FuelLogEntry`.
4. Then the sync-participating collections (`Checklist*`, `Shopping*`, `Recipe*`, `Bar/Pantry`,
   `MaintenanceTask`, `CaptainLogEntry`), keeping `SyncService`'s `toJson()` contract identical so the
   outbox/inbox payloads don't change.
5. Register the schema (Drift `@DriftDatabase`) — the analogue of today's `IsarService.schemas`.
   `IsarService.init()`'s health-check / seed-on-empty / `hardReset()` flow needs a Drift equivalent
   (`startup_screen.dart` calls it).
6. One-time **data migration** on upgrade: open the old Isar DB if present, copy rows into Drift,
   then retire Isar. Gate behind a version flag so it runs once.
7. Delete `isar_community`, drop the `buildQuery()` helper, remove the `IsarService` Isar bits.

## Landmines to check before starting

- `buildQuery().findAll()` is used in ~every repo (CLAUDE.md guardrail: never `getAll([])`). Each maps
  to a Drift `select(table).get()`; the sort-in-Dart patterns (e.g. fuel by date desc) can move into
  SQL `orderBy`.
- Embedded/nested types: `MealPlanSlot` is `@embedded` in `MealPlan.slots`; `Recipe.tastingLog` is a
  list of `TastingRecord`. Drift has no embedded — model these as JSON columns or child tables.
- `UserSettings` is a singleton (id=1); keep that invariant.
- Seed data (`bundled_data_seeder.dart`) writes through Isar today; it must write through the same
  repositories (or a Drift batch) after migration.
- Tests: `test/test_helpers/isar_test_helper.dart` opens a real temp Isar per test. Provide a Drift
  in-memory (`NativeDatabase.memory()`) equivalent so the 15+ repository CRUD suites port over
  unchanged (they only touch the repository interfaces).

## Bundle with S2 / T4

While each model is being rewritten as a Drift table, fold in S2/T4: Drift's generated data classes
give immutable rows with `copyWith`/equality/`toString` for free, retiring the hand-written
`fromJson`/`toString` gaps — but keep a JSON codec for the sync payloads + IMP1 import/export.

## Acceptance

Repository interfaces and every UI caller unchanged; all repository CRUD tests green against
in-memory Drift; app builds and runs; existing Isar data migrated once on upgrade; `isar_community`
and the `buildQuery()` workaround gone.
