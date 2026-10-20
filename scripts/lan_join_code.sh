#!/usr/bin/env bash
# Prints the 6-digit LAN join code (#435) shown in an iOS host's lobby.
# Reads the code's accessibility label ("Join code 1 2 3 4 5 6") via idb and
# caches it in /tmp/sisumate_lan_join_code for later steps (the host leaves
# the lobby once the game starts).
#
# Usage: bash scripts/lan_join_code.sh <ios-host-udid>
#        bash scripts/lan_join_code.sh --cached
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE=/tmp/sisumate_lan_join_code

if [ "${1:-}" = "--cached" ]; then
  [ -s "$CACHE" ] && cat "$CACHE" && exit 0
  echo "no cached join code (run with the host udid while it shows the lobby)" >&2
  exit 1
fi

UDID="${1:?usage: lan_join_code.sh <ios-host-udid> | --cached}"
# shellcheck disable=SC1091
source "$ROOT/.idb_venv/bin/activate"
CODE="$(idb ui describe-all --udid "$UDID" 2>/dev/null | python3 -c '
import json, re, sys
for el in json.load(sys.stdin):
    m = re.match(r"Join code ((?:\d ?){6})$", (el.get("AXLabel") or "").strip())
    if m:
        print(m.group(1).replace(" ", ""))
        break
')"
if [ -z "$CODE" ]; then
  echo "join code not found on $UDID (is the host on the lobby screen?)" >&2
  exit 1
fi
printf '%s' "$CODE" > "$CACHE"
echo "$CODE"
