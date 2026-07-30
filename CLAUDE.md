# Sisu Mate — AI Project Instructions

> Portable design: `AI_CONTEXT_PLAYBOOK.md` (repo root). This file is the **project-specific** runtime contract.

## Session start (token budget)

1. Read `.ai_context/INDEX.md` only (≤ ~80 lines).
2. From its **Read-Next** table, load **at most 1–2** topical files (prefer **named sections**, not whole files when large).
3. Prefer **source of truth** over inventory docs: open the one model / route / service file you need.
4. **Never** load by default: `changelog.md`, `.ai_context/archive/*`, more than one `gameflow.md`, or `plans/*` (plans only when the task is that epic).

**Budget:** INDEX + ≤2 topical files + relevant source. Exceed only if blocked.

Do not assume product behavior — derive from routed context + source.

---

## What belongs in context (tiers)

| Tier | Content | Maintain? |
| --- | --- | --- |
| **A** | Decisions, Pro gates, open risks, theme rules, open backlog (`outstanding`), `NEXT` | Yes — keep accurate |
| **B** | Cross-file synthesis (sync eligibility, RLS why, WirePrefix) | Yes if wrong |
| **C** | Derivable inventory (model fields, full route lists, provider catalogs, pasted snippets) | **Do not maintain** — pointer to source; delete mirrors if found |
| **D** | History | Hot `changelog.md` (short) only; older → `archive/` — never session-load |

**Golden rule:** context holds *non-derivable* truth only. If one source file answers it, write a path pointer, not a second copy.

---

## Self-heal (continuous, narrow)

When reading source that **contradicts a Tier A/B claim**, fix the context file immediately (one sentence in the reply is enough).

- Do **not** expand silence into new field tables, provider dumps, or code blocks.
- If you catch yourself updating a mirror of source, **delete that section** and leave a path pointer instead.
- Resolved risks/backlog: **delete** the row (never long-lived `~~strikethrough~~`).

---

## How a task works

### 1. Plan
- Short bullet list: change, files, acceptance criteria.
- Model / provider / Pro / sync → re-read the **matching section** of `risks.md` (not the whole file if avoidable).

### 2. Implement
- Smallest change that meets the requirement. No drive-by refactors.
- Comments only for non-obvious *why*.
- Pattern: repository → provider → `ConsumerWidget`. **Never** Drift/Supabase from UI.
- Local DB: Drift. Domain models in `lib/models/` (plain Dart). Tables in `lib/data/drift/app_database.dart`. Mapping in repositories. List/embedded fields = JSON text columns.
- New/changed Drift column → domain model + repo mapping + `fromJson`/`toJson` if serialized → `build_runner`.

### 3. Analyze & generate
```
flutter analyze
dart run build_runner build --delete-conflicting-outputs
```
Zero analyzer issues. Do not suppress.

### 4. Build
Always pass dart-defines (missing → splash hang / missing credentials assert):
```
flutter build apk --debug --dart-define-from-file=dart-defines.json
```
Zero build errors before claiming done.

### 5. Test
```
flutter test
```
All existing tests pass. New tests for new business logic (repos, Pro gates, sync, game/flow bugs). No UI-layout-only tests.

### 6. Update context (end of task)
1. Update **Tier A/B** files actually affected (not every file).
2. Cap `INDEX.md` → **NEXT** at ~6 lines (last / doing / blockers).
3. Prepend a **short** entry to `.ai_context/changelog.md` (≤10 lines):
   ```
   ## [YYYY-MM-DD] — <title>
   - Files: …
   - Context: …
   - Risks: … (or none)
   ```
4. If hot changelog exceeds ~250 lines, move older entries to `.ai_context/archive/` (keep header pointer).

---

## Mandatory rules

- **No real install base yet** (dev phone + sims only). Schema/model changes do not need backward-compatible migrations or data-preserving upgrade paths — wiping and reseeding a local test device or the Supabase test project is an acceptable resolution. Still cascade every DB-affecting change through all related layers in the same change: domain model → Drift column/repo mapping → Supabase column/RLS → sync (wire-prefix/outbox) → UI. `schemaVersion` and `supabase/migrations/` keep incrementing normally as changes land — this removes the *migration-safety* obligation, not the version-tracking mechanism itself.
- Zero analyze/build errors is the exit criterion.
- Never edit `lib/data/drift/app_database.g.dart` by hand.
- Never call Drift or Supabase from UI — use repositories via `lib/core/di.dart`.
- Never bypass Pro gates in `access_tiers.md`; new gates use `isProProvider`.
- New Drift table → register in `@DriftDatabase(tables: [...])`.
- `SisuColors` only in `lib/core/colors.dart`.
- Any GUI colour/layout change → read `theme.md` first; tokens only from `SisuColors`.
- Self-heal Tier A/B only (see above).

---

## Shell / command practices

- No `cd … && … > relative`; use absolute out paths for captures.
- Do not inline shell operators (`&`, `|`, `&&`, `$(…)`, redirects) in agent-invoked commands — put them in `scripts/*.sh`.

| Script | Purpose |
| --- | --- |
| `ios_run.sh` / `android_run.sh` | Background `flutter run` |
| `stop_flutter.sh` | Kill flutter run |
| `screencap.sh` | adb screenshot → abs path |
| `wait_for_flutter.sh` | Poll run log |
| `supabase_cli.sh` | Auth/REST/RPC checks (credentials from dart-defines) |
| `idb_tap_label.sh` / `adb_tap_text.sh` | UI tap by label/text |
| `liars_dice_4sim_setup.sh` | 4-device multiplayer harness (Liar's Dice) |
| `mp_multiseat_stress_setup.sh` | LT6 multi-seat stress for roster games (`liars_dice` \| `dudo`) |
| `lt_mirror_harness.sh` | LT1 dual-device same-boat bootstrap (driver + mirror) |
| `lt_module_crud_sweep.sh` | LT2–LT4 module CRUD / side-action / reuse sweep |
| `lt_ui_helpers.sh` | Shared adb/idb helpers for LT scripts |
| `sync_conflict_2device_setup.sh` | 2-device offline-edit sync-conflict smoke test (SUG2); see `lib/services/sync_conflict_2device_setup.md` |

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
