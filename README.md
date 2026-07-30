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

```
flutter test
```

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

## Working on this project

This repo is set up for AI-assisted development with a token-efficient context system —
see `CLAUDE.md` for the project's session rules and `.ai_context/` for the maintained
context files (`INDEX.md` is the entry point).
