# Screens & Navigation — gotchas only

> **No full screen inventory or route tree.** Source: `lib/core/app_router.dart` (`AppRoutes`, `GameCatalog`), screen files under `lib/ui/`.

## Navigation

- Top-level: **GoRouter** (`MaterialApp.router`, `createAppRouter()`).
- Prefer `context.go` / `context.push` with `AppRoutes.*`.
- Some detail/editor flows still use ad-hoc `Navigator.push` + `extra`.
- **No bottom tab bar** — home is a tile grid + per-screen `endDrawer`.
- Paywall is **not** a GoRouter route: `RevenueCatService.showPaywall` → `MaterialPageRoute`.
- Games: `AppRoutes.playGame(id)` / `lobbyGame(id)`; multiplayer-ready id set = `GameCatalog.multiplayerReady` (today: `liars_dice` only).

## Auth / startup

`StartupScreen` → DB init + theme restore → `onboarding_seen_v1` → onboarding or home. No hard auth gate for Free. Owner: `/account`. Crew: `/join` (anonymous + share code). Developer console: `/admin` only if `AuthService.developerEmail`.

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
| Home drawer Pro | Free + ≤1 boat → lock tile for boat management (no navigation). |
| Games multiplayer | Only Liar's Dice; others dimmed + "Solo only" when multiplayer toggle on. |
| Lobby coupling | `lobby_screen.dart` hard-imports Liar's Dice providers — **blocker for GAME1** second title. |
| Paywall context | Don't call `showPaywall` after async gap with a disposed `BuildContext`. |

## Per-game logic

Before changing a game: **only** that game's `lib/ui/games/games/<id>/gameflow.md` + `logic.dart`. Cap discipline: do not load other games' gameflows "for patterns" without grep first.
