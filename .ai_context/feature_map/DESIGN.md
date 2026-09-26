# Feature Map — Design (#353)

> Planning output of #353. The map itself is built by the child issues listed at the end.
> Not session-loaded: open it via the `INDEX.md` Read-Next row only when a task needs to
> find, reach, script, document, or audit a feature.

## 1. Purpose

A searchable tree of every screen, dialog and tappable element in Sisu Mate. From any
node, an agent can walk `parent` links back to the root (`app.launch`) and get the exact
reach path, the preconditions (onboarding, Free/Pro, boat, auth, network), the expected
screen at each step, and the script that drives it. Later uses: user manual and store copy,
and a lint for dead routes, unreachable screens and handler-less menu items.

## 2. Research summary (why this root and breakdown)

| Finding | Source | Consequence for the design |
| --- | --- | --- |
| Entry flow: `StartupScreen` opens the **file** DB through the `DatabaseService()` singleton, then `hasSeenOnboarding()` (`onboarding_seen_v1`, debug bypass `kBypassOnboardingForTesting`), then `/onboarding` or `/home` | `lib/ui/startup/startup_screen.dart`, `lib/ui/onboarding/onboarding_screen.dart` | Root = `app.launch` (cold start). Host scripts **can't** boot through `StartupScreen` (it opens the file DB, not an injected one), so they start at `/home` or `/onboarding` with an in-memory DB. Startup/corruption nodes get device scripts; `test/startup_lifecycle_test.dart` already covers the host logic. |
| `createAppRouter()` hardcodes `initialLocation: AppRoutes.startup` | `lib/core/app_router.dart` | Foundation adds an optional `initialLocation` param. This is the **only** feature-map edit to that hotspot. |
| No bottom tabs. Home is a reorderable tile grid (`HomeModules.catalog`, #351) plus an end drawer. Every module uses `TitleTile` (Back, Menu → end drawer, `StatusBar`, `actionsBuilder` extras, import/export sheet with Pro locks) | `lib/ui/home/`, `lib/ui/components/title_tile.dart`, `common_drawer.dart`, `import_export.dart` | Module screens hang off `home.tile.<id>`. Chrome (title bar, drawer sections, import/export, paywall, ads) is modelled **once** as `kind: component` nodes that module screens reference, not copy. |
| Many flows use `Navigator.push`/`extra` (`CheckPageViewer`, `RecordDetailScreen`, ingredient detail, recipe editor) and the paywall is a `MaterialPageRoute`, not a GoRoute | `app_router.dart` `_MissingExtraScreen`, `screens.md` | A node's `route` is optional. Reach is always described as a **tap path**. Deep-linking a detail route without `extra` shows `_MissingExtraScreen`, which the lint issue checks for. |
| Shared detail primitives are used across modules: `SwipeableListItem`, `ItemDetailShell`, `RecordDetailScreen`, `CheckPageViewer` (checklists, safety, maintenance), `IngredientDetailScreen` (chef, cocktails) | `lib/ui/components/`, `lib/ui/checklists/check_page_viewer.dart` | One issue owns all shared components, **including `check_page_viewer.dart`**, so the parallel module issues never edit a shared file. |
| Keys are almost absent (~23 `Key`s in `lib/ui`); ~105 tooltips/semantics labels; tests find by text | `grep` over `lib/ui` | Finder priority: text → tooltip → semantics label → `Key`. Add keys only where a finder is ambiguous. Device drivers can only see semantics (text/tooltip/label), never `Key`s. |
| Host harness exists: in-memory Drift + `debugProOverrideForTests` + `platform_mocks.dart`; `integration_test/app_smoke_test.dart` runs on `flutter-tester` inside `run_full_suite.sh` (`flutter test integration_test`, recursive) | `integration_test/`, `test/test_helpers/` | Host navigators live under `integration_test/feature_map/` and join the suite automatically. The suite script is **not** edited. |
| Device helpers exist: `adb_tap_text.sh`, `idb_tap_label.sh`, `adb_swipe_reveal_action.sh`, `lt_ui_helpers.sh` (`and_*` / `ios_*` / `wait_for_text`), `android_run.sh`/`ios_run.sh`, `screencap.sh` | `scripts/` | Device drivers source `lt_ui_helpers.sh`. They're on-demand, never in the suite. android-34 emulator is broken, so drivers target a real phone or the iOS Sim. |
| Games already carry per-game `gameflow.md` (rules and state machine) | `lib/ui/games/games/<id>/` | Game nodes cover UI reach and taps only and link to `gameflow.md`. Rules are never copied. |

## 3. Layout

```
.ai_context/feature_map/
  DESIGN.md                  this file (hand-written)
  INDEX.md                   hand-written stub: module list + search commands (Foundation)
  nodes/<area>/<screen>.md   one file per screen / dialog / sheet / component
  nodes/<area>/_index.md     GENERATED per-area shard (keyword → id → path-to-root)
tool/feature_map.dart        generator + lint + find/path CLI (pure Dart, no Flutter imports)
test/feature_map_lint_test.dart            runs the lint in `flutter test` (suite gate)
integration_test/feature_map/_harness.dart shared host primitives (Foundation only)
integration_test/feature_map/<area>_test.dart  host navigators, one file per area
scripts/feature_map.sh       run a node's script by id (host or device)
scripts/feature_map/<area>.sh  device-only drivers, one file per area, only if needed
```

`<area>` is one of: `app`, `startup`, `home`, `chrome`, `components`, `checklists`, `safety`,
`maintenance`, `shopping`, `logbook`, `fuel`, `inventory`, `crew`, `documents`, `chef`,
`cocktails`, `weather`, `anchor`, `community`, `settings`, `account`, `games`,
`game_<id>`. **Each child issue writes only its own area directories and files.** That is
why the index is sharded per area: parallel agents never regenerate each other's files.

## 4. Node schema

One Markdown file per **screen-level** node (screen, dialog, sheet, drawer, component). YAML
front matter holds the node plus its `elements:` (tappables). The generator flattens each
element into its own node with id `<file id>.<element key>` and `parent` = the file node.
The body is optional prose for the manual (≤10 lines, user-facing wording).

```yaml
---
id: shopping.list                 # stable, see §5
kind: screen                      # screen|dialog|sheet|drawer|component|gate|external
title: Shopping & Spares          # what the user sees as the heading
parent: home.tile.shopping        # canonical opener: element id (or a screen id for automatic
                                  # navigation, e.g. startup.splash → home.screen); root has none
also_from: [maintenance.item.add_to_shopping]   # other opener ids (optional)
route: AppRoutes.shopping         # AppRoutes SYMBOL, never the path string; omit if Navigator/dialog
source: lib/ui/shopping/shopping_screen.dart
widget: ShoppingScreen            # lint checks `class ShoppingScreen` exists in source
uses: [chrome.title_tile, chrome.drawer, components.swipeable_list_item]
looks: Title bar, sectioned list of items with state colours, add FAB.
preconditions: {onboarding: seen, tier: any, boat: any, auth: any, network: any}
expected: Heading "Shopping & Spares" visible.            # what the script asserts on arrival
script: {host: integration_test/feature_map/shopping_test.dart#shopping.list}
keywords: [spares, provisioning, buy, port run]
elements:
  - key: fab_add
    kind: fab                     # button|icon|tile|fab|swipe|menu_item|toggle|field|long_press|link
    label: Add item               # visible text / tooltip / semantics label
    finder: {tooltip: Add item}   # host finder: text|tooltip|semantics|key|icon (+ index if repeated)
    device: {label: Add item}     # adb/idb semantic match; omit ⇒ same as label
    action: Opens the add-item dialog.
    opens: shopping.add_item      # target node id (optional)
    preconditions: {tier: any}    # merged over the file's preconditions
    expected: Dialog "Add item" shows.
    script: {host: integration_test/feature_map/shopping_test.dart#shopping.list.fab_add}
---
Optional manual prose.
```

**Cross-area references.** `parent`, `opens`, `also_from` and `uses` may only point at areas
whose issue is already merged (your dependencies). An entry point from an area still in
flight (for example Collections reached from Cocktails while Chef is being built) goes in
the body as `TODO(link): <area>.<id>`. The Audit issue resolves those, so parallel issues
never fail each other's lint.

**Preconditions vocabulary** (closed set, lint-enforced):

| Key | Values | Meaning / how scripts set it |
| --- | --- | --- |
| `onboarding` | `seen` · `unseen` · `any` | Harness sets `onboarding_seen_v1` in mock SharedPreferences. Device: fresh install ⇒ unseen; tap **Skip** to reach home. |
| `tier` | `free` · `pro` · `free_limited` · `any` | `free_limited` = FREE-EDITS counter path. Gate *rules* live in `access_tiers.md`: nodes cite its section name, never restate the matrix. Harness: `debugProOverrideForTests` + `isProProvider` override. |
| `boat` | `none` · `active` · `multiple` | Harness seeds boats in the in-memory DB. |
| `auth` | `none` · `owner` · `crew` · `developer` | `developer` = `AuthService.developerEmail` (the `/admin` drawer tile). Harness: `fake_auth_backend.dart`. |
| `network` | `online` · `offline` · `any` | Harness: `mockConnectivityChannel()` state. |
| `platform` | `host` · `device` · `android` · `ios` | `device` = real camera, GPS, LAN, ads, purchases, permissions. |
| `build` | `debug` · `any` | For debug-only bypasses (`kForceProForTesting`, `DebugBootstrap`). |

## 5. Stable ids

- Dotted lowercase snake_case: `<area>.<screen>[.<element>]`, e.g. `shopping.list.fab_add`,
  `home.tile.shopping`, `chrome.drawer.upgrade_pro`, `game_yatzy.board.roll`.
- The root is `app.launch`. `home.screen` has parent `startup.splash` (with `onboarding: seen`);
  `onboarding.pager` hangs off `startup.splash` too, and its **Skip**/**Get started** elements
  open `home.screen`.
- Ids are **never renamed**. If the UI changes, keep the id and update the fields. If a
  feature is removed, delete its node; the lint then flags any dangling `parent`/`opens`.
- When a `Key` is needed, its value **is the node id**: `Key('shopping.list.fab_add')`. That
  makes code ↔ map grep-able both ways.

## 6. Index, search, traverse-to-root

`dart run tool/feature_map.dart <cmd>` (pure Dart plus a `yaml` dev dependency, like
`tool/error_log_admin.dart`, with no `dart:ui`):

| Command | Output |
| --- | --- |
| `index [<area>]` | Regenerates `nodes/<area>/_index.md`: a table of `id · title · keywords · path-to-root`. Run it after editing that area only. |
| `find <keyword>` | Case-insensitive match over id, title, label, keywords. Prints ids and files. |
| `path <id>` | Walks `parent` to `app.launch` and prints numbered steps, each with how to reach it, effective preconditions (merged root→leaf), `expected`, and `script`. This is what an agent follows. |
| `lint` | See §8. Exit ≠ 0 on errors. |

Plain `grep -r <word> .ai_context/feature_map/nodes` also works, because the nodes are
readable Markdown.

## 7. Script conventions

**Host first (CI-safe, preferred).** One file per area:
`integration_test/feature_map/<area>_test.dart`. **Each test's name is the node id**, so a
single node runs with:

```
flutter test integration_test/feature_map/shopping_test.dart --plain-name "shopping.list.fab_add"
```

- `_harness.dart` (Foundation only) exposes `pumpSisuApp(tester, FmState(...))`, which
  builds `createAppRouter(initialLocation: …)`, the in-memory `AppDatabase`, the provider
  overrides for tier/auth/boat/network/readiness, and mock SharedPreferences for onboarding.
  It also exposes the primitives `tapNode(finder)`, `openEndDrawer()`, `openHomeTile(id)`,
  `backToHome()` and `settle()` (bounded pumps: no `pumpAndSettle` on screens with ads or
  animations).
- Each test reaches its node **by tapping from the start location** (a real reach path, not a
  deep link), then asserts `expected`. Parent-screen tests make sure the children's openers
  work. Area files keep a small `reach<Screen>()` helper that children reuse.
- A new host test must stay green on `flutter-tester` inside `./scripts/run_full_suite.sh`.
  If a flow can't run on the host (platform channels, camera, GPS, LAN, real ads/purchases),
  mark the node `script: {device: …}` and skip the host test. Don't fake it.

**Device drivers (on demand, not in the suite).**
`scripts/feature_map/<area>.sh <node-id> <serial|udid>` sources `scripts/lt_ui_helpers.sh`
and uses `and_tap_text`/`ios_tap_label`/`wait_for_text`, plus
`adb_swipe_reveal_action.sh` for swipes. No pixel coordinates. Launch with
`android_run.sh`/`ios_run.sh` and `--dart-define-from-file=dart-defines.json`. Finders
use `device.label`, so any icon-only control a driver must hit needs a tooltip or
`semanticsLabel` (added by that area's issue).

**Runner.** `scripts/feature_map.sh <node-id> [--device <id>]` resolves the node's `script`
through `tool/feature_map.dart` and runs the host test (default) or the device driver.
Per the CLAUDE.md shell rule, any pipes or redirects live inside the script.

**Keys and semantics policy.** Keep changes to the minimum each area needs:
text/tooltip first; add a tooltip or `semanticsLabel` to icon-only buttons (this also helps
a11y, TEST10); add `Key('<node id>')` only for repeated or ambiguous widgets. Shared
components get **parameterised** hooks (for example `SwipeableListItem` labels its actions
so drivers can find them) in the Components issue, so module issues never edit
`lib/ui/components/`.

## 8. Lint (`tool/feature_map.dart lint`, run by `test/feature_map_lint_test.dart`)

Errors (fail the suite): duplicate ids; `parent`/`opens`/`also_from`/`uses` pointing at a
missing id; a cycle, or a node not reaching `app.launch`; `source` file missing; `widget`
class not found in `source`; `route` symbol not in `AppRoutes`; `script.host` file missing or
no `testWidgets('<id>'` in it; `script.device` file missing; unknown precondition key or value.

Warnings (printed, never failing): an element without any script; a stale `_index.md`
shard (so parallel agents don't fail each other's suites mid-work).

The final **Audit** issue adds the cross-checks: an `AppRoutes` constant with no node (dead
or unmapped route), a detail route reachable only without `extra` (`_MissingExtraScreen`),
a drawer/menu `ListTile` with a null `onTap` in source but no `gate` node explaining it, and
screens no node `opens`.

## 9. Reconciling with "no Tier-C mirrors" (needs Frik's OK)

`screens.md` says "no full screen inventory", and CLAUDE.md forbids derivable inventories.
The feature map **is** an inventory, so this is a deliberate, scoped exemption. It stays
honest by these rules:

1. **Pointers, not copies.** Routes are `AppRoutes` symbols, code is `source` + `widget`
   pointers, gate rules cite `access_tiers.md` §, game rules cite `gameflow.md`. No field
   lists, no pasted code, no route path strings, no copied dialog copy beyond the one
   `label`/`expected` anchor a test asserts.
2. **Content that can't be derived from source.** Reach paths across files,
   preconditions, and expected state are cross-file synthesis (Tier B), which is what
   agents otherwise re-derive every time.
3. **Mechanically verified.** The lint catches pointer drift, and the host tests fail when
   labels or navigation change. Stale map content becomes a red suite, not silent drift.
4. **Never session-loaded.** It's reached through one Read-Next row. Areas are read per
   task (`path`/`find`), never whole.

`screens.md` keeps its "gotchas only" rule and gets one pointer line to this map.

## 10. Child issues (dependency tree)

All are sub-issues of #353. Each issue's Notes list its exact `Depends on`.

1. **#354 Foundation** (blocks all).
2. **#355 Startup & onboarding** after #354, in parallel with **#356 Components**.
3. **#357 Home shell & chrome** after #355.
4. After #357 + #356, in parallel: #358 Checklists · #359 Safety · #360 Maintenance ·
   #361 Shopping · #362 Logbook · #363 Fuel+Inventory · #364 Crew+Documents ·
   #365 Chef+Collections · #366 Cocktails · #367 Weather · #368 Anchor · #369 Community ·
   #370 Settings · #371 Account · #372 Games hub.
5. After #372, in parallel: #373–#381 (one per game).
6. **#382 Audit + manual PoC** last (runs alone).
