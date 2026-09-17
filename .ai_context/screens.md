# Screens & Navigation — gotchas only

> **No full screen inventory or route tree.** Source: `lib/core/app_router.dart` (`AppRoutes`, `GameCatalog`), screen files under `lib/ui/`.

## Navigation

- Top-level: **GoRouter** (`MaterialApp.router`, `createAppRouter()`).
- Prefer `context.go` / `context.push` with `AppRoutes.*`.
- Some detail/editor flows still use ad-hoc `Navigator.push` + `extra`.
- **No bottom tab bar** — home is a tile grid + per-screen `endDrawer`.
- Paywall is **not** a GoRouter route: `RevenueCatService.showPaywall` → `MaterialPageRoute`.
- Games: `AppRoutes.playGame(id)` / `lobbyGame(id)`; multiplayer-ready set = `GameCatalog.multiplayerReady` (source of truth; solitaire is `soloOnlyByDesign`).

## Auth / startup

`StartupScreen` → DB init + theme restore → `onboarding_seen_v1` → onboarding or home. No hard auth gate for Free. Owner: `/account`. Crew: `/join` via `JoinBoatService` (redeem share code **first**, then local boat upsert + active boat + **restamp content** + `ensureStarted` — invalid code never half-enrolls). Developer console: `/admin` only if `AuthService.developerEmail`.

## Shared UI primitives (prefer these)

| Widget | File | Note |
| --- | --- | --- |
| `TitleTile` | `ui/components/title_tile.dart` | Binding title bar (`theme.md` §5.1); optional `actionsBuilder` |
| Drawer sections | `ui/components/common_drawer.dart` | Account, data mgmt, Pro upgrade, about |
| `SwipeableListItem` | `ui/components/swipeable_list_item.dart` | Uniform swipes |
| `ThemedStateTile` / `ChecklistItemTile` | components | State colours |
| `SmartImage` | `ui/components/smart_image.dart` | local → remote → asset |
| `ItemDetailShell` / `CheckPageViewer` | components / checklists | Shared detail chrome; FREE-EDITS gate on check path |
| `BannerAdWidget` / `NativeAdWidget` | components | Pro hides banner |

## Gotchas (non-derivable)

| Area | Risk |
| --- | --- |
| End drawer menu button | `Scaffold.of(context).openEndDrawer()` needs a **descendant** context of the `Scaffold` — wrap body in `Builder`. Ancestor `build` context fails silently (ChefScreen bug class). |
| Drawer layout | Content above footer: `Expanded(child: SingleChildScrollView(...))` + pinned footer. Bare `Column` + `Spacer` overflows when sections grow. |
| Nested `Slidable` | Never wrap an `ExpansionTile` that already has per-row `Slidable`s; scope outer `Slidable` to the **header row only**. |
| Checklist complete | List-level complete = hard Pro gate + interstitial; detail (`CheckPageViewer`) = FREE-EDITS (5 free). |
| Checklist item rows | Deep `isProAsync.when` → `SwipeableListItem` — preserve Pro gate when refactoring layout. |
| Checklist autopilot (BAI3) | Banner is keyword-match on existing checklist *titles* (last minute / one day / one week / document / watch) from trip window + weather — no new schema. Logic: `SuggestionEngine.checklistAutopilot` + `checklist_autopilot_provider.dart`. |
| Home drawer Pro | Free + ≤1 boat → lock tile for boat management (no navigation). |
| Crew join (`/join`) | Always go through `JoinBoatService.join` — never set active boat before redeem succeeds. Restamp is required so local rows use the captain’s boat GUID for wire-prefix sync. |
| Home tile order (#351) | Device-local SharedPreferences (`home_tile_order_v1`); not synced. Long-press → jiggle edit mode + drag; **Done** exits. New catalog ids merge next to default neighbors (`HomeModules.merge`). |
| Home readiness (BAI1) | `_PassageReadinessCard` always shown (Ready is useful). Uses `passage_readiness_provider` + `SuggestionEngine.passageReadiness` (safety + maint + wind + fuel ETA). |
| Fuel burn (BAI4/SUG6–7) | Single fill → remaining is **unknown** (`null`), not full tank. L/day = last 6 intervals, recency-weighted. Source: `fuel_burn_estimator.dart`. |
| Games multiplayer | Hub multiplayer toggle: non-`multiplayerReady` tiles dim + "Solo only" badge. Lobby `switch (gameId)` starts the matching notifier — add both chip + case when shipping a new multiplayer title. |
| AI seats (GAI1/GAI5) | Lobby Skill + Style chips → `LobbyPlayer.aiDifficulty` / `aiPersona`. Dice multi-seat bots (Dudo, Liar's Dice) apply **per-seat** skill/style; board games still use max-seat skill unless they grow their own. |
| Screen+Drift tests (TEST6) | Prefer `AppDatabase.forTesting(NativeDatabase.memory())` + real screen pump (see `test/shopping_screen_integration_test.dart`); not dialog-only. Free tier: `debugProOverrideForTests` when Sync would hit platform channels. |
| Paywall context | Don't call `showPaywall` after async gap with a disposed `BuildContext`. |
| Passage hand-off (#329) | Anchor owns the live hook; Weather owns routing/GRIB/departure window. Open planner with `PassageHandoff` extras (`lib/ui/passage_handoff.dart`). #328 saved spots become dest via `toDestination` — do not copy isochrones onto the alarm map. Home keeps two tiles. |
| Saved spots (#328) | Catalog is `AnchorSpot` (new table), **not** `AnchorWatch`. Weigh/drop never deletes spots. Share the saved record (`CommunityShareKind.anchorage`); default include coords, optional strip. Route via `PassageHandoff.toDestination`. |

## Per-game logic

Before changing a game: **only** that game's `lib/ui/games/games/<id>/gameflow.md` + `logic.dart`. Cap discipline: do not load other games' gameflows "for patterns" without grep first.
