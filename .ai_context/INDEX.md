# Sisu Mate — AI Context Index

> Only file read in full every session. Keep lean. Non-derivable orientation + router only.
> Portable design rules + bootstrap prompt for other projects: `AI_CONTEXT_PLAYBOOK.md` (repo root).

## NEXT

- **Last (claudevc):** fixed + closed #225 (`triage_error_logs.sh` auto-filed this from a live on-device capture on the user's Samsung SM_S928U1 — Chef's `_RecipeCard` stacked up to 6 optional sections (chips/count/time/allergens/dietary badges) into a fixed-height grid cell; a fully-tagged recipe like "Blackened Red Snapper" overflowed 20-53px. Fixed by wrapping the card body in `SingleChildScrollView`, same shape as #160/#178. Regression test reproduces it by narrowing the test viewport to ~340px — the default 800×600 test surface never triggers it). Also fixed #213 (Captain's Log GPS/SOG/COG + fields) and #209/#205 (drawer cleanup, bulk actions). #198 left open — unrelated network blip.
- **Last (CLI agent / claudecli):** fixed + closed #184, #133/#134, #135, #157, #185, #186, #187, #124 (not-planned). Shipped the LLM/AI line: **#203** BYOK framework superseding #14/#19; **#16** privacy payload builders; **#17** query caching; **#15** local token/cost tracking; **#208** AI-separation design rule; **#18** first LLM feature (maintenance alert explainer); **#20** re-evaluated/closed. Then **#215**: reworked the key to be **local-only by default with an owner-only opt-in "share with crew" toggle** (`llmApiKeyShared`, schemaVersion 7) — `toJson()` only carries the real key when shared, and `InboundSyncApplier._upsertBoat` only *adopts* an inbound key when the incoming boat says shared (`Value.absent()` otherwise) so a device's own local key can never be silently wiped by an unrelated inbound sync. Note: claudevc's #211 (dedicated multi-provider AI settings screen) is a related, independently-filed follow-up — not yet implemented, may overlap Touches with `llm_api_key_dialog.dart`/`settings_screen.dart` if picked up.
- **Doing:** nothing claimed by either agent. #210 (search list *contents* not just titles, reuses #207's `watchItemsForAppType`), #211 (multi-provider key storage, re-scoped), #212 (weather map never calls `MapController.move` on GPS lock), #214 (wine/cocktail pairing fields + seed research) remain filed but unimplemented.
- **New (claudecli research pass, unimplemented):** surveyed the app for LLM use cases seeding structurally can't do; filed #216 (risk-ranked maintenance triage — also surfaces the missing engine-hours/last-serviced UI; `MaintenanceTask` has full repo CRUD but zero UI today), #217 (location-aware replacement-part sourcing), #218 (cross-history pattern detection in log/maintenance notes), #219 (passage weather safety briefing), #220 (freeform Captain's Log NL parsing), #221 (messy CSV/text import parsing), #222 (warranty/manual coverage assistant, paste-excerpt scoped). All depend on #203/#208; #216 explicitly supersedes the shallow #18 explainer for Maintenance.
- **Shipped (claudecli):** #223 + #224 — grounded web/X search. `LlmClientService.completeWithSearch()` hits xAI's `/v1/responses` (`web_search`+`x_search` tools; genuinely different endpoint/shape than `/v1/chat/completions` — confirmed via docs, not assumed) with defensive `output_text`/`output[]` parsing and `LlmResult.citations`; `LlmProvider.supportsGroundedSearch` gates it per-provider (xai only; openai stays false — its equivalent lives only on its own separate Responses API, unimplemented) and the method **hard-fails to `groundedSearchUnsupported` rather than silently falling back to an ungrounded completion**. `LlmUsageTracker.record()` gained `extraCostUsd` (+ `xaiGroundedSearchToolCostUsd` flat estimate — xAI doesn't expose an exact per-call tool-cost field). New `lib/ui/crew/travel_safety_dialog.dart` (destination + nationalities only, no passport upload path exists) reached via a purple `auto_awesome` badge in `crew_screen.dart`. 30 new tests, full `flutter test` green (1400 tests).
- **Open game bugs:** none
- **Blockers:** rotate Play SA key if prior builds shipped; android-34 emulator image broken (use `test18_a/b` AVDs — see `liars_dice/live_test_setup.md`). Self-heal: the prior note here about a huge uncommitted `chef_screen.dart` diff blocking `run_full_suite.sh` was this session's own transient `dart format`-on-a-never-formatted-file side effect (693 deletions/1013 insertions, pure re-wrapping, no logic change) — reverted to HEAD and the real #225 fix reapplied by hand as a 7-line diff; `flutter analyze` is clean project-wide again, nothing to resolve.

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
