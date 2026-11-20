#!/usr/bin/env bash
# First-run / drift check for a local SisuMate checkout.
#
# Usage:
#   scripts/setup_local.sh             # check, then offer flutter pub get
#   scripts/setup_local.sh --check     # read-only checks (no pub get)
#   scripts/setup_local.sh --analyze   # also run flutter analyze
#
# Exit 0 when there are no failures. Warnings (optional store credentials,
# no attached device) do not fail the run.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MODE="interactive"
ANALYZE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) MODE="check" ;;
    --analyze) ANALYZE=1 ;;
    -h|--help)
      sed -n '2,9p' "$0"
      exit 0
      ;;
    *)
      echo "usage: setup_local.sh [--check] [--analyze]" >&2
      exit 64
      ;;
  esac
  shift
done

FAIL=0
WARN=0
ok() { printf '  ok    %s\n' "$*"; }
warn() { printf '  warn  %s\n' "$*"; WARN=$((WARN + 1)); }
fail() { printf '  FAIL  %s\n' "$*"; FAIL=$((FAIL + 1)); }
section() { printf '\n== %s ==\n' "$*"; }

section "Toolchain"
if command -v flutter >/dev/null 2>&1; then
  ok "flutter: $(flutter --version 2>/dev/null | head -1)"
else
  fail "flutter not on PATH — install Flutter 3.24+ or put it on PATH"
fi
if command -v dart >/dev/null 2>&1; then
  ok "dart: $(dart --version 2>&1 | head -1)"
else
  fail "dart not on PATH"
fi
if command -v xcodebuild >/dev/null 2>&1; then
  ok "xcodebuild present"
else
  warn "xcodebuild missing — iOS builds unavailable"
fi
if command -v adb >/dev/null 2>&1; then
  ok "adb present"
else
  warn "adb missing — Android device work unavailable"
fi

section "Config"
if [[ ! -f dart-defines.json ]]; then
  fail "dart-defines.json missing — builds hang at splash without it"
else
  if git check-ignore -q dart-defines.json; then
    ok "dart-defines.json is gitignored"
  else
    fail "dart-defines.json is not gitignored — never commit credentials"
  fi
  if python3 - "$ROOT/dart-defines.json" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    data = json.load(open(path, encoding="utf-8"))
except (OSError, ValueError) as exc:
    print(f"  FAIL  dart-defines.json is not valid JSON: {exc}")
    raise SystemExit(1)

required = ["SUPABASE_URL", "SUPABASE_ANON_KEY"]
missing = [key for key in required if not str(data.get(key, "")).strip()]
if missing:
    print(f"  FAIL  dart-defines.json missing: {', '.join(missing)}")
    raise SystemExit(1)
PY
  then
    ok "SUPABASE_URL + SUPABASE_ANON_KEY set"
  else
    fail "dart-defines.json is invalid or missing required keys"
  fi
fi
if [[ -f .mcp.json ]]; then
  ok ".mcp.json present — authenticate the Supabase MCP in your harness"
else
  warn ".mcp.json missing — Supabase MCP unavailable"
fi

section "Release credentials (store uploads only)"
if [[ ! -d secrets ]]; then
  warn "secrets/ missing — store uploads will refuse"
fi
for path in \
  secrets/google-play-service-account.json \
  secrets/appstore-connect.json \
  android/key.properties
do
  if [[ -f "$path" ]]; then
    if git check-ignore -q "$path"; then
      ok "$path (ignored)"
    else
      fail "$path is not gitignored — never commit signing material"
    fi
  else
    warn "$path missing — the matching store release will refuse"
  fi
done
KEY_FOUND=0
for key in secrets/AuthKey_*.p8; do
  [[ -e "$key" ]] || continue
  KEY_FOUND=1
  if git check-ignore -q "$key"; then
    ok "$key (ignored)"
  else
    fail "$key is not gitignored — never commit signing material"
  fi
done
if [[ "$KEY_FOUND" -eq 0 ]]; then
  warn "secrets/AuthKey_*.p8 missing — App Store upload will refuse"
fi

section "Devices"
if command -v flutter >/dev/null 2>&1; then
  DEVICE_LOG="$(mktemp "${TMPDIR:-/tmp}/sisu_devices.XXXXXX")"
  if flutter devices >"$DEVICE_LOG" 2>&1; then
    if grep -q 'No devices' "$DEVICE_LOG"; then
      warn "no devices — start a simulator/emulator or attach a phone"
    else
      ok "device target(s):"
      sed -n '1,8p' "$DEVICE_LOG" | sed 's/^/        /'
    fi
  else
    warn "flutter devices failed — see the output above"
  fi
  rm -f "$DEVICE_LOG"
fi

section "Dependencies"
if [[ "$MODE" == "interactive" ]]; then
  read -r -p "Run flutter pub get now? [y/N] " answer
  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    if flutter pub get; then
      ok "flutter pub get"
    else
      fail "flutter pub get failed"
    fi
  else
    warn "skipped flutter pub get"
  fi
else
  ok "skipped flutter pub get (--check)"
fi

if [[ "$ANALYZE" -eq 1 ]]; then
  section "Analyze"
  if flutter analyze; then
    ok "flutter analyze"
  else
    fail "flutter analyze"
  fi
fi

section "Summary"
printf '  failures: %s   warnings: %s\n' "$FAIL" "$WARN"
if [[ "$FAIL" -gt 0 ]]; then
  echo "setup_local: fix the failures above."
  exit 1
fi
echo "setup_local: ready."
