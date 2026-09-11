# Sisu Mate — Theme & GUI Consistency Standard

> **THE GOLDEN RULE:** Read this file **before changing the colours or layout of any GUI** — every screen, tile, list, title bar, drawer, dialog, or detail view, in **every** module **including Games**. All apps inside Sisu Mate must look and behave as one app. If a change would make a screen diverge from what's below, either bring the screen into line or update this file first (and record it in the commit + relevant GitHub issue). Colours come **only** from `SisuColors` in `lib/core/colors.dart` — never hard-code hex or redefine colours in a widget.
>
> This standard was set by the product owner (2026-07-07) after finding widespread inconsistency: divergent layouts, non-uniform swipe actions, inconsistent title bars, missing drawer buttons, title overflows, and screens ignoring the dark theme. Treat consistency as a feature.

---

## 0. Canonical tokens

All colours live in `lib/core/colors.dart` (`SisuColors`). Existing tokens: status-bar (Pro/Free × On/Off), `completedBackground/Text` (teal), `incompleteBackground/Text` (blue-grey), `hiddenBackground/Text`, `notAvailableBackground/Text` (red), dark/light surface tokens (`darkBackground #121212`, `darkSurface #1e1e1e`, …).

**Item-list state palette (UX1 + UX4):** dark `state*Bg/Desc/Title` and light `lightState*Bg/Desc/Title` for default / stocked(completed) / shopping / unavailable / hidden. Resolve via `SisuColors.itemStateColors(isDark, ItemListState)`. Shared tiles: `ThemedStateTile` (generic) and `ChecklistItemTile` (checklists/maintenance/safety). Pair with `SwipeableListItem` for §6.6 swipes.

**Three-layer greys + elevation (UX1):** `getAppBackground` / `getListSurface` / `getTileColor` + `tileElevation(isDark)`.

---

## 1. Theme modes

- **Dark is the default.** A light theme exists and must be derived to mirror every rule here (lightest scaffold, white/near-white tiles, dark text, same layout & states).
- **The only theme toggle lives in the main-screen (home) drawer.** Persisted to `UserSettings.isDarkMode`, restored on startup (`ThemeModeNotifier`). Do not add per-screen theme controls.
- Every screen must obey the active theme via `Theme.of(context)` / `SisuColors.getXxx(isDark)` — **no screen may ignore the dark theme** (a current bug across list screens).

---

## 2. Elevation & separation ("elegant separator")

Tiles are separated from their background not by heavy borders but by an **elegant** cue: a soft **shadow**, subtle **glow**, or light **3D** raise. Pick one token and use it everywhere so all tiles feel the same. The three background layers (§3) plus this elevation are what make the UI read cleanly on dark grey.

### 2.1 Tonal bar fill (title bar + tiles)

Horizontal surfaces (title bar, home tiles, main-list tiles, item rows) are **not** a flat fill. They use a **same-hue tonal bar**: the `SisuColors` token in the **middle**, a **darker shade of that same hue** (HSL lightness only) at **both ends**. Constructor: `SisuColors.tonalBarGradient`. Do not invent a second hue or a left-to-right brand wipe.

Picked over LTR dark→colour (pulls the eye to one side) and centre-dark (reads as a crease). Text contrast is still against the centre token.

---

## 3. Background layering (applies to ALL screens)

Three stacked greys, consistent across the main screen, main lists, and item lists:

1. **App/scaffold background** — the **darkest** grey (darker than `#121212`).
2. **List/surface layer** — `#121212`-ish.
3. **Tile** — slightly lighter grey, raised with the §2 separator.

Light theme mirrors this (lightest → white).

---

## 4. Main (home) screen  ✅ done (UX2, 2026-07-07)

- Background: darkest grey (`SisuColors.getAppBackground` → `#0D0D0D` dark).
- Module tiles: **one uniform dark blue-grey** in the title-bar family but darker — `SisuColors.getHomeTile` (`#2E3D45` dark) — with the standard elevation (§2). (The owner preferred this cohesive blue-grey over a neutral `#121212`.)
- Each tile keeps its **per-module accent colour on the icon only** (green cart, purple glass, gold spoons, …) for identity; the tile background stays uniform.
- **Three columns.**

---

## 5. Main list screens — **Chef's list is the reference layout**  ✅ done (UX3, 2026-07-09)

**Shipped:** shared `MainListTile` + `MainListSearchBar`; `GroupGrid` is 2-col (`childAspectRatio` 0.58) with live item counts; tile body uses non-scrollable `SingleChildScrollView` so fixed-aspect cells never throw RenderFlex overflow; Checklists / Maintenance / Safety / Crew / Documents / Inventory / Fuel / Logbook use the main-list chrome; Chef/Cocktail card titles use high-contrast `getTextPrimaryColor`.

Chef's structure is the reference; main lists follow the theme (darkest scaffold, dark-grey raised tiles) with readable text on dark grey.

### 5.1 Title bar standard (owner, 2026-07-12 — BINDING for every screen)

Implemented once in `TitleTile` (`lib/ui/components/title_tile.dart`) — plug it in, don't rebuild:

1. **Line 2 is ALWAYS the status line**: `boat name • Pro/Free • Online/Offline • email user`,
   with `• Syncing (N)` appended while the outbox is non-empty (`syncOutboxCountProvider`).
   Per-screen subtitle text is retired — `TitleTile.subtitle` is ignored (strip on touch, UX7).
2. **Back arrow on the far left** whenever the screen can pop (`Navigator.canPop`); the home
   screen is the root so it never shows one. No screen adds its own back button.
3. **Trailing icons, right → left**: **drawer (menu)** far right, then **import/export**, then
   **share** (leftmost of the cluster). `actionsBuilder` lists must therefore order
   `[share…, import/export…]`; the menu icon is appended by `TitleTile`.

**Vertical structure (top to bottom):**
1. **Title bar** — per §5.1.
2. **Tabs row** — e.g. Chef / My Pantry / Chef's Choice — only in apps where tabs make sense.
3. **Search row** — all apps.
4. **Tags row** — where tags make sense.
5. **The list** — **two columns of tiles.**

**Main-list tile anatomy (rows, top → bottom):**
1. Icon / image.
2. **Title** — Chef's current title colour is hard to read on dark grey; pick a **more readable** colour. (Improve once, in `SisuColors`, for all.)
3. **Tags** (where appropriate) — Chef's current tag style is good; reuse it.
4. **Count** of tasks / ingredients / items — same style as Chef's.
5. **Time** — Chef shows prep + cook. Other lists show a sensible **total time** across the list's items (must recompute as users hide/delete/add items). Where money fits, show **cost** too.
6. **Attention line** — Chef shows **allergens in red**; other lists show **expiry / due dates** or similar in the same attention style.
7. **Badges line** — Chef shows vegan/halal/gluten-free/etc.; other lists show something equally useful for that domain.

---

## 6. Item-list screens (inside a list)  ✅ done (UX4, 2026-07-09)

> **Shipped:** raised state-coloured tiles on Checklist / Maintenance / Safety (`ChecklistItemTile`), Shopping / Bar / Pantry / Crew / Inventory / Documents / Fuel (`ThemedStateTile` + light+dark `itemStateColors`). Colour tells state; no tick/cart status icons on tiles. Swipes via `SwipeableListItem` where hide/complete/stock apply. Record lists without hide/stock use `ItemListState.defaults` only.

### 6.1 Background & tiles
Same three-layer greys as §3: darkest scaffold, `#121212` surface, raised state-coloured tiles with the §2 separator.

### 6.2 Title bar
Follows §5.1 (binding for every screen, including item screens): mandatory status line, back arrow, and share/import-export/drawer icon order. The drawer holds per-list options (e.g. **sync item counts**, **show/hide deleted items** where relevant, factory reset, and other list-specific tasks).

### 6.3 Header rows (below the title bar)
1. List name.
2. Prep/cook (Chef) — or time/cost / whatever matched the tapped main-list tile.
3. Ingredients / tasks / count as appropriate.
4. Servings — keep for Chef & Cocktails; omit where it doesn't fit.

### 6.4 Tile anatomy
- **Left:** the item's image/icon. **Do not** put tick / shopping-cart / red-cross status icons here — **the tile colour tells the state story** (§6.5), not icons.
- **Title:** item name.
- **Next row:** quantity used / task description.
- **Next row:** the date it was last completed / added / purchased (where appropriate), with associated **cost** where appropriate. Design a genuinely useful secondary line per app — **not** a literal "in my pantry / fresh provision" label (that's conveyed by colour).

### 6.5 State → colour (the tile colour IS the status)
Each state uses a background with a **lighter description** text and an **even-lighter title** text. Grey is the quiet default; red is alarm — they are not two spellings of “not stocked”.

| Colour | Enum | Meaning |
|---|---|---|
| **Grey** | `defaults` | Still to do (Safety / Maintenance / checklists), or listed in pantry/bar but not aboard. No alarm. |
| **Green** | `stocked` | Done, or aboard (in pantry / in bar / bought). |
| **Blue** | `shopping` | On the shopping list. |
| **Red** | `unavailable` | Missing for *this* recipe (Chef / Cocktails ingredient rows + “Missing N” on recipe cards). Alarm only. Not used for pantry/bar catalog unstocked, and not implemented as “deleted”. |
| **Dark grey** | `hidden` | Hidden on purpose. |

Pantry / My Bar catalog: green → blue → **grey**. Recipe lines: green → blue → **red**. Checklists never use red.

*(If a state is missing from this list, raise it — the owner asked to be told.)*

### 6.6 Swipe actions (uniform across every list)
- **Swipe RIGHT** (action icons appear on the **left**), organise: **(un)hide** (darker grey), **shopping/Done** (blue/green), **email** (indigo), **delete** (red) — where applicable.
- **Swipe LEFT** (action icons appear on the **right**), state only: **complete** / **in-stock** toggle — no secondary actions (e.g. email is on the organise side).

This must be identical everywhere. The shared `SwipeableListItem` component is the vehicle; bespoke `Slidable`/`Card` tiles that diverge (e.g. the old My Bar card) are bugs — route them through the shared component.

---

## 7. Item detail screen (tap a tile)  ✅ done (UX5, 2026-07-09)

Tapping any item opens its **detail screen** — one per item, **swipeable through the list**: swipe **left → previous/up**, swipe **right → next/down** the list. Same theme colours.

- Shows **all** fields for the item (tiles can't show everything), organised **important → less important**, aesthetically arranged so the key info is visible at a glance.
- **Editable in place:** tap any field, change it, and **Save**. Actions available: **Save / (un)delete / (un)hide / (in)complete / Cancel**.
- An **image area** with a button **overlapping the image/icon** to take a photo or upload one. Prefer a single **camera+** (`add_a_photo`) control that opens the shared Camera/Gallery bottom sheet (`pickPhotoFromCameraOrGallery` in `lib/ui/components/photo_source_picker.dart`) — not separate Camera + Gallery buttons.
- A **history list** at the bottom (previous completions / purchases).
- The **action buttons sit above the history list** so they're always readily available (history scrolls under them).

**Implementation:** shared `ItemDetailShell` (`lib/ui/components/item_detail_shell.dart`) + `RecordDetailScreen` for Crew/Inventory/Documents/Fuel. Checklist/Maintenance/Safety use upgraded `CheckPageViewer`. Shopping uses `ShoppingItemDetailScreen`. Bar/Pantry use `IngredientDetailScreen` (bar: tappable “Used in cocktails”; pantry: tappable “Used in menus”). Chef/Cocktail recipe details keep their rich layouts and gained **TitleTile menu + endDrawer** (edit, share, sync counts, favourite/delete where relevant). Cocktail ingredients open My Bar; menu ingredients open My Pantry when tracked. Photo pick everywhere goes through `pickPhotoFromCameraOrGallery`. `toggleComplete` appends to `completionHistory` for the history pane. Orphaned `ItemDetailScreen` removed.

**Shopping ↔ stock:** `ShoppingRepository.ensureInShopping` is idempotent; pending cart names stream via `watchAllItemNames` / `shoppingItemNamesProvider`. Marking a cart item **bought** stocks matching Bar+Pantry rows by name and resyncs recipe missing counts (Drift streams update lists).

---

## 8. Games  ✅ done (UX6, 2026-07-09)

Hub uses app chrome: `SisuColors` scaffold, `TitleTile` + subtitle, end drawer (`Account` / `Data` / `About`), raised tiles with readable titles, multiplayer switch on tile surface. Lobby uses app background. Help screen overlays use `SisuColors` (in-game board art may stay immersive).

---

## 9. Cross-screen live updates (Drift)

With the Drift migration, repositories expose reactive `.watch()` streams — **any** screen watching a table updates automatically when **another** screen writes to it. So "notify other lists of state changes" is already handled: build screens on the `StreamProvider`s (e.g. `recipesProvider`, `barIngredientsProvider`) and edits propagate app-wide with no manual signalling. Prefer this over `ref.invalidate` for list state.

---

## 10. Definition-of-done for any GUI change

Before finishing a UI task, confirm:
- [ ] Uses `SisuColors` tokens (added there if new) — no inline hex, no redefined colours.
- [ ] Honours the active dark/light theme via `Theme.of(context)`.
- [ ] Three-layer greys + the standard tile separator (§2–3).
- [ ] Title bar matches §5.1: mandatory status line (not free-text subtitle), back arrow when it can pop, icons in share/import-export/drawer order.
- [ ] Swipe actions match §6.6 exactly (via `SwipeableListItem`).
- [ ] Tile state colours match §6.5 (colour tells the story; no status icons on the tile).
- [ ] No title/label overflow (pump a widget test — `RenderFlex` overflow fails the test).
- [ ] Tap → swipeable, editable detail screen with sticky actions over a history list (§7).
