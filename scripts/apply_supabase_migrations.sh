#!/usr/bin/env bash
# Apply every file in supabase/migrations/ to the remote Supabase Postgres
# (in filename order). Tracks applied versions in public.schema_migrations.
#
# Credentials (first match wins):
#   1) SUPABASE_DB_URL env  (postgresql://postgres:...@.../postgres)
#   2) dart-defines.json key SUPABASE_DB_URL
#   3) .env key SUPABASE_DB_URL
#
# Get the URI from Supabase Dashboard → Project Settings → Database →
# Connection string → URI (use the **session** pooler or direct string they
# show for your project — not the app anon key).
#
# Usage:
#   ./scripts/apply_supabase_migrations.sh
#   SUPABASE_DB_URL='postgresql://...' ./scripts/apply_supabase_migrations.sh
#   ./scripts/apply_supabase_migrations.sh --dry-run
#
# Requires: psql (brew install libpq && brew link --force libpq)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

resolve_psql() {
  if command -v psql >/dev/null 2>&1; then
    command -v psql
    return
  fi
  if [[ -x /opt/homebrew/opt/libpq/bin/psql ]]; then
    echo /opt/homebrew/opt/libpq/bin/psql
    return
  fi
  if [[ -x /usr/local/opt/libpq/bin/psql ]]; then
    echo /usr/local/opt/libpq/bin/psql
    return
  fi
  echo "error: psql not found. Install with: brew install libpq" >&2
  exit 1
}

resolve_db_url() {
  if [[ -n "${SUPABASE_DB_URL:-}" ]]; then
    echo "$SUPABASE_DB_URL"
    return
  fi
  python3 - <<'PY'
import json, os
from pathlib import Path
for p in (Path("dart-defines.json"), Path(".env")):
    if not p.exists():
        continue
    if p.suffix == ".json":
        d = json.loads(p.read_text())
        u = (d.get("SUPABASE_DB_URL") or "").strip()
        if u:
            print(u)
            raise SystemExit
    else:
        for line in p.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            if k.strip() == "SUPABASE_DB_URL":
                u = v.strip().strip('"').strip("'")
                if u:
                    print(u)
                    raise SystemExit
raise SystemExit(1)
PY
}

MIG_DIR="$ROOT/supabase/migrations"
if [[ ! -d "$MIG_DIR" ]]; then
  echo "error: no $MIG_DIR" >&2
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "(dry-run) would apply in order:"
  ls -1 "$MIG_DIR"/*.sql | sort
  exit 0
fi

PSQL="$(resolve_psql)"
if ! DB_URL="$(resolve_db_url)"; then
  cat >&2 <<'EOF'
error: no SUPABASE_DB_URL.

This is the Postgres connection URI (not SUPABASE_ANON_KEY, not the
dashboard login password).

1. Supabase Dashboard → Project Settings → Database
2. Copy "Connection string" → URI (Session mode pooler is fine)
3. Either:
     export SUPABASE_DB_URL='postgresql://postgres....'
     ./scripts/apply_supabase_migrations.sh
   or add SUPABASE_DB_URL to dart-defines.json / .env (gitignored).

Pending polar migrations (at least) are required for #258/#275/#276:
  boats.polar, boats.polarBySeaState, sailing_polar_samples(+seaState).
EOF
  exit 1
fi

echo "==> applying migrations via psql (history table: public.schema_migrations)"

export PGPASSWORD=""
# Use a single session for bookkeeping + each file.
"$PSQL" "$DB_URL" -v ON_ERROR_STOP=1 <<'SQL'
create table if not exists public.schema_migrations (
  version text primary key,
  applied_at timestamptz not null default now()
);
SQL

applied=0
skipped=0
for f in $(ls -1 "$MIG_DIR"/*.sql | sort); do
  version="$(basename "$f" .sql)"
  already="$("$PSQL" "$DB_URL" -tAc "select 1 from public.schema_migrations where version = '${version}'" | tr -d '[:space:]')"
  if [[ "$already" == "1" ]]; then
    echo "  skip  $version (already applied)"
    skipped=$((skipped + 1))
    continue
  fi
  echo "  apply $version"
  "$PSQL" "$DB_URL" -v ON_ERROR_STOP=1 -f "$f"
  "$PSQL" "$DB_URL" -v ON_ERROR_STOP=1 -c \
    "insert into public.schema_migrations(version) values ('${version}') on conflict do nothing;"
  applied=$((applied + 1))
done

echo "==> done: applied=$applied skipped=$skipped"
echo "==> verifying expected polar/sync schema"
bash "$ROOT/scripts/verify_supabase_schema.sh" --require
