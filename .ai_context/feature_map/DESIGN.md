# Feature Map — Design (#353)

> Rationale and ownership. **Agents doing feature work read `FORMAT.md` plus one leaf file, not this.**
> Never session-loaded: reached via the `INDEX.md` Read-Next row.

## 1. Goal

Every feature in the app, from UI taps down to DB, sync, network, AI, platform and ops, is a tiny
wiki file. An agent finds it by `grep`/`find`, reads **one** ~150-token file, and runs
`scripts/fm.sh <id>` to get there or exercise it. Future uses: user manual and store copy,
and an audit for dead routes, unreachable screens and handler-less menu items.

## 2. Decisions (approved by Frik, 2026-09-26)

| Decision | Why |
| --- | --- |
| One file per feature; the **folder path is the tree and the id** (`home/shopping/add_item`) | Path-to-root costs zero reads. No `parent:` field to drift. `find` shows a subtree. |
| Fixed 13-line `key: value` template, no YAML block, no body (`FORMAT.md`) | Each grep hit is a whole, meaningful line. Uniform files are cheap to lint and to generate manuals from. |
| `reach` is an **executable step list** (`text:`/`tip:`/`label:`/`swipe:`/…), not prose | Past device agents mis-tapped because of label drift, Android `content-desc` vs `text`, iOS merged tile+subtitle labels, below-fold slivers and unlabeled FABs (`lib/ui/games/games/liars_dice/live_test_setup.md`). One executor runs the same steps on host and device and always scroll-retries. The suite runs it on host, so drift turns the suite red before a device agent hits it. |
| Targets must be unique accessibility labels; no pixel coords, indexes or `Key`s | Devices only see semantics. Fixing an ambiguous label in the app also helps a11y (TEST10). |
| `script` is just a name (area test file) or a test path; one wrapper `scripts/fm.sh` | Fewest tokens. The rules in `FORMAT.md` say how a name resolves. |
| One host test file per area under `test/feature_map/`, tests named by id | Plain widget tests (parallel, fast). `integration_test/` can't hold them: on Flutter 3.41 `flutter test integration_test -d flutter-tester` fails to launch every file after the first. Device runs use `fm_device_reach.sh`, not `integration_test`. Keep surfaces ≥800 px wide: the test font is wider than real fonts. |
| **All** layers: `system/<layer>/` for non-UI features, linked from UI via `uses:` | Completeness. "Enhance feature X" lands on the UI file and its `uses:` list names the DB/sync/network pieces. |
| Public GitHub wiki **generated** from this folder (#394, `tool/feature_map_wiki.dart` + `scripts/publish_wiki.sh`) | One source. Users get plain-language pages; `reach` steps become numbered taps; internals never leave. The wiki is overwritten on every publish. |
| Touches **derived** (`feature_map.dart touches/overlap`), not a field | `source` is the ownership list; a hand-kept touches line would drift. Hotspots from CLAUDE.md always conflict. |
| No generated index | `grep`/`find` over tiny files is the index. Nothing is regenerated, so parallel agents never collide. |

## 3. Tier-C reconciliation (exemption approved)

The map is a deliberate inventory, allowed because: it holds pointers (`source` = file + symbol,
gate rules cite `access_tiers.md`, game rules cite `gameflow.md`); its content is cross-file
synthesis (reach, needs, uses); it is **mechanically verified** (lint + host scripts in the suite);
and it is never session-loaded. No field lists, pasted code, route strings or copied dialog text
beyond the one label a step or `expect` needs.

## 4. Tree roots and ownership (parallel-safe)

| Path | Owner issue |
| --- | --- |
| `FORMAT.md`, `DESIGN.md`, lint, `fm.sh`, reach executor | #354 Foundation |
| `launch/` | #355 Startup & onboarding |
| `shared/<component>/`: swipe rows, detail shells, `CheckPageViewer`, pickers, shared dialogs | #356 Components |
| `home.md`, `home/drawer.md` + `home/drawer/*` (except `settings`, `account`), home shell features, `shared/title_bar/`, `shared/import_export/`, `shared/paywall/`, `shared/ads/` | #357 Home shell |
| `home/<module>.md` + `home/<module>/` | that module's issue (#358–#369) |
| `home/drawer/settings*`, `home/polar*` | #370 Settings |
| `home/drawer/account*` | #371 Account |
| `home/games.md`, `home/games/{lobby,help}*` | #372 Games hub |
| `home/games/<game>.md` + `home/games/<game>/` | per-game issue (#373–#381) |
| `system/<layer>/` | #383 db · #384 sync · #385 auth · #386 pro+ads · #387 network · #388 platform · #389 ai · #390 logic · #391 errors+ops · #392 lan |

Shared UI features are documented once under `shared/`, with `reach` through one representative
module. Module files `uses:` them rather than copying.

## 5. Lint (`tool/feature_map.dart lint`, run in `flutter test`)

**Errors:** a file doesn't have exactly the 13 keys in order; unknown `layer`/`kind`/`needs` value;
malformed `reach` step; `source` file missing or symbol not found; `script` name has no area file,
or the area file has no `testWidgets('<id>'`; a test-path `script` doesn't exist; a child folder
without its `<name>.md`.

**Also errors since #382:** a `uses:` id that doesn't exist; a UI feature with `script: -` that isn't `platform=device`.

**Audit** (`dart run tool/feature_map.dart audit`, #382): lists screens/dialogs, routed widgets and
`lib/services/` files no feature points at (all three are pinned to zero in `test/feature_map_lint_test.dart`),
plus informational lists: detail routes that need `extra` (reached by tapping, never deep-linked),
`onTap: null` handlers (all reviewed as by-design at #382), and features without a host script.
**Manual:** `dart run tool/feature_map_wiki.dart --manual <id-prefix> <out.md>` (example: `docs/manual/shopping.md`).

## 6. Order

#354 → (#355 → #357) ∥ #356 ∥ #383–#391 → #358–#372 → #373–#381 and #392 → #382 Audit. Exact `Depends on` lines are in each issue.
