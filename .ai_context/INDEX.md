# Sisu Mate — AI Context Index

> Only file read in full every session. Keep lean. Non-derivable orientation + router only.
> Portable design rules + bootstrap prompt for other projects: `AI_CONTEXT_PLAYBOOK.md` (repo root).

## NEXT

- **Last (claude, CLI):** shipped **#220** freeform Captain's Log entry parsing. New `ai_log_entry_parse_dialog.dart` — a distinct purple `auto_awesome` FAB next to Captain's Log's normal "Add Entry" FAB (#208) takes freeform typed/dictated text, sends it via new `LlmPayloadBuilder.parseLogEntryText` (intentionally unfiltered — the freeform text itself *is* the payload, documented as a deliberate exception to this file's usual whitelist discipline), then prefills `AddEditCaptainLogDialog`'s weather/wind/notes fields (`aiDraft` param) for the user to review/edit — **never auto-saves**. Response parsing (`parseAiLogEntryResponse`, extracted top-level for direct unit testing) degrades gracefully on well-formed/partial/malformed JSON alike. Also shipped **#218** cross-history pattern detection (`history_pattern_dialog.dart`, historical log/maintenance notes → recurring-theme detection). 43 new/changed tests total, suite green.
- **Last (claudevc):** shipped **#244** GRIB import+viewer UI (`GribImportService` mirrors `ImageService`'s copy-to-app-storage pattern; `GribViewerScreen`) + **#243** GRIB2 parser core. Weather-issues batch complete (11 shipped, #231→#239). Working the #235 GRIB split (#243→#244→#245); starting **#245**'s (low-bandwidth request flow) required design pass next — currently just an unscoped placeholder.
- **Shipped (claude/claudecli):** LLM line #203/#16/#17/#15/#208/#18/#215/#223/#224 (BYOK, grounded search) + #216 (maintenance risk triage) + #217 (part sourcing) + #226/#227/#228 (safety compliance, insurance claim, customs check — thin wrappers over `ui/components/pasted_excerpt_check_dialog.dart`, extracted at #227) + #221 (messy import parsing: `ai_messy_import_dialog.dart`, "Paste messy list" on every module's Import/Export sheet, output re-validated through `ImportService.parse` before persist). LLM-issue batch complete.
- **Doing (claude/claudecli):** nothing claimed. Batch #226/#227/#228/#221 shipped this session.
- **Open game bugs:** none
- **Blockers:** rotate Play SA key if prior builds shipped; android-34 emulator image broken (use `test18_a/b` AVDs — see `liars_dice/live_test_setup.md`).

**Rule:** update NEXT before ending a session (≤6 lines). No essay of shipped history.

## Read-Next (section-scoped; ≤2 files per task)

| Task | Load |
| --- | --- |
| Backlog / pick next work | GitHub Issues: `gh issue list --state open` (skip `agent:*`-claimed, placeholder-Touches, unresolved `Depends on #N`; "do all TEST issues" adds `--label test-gap`; protocol in `Claude.md` §Issue kickoff) |
| Parallel agents | `Claude.md` §Parallel agents (issue labels + worktrees) |
| Full test suite (post every task) | **`./scripts/run_full_suite.sh`** (SEC3 → analyze → `flutter test` → live RLS → integration). Flags: `--skip-live`, `--skip-integration`, `--device <id>`. Detail: `Claude.md` §5 + `README.md` Testing + `test-gap` issues on GitHub |
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
| Epic design (sharing, conflicts) | `plans/<epic>.md` only when implementing that epic |

**Never session-load:** `.ai_context/archive/*` (includes retired changelog/parallel_ai/outstanding snapshots). Open backlog = GitHub Issues, not a context file.

## App (one paragraph)

Offline-first Flutter app for sailors. Modules: Checklists, Shopping, Captain's Log, Maintenance, Safety, Documents, Crew, Inventory, Fuel & Water, Chef, Cocktails, Games, Weather, Community. Free = read-only + ads (+ limited free edits). Pro = completion, boat sync, crew share code, no ads. Seed data into Drift on first launch.

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
- Self-heal **Tier A/B only** (see `Claude.md`); never grow source mirrors.
- End task: touch affected context + NEXT; close/comment the GitHub issue. History = git log + issue threads.
- UI never talks to Drift/Supabase; Pro via `isProProvider`.
- Drift between context and code is the failure mode — fix claims, delete mirrors.
