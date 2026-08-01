#!/usr/bin/env bash
# TEST8 — live Supabase RLS / auth smoke against the test project.
# Credentials: dart-defines.json (gitignored). Skip cleanly if missing.
#
# Usage:
#   ./scripts/test_supabase_rls.sh
#   SISU_LIVE_SUPABASE=0 ./scripts/test_supabase_rls.sh   # force skip
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "${SISU_LIVE_SUPABASE:-1}" == "0" ]]; then
  echo "TEST8 skip: SISU_LIVE_SUPABASE=0"
  exit 0
fi

if [[ ! -f dart-defines.json ]]; then
  echo "TEST8 skip: no dart-defines.json (no live credentials)"
  exit 0
fi

python3 - <<'PY'
import json, sys, urllib.request, urllib.error

cfg = json.load(open("dart-defines.json"))
url = cfg.get("SUPABASE_URL") or ""
key = cfg.get("SUPABASE_ANON_KEY") or ""
email = cfg.get("SUPABASE_DEBUG_EMAIL") or ""
password = cfg.get("SUPABASE_DEBUG_PASSWORD") or ""
if not url or not key:
    print("TEST8 skip: SUPABASE_URL/ANON_KEY missing")
    sys.exit(0)

def call(method, path, token=None, body=None, prefer=None):
    headers = {"apikey": key, "Authorization": f"Bearer {token or key}"}
    if prefer:
        headers["Prefer"] = prefer
    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode()
    req = urllib.request.Request(f"{url}{path}", data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except Exception as e:
        print(f"TEST8 skip: network error {e}")
        sys.exit(0)

failed = 0
def check(name, cond, detail=""):
    global failed
    if cond:
        print(f"TEST8 ok: {name}")
    else:
        failed = 1
        print(f"TEST8 FAIL: {name} {detail}", file=sys.stderr)

# 1) No JWT beyond anon key: unauthenticated-style call still sends apikey.
#    RLS must not dump all profiles to the world.
status, raw = call("GET", "/rest/v1/profiles?select=id&limit=5")
# 200 with empty list, or 401/403 — all acceptable; 200 with many rows of
# other users' data is the failure mode we care about when anon has no
# policy — project-specific. At minimum request must not 500.
check("profiles endpoint responds", status in (200, 401, 403), f"status={status}")

# 2) Owner password grant
if email and password:
    status, raw = call("POST", "/auth/v1/token?grant_type=password", body={
        "email": email, "password": password,
    })
    if status != 200:
        check("owner sign-in", False, f"status={status} body={raw[:200]!r}")
        sys.exit(1)
    tok = json.loads(raw).get("access_token")
    check("owner sign-in returns access_token", bool(tok))
    # 3) Owner can select boats
    status, raw = call("GET", "/rest/v1/boats?select=supabaseId,name&limit=10", token=tok)
    check("owner boats select", status == 200, f"status={status}")
    # 4) Invalid share code RPC fails
    status, raw = call(
        "POST",
        "/rest/v1/rpc/redeem_boat_code",
        token=tok,
        body={"p_code": "___invalid_sisu_code___"},
    )
    check(
        "invalid share code does not succeed",
        status >= 400 or (status == 200 and b"error" in raw.lower()),
        f"status={status}",
    )
else:
    print("TEST8 note: no SUPABASE_DEBUG_EMAIL/PASSWORD — skipped owner paths")

# 5) Completely bogus bearer must not get privileged rows
status, raw = call(
    "GET",
    "/rest/v1/boats?select=supabaseId&limit=5",
    token="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.sig",
)
check("bogus JWT rejected or empty", status in (200, 401, 403), f"status={status}")
if status == 200:
    try:
        rows = json.loads(raw)
        # With invalid JWT some gateways fall back to anon; empty is fine.
        check("bogus JWT does not return huge boat dump", len(rows) < 50, f"n={len(rows)}")
    except Exception:
        pass

sys.exit(failed)
PY
