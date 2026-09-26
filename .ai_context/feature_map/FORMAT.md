# Feature Map — file format + rules (read this, then only the leaf you need)

**One feature = one file.** The folder path is the tree and the id:
`home/shopping/add_item.md` → id `home/shopping/add_item`, parent `home/shopping`.
A feature with children also has a folder of the same name (`home/shopping.md` + `home/shopping/`).
Roots: `launch/` (cold start, onboarding) · `home/` (everything reached from Home) · `system/<layer>/` (no UI).

## Template (13 lines, this order, every line present; `-` = not applicable)

```
title: <short name users/agents would search for>
desc: <one sentence: what it does + key gate>
layer: <ux|db|sync|network|auth|pro|ads|ai|platform|lan|logic|errors|ops>
keywords: <comma list: synonyms, user words, module name>
kind: <screen|dialog|button|fab|tile|swipe|menu|toggle|field|longpress|service|job|repo|test>
looks: <where it is + what it looks like, one line>
reach: <step > step > …   (UI)   |   trigger in words (system)>
needs: <k=v · k=v (notes)>
action: <what tapping/triggering it does>
expect: <observable result the script asserts>
uses: <comma list of other feature ids it depends on, e.g. system/sync/outbox>
script: <area name | test file path | ->
source: <file (Class/function names)>
```

## `reach` — executable, never prose (UI features)

Starts at Home with onboarding seen (`home/…`) or at cold launch (`launch/…`). Steps are joined by ` > `:

| Step | Does |
| --- | --- |
| `text:<s>` | tap the widget whose visible text is exactly `<s>` |
| `tip:<s>` | tap by tooltip (icon buttons, FABs) |
| `label:<s>` | tap by semantics label |
| `long:<s>` | long-press text/label `<s>` |
| `swipe:<row text>:<action>` | swipe the row to reveal `<action>`, then tap it |
| `type:<field label>=<value>` | enter text in the field labelled `<field label>` |
| `wait:<s>` | wait until `<s>` is visible (async loads) |
| `back` | system/title-bar back |

The executor always **scrolls until the target is visible** before acting, so no scroll steps are needed.
A target must be **unique on its screen**. If it isn't, or it's an icon-only control with no tooltip/label,
fix the app (add `tooltip`/`semanticsLabel`). Never use indexes, pixel coordinates, or `Key`s (devices can't see keys).

## `needs` keys

`onboarding=seen|unseen` · `tier=free|pro|free_limited` · `boat=none|active|multiple` ·
`auth=none|owner|crew|developer` · `network=online|offline` · `platform=host|device|android|ios` · `build=debug`.
Omitted key = any. Gate *rules* live in `access_tiers.md`; only state what this feature needs.

## `script` + running

`scripts/fm.sh <id> [--reach] [--device <serial|udid>]` (never call the test files directly):

- `script: shopping` → `test/feature_map/shopping_test.dart`, test named `<id>` (variants `<id> [free]`).
- `script: test/foo_test.dart` → existing unit/widget test (typical for `system/…`).
- `--reach` stops once the feature is on screen (host or device). Use it to *get there* and then work by hand.
- `--device` runs the same `reach` steps on a real phone/sim via `scripts/lt_ui_helpers.sh` (label taps, scroll-retry).
- Missing script test for a feature? Create it in the area file. The suite runs every host script.

## Parallel work (Touches, derived — no extra field)

`source` is the feature's ownership list: put **every** file a change to this feature edits
(`a.dart (Sym); b.dart`). Then:

```
dart run tool/feature_map.dart touches <id> [<id>…]   # paste into the issue's Touches
dart run tool/feature_map.dart overlap <id> <id>      # exit 2 + files if not parallel-safe
```

Touches = the feature file + `source` files + `script` file; `uses` sources are listed as
dependencies. CLAUDE.md single-owner hotspots are flagged and always conflict.

## Public wiki (generated — this folder is the only source)

`title`, `desc`, `keywords`, `looks`, `reach`, `needs`, `action`, `expect` of `layer: ux` features are
**published** to the public GitHub wiki: write them in plain user language (no paths, class/function
names, `AppRoutes`, `()`). Developer/debug-only and `system/…` features are never published.
After creating or changing any feature file: `scripts/publish_wiki.sh` (`--dry-run` to preview).

## Find things (cheapest first)

```
find .ai_context/feature_map/home/shopping              # subtree
grep -ri "spares" .ai_context/feature_map               # any field
grep -rl "^layer: sync" .ai_context/feature_map         # by layer
grep -rl "tier=pro" .ai_context/feature_map             # by gate
```
