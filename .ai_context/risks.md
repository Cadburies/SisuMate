# Risks & Cascades — open only

> Read the **relevant §** before non-trivial change. **No resolved strikethrough history** — that lives in changelog archive. **No mirrored schemaVersion numbers** — open `app_database.dart`.

## Cascade table

### AppDatabase + DatabaseService
**High** · `app_database.dart`, `database_service.dart`  
Depends on: Drift, path_provider, seeder. Depended on by: all repos, SyncService, di, startup.  
No install base yet — see `CLAUDE.md` § Mandatory rules: schema changes don't need backward-compatible migrations.

- Every table must be in `@DriftDatabase(tables: [...])` or generated accessors never exist → `build_runner`.
- Row classes: `@DataClassName('XRow')` to avoid domain name clashes. Outbox column: `targetTable`.
- Embedded lists = JSON text columns via model `toJson`/`fromJson`.
- `factoryReset()` wipes rows + reseed — invalidate providers if UI open.
- `hardReset()` deletes sqlite file + swaps `AppDatabase.instance` (corruption path only).
- Fresh seed sentinel: empty `checklistGroups`. **Current schemaVersion + migrations: source only.**

### Domain models
**High** · `lib/models/`  
Change field → Drift column + repo row↔domain + `fromJson`/`toJson` if serialized. Models mutable; S2 equality only (no freezed/`copyWith`).

### di.dart
**High** · Changing a provider type/name breaks all consumers. One definition per provider.

### RevenueCat / isProProvider
**High** · `revenuecat_service.dart`, `isProProvider`  
Gates: ads, completion, boats, FreeEditGate, paywall UI. Sync uses separate `_syncAllowed()`.  
If RC init fails, `isPro()` may retry init and treat user Free until success. Debug force-Pro: `kDebugMode` only.

### SyncService
**High** · `sync_service.dart`, `wire_prefix.dart`  
Depends on Drift outbox, RC, Supabase, connectivity. Started from startup path.  
- Eligibility: Pro **or** anonymous crew — check `_syncAllowed()` before assuming Free never touches sync code paths.
- Queue monitor / process only after eligibility allows start; do not reintroduce ungated timers.
- Outbound ids wire-prefixed except `boats`. Inbound: `InboundSyncApplier` + ConflictLogs when dirty local + newer remote.
- Repos must keep calling `queueOutgoingChange` after writes.

### Navigation / paywall context
**Medium** · Paywall via `Navigator.push` — avoid disposed context after await. Routes: `app_router.dart`.

### Supabase dart-defines
**Medium** · Missing `--dart-define-from-file=dart-defines.json` → assert / splash hang. Anon key is public-by-design (RLS guards). Never put service-role secrets in dart-defines.

### Manual JSON
**Medium** · Hand `fromJson`/`toJson` on all models — easy to miss a field on schema change.

## Global state that can break a session

| State | Corruption | Reset |
| --- | --- | --- |
| Drift DB unopenable | File corrupt | Startup → hardReset |
| User wipe | Intentional | factoryReset + reseed |
| isPro stale after purchase | SDK not updated | Stream should re-emit; else invalidate |
| Outbox stuck | retries exhausted | Monitor drops after policy (5 retries / 24h) |

## Open tech-debt / anti-patterns still true

1. **Drawer `Column` overflow** — use `Expanded` + `SingleChildScrollView` above footer when adding sections.
2. **Nested `Slidable`s** — outer only on header row, never whole `ExpansionTile` with child slidables.
3. **PDF core fonts** — no U+2022; use ASCII bullets or embed a Unicode font.
4. **Liar's Dice bid escalate path** — single bid per round in normal play; `lastDeclaredBid` escalate branches are mostly dead unless multi-bid rounds are added.
5. **Lobby hard-wired to Liar's Dice** — GAME1 blocker for second multiplayer title.

## Do not touch lightly

| File | Why |
| --- | --- |
| `app_database.g.dart` | Generated |
| `app_database.dart` | Schema + migrations |
| `di.dart` | Global wiring |
| `database_service.dart` | Launch path |
| `bundled_data_seeder.dart` | Seed order + hardcoded IDs |
| `models.dart` barrel | `part` list |

## Platform

| Topic | Note |
| --- | --- |
| Ad unit / App IDs | Platform-specific in `AdHelper` + manifests |
| iOS `GADApplicationIdentifier` | **Required** in `Info.plist` — missing → SIGABRT on non-debugger launches (TestFlight/App Store). Preserve on plist regen. |
| Desktop | AdMob/RC skip init with silent fallback |

## DB history (one line)

Migrated Isar → Drift (2026-07). **Do not reintroduce Isar.**
