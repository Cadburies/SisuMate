#!/usr/bin/env bash
# Thin helper around the Supabase REST/auth API for ad-hoc verification
# (RLS checks, RPC smoke tests, wire-format checks) without ever needing
# inline $(...) / $VAR / pipes at the call site — every subcommand does its
# own sign-in + request + JSON parsing internally and just prints the result.
#
# Credentials come from dart-defines.json (gitignored) — never hardcode them
# here. Project must have SUPABASE_URL/SUPABASE_ANON_KEY and, for owner mode,
# SUPABASE_DEBUG_EMAIL/SUPABASE_DEBUG_PASSWORD.
#
# Usage:
#   bash scripts/supabase_cli.sh owner-token
#   bash scripts/supabase_cli.sh owner-rpc <function_name> ['{"param":"value"}']
#   bash scripts/supabase_cli.sh owner-select <table> ['select=col1,col2&col=eq.val']
#   bash scripts/supabase_cli.sh anon-token
#   bash scripts/supabase_cli.sh anon-rpc <function_name> ['{"param":"value"}']
#   bash scripts/supabase_cli.sh anon-select <table> ['select=col1,col2']
#   bash scripts/supabase_cli.sh noauth-select <table> ['select=col1,col2']   # verifies RLS lockout
#   bash scripts/supabase_cli.sh join-boat <share_code>   # anon signup + redeem_boat_code
set -euo pipefail
cd "$(dirname "$0")/.."
MODE="${1:?usage: supabase_cli.sh <mode> [args...]}"
shift || true

python3 - "$MODE" "$@" <<'PY'
import json, sys, urllib.request, urllib.error

mode = sys.argv[1]
args = sys.argv[2:]
cfg = json.load(open("dart-defines.json"))
url = cfg["SUPABASE_URL"]
key = cfg["SUPABASE_ANON_KEY"]

def call(method, path, token=None, body=None):
    headers = {"apikey": key, "Authorization": f"Bearer {token or key}"}
    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode()
    req = urllib.request.Request(f"{url}{path}", data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
    except urllib.error.HTTPError as e:
        raw = e.read()
        print(f"HTTP {e.code}")
    if not raw:
        print("(empty response)")
        return None
    try:
        parsed = json.loads(raw)
        print(json.dumps(parsed, indent=2))
        return parsed
    except json.JSONDecodeError:
        print(raw.decode())
        return None

def owner_token():
    body = {"email": cfg["SUPABASE_DEBUG_EMAIL"], "password": cfg["SUPABASE_DEBUG_PASSWORD"]}
    req = urllib.request.Request(
        f"{url}/auth/v1/token?grant_type=password",
        data=json.dumps(body).encode(),
        headers={"apikey": key, "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        return json.load(resp)["access_token"]

def anon_token():
    req = urllib.request.Request(
        f"{url}/auth/v1/signup",
        data=b"{}",
        headers={"apikey": key, "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        d = json.load(resp)
        if not d.get("access_token"):
            raise SystemExit(f"anon signup failed (is Anonymous sign-in enabled?): {d}")
        return d["access_token"]

if mode == "owner-token":
    print(owner_token())
elif mode == "anon-token":
    print(anon_token())
elif mode == "owner-rpc":
    fn = args[0]
    params = json.loads(args[1]) if len(args) > 1 else {}
    call("POST", f"/rest/v1/rpc/{fn}", token=owner_token(), body=params)
elif mode == "anon-rpc":
    fn = args[0]
    params = json.loads(args[1]) if len(args) > 1 else {}
    call("POST", f"/rest/v1/rpc/{fn}", token=anon_token(), body=params)
elif mode == "owner-select":
    table = args[0]
    qs = args[1] if len(args) > 1 else "select=*"
    call("GET", f"/rest/v1/{table}?{qs}", token=owner_token())
elif mode == "anon-select":
    table = args[0]
    qs = args[1] if len(args) > 1 else "select=*"
    call("GET", f"/rest/v1/{table}?{qs}", token=anon_token())
elif mode == "noauth-select":
    table = args[0]
    qs = args[1] if len(args) > 1 else "select=*"
    call("GET", f"/rest/v1/{table}?{qs}")  # anon key only, no user session
elif mode == "join-boat":
    code = args[0]
    tok = anon_token()
    call("POST", "/rest/v1/rpc/redeem_boat_code", token=tok, body={"p_code": code})
else:
    raise SystemExit(f"unknown mode: {mode}")
PY
