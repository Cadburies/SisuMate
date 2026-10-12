---
name: schema-change
description: Use when a task adds/changes/removes a Drift table or column (app_database.dart), a domain model field that maps to one, a Supabase table/column/RLS policy, or a synced wire field. The full cascade + remote apply + verify, in one change.
---

# Schema change (SisuMate, non-negotiable)

Project-native skill. The rule lives in AGENTS.md §Mandatory rules; this is the procedure. There is no install base, so wipe/reseed is fine and there's no data-preserving migration. Every layer still lands **in the same change**.

## Cascade checklist (do in order)

1. **Domain model** `lib/models/`: field, `fromJson`/`toJson` if serialized. List/embedded fields are JSON text columns.
2. **Drift** `lib/data/drift/app_database.dart`: column/table. A new table goes in `@DriftDatabase(tables: [...])`. **Bump `schemaVersion`.**
3. **Repository mapping** in `lib/data/repositories/` (row ↔ model). UI never touches Drift.
4. **Generate:** `dart run build_runner build --delete-conflicting-outputs`. Never hand-edit `*.g.dart` (the factory guard denies it).
5. **Supabase migration:** new `supabase/migrations/YYYYMMDDHHMMSS_<what>.sql`, later than the last file. Make it idempotent (`add column if not exists`, `drop policy if exists` then `create policy`). Include RLS for every new table.
6. **Sync:** wire fields and WirePrefix (`lib/services/sync_service.dart`, `wire_prefix.dart`). Read `caching.md` §Sync outbox and `risks.md` §SyncService first.
7. **Pro/crew access:** if the data is Pro- or crew-scoped, check `access_tiers.md`.
8. **Apply remotely via the Supabase MCP only:** `list_migrations`, then `apply_migration` for each file not yet applied, in order. The project ref is from `SUPABASE_URL` in `dart-defines.json`. Don't use psql, the dashboard SQL editor or a DB-URL script. If the MCP isn't authenticated, stop and tell the user. Don't claim done.
9. **Verify:** `./scripts/verify_supabase_schema.sh --require`, plus the full suite **without** `--skip-live`.
10. **Tests:** cover the round trip (model ↔ Drift ↔ wire). Extend TEST14 import round-trip if the field is exported.

## Before you start

- `app_database.dart` and `models.dart` are single-owner hotspots. Claim them, and check no other `agent:*` issue lists them.
- Read `risks.md` §AppDatabase + DatabaseService and §Domain models (those sections only).

## Done means

The issue comment states the migration file name(s), the MCP apply result, the `verify_supabase_schema.sh --require` output, and the suite result with no `--skip-live`.
