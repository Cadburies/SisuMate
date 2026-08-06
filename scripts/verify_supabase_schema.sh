#!/usr/bin/env bash
# Live check: remote Supabase schema has the columns/tables the app sync wire
# expects. Uses dart-defines.json (anon key + optional debug login).
#
# Usage:
#   ./scripts/verify_supabase_schema.sh           # skip cleanly if offline / no creds
#   ./scripts/verify_supabase_schema.sh --require # fail if missing or unreachable
#
# Wired into run_full_suite.sh after TEST8 live RLS (unless --skip-live).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

REQUIRE=0
if [[ "${1:-}" == "--require" ]]; then
  REQUIRE=1
fi

if [[ ! -f dart-defines.json ]]; then
  if [[ "$REQUIRE" -eq 1 ]]; then
    echo "verify_supabase_schema: FAIL — no dart-defines.json" >&2
    exit 1
  fi
  echo "verify_supabase_schema: skip (no dart-defines.json)"
  exit 0
fi

python3 - "$REQUIRE" <<'PY'
import json, sys, urllib.request, urllib.error

require = sys.argv[1] == "1"
cfg = json.load(open("dart-defines.json"))
url = (cfg.get("SUPABASE_URL") or "").rstrip("/")
key = cfg.get("SUPABASE_ANON_KEY") or ""
email = cfg.get("SUPABASE_DEBUG_EMAIL") or ""
password = cfg.get("SUPABASE_DEBUG_PASSWORD") or ""

def fail(msg):
    print(f"verify_supabase_schema: FAIL — {msg}", file=sys.stderr)
    sys.exit(1)

def skip(msg):
    if require:
        fail(msg)
    print(f"verify_supabase_schema: skip — {msg}")
    sys.exit(0)

if not url or not key:
    skip("SUPABASE_URL / SUPABASE_ANON_KEY missing")

def call(path, token=None):
    headers = {
        "apikey": key,
        "Authorization": f"Bearer {token or key}",
        "Accept": "application/json",
    }
    req = urllib.request.Request(f"{url}{path}", headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return resp.status, resp.read().decode(), None
    except urllib.error.HTTPError as e:
        body = e.read().decode() if e.fp else ""
        return e.code, body, e
    except Exception as e:
        return None, str(e), e

# Prefer authenticated session when debug creds exist (RLS-safe probes).
token = None
if email and password:
    body = json.dumps({"email": email, "password": password}).encode()
    req = urllib.request.Request(
        f"{url}/auth/v1/token?grant_type=password",
        data=body,
        headers={"apikey": key, "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            token = json.loads(resp.read().decode()).get("access_token")
    except Exception as e:
        print(f"verify_supabase_schema: warn — debug login failed ({e}); using anon")

checks = []

def expect_ok(label, path, ok_codes=(200,)):
    status, body, err = call(path, token=token)
    if status is None:
        fail(f"{label}: network error: {body}")
    if status in ok_codes:
        checks.append((label, "ok", status))
        return
    # Column missing → 400 PGRST204 / 42703; table missing → 404 PGRST205
    snippet = body.replace("\n", " ")[:220]
    checks.append((label, "FAIL", f"{status} {snippet}"))

# Expected wire schema (keep in sync with lib models + supabase/migrations).
expect_ok("boats.polar", "/rest/v1/boats?select=supabaseId,polar&limit=1")
expect_ok(
    "boats.polarBySeaState",
    "/rest/v1/boats?select=supabaseId,polarBySeaState&limit=1",
)
expect_ok(
    "sailing_polar_samples.seaState",
    "/rest/v1/sailing_polar_samples?select=supabaseId,seaState&limit=1",
)

failed = [(l, d) for l, s, d in checks if s == "FAIL"]
for label, status, detail in checks:
    print(f"  {status:4} {label}" + (f" — {detail}" if status == "FAIL" else ""))

if failed:
    fail(
        f"{len(failed)} schema check(s) failed. "
        "Run: ./scripts/apply_supabase_migrations.sh "
        "(needs SUPABASE_DB_URL from Dashboard → Database connection string)."
    )

print("verify_supabase_schema: ok")
PY
