# Caching, Persistence & Offline — synthesis

> Cross-cutting behavior. Table list / exact `schemaVersion` → `app_database.dart` (do not mirror counts that drift).

## Layers

| Layer | Tech | Role |
| --- | --- | --- |
| Primary store | Drift SQLite (`sisu_mate.sqlite`) | All app data via repositories |
| Outbox | `SyncOutboxItems` | Pending outbound writes |
| Conflicts | `ConflictLogs` | T5 dirty-local vs newer-remote |
| Prefs | SharedPreferences | RC user id, interstitial counters, onboarding flag |
| Images | `cached_network_image` via `SmartImage` | Disk cache; hierarchy local → remote → asset |
| Entitlement | RevenueCat SDK cache | `isPro()` offline uses last SDK value |

## Drift lifecycle

- Lifecycle: `DatabaseService` (`init`, `runDeferredSeeds`, factory/hard reset).
- RT1: open + fresh seed on splash; expansion/patch seeds **after** first navigation.
- Soft delete: `isHidden` / permanent flags per domain.
- Invalidation: factoryReset / hardReset / inbound sync upsert / Riverpod invalidate where needed.

## Sync outbox

1. Eligible write → `queueOutgoingChange` (Pro or anonymous crew).
2. Process on online + init + periodic monitor (only after sync allowed to start).
3. Priority order, batch ~10; success deletes row; failure `retryCount` + backoff; drop after policy (~5 / 24h).
4. Synced content tables: see `InboundSyncApplier.syncedTables` in source (+ `boats` outbound). WirePrefix on ids except `boats`.

## SharedPreferences keys

| Key | Purpose |
| --- | --- |
| `revenuecat_user_id` | Stable RC identity |
| `interstitial_ad_count` / `interstitial_ad_date` | 3/day cap |
| `onboarding_seen_v1` | Skip intro |

## Supabase (live)

- Project/credentials: `dart-defines.json` (+ human `.env` copy). Migrations under `supabase/migrations/`.
- PK design: `supabaseId` text PK for idempotent upsert; trigger mirrors to `id` for realtime streams.
- Columns: quoted camelCase matching model `toJson`.
- **RLS (SHARE6):** membership via `accessible_boat_ids()`; content scoped by wire-prefix boat GUID; boats owner-write; **session required** (anon key alone locked out). Anonymous crew = joined boat only.
- Community templates: browse live; local `CommunityTemplates` cache for published/imported.

## Never “our” cache

- Supabase auth session (SDK).
- RevenueCat offerings (fetched each paywall open).

## Offline feature matrix (summary)

| Feature | Offline |
| --- | --- |
| Read modules / complete / shopping writes | Yes (Drift; outbox if sync-eligible) |
| Community browser / RC offerings / ads load | Needs network (ads fail soft) |
| isPro | Last SDK cache; may false if never inited |
| Owner/crew auth | Needs network |

## Design docs

Deep sharing/conflict designs: `plans/pro-sync-sharing.md`, `plans/offline-conflict-resolution.md` — load only when that epic is the task.
