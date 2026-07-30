#!/usr/bin/env bash
# Multi-seat LAN stress setup (LT6) for roster-style multiplayer games
# (Liar's Dice, Dudo). Boots/joins N real devices: host + clients, optional AI.
#
# Usage:
#   bash scripts/mp_multiseat_stress_setup.sh <game_id> [host_device_id]
#
# game_id: liars_dice | dudo
# host_device_id: optional flutter/adb device id (default: first Android or iOS)
#
# Environment overrides:
#   IOS_HOST, IOS_CLIENT, AND_CLIENT  — device ids
#   AI_COUNT                          — AI seats host adds (default 1)
#
# 2-role titles (yatzy/checkers/backgammon/cribbage/uno/poker) are intentionally
# out of scope for 3+ seat stress — they only have two seats by design.
set -euo pipefail
cd "$(dirname "$0")/.."

GAME_ID="${1:?usage: mp_multiseat_stress_setup.sh <liars_dice|dudo> [host_device]}"
case "$GAME_ID" in
  liars_dice) GAME_LABEL="Liar's Dice" ;;
  dudo) GAME_LABEL="Dudo" ;;
  *)
    echo "LT6 multi-seat stress only applies to roster games: liars_dice | dudo" >&2
    echo "2-role titles are 2-seat by design — use a normal 2-device live pass." >&2
    exit 2
    ;;
esac

PKG="com.sailingsisu.sisumate"
IOS_HOST="${IOS_HOST:-43C4A261-F7F0-47FE-AC5B-C5313F7DFBEF}"   # iPhone 16 Plus
IOS_CLIENT="${IOS_CLIENT:-DCC47B42-BE62-4EBD-A6F2-B8A7E4C3A6D2}" # iPhone 16
AND_CLIENT="${AND_CLIENT:-R5CX2036L1F}" # real phone when present
AI_COUNT="${AI_COUNT:-1}"
LOGDIR="${TMPDIR:-/tmp}/sisumate"
mkdir -p "$LOGDIR"

ios_tap() { bash scripts/idb_tap_label.sh "$1" "$2"; }
ios_text() { source .idb_venv/bin/activate && idb ui text "$2" --udid "$1"; }
and_tap() { bash scripts/adb_tap_text.sh "$@"; }

echo "== LT6 multi-seat stress: $GAME_LABEL =="

# Boot second iOS sim if needed
if ! xcrun simctl list devices | grep -q "$IOS_CLIENT.*(Booted)"; then
  echo "Booting iOS client $IOS_CLIENT..."
  xcrun simctl boot "$IOS_CLIENT" 2>/dev/null || true
  sleep 3
fi

echo "== Ensuring idb companions =="
if ! pgrep -f "idb_companion --udid $IOS_HOST" > /dev/null; then
  idb_companion --udid "$IOS_HOST" > "$LOGDIR/idb_lt6_host.log" 2>&1 &
  sleep 2
fi
if ! pgrep -f "idb_companion --udid $IOS_CLIENT" > /dev/null; then
  idb_companion --udid "$IOS_CLIENT" --grpc-port 10883 --debug-port 10884 \
    > "$LOGDIR/idb_lt6_client.log" 2>&1 &
  sleep 2
fi
source .idb_venv/bin/activate
idb connect localhost 10882 > /dev/null 2>&1 || true
idb connect localhost 10883 > /dev/null 2>&1 || true

echo "== Force-stop + launch apps (clean slate) =="
xcrun simctl terminate "$IOS_HOST" "$PKG" 2>/dev/null || true
xcrun simctl terminate "$IOS_CLIENT" "$PKG" 2>/dev/null || true
adb -s "$AND_CLIENT" shell am force-stop "$PKG" 2>/dev/null || true
sleep 1
xcrun simctl launch "$IOS_HOST" "$PKG" 2>/dev/null || true
xcrun simctl launch "$IOS_CLIENT" "$PKG" 2>/dev/null || true
adb -s "$AND_CLIENT" shell am start -n "$PKG/.MainActivity" 2>/dev/null || true
echo "Waiting 8s for home screens..."
sleep 8

# Host on iOS (shares host network — best mDNS with phone as client)
echo "== Host ($IOS_HOST): lobby for $GAME_LABEL =="
ios_tap "$IOS_HOST" "Games"
sleep 2
ios_tap "$IOS_HOST" "Multiplayer Mode"
sleep 1
ios_tap "$IOS_HOST" "$GAME_LABEL"
sleep 2
ios_tap "$IOS_HOST" "e.g. Frik"
sleep 1
ios_text "$IOS_HOST" "IOS-Host"
sleep 1
ios_tap "$IOS_HOST" "Host Game"
sleep 3
for ((i = 1; i <= AI_COUNT; i++)); do
  ios_tap "$IOS_HOST" "Add AI Player"
  sleep 1
done

join_ios() {
  local udid="$1" name="$2"
  ios_tap "$udid" "Games"
  sleep 2
  ios_tap "$udid" "Multiplayer Mode"
  sleep 1
  ios_tap "$udid" "$GAME_LABEL"
  sleep 2
  ios_tap "$udid" "e.g. Frik"
  sleep 1
  ios_text "$udid" "$name"
  sleep 1
  ios_tap "$udid" "Join a Game"
  sleep 4
  # Prefer host entry by Android_/iPhone hostname fragment; fall back to game label
  if ! bash scripts/idb_tap_label.sh "$udid" "local" 2>/dev/null; then
    # second match of game name in list — use hostname if present in dump
    source .idb_venv/bin/activate
    idb ui describe-all --udid "$udid" 2>/dev/null | python3 -c "
import json,sys
data=json.load(sys.stdin)
for el in data:
    lab=el.get('AXLabel') or ''
    if 'local' in lab or 'Android_' in lab or lab.startswith('$GAME_LABEL\n'):
        f=el['frame']
        print(f\"{f['x']+f['width']/2:.0f} {f['y']+f['height']/2:.0f}\")
        break
" | { read x y && idb ui tap "$x" "$y" --udid "$udid"; } || ios_tap "$udid" "$GAME_LABEL"
  fi
  sleep 3
}

join_android() {
  local serial="$1" name="$2"
  and_tap "$serial" "Games"
  sleep 2
  and_tap "$serial" -c "Multiplayer Mode"
  sleep 1
  and_tap "$serial" "$GAME_LABEL"
  sleep 2
  # Name field via dump
  BOUNDS=$(adb -s "$serial" exec-out uiautomator dump /dev/tty 2>/dev/null | python3 -c "
import sys,re
xml=sys.stdin.read()
m=re.search(r'class=\"android.widget.EditText\"[^>]*bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"', xml)
if not m:
  m=re.search(r'bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"[^>]*class=\"android.widget.EditText\"', xml)
if m:
  x1,y1,x2,y2=map(int,m.groups())
  print((x1+x2)//2, (y1+y2)//2)
")
  if [ -n "${BOUNDS:-}" ]; then
    adb -s "$serial" shell input tap $BOUNDS
    sleep 1
    adb -s "$serial" shell input text "$name"
    sleep 1
    adb -s "$serial" shell input keyevent 111
    sleep 1
  fi
  and_tap "$serial" "Join a Game"
  sleep 4
  and_tap "$serial" -c "$GAME_LABEL" 2>/dev/null || true
  sleep 3
}

echo "== Join iOS client as IOS-2 =="
join_ios "$IOS_CLIENT" "IOS-2"

if adb -s "$AND_CLIENT" get-state 2>/dev/null | grep -q device; then
  echo "== Join Android as AndPlayer =="
  join_android "$AND_CLIENT" "AndPlayer"
else
  echo "Android $AND_CLIENT not present — continuing with 2 iOS + AI only"
fi

echo "== Host lobby snapshot =="
source .idb_venv/bin/activate
idb ui describe-all --udid "$IOS_HOST" 2>/dev/null | python3 -c "
import json,sys
data=json.load(sys.stdin)
for el in data:
    lab=el.get('AXLabel') or ''
    if lab: print(lab)
"
echo ""
echo "If Start Game (N players) is visible with N>=3, start with:"
echo "  bash scripts/idb_tap_label.sh $IOS_HOST 'Start Game'"
echo "Then play a short round across seats to complete LT6 for $GAME_ID."
