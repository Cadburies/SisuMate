# Data Models, State & API — exceptions only

> **No field tables.** Open `lib/models/<name>.dart` + matching Drift table in `lib/data/drift/app_database.dart` + repo mapping. This file is architecture + non-obvious gotchas only.

## Architecture

```
Drift (SQLite) → repository (*_impl row↔domain) → Riverpod provider → ConsumerWidget
```

- UI never calls Drift or Supabase.
- Supabase only via `SyncService` (sync-eligible = Pro **or** anonymous crew).
- Domain models: plain mutable Dart, `part` of `lib/models/models.dart`.
- `id`: domain `int` auto-increment; wire identity is `supabaseId` (text).
- List/embedded fields: JSON text columns; repo `jsonEncode`/`jsonDecode`.

## Equality (S2)

All 26 models have hand-written `==` / `hashCode` / `toString` (lists use `listEquals` / `Object.hashAll`). **Not** freezed: still mutable, no `copyWith`. Full immutability would be a new product decision (~340 `SomeModel()..field =` sites).

## Providers

**Source of truth:** `lib/core/di.dart` + `lib/providers/`. Grep; do not maintain a catalog here.

Non-obvious only:

| Name | Gotcha |
| --- | --- |
| `isProProvider` | `StreamProvider` — re-emits on RevenueCat customer-info updates (no manual invalidate for purchase) |
| `activeBoatProvider` | In `shopping_provider.dart`; reads `userSettings.activeBoatSupabaseId` → `getBoatById` |
| `checklistGroupsProvider` / `checklistItemsProvider` | `StreamProvider.family` — filter by `appType` / `groupSupabaseId` |
| `pendingConflictsProvider` | Drives drawer conflict badge (T5) |
| `syncOutboxCountProvider` | TitleTile "Syncing (N)" |

## Services — non-obvious only

Full list: `lib/services/`. Notes that are not obvious from names:

| Service | Why non-obvious |
| --- | --- |
| `SyncService` | `_syncAllowed()` = Pro **or** anonymous crew — not the same as feature Pro gates |
| `WirePrefix` | Outbound `<boatGuid>::<id>`; strip inbound; **boats table never prefixed** |
| `BoatEnrollmentService` | Adopts seed boat `00000000-…` into permanent GUID at Pro enroll |
| `FreeEditGate` | Free gets 5 completions/notes (`UserSettings.freeEditsUsed`) then paywall; Pro unlimited |
| `RecipeImportService` | Regex JSON-LD extract — **no** HTML parser package; `parseHtml` for tests |
| `EmailService` | Hand-built `mailto:` (not `Uri.queryParameters`) — avoids `+` spaces in Gmail |
| `RecipeShareService` | PDF bullets use `-` not `•` — Helvetica has no U+2022 glyph |
| `CalorieCalculator` | Weight units only (g/kg/oz/lb); partial results when macros missing |
| `CsvExportService` | Exists; **not wired to UI** |
| `ErrorLogService` | Singleton (#121); `FlutterError.onError`/`PlatformDispatcher.onError` capture from `main.dart`; fingerprint dedupe in-memory per run; `initDeferredContext()` (app version/Pro) called post-first-frame like RevenueCat/AdMob — do **not** call `RevenueCatService().isPro()` from its constructor, that reintroduced RT1 jank once already |

## Model / table exceptions

Open the `.dart` file for fields. Only cross-cutting traps:

| Area | Gotcha |
| --- | --- |
| All models | Manual `fromJson`/`toJson` for sync + import + JSON columns; update with every field change |
| `Boat.supabaseId` | Pre-enroll `00000000-…`; enrollment replaces with GUID |
| `Boats.ownerId` / `shareCode` | SHARE4; inbound-oriented; crew join |
| `BarIngredient` / `PantryIngredient` | `boatSupabaseId` stamping for multi-device scope |
| `UserSettings` | Singleton id=1; `isPro`/`proExpiresAt` **not** authoritative (RevenueCat is); `freeEditsUsed` FREE-EDITS |
| `CommunityTemplate` | `toJson` **omits** rather than nulls `id` where required by server; server-maintained download/rating/version fields |
| `ChecklistGroup` | `communityTemplateId` / `communityTemplateVersion` for S5 link + merge |
| `ConflictLog` | T5 concurrent dirty local + newer remote |
| `SyncOutbox` | Column is `targetTable` (not `tableName` — reserved on Drift `Table`) |
| `ErrorLog` | Local-only (#121), **never synced** — no `boatSupabaseId`/`isSynced`; `fingerprint` dedupes; read by `scripts/triage_error_logs.sh` (Android only so far), never by app UI |
| Drift rows | `@DataClassName('XRow')` avoids clashing with domain class names |

**schemaVersion / migrations:** only `AppDatabase.schemaVersion` + migration steps in `app_database.dart`. Do not copy the number into other context files. No install base yet — wipe/reseed is OK for **local** Drift. **Remote is not optional:** every Supabase-affecting change needs a file under `supabase/migrations/`, apply via **Supabase MCP** (`list_migrations` → `apply_migration`), then `./scripts/verify_supabase_schema.sh --require` (see `CLAUDE.md` § Mandatory rules — Schema change ⇒ migrate + verify).

## Repositories

Interfaces: `lib/domain/repositories/`. Impls: `lib/data/repositories/*_impl.dart`. Pattern: inject `SyncService`, call `queueOutgoingChange` after writes when eligible. Community merge/rate APIs live on `CommunityRepository` — open that interface when touching S5.

## Supabase

Do not duplicate schema here → `caching.md` §Supabase + `supabase/migrations/`. Credentials: compile-time dart-defines only (not `.env` runtime).

## Seed (first launch)

Empty `checklistGroups` ⇒ fresh seed via `bundled_data_seeder.dart`. Default boat GUID all-zeros; checklists + Yanmar maintenance + shopping **categories only** (no sample items) + recipes. Recipe expansion packs (cocktails-import, menus-import, coverage-cocktails) are seeded inside `seed_recipes.dart` itself, first-install only — not deferred. Bar/pantry ingredients diff-insert on every launch (new hardcoded rows catch up automatically) via `seed_expansion_catalog.dart`, invoked by `runDeferredSeeds()` after first navigation (RT1). One call site per pack; do not add a second.
