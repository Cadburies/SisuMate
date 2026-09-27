title: Local database schema and migrations
desc: The Drift schema for all modules; with no install base yet, a schema bump wipes and recreates local tables instead of migrating.
layer: db
keywords: schema, drift, tables, migration, schemaVersion, wipe
kind: service
looks: -
reach: app start when the stored schema version differs from the code
needs: -
action: onUpgrade recreates every table (dev/sim only policy); Supabase migrations track remote changes separately.
expect: Opening an older-schema database leaves a consistent, empty-then-seeded schema.
uses: system/sync/remote_schema
script: test/app_database_migration_test.dart
source: lib/data/drift/app_database.dart (AppDatabase)
