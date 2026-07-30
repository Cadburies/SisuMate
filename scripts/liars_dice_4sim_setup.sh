#!/usr/bin/env bash
# One-shot setup for the Liar's Dice 4-device live multiplayer test:
# 2 iOS Simulators + 2 Android emulators, host adds 2 AI bots, all 3 real
# clients join, leaving the host on the "Start Game (6 players)" lobby
# screen ready to tap. See liars_dice/live_test_setup.md for background,
# device IDs, and troubleshooting (zombie hosts, NAT-isolated Android
# discovery, why label-based taps are used instead of raw coordinates).
#
# Usage: bash scripts/liars_dice_4sim_setup.sh
# Requires: idb + idb_companion installed (brew tap facebook/fb && brew
# install idb-companion; python venv at .idb_venv with fb-idb — see
# live_test_setup.md "One-time environment setup").
set -euo pipefail
cd "$(dirname "$0")/.."

PKG="com.sailingsisu.sisumate"
IOS_HOST="DCC47B42-BE62-4EBD-A6F2-B8A7E4C3A6D2"   # iPhone 16
IOS_CLIENT="AB064E47-9EBD-460E-9DA4-07E552360FB5" # iPhone 16e
AND_CLIENT1="emulator-5554"
AND_CLIENT2="emulator-5556"

LOGDIR="${TMPDIR:-/tmp}/sisumate"
mkdir -p "$LOGDIR"

ios_tap() { bash scripts/idb_tap_label.sh "$1" "$2"; }
ios_text() { source .idb_venv/bin/activate && idb ui text "$2" --udid "$1"; }
and_tap() { bash scripts/adb_tap_text.sh "$@"; }

echo "== Ensuring idb_companions are running =="
if ! pgrep -f "idb_companion --udid $IOS_HOST" > /dev/null; then
  idb_companion --udid "$IOS_HOST" > "$LOGDIR/idb_companion_host.log" 2>&1 &
  sleep 2
fi
if ! pgrep -f "idb_companion --udid $IOS_CLIENT" > /dev/null; then
  idb_companion --udid "$IOS_CLIENT" --grpc-port 10883 --debug-port 10884 > "$LOGDIR/idb_companion_client.log" 2>&1 &
  sleep 2
fi
source .idb_venv/bin/activate
idb connect localhost 10882 > /dev/null 2>&1 || true
idb connect localhost 10883 > /dev/null 2>&1 || true

echo "== Force-stopping + relaunching app on all 4 devices (clean slate, no zombie hosts) =="
xcrun simctl terminate "$IOS_HOST" "$PKG" 2>/dev/null || true
xcrun simctl terminate "$IOS_CLIENT" "$PKG" 2>/dev/null || true
adb -s "$AND_CLIENT1" shell am force-stop "$PKG"
adb -s "$AND_CLIENT2" shell am force-stop "$PKG"
sleep 1
xcrun simctl launch "$IOS_HOST" "$PKG"
xcrun simctl launch "$IOS_CLIENT" "$PKG"
adb -s "$AND_CLIENT1" shell am start -n "$PKG/.MainActivity"
adb -s "$AND_CLIENT2" shell am start -n "$PKG/.MainActivity"
echo "Waiting 8s for all 4 to reach the home screen..."
sleep 8

echo "== Host (iPhone 16): navigate to Liar's Dice lobby, host, add 2 AI bots =="
ios_tap "$IOS_HOST" "Games"
sleep 2
ios_tap "$IOS_HOST" "Multiplayer Mode"
sleep 1
ios_tap "$IOS_HOST" "Liar's Dice"
sleep 2
ios_tap "$IOS_HOST" "e.g. Frik"
sleep 1
ios_text "$IOS_HOST" "IOS-Host"
sleep 1
ios_tap "$IOS_HOST" "Host Game"
sleep 3
ios_tap "$IOS_HOST" "Add AI Player"
sleep 1
ios_tap "$IOS_HOST" "Add AI Player"
sleep 2
echo "Host ready with 3 players (host + 2 AI). Now joining 3 real clients..."

join_ios_client() {
  local udid="$1" name="$2"
  ios_tap "$udid" "Games"
  sleep 2
  ios_tap "$udid" "Multiplayer Mode"
  sleep 1
  ios_tap "$udid" "Liar's Dice"
  sleep 2
  ios_tap "$udid" "e.g. Frik"
  sleep 1
  ios_text "$udid" "$name"
  sleep 1
  ios_tap "$udid" "Join a Game"
  sleep 3
  # Fresh restart => exactly one legitimate host advertised; tap the first
  # "Liar's Dice" match. If this ever picks a stale/unreachable entry, rerun
  # this script (it force-stops everything first) rather than debugging taps.
  ios_tap "$udid" "Liar's Dice"
  sleep 3
}

join_android_client() {
  local serial="$1" name="$2"
  and_tap "$serial" "Games"
  sleep 2
  # Toggle switch has no stable single-word label; tap the whole card text.
  and_tap "$serial" -c "Multiplayer Mode"
  sleep 1
  and_tap "$serial" "Liar's Dice"
  sleep 2
  adb -s "$serial" shell input tap 540 1165   # name EditText (see live_test_setup.md)
  sleep 1
  adb -s "$serial" shell input text "$name"
  sleep 1
  adb -s "$serial" shell input keyevent 111   # dismiss keyboard BEFORE tapping Join
  sleep 1
  and_tap "$serial" "Join a Game"
  sleep 3
  and_tap "$serial" -c "Liar's Dice"
  sleep 3
}

echo "== Joining iPhone 16e as IOS-2 =="
join_ios_client "$IOS_CLIENT" "IOS-2"

echo "== Joining Android emulator-5554 as Android1 =="
join_android_client "$AND_CLIENT1" "Android1"

echo "== Joining Android emulator-5556 as Android2 =="
join_android_client "$AND_CLIENT2" "Android2"

echo "== Done. Verifying host lobby shows 6 players... =="
source .idb_venv/bin/activate
idb ui describe-all --udid "$IOS_HOST" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for el in data:
    label = el.get('AXLabel') or ''
    if label:
        print(label)
"
echo ""
echo "If the list above shows IOS-Host, AI 1, AI 2, IOS-2, Android1, Android2"
echo "and 'Start Game (6 players)', tap Start Game on the host to begin:"
echo "  bash scripts/idb_tap_label.sh $IOS_HOST 'Start Game'"
echo "Otherwise, see live_test_setup.md 'Troubleshooting' before re-running."
