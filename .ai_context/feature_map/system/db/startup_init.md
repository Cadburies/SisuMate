title: Database start-up and first-run seed
desc: Opens the local Drift database on launch; a fresh install is seeded (settings row, bundled content, factory baseline); a corrupt database is detected so the app can offer a reset.
layer: db
keywords: database, startup, init, seed, first run, corrupt, drift, sqlite
kind: service
looks: -
reach: runs on every launch from the splash screen, before Home
needs: -
action: Empty checklist-groups table means fresh install → seed; a failing first query means corrupt → DbInitResult.corrupted.
expect: healthy / seeded / corrupted result; deferred catalog seeding runs after Home appears.
uses: system/db/bundled_seed
script: test/startup_lifecycle_test.dart
source: lib/services/database_service.dart (DatabaseService, DbInitResult, runDeferredSeeds)
