# Sisu Mate

An offline-first Flutter app for sailors — checklists, maintenance, safety, provisioning,
crew, and onboard games, all working without a signal and syncing when you're back online.

## Features

### Boat & trip management

- **Checklists** — grouped checklists with a guided check-page flow, history, and photo
  attachments.
- **Maintenance** — scheduled maintenance tracking, seeded with common engine service
  intervals.
- **Safety** — safety briefings and equipment checks.
- **Captain's Log** — logbook entries for trips, conditions, and incidents.
- **Fuel & Water** — fuel and water level logging.
- **Inventory** — onboard spares and equipment inventory.
- **Documents** — a vault for boat documents (registration, insurance, manuals).
- **Crew & Contacts** — crew roster and contact management, with share-code crew invites.
- **Weather** — marine weather and passage planning.
- **Boats** — manage one or more boats per account (multi-boat is a Pro feature).

### Provisioning & onboard life

- **Shopping** — shopping lists with origin categories and budget tracking.
- **Chef** — recipes, meal planning, provisioning lists, and a guided cooking mode.
- **Cocktails** — cocktail recipes with batch scaling.

### Community

- **Community** — browse and import checklist templates shared by other users, with
  ratings.

### Games

Nine onboard games for when you're anchored or waiting out weather:

- **Board/dice:** Yatzy, Liar's Dice, Dudo, Checkers, Backgammon
- **Cards:** Cribbage, Uno, Poker, Solitaire (solo only, by design)

Eight of the nine support **local LAN multiplayer** — no internet required, just the same
Wi-Fi network. One device hosts (via mDNS discovery + a lightweight WebSocket protocol),
others join from the lobby; AI opponents can fill empty seats. Every multiplayer title
also has a full single-player mode against AI.

### Accounts & sync

- **Offline-first**: the app is fully usable with no connection; a local Drift (SQLite)
  database is the source of truth.
- **Pro sync**: Pro accounts get realtime sync across devices via Supabase, plus crew
  members can join a boat anonymously via a share code without needing their own Pro
  subscription.
- **Free vs Pro**: Free users get full read access and limited edits (with ads); Pro
  removes ads, unlocks unlimited edits, multi-boat management, sync, and Community
  import. Managed through RevenueCat.

## Tech stack

- **Flutter** 3.41+ / **Dart** ^3.8.1, Material 3
- **State management:** Riverpod 3
- **Local database:** Drift (SQLite)
- **Backend:** Supabase (Pro sync, crew sharing, Community)
- **Payments:** RevenueCat
- **Ads:** Google Mobile Ads (Free tier)
- **LAN multiplayer:** `bonsoir` (mDNS discovery) + raw WebSocket transport
- **Routing:** go_router

## Getting started

1. `flutter pub get`
2. Provide a `dart-defines.json` with your Supabase and RevenueCat credentials (see
   `lib/core/di.dart` / `revenuecat_service.dart` for the expected keys).
3. Run with dart-defines (required — omitting them causes a splash hang or missing
   credentials assertion):
   ```
   flutter run --dart-define-from-file=dart-defines.json
   ```

### Building

```
flutter build apk --debug --dart-define-from-file=dart-defines.json
```

### Testing

**After every implementation task**, run the full regression suite and require green:

```bash
./scripts/run_full_suite.sh
```

That is the single entry point. It runs, in order:

| # | Step | What |
| --- | --- | --- |
| 1 | **SEC3** | `scripts/scan_release_secrets.sh` — no secrets in assets/lib/APK |
| 2 | **Analyze** | `flutter analyze` — zero issues |
| 3 | **Host tests** | `flutter test` — unit, widget, screen+Drift, P0–P3 host gates (offline, import, crew join, AI determinism, units, a11y…) |
| 4 | **TEST8 live RLS** | `scripts/test_supabase_rls.sh` — skips cleanly if no `dart-defines.json` / offline |
| 5 | **TEST9 integration** | `flutter test integration_test` — default device `flutter-tester` |

```bash
# Offline / no Supabase credentials (still runs 1–3 + skips 4):
./scripts/run_full_suite.sh --skip-live

# Host-only (no integration_test):
./scripts/run_full_suite.sh --skip-live --skip-integration

# Integration on a real simulator/device:
./scripts/run_full_suite.sh --device <device-id>
```

| Flag | When to use |
| --- | --- |
| `--skip-live` | No network or no `dart-defines.json` |
| `--skip-integration` | Host unit/widget only (faster local loop) |
| `--device <id>` | Real sim/device for `integration_test` instead of `flutter-tester` |

Piecemeal equivalent (same coverage as the script):

```bash
./scripts/scan_release_secrets.sh
flutter analyze
flutter test
./scripts/test_supabase_rls.sh                          # optional; skips without dart-defines
flutter test integration_test -d flutter-tester
```

Targeted smoke for recent P1 gates:

```bash
flutter test test/offline_persistence_test.dart \              # TEST13
             test/import_roundtrip_test.dart \                 # TEST14
             test/join_boat_flow_test.dart \                   # TEST15
             test/checklist_items_screen_integration_test.dart # TEST17
```

AI agents use the same gate in `CLAUDE.md` §5. Open backlog: GitHub Issues (`test-gap` label = testing gaps). Parallel agents: `CLAUDE.md` §Parallel agents.

## Architecture

```
lib/core/     di, colors, theme, units, app_router
lib/data/     drift/ (schema), repositories/, seed/
lib/models/   plain Dart domain models
lib/services/ Database, Sync, Auth, WirePrefix, LAN multiplayer, ads…
lib/ui/       home, modules (checklists, chef, games, …), community, account
```

Pattern: **repository → provider → `ConsumerWidget`**. The UI never talks to Drift or
Supabase directly — everything goes through repositories wired up in `lib/core/di.dart`.

## Legal

- Privacy policy source: `legal/privacy-policy.html` (`legal/privacy-policy-url.txt` holds the
  published URL). Published via GitHub Pages from a separate public repo, so this private
  source tree stays private: https://cadburies.github.io/sisumate-legal/privacy-policy.html —
  this is the URL used in store listings (App Store / Play Console) and the Wix site embed.
  Edit the file here, then copy it over to `sisumate-legal` and push, so the two don't drift.
- `grok/forms/` also has draft `terms.html` / `support.html` (same publish pattern, not yet
  hosted) and store-questionnaire answer text (App Privacy, Data Safety, keywords, age rating,
  etc.) — see `grok/forms/README.md` for what goes where.
- Store listing copy/assets (short/full description, icon, feature graphic, screenshots):
  `.claude/store_assets/`.

## Working on this project

This repo is set up for AI-assisted development with a token-efficient context system —
see `CLAUDE.md` for the project's session rules and `.ai_context/` for the maintained
context files (`INDEX.md` is the entry point).
