# Sisu Mate — AI Project Instructions

> Portable design: `AI_CONTEXT_PLAYBOOK.md` (repo root). This file is the **project-specific** runtime contract.

## Session start (token budget)

1. Read `.ai_context/INDEX.md` only (≤ ~80 lines).
2. From its **Read-Next** table, load **at most 1–2** topical files (prefer **named sections**, not whole files when large).
3. Prefer **source of truth** over inventory docs: open the one model / route / service file you need.
4. **Never** load by default: `.ai_context/archive/*`, more than one `gameflow.md`, or `plans/*` (plans only when the task is that epic).

**Budget:** INDEX + ≤2 topical files + relevant source. Exceed only if blocked.

Do not assume product behavior — derive from routed context + source.

---

## What belongs in context (tiers)

| Tier | Content | Maintain? |
| --- | --- | --- |
| **A** | Decisions, Pro gates, open risks, theme rules, `NEXT` | Yes — keep accurate |
| **B** | Cross-file synthesis (sync eligibility, RLS why, WirePrefix) | Yes if wrong |
| **C** | Derivable inventory (model fields, full route lists, provider catalogs, pasted snippets) | **Do not maintain** — pointer to source; delete mirrors if found |
| **D** | History | `git log` + closed GitHub issues; pre-2026-08 snapshots in `archive/` — never session-load |

**Golden rule:** context holds *non-derivable* truth only. If one source file answers it, write a path pointer, not a second copy.

---

## Self-heal (continuous, narrow)

When reading source that **contradicts a Tier A/B claim**, fix the context file immediately (one sentence in the reply is enough).

- Do **not** expand silence into new field tables, provider dumps, or code blocks.
- If you catch yourself updating a mirror of source, **delete that section** and leave a path pointer instead.
- Resolved risks/backlog: **delete** the row (never long-lived `~~strikethrough~~`).

---

## How a task works

### 1. Pick & claim (before any planning or code)
1. Resolve what the task actually is: an explicit ask ("do issue #N"), a batch/sequence ("do all
   TEST issues" / "pick next work" → `gh issue list --state open`, highest priority first —
   P1 > P2 > P3, lowest number breaks ties), or a one-off the user just typed. See
   §Issue kickoff for the exact command shorthand. There is no "claimable" label — an issue's
   workability is judged from its **Touches** field (real paths, not a placeholder) and its Notes
   (skip anything with an unresolved `Depends on #N`).
2. Before claiming, check what else is already claimed: `gh issue list` and look for any open
   issue already carrying an `agent:*` label — that is in-flight work by another agent in this
   same shared tree.
3. Check parallel safety against **every** currently claimed issue: no overlap in **Touches**,
   not a listed bad pair, and not a single-owner hotspot another claim already owns
   (`lib/core/di.dart`, `app_database.dart`, `app_router.dart`, `models.dart`, `units.dart`,
   `lobby_screen.dart`, `suggestion_engine.dart`, `mixologist_service.dart`, the suite/SEC3
   scripts). Full rules in §Parallel agents. If it collides, pick a different task — never guess
   and proceed anyway.
4. Claim it **first, before writing any code**: `gh issue edit <N> --add-label agent:<you>` + a
   one-line comment stating what's claimed and why it's parallel-safe against the other open
   claims. Only once the claim lands, move to Plan.

### 2. Plan
- Short bullet list: change, files, acceptance criteria.
- Model / provider / Pro / sync → re-read the **matching section** of `risks.md` (not the whole file if avoidable).

### 3. Implement
- Smallest change that meets the requirement. No drive-by refactors.
- Comments only for non-obvious *why*.
- Pattern: repository → provider → `ConsumerWidget`. **Never** Drift/Supabase from UI.
- Local DB: Drift. Domain models in `lib/models/` (plain Dart). Tables in `lib/data/drift/app_database.dart`. Mapping in repositories. List/embedded fields = JSON text columns.
- New/changed Drift column → domain model + repo mapping + `fromJson`/`toJson` if serialized → `build_runner`.

### 4. Analyze & generate
```
flutter analyze
dart run build_runner build --delete-conflicting-outputs
```
Zero analyzer issues. Do not suppress.

### 5. Build
Always pass dart-defines (missing → splash hang / missing credentials assert):
```
flutter build apk --debug --dart-define-from-file=dart-defines.json
```
Zero build errors before claiming done.

### 6. Test (mandatory after every task)

```bash
./scripts/run_full_suite.sh
```

**Must be green before claiming done.** Add regression tests for every new / changed / fixed behavior. Prefer TEST6-style screen+Drift integrations when touching module UI. No UI-layout-only tests.

#### What the full suite runs (in order)

1. **SEC3** — `scripts/scan_release_secrets.sh` (pubspec/assets/lib; optional APK if present)
2. **`flutter analyze`**
3. **`flutter test`** — all unit/widget/TEST6/P0–P3 host tests under `test/`
4. **TEST8 live RLS** — `scripts/test_supabase_rls.sh` (skips cleanly without `dart-defines.json` / offline)
5. **Live schema parity** — `scripts/verify_supabase_schema.sh` (same skip rules; after any schema change, apply migrations first)
6. **TEST9** — `flutter test integration_test` (default device: `flutter-tester`)

#### Flags

| Flag | Effect |
| --- | --- |
| *(none)* | Full suite above |
| `--skip-live` | Skip live Supabase RLS **and** schema parity (offline / no credentials) |
| `--skip-integration` | Skip `integration_test/` |
| `--device <id>` | Run integration_test on that device instead of flutter-tester |

Fallback if the script is unavailable:

```bash
bash scripts/scan_release_secrets.sh
flutter analyze
flutter test
bash scripts/test_supabase_rls.sh          # optional; skips without dart-defines
bash scripts/verify_supabase_schema.sh     # optional; skips without dart-defines
flutter test integration_test -d flutter-tester
```

#### Suite map (where coverage lives)

| Layer | What | Where |
| --- | --- | --- |
| Unit / widget | Business logic, dialogs, pure helpers | `test/**/*_test.dart` |
| Screen + Drift (TEST6/17) | Real screen + Riverpod + in-memory Drift | `test/*_integration_test.dart` (shopping, inventory, fuel, **checklist complete**) |
| P0 ship gates | Free/Pro matrix, startup lifecycle, secrets | `test/pro_free_gate_matrix_test.dart`, `startup_lifecycle_test.dart`, `release_secrets_scan_test.dart` |
| Offline (TEST13) | File-DB kill/relaunch + outbox drain | `test/offline_persistence_test.dart` |
| Import round-trip (TEST14) | Empty-DB export↔import + bad JSON | `test/import_roundtrip_test.dart` |
| Crew join (TEST15) | Share-code join / no half-enroll / restamp | `test/join_boat_flow_test.dart`, `lib/services/join_boat_service.dart` |
| Game AI determinism (TEST28) | Fixed seed → same move | `test/game_ai_determinism_test.dart`, `lib/services/game_ai/` |
| Units edges (TEST27) | 0 / null / huge conversions | `test/unit_converter_test.dart` |
| Live Supabase (TEST8) | Auth/RLS smoke | `test/live_supabase_rls_test.dart`, `scripts/test_supabase_rls.sh` |
| Integration (TEST9) | App smoke under IntegrationTest binding | `integration_test/` |
| A11y / perf / channels (TEST10) | Guidelines, first paint, safe fallbacks | `test/accessibility_test.dart`, `performance_smoke_test.dart`, `platform_channel_fallback_test.dart` |
| Error-log capture/dedupe/redaction (#121) | FlutterError/async capture, fingerprint dedupe, secret redaction | `test/error_log_service_test.dart`, `lib/services/error_log_service.dart` |

Also: human **README.md → Testing**; open backlog = GitHub Issues (`test-gap` label for testing gaps); parallel-agent protocol in §Parallel agents below.

### 7. Update context (end of task)
1. Update **Tier A/B** files actually affected (not every file).
2. Cap `INDEX.md` → **NEXT** at ~6 lines (last / doing / blockers).
3. Close or comment the GitHub issue: suite result (+ skip flags used), files touched, blockers. History = git log + issue threads — there is no changelog file.
4. Remove the claim: `gh issue edit <N> --remove-label agent:<you>` (closing the issue leaves the
   label attached otherwise, which reads as still-claimed to the next session's §1 check).

### 8. Commit & push (closing rule — only once the suite is green)
Once §6 is green and §7 is done, commit and push **without waiting for a separate ask** — a
green suite is the trigger, not a reason to pause for confirmation:
1. `git add` the **specific files the task touched** (source + tests + the Tier A/B context
   files updated in step 7) — never a blanket `git add -A`; that risks sweeping up another
   agent's unrelated in-progress edits in a shared working tree (see §Parallel agents).
2. Commit with a message describing the change and why (issue number if one exists).
3. `git push origin <current-branch>`. If the push is rejected (remote moved), `git fetch` +
   rebase/merge and retry — never force-push.
4. Skip this step only if the suite is not green, the user asked to hold off, or the task was
   pure investigation/read-only with no diff.

---

## Mandatory rules

- **Offline-first AI (#286).** Every feature that uses `LlmClientService` / “AI” must also work **with no network and no API key** via local algorithms, heuristics, or bundled tables. Cloud LLM (BYOK) is **optional enrichment when online + key configured** — never the only path. Prefer pure Dart services under `lib/services/*_local_*.dart` (or rules engines) that return structured results; wire dialogs to try local first, then optionally “Improve with AI”. Positive references: polar offline improve (`PolarLocalImprove`), Games AI (`lib/services/game_ai/`). New LLM-only features are rejected in review.
- **No real install base yet** (dev phone + sims only). Schema/model changes do not need backward-compatible migrations or data-preserving upgrade paths — wiping and reseeding a local test device or the Supabase test project is an acceptable resolution. Still cascade every DB-affecting change through all related layers in the same change: domain model → Drift column/repo mapping → Supabase column/RLS → sync (wire-prefix/outbox) → UI. `schemaVersion` and `supabase/migrations/` keep incrementing normally as changes land — this removes the *migration-safety* obligation, not the version-tracking mechanism itself.
- **Schema change ⇒ migrate + verify (non-negotiable).** Any task that touches Drift tables/columns (`app_database.dart`), domain models that map to them, or Supabase wire fields **must** in the **same** change:
  1. Bump `AppDatabase.schemaVersion` (local wipe/recreate path stays acceptable).
  2. Add/update `supabase/migrations/YYYYMMDDHHMMSS_*.sql` for every remote column/table/RLS change (idempotent `if not exists` / `drop policy if exists` preferred).
  3. **Apply** remote migrations before claiming done via the **Supabase MCP only** (`list_migrations` → `apply_migration` for each not-yet-applied file under `supabase/migrations/`, in order). Project ref from `SUPABASE_URL` in `dart-defines.json` (e.g. `mvjgenxntirjgmwrsmmv`). Do **not** use `psql`, Dashboard SQL editor as the primary path, or a `SUPABASE_DB_URL` shell apply script.
  4. **Verify** remote parity: `./scripts/verify_supabase_schema.sh --require` (or leave live suite unskipped so verify runs after TEST8).
  5. Run `dart run build_runner build` when Drift tables change; never hand-edit `app_database.g.dart`.
  A green host suite with `--skip-live` is **not** enough if the task changed schema and remote still lacks the columns (e.g. `boats.polar` / `sailing_polar_samples`). Comment the issue with apply/verify result.
- Zero analyze/build errors is the exit criterion.
- Never edit `lib/data/drift/app_database.g.dart` by hand.
- Never call Drift or Supabase from UI — use repositories via `lib/core/di.dart`.
- Never bypass Pro gates in `access_tiers.md`; new gates use `isProProvider`.
- New Drift table → register in `@DriftDatabase(tables: [...])`.
- `SisuColors` only in `lib/core/colors.dart`.
- Any GUI colour/layout change → read `theme.md` first; tokens only from `SisuColors`.
- Self-heal Tier A/B only (see above).
- Every GitHub issue you file must carry an accurate **Touches** field (real file paths). This is the only parallel-safety signal other agents have — see §Issue kickoff.

---

## Error logging (#121/#122)

Every `catch`/`FlutterError.onError`/`PlatformDispatcher.onError` site in the app feeds a local
`ErrorLogTable` (`lib/services/error_log_service.dart`), read by `scripts/triage_error_logs.sh`
to auto-file one deduped GitHub issue per fingerprint. Verdict when writing or touching a `catch`:

| Verdict | When | Action |
| --- | --- | --- |
| **Log as `exception`** | Unexpected failure the user/dev must hear about (I/O, parse, network, DB, null-state bugs) — usually already user-visible via `setState`/`SnackBar`, but that alone doesn't reach an agent | `ErrorLogService().logException(e, st, context: '<module>: <what was attempted>')` |
| **Log as `warning`** | Degraded but survivable (offline, denied permission, best-effort retry, corrupt-but-recoverable local data) | `logWarning(msg, context: ...)` — no stack needed |
| **Don't log** | Expected control flow (user-cancelled purchase/picker, invalid share code, a documented multi-cause early-return where the majority case is normal, per-item parse-and-skip loops, cosmetic display fallbacks, test/platform-channel-absent cleanup paths) | Leave as-is; the *why* belongs in a code comment at the site, not this table |

Context strings: `'<module>: <operation>'` — the fingerprint/sourceFile extraction needs enough
to point an agent at the right file without re-deriving it from a bare message. Never log
credentials/tokens (`ErrorLogService` redacts `Authorization`/`Bearer`/`apikey`/tokens
automatically, but don't rely on that as the only guard — keep messages boring).

When in doubt, don't log and say why in a one-line comment — the triage automation files one
GitHub issue per fingerprint, so noise from expected-control-flow paths becomes noise in the
issue tracker, not just the log table.

---

## Issue kickoff (one-line user commands)

Shorthand the user may give any agent at session start:

- **"do issue #N"** → `gh issue view N`; claim per §Parallel agents, then execute to its Acceptance boxes.
- **"do all TEST issues"** → `gh issue list --label test-gap --state open`, excluding any already carrying an `agent:*` label; work highest priority first (P1 > P2 > P3, lowest number breaks ties), one at a time, full suite + comment + close after each.
- **"pick next work"** → same query without the `test-gap` filter, narrowed to issues with a concrete **Touches** field (real paths — skip placeholder-style ones like "new service if ever built") and no unresolved `Depends on #N` in Notes.

Label vocabulary: TEST = `test-gap`; types = `bug` / `enhancement` / `chore` / `test-gap`; `historical` = closed archive, never touch. **No "claimable" label exists** — the **Touches** field is the vetting signal. Every issue, whether filed by a human or an agent (a bug found mid-task, a follow-up), **must** carry an accurate Touches field predicting the real files/paths it will change: this is what the parallel-safety check in §1 and §Parallel agents reads. A vague or missing Touches field blocks safe parallel work — write it before anything else when filing.

While batching: claim before code; suite green per issue (`--skip-*` flags need justification in the issue comment); respect Touches overlap + bad pairs (§Parallel agents); if blocked, comment why and move to the next issue — never flail.

---

## Parallel agents (local CLIs)

- Backlog = open GitHub Issues not already carrying an `agent:*` label, with a concrete **Touches** field. Session start: `gh issue list --state open`; skip anything labeled `agent:*` or with an unresolved `Depends on #N` in Notes. Claim with `gh issue edit <N> --add-label agent:<you>` + a one-line comment. **Claim before code.** Never take an issue carrying another `agent:*` label unless it has been idle >1 session and the user reassigns.
- Disjoint scope: no two claimed issues may overlap in their **Touches** fields. Single-owner hotspots per wave: `lib/core/di.dart`, `app_database.dart`, `app_router.dart`, `models.dart`, `units.dart`, `lobby_screen.dart`, `suggestion_engine.dart`, `mixologist_service.dart`, and the suite/SEC3 scripts.
- Bad pairs (same stack): game AI ∥ TEST18 LAN (lobby/games) · units feature ∥ units tests · anything ∥ suite-script edits.
- One agent per worktree: `git worktree add ../SisuMate-<N> issue-<N>`; run the full suite in the worktree before merging to `main`.
- Hand-off: comment on the issue (suite result, flags, files touched), close it, remove the `agent:<you>` claim label, set INDEX **NEXT**, then commit + push per §8 (scoped `git add`, never `-A`, in a shared tree).

---

## Shell / command practices

- No `cd … && … > relative`; use absolute out paths for captures.
- Do not inline shell operators (`&`, `|`, `&&`, `$(…)`, redirects) in agent-invoked commands — put them in `scripts/*.sh`.

### Automatic suite (every task, via §6)

| Script | Purpose |
| --- | --- |
| `run_full_suite.sh` | **Default post-task gate** — SEC3 → analyze → `flutter test` → TEST8 live RLS → schema parity → `integration_test/`. Flags: `--skip-live`, `--skip-integration`, `--device <id>`. See §6 above. |
| `scan_release_secrets.sh` | SEC3: scan pubspec/assets/lib (+ optional APK/IPA) for leaked credentials |
| `test_supabase_rls.sh` | TEST8: live Supabase auth/RLS smoke (`dart-defines.json`; skips if missing) |
| `verify_supabase_schema.sh` | Live REST check for wire columns/tables (`boats.polar`, `polarBySeaState`, `sailing_polar_samples`…). `--require` fails hard. **Apply** outstanding SQL via Supabase MCP (`apply_migration`), not a shell/DB-URL script. |

### Dev / device helpers (primitives — no assertions of their own)

| Script | Purpose |
| --- | --- |
| `ios_run.sh` / `android_run.sh` | Background `flutter run` |
| `stop_flutter.sh` | Kill flutter run **by name** — kills every agent's `flutter run`, not just yours. In a shared working tree, prefer `kill <pid>` against the pid `android_run.sh`/`ios_run.sh` printed. |
| `screencap.sh` | adb screenshot → abs path |
| `wait_for_flutter.sh` | Poll run log |
| `supabase_cli.sh` | Auth/REST/RPC checks (credentials from dart-defines) |
| `idb_tap_label.sh` / `adb_tap_text.sh` | UI tap by label/text (iOS / Android) — semantic match, not hand-computed pixel coords |
| `adb_swipe_reveal_action.sh` | Android: swipe a list card to reveal its `SwipeableListItem` action pane, then tap the named action (e.g. swipe + tap "Complete") — bounds computed live from `uiautomator dump`, never hardcoded |
| `wipe_android_avds.sh` | Factory-wipe all local Android AVD userdata/snapshots (keeps AVD defs; does not touch physical phones) |

### GUI test drivers — run on demand only (real device/sim required; NOT part of `run_full_suite.sh`)

These exercise flows the automatic suite can't (real ad units, real permission dialogs, real timing, multi-device LAN). Run them when working the matching TEST issue or investigating a report in that area — not on every task.

| Script | Purpose |
| --- | --- |
| `liars_dice_4sim_setup.sh` | 4-device multiplayer harness (Liar's Dice) |
| `test18_rc_play.sh` | TEST18 live driver: full LAN round + mid-game same-seat rejoin (after `liars_dice_4sim_setup.sh`) |
| `test19_permissions_smoke.sh` | TEST19 permissions + cold-resume smoke: `ios <udid>` \| `and <serial>` (sim quirks documented in header) |
| `test20_admob_smoke.sh` | TEST20 AdMob smoke (Android): drives Home banner, a checklist's native-ad+FAB list, and the free-tier Complete swipe (interstitial path); screenshots + ad-state log lines to `/tmp/test20/`. Needs `kForceProForTesting = false` for the run — flip it back before finishing (see header comment for known ad bugs already filed, don't re-discover blind) |
| `test21_perf_smoke.sh` | TEST21 perf smoke: cold-open timing ×3 + long-list fling scroll (`and <serial>` \| `ios <udid>`) |
| `mp_multiseat_stress_setup.sh` | LT6 multi-seat stress for roster games (`liars_dice` \| `dudo`) |
| `lt_mirror_harness.sh` | LT1 dual-device same-boat bootstrap (driver + mirror) |
| `lt_module_crud_sweep.sh` | LT2–LT4 module CRUD / side-action / reuse sweep |
| `lt_ui_helpers.sh` | Shared adb/idb helpers for LT scripts |
| `sync_conflict_2device_setup.sh` | 2-device offline-edit sync-conflict smoke test (SUG2); see `lib/services/sync_conflict_2device_setup.md` |

### Ops automation — run on demand only (real device required; NOT part of `run_full_suite.sh`)

| Script | Purpose |
| --- | --- |
| `triage_error_logs.sh` | #121: force-stops the app, pulls the local error log (`ErrorLogTable`) off a connected **Android** device, then does everything else (dump, dedupe, file one GitHub issue per new fingerprint) on the local copy only — nothing is ever written back to the device. Idempotent via a GitHub issue-body search for the fingerprint marker, safe to rerun. Uses `tool/error_log_admin.dart` (raw sqlite3, not Drift — plain `dart run` can't resolve `dart:ui`, which `app_database.dart` pulls in transitively via `path_provider`) + `scripts/_error_log_issue_body.py` (issue title/body template — resolves `sourceFile` to a repo-relative path, embeds a ±6-line code snippet + the nearest enclosing class/mixin straight into the issue body and title so an agent doesn't need to re-open the file to start, degrades gracefully if the file's moved/missing at triage time; not a standalone script). RenderFlex-overflow rows get an extra `ui-overflow` label so they're `gh issue list --label ui-overflow`-findable regardless of whether `sourceFile` resolved. Ends by calling `triage_ips_crashes.sh` (no device pull) so any `.ips` sitting in `crash_store/` still get processed and the folder wiped. |
| `triage_error_logs_ios.sh` | #267: **iOS** counterpart, same dump/dedupe/file-issue flow, but pulls `sisu_mate.sqlite` via `idb file pull --bundle-id ... Documents/sisu_mate.sqlite` (physical devices need the deprecated `--bundle-id` form — the newer `--application` form errors "requires a rooted device" on real hardware) instead of `adb run-as`. Needs `.idb_venv` (repo-local) + `idb_companion` (brew) — run `idb connect <udid>` first if `idb list-targets` shows "No Companion Connected". Native `.ips` hard crashes go through `triage_ips_crashes.sh --udid` (not `/tmp`). Only reaches devices physically connected to this Mac — a remote external tester's crash needs App Store Connect → TestFlight → Crashes instead, or the tester dropping a `.ips` into `crash_store/` and running `triage_ips_crashes.sh`. |
| `triage_ips_crashes.sh` | Native/hard-crash add-on: copy `.ips` into gitignored `crash_store/` (connected iOS via `idb crash list/show`, Simulator `DiagnosticReports` Runner/SisuMate, or files already in the folder), group SisuMate/Runner/Boat Checks crashes by `Fingerprint: ips:<hash>`, file one GitHub issue per new hash, ignore Apple daemons, then delete every `.ips` from `crash_store/`. `--dry-run` / `--keep`. Not part of `run_full_suite.sh`. Parser: `scripts/_ips_crash.py`. |
| `play_release.sh` | Signed Play AAB + Android Publisher upload. Default `--track internal` (pass `--track production` only when asked). Needs gitignored `secrets/google-play-service-account.json` + `android/key.properties`. Refuses leftover `boatchecks@` SA and `FORCE_PRO_*` dart-defines. Host-only — no device. Not part of `run_full_suite.sh`. Uploader: `scripts/_play_upload.py`. Full agent procedure: `.ai_context/store_release.md`. |
| `appstore_release.sh` | Signed iOS IPA + App Store Connect / TestFlight upload via iTMSTransporter. Default `--track testflight`. Needs gitignored `secrets/appstore-connect.json` + `secrets/AuthKey_<key_id>.p8`. Refuses `FORCE_PRO_*` dart-defines. `--test` checks the API key without building. Does **not** submit for App Review. Host-only — no device. Not part of `run_full_suite.sh`. Full agent procedure: `.ai_context/store_release.md`. |

New operator-heavy patterns → new script + row here.

## Key source paths (not context)

| What | Where |
| --- | --- |
| Providers | `lib/core/di.dart`, `lib/providers/` |
| Domain models | `lib/models/` |
| Drift schema | `lib/data/drift/app_database.dart` (`schemaVersion` lives **here**) |
| DB lifecycle | `lib/services/database_service.dart` |
| Pro | `lib/services/revenuecat_service.dart`, `isProProvider` |
| Sync | `lib/services/sync_service.dart`, `wire_prefix.dart` |
| Colours / theme | `lib/core/colors.dart`, `lib/core/theme.dart` |
| Routes | `lib/core/app_router.dart` |
| Seed | `lib/data/seed/bundled_data_seeder.dart` (base) + `lib/data/seed/seed_expansion_catalog.dart` (deferred catalog) |
