# Sisu Mate — AI Context Index

> Only file read in full every session. Keep lean. Non-derivable orientation + router only.

## NEXT

- **Last:** factory hardening. `AGENTS.md` is now the only contract (`CLAUDE.md` points to it) (#418). Agnostic skills live in `skills/` (#425). The `scripts/_factory.py` guard denies unsafe git, generated-file edits and governance edits (#419).
- **Next:** factory series #420 suite receipt + test floor → #421 claim scripts → #422 cold review → #423 out-of-scope list (Frik writes it). #424 flaky game timers. #395, map bugs #393/#396–#409.
- **Blockers:** android-34 emulator image broken.


**Rule:** update NEXT before ending a session (≤6 lines). No essay of shipped history.

## Read-Next (section-scoped; ≤2 files per task)

| Task | Load |
| --- | --- |
| Play / App Store upload | `.ai_context/store_release.md` (commands, secrets, tester tracks). Scripts: `play_release.sh`, `appstore_release.sh` |
| Backlog / pick next work | GitHub Issues: `gh issue list --state open` (skip `agent:*`-claimed, placeholder-Touches, unresolved `Depends on #N`; "do all TEST issues" adds `--label test-gap`; protocol in `AGENTS.md` §Issue kickoff) |
| Parallel agents | `AGENTS.md` §Parallel agents (issue labels, shared tree on main) |
| Full test suite (post every task) | **`./scripts/run_full_suite.sh`** (SEC3 → analyze → `flutter test` → live RLS → integration). Flags: `--skip-live`, `--skip-integration`, `--device <id>`. Detail: `AGENTS.md` §5 + `README.md` Testing + `test-gap` issues on GitHub |
| GUI / colour / layout | `theme.md` → `lib/core/colors.dart` |
| New screen / home tile | `screens.md` gotchas + `home_screen.dart` + `theme.md` §5 |
| One game | that game only: `lib/ui/games/games/<game>/gameflow.md` + `logic.dart` — never all 9 |
| Model / Drift column | `data_models.md` (exceptions) → open that model + `app_database.dart` |
| Sync / WirePrefix / RLS | `caching.md` + `sync_service.dart` / `wire_prefix.dart` |
| Pro / paywall | `access_tiers.md` |
| Provider / DI | grep `lib/core/di.dart` + `lib/providers/` — not a full provider dump |
| Auth / crew join | `auth_service.dart` + `join_boat_service.dart` + `boat_enrollment_service.dart` + `join_boat_screen.dart` |
| Seed | `bundled_data_seeder.dart` (+ `data_models.md` §Seed if needed) |
| Import / export | `import_service.dart` + `ui/components/import_export.dart` |
| Cascade risk (model/Pro/sync) | matching **§** in `risks.md` only |
| Find / reach / script a feature (Feature Map) | `feature_map/FORMAT.md` → `grep`/`find` → read **one** leaf; run `scripts/fm.sh <id>` (#354) |
| Epic design (sharing, conflicts) | `plans/<epic>.md` only when implementing that epic |

**Never session-load:** `.ai_context/archive/*` (includes retired changelog/parallel_ai/outstanding snapshots). Open backlog = GitHub Issues, not a context file.

## App (one paragraph)

Offline-first Flutter app for sailors. Modules: Checklists, Shopping, Captain's Log, Maintenance, Safety, Documents, Crew, Inventory, Fuel & Water, Chef, Cocktails, Weather, Polar, Anchor Alarm, Community, Games (last on home). Free = read-only + ads (+ limited free edits). Pro = completion, boat sync, crew share code, no ads. Seed data into Drift on first launch.

## Stack

Flutter 3.24+ / Dart ^3.8.1 · Material 3 · Riverpod 3 · Drift (SQLite) · Supabase (Pro/crew) · RevenueCat (`Boat Checks Pro`) · AdMob · LAN multiplayer (bonsoir + WebSocket). Config: `--dart-define-from-file=dart-defines.json`.

## Layout map

```
lib/core/     di, colors, theme, units, app_router
lib/data/     drift/, repositories/, seed/
lib/models/   plain Dart (models.dart parts)
lib/services/ Database, Sync, Auth, WirePrefix, enrollment, heartbeat, ads…
lib/ui/       home, modules…, games/, community/, account/, components/
```

**schemaVersion** → only in `lib/data/drift/app_database.dart` (do not mirror a number here).

## Global singletons

`AppDatabase` · `DatabaseService` · `RevenueCatService` (`isPro()` authoritative for features) · `SyncService` (Pro **or** anonymous crew) · `AuthService` · `AdMobService` · `ErrorLogService` (#121 — FlutterError/async capture, fingerprint dedupe, never syncs)

## Rules (short)

- Theme: `theme.md` before any UI colour/layout work.
- Self-heal **Tier A/B only** (see `AGENTS.md`); never grow source mirrors.
- End task: touch affected context + NEXT; close/comment the GitHub issue. History = git log + issue threads.
- UI never talks to Drift/Supabase; Pro via `isProProvider`.
- Drift between context and code is the failure mode — fix claims, delete mirrors.
