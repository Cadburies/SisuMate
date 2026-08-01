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

# The home grid's lower tiles (incl. "Games") sit below the fold on these
# devices; off-screen a11y nodes exist but their coordinates don't tap.
# Retry the tap, scrolling the screen up between attempts.
ios_tap_scroll() { # $1 udid, $2 label — taps only when substantially visible
  local coords x y
  for _ in 1 2 3 4 5 6 7 8; do
    coords="$(idb ui describe-all --udid "$1" 2>/dev/null | python3 -c "
import json, sys
needle = sys.argv[1]
data = json.load(sys.stdin)
exact = None
sub = None
for el in data:
    lab = el.get('AXLabel') or ''
    f = el.get('frame') or {}
    w = f.get('width') or 0
    h = f.get('height') or 0
    # Slivers (a few pt tall at the screen edge) accept taps that iOS then
    # routes to the home-indicator area — require a real touch target.
    if w < 44 or h < 44:
        continue
    c = (int(f['x'] + w/2), int(f['y'] + h/2))
    # Flutter merges tile + subtitle into one 'Tile\nSubtitle' a11y node, so
    # an exact match is not guaranteed — fall back to substring.
    if lab == needle and exact is None:
        exact = c
    elif needle in lab and sub is None:
        sub = c
hit = exact or sub
if hit:
    print(f'{hit[0]} {hit[1]}')
" "$2")"
    if [ -n "$coords" ]; then
      read -r x y <<<"$coords"
      idb ui tap "$x" "$y" --udid "$1" && return 0
    fi
    idb ui swipe 196 700 196 250 --udid "$1" || true
    sleep 1
  done
  return 1
}
and_tap_scroll() { # $1 serial, $2 text, $3 optional -c
  for _ in 1 2 3 4 5; do
    if [ "${3:-}" = "-c" ]; then
      and_tap -c "$1" "$2" && return 0
    else
      and_tap "$1" "$2" && return 0
    fi
    adb -s "$1" shell input swipe 540 1700 540 1000
    sleep 1
  done
  return 1
}

# Taps the discovered-game LIST ENTRY (label contains "host:port"), never the
# AppBar title ("<game> — Multiplayer") which also contains the game name.
ios_tap_game_entry() { # $1 udid, $2 game label
  local coords x y
  coords="$(idb ui describe-all --udid "$1" 2>/dev/null | python3 -c "
import json, sys
needle = sys.argv[1]
data = json.load(sys.stdin)
for el in data:
    lab = el.get('AXLabel') or ''
    f = el.get('frame') or {}
    w = f.get('width') or 0
    h = f.get('height') or 0
    if needle in lab and ':' in lab and w > 0 and h > 0:
        print(f\"{int(f['x'] + w/2)} {int(f['y'] + h/2)}\")
        break
" "$2")"
  [ -n "$coords" ] || return 1
  read -r x y <<<"$coords"
  idb ui tap "$x" "$y" --udid "$1"
}
and_tap_game_entry() { # $1 serial, $2 game label
  local bounds
  bounds="$(adb -s "$1" exec-out uiautomator dump /dev/tty 2>/dev/null | python3 -c "
import re, sys
needle = sys.argv[1]
xml = sys.stdin.read()
for m in re.finditer(r'<node[^>]*>', xml):
    node = m.group(0)
    lab = ''
    for attr in ('text', 'content-desc'):
        am = re.search(attr + r'=\"([^\"]*)\"', node)
        if am and am.group(1):
            lab = am.group(1)
            break
    if needle in lab and ':' in lab:
        bm = re.search(r'bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"', node)
        if bm:
            x1, y1, x2, y2 = map(int, bm.groups())
            print((x1 + x2) // 2, (y1 + y2) // 2)
            break
" "$2")"
  [ -n "$bounds" ] || return 1
  adb -s "$1" shell input tap $bounds
}

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

# Poll until each device shows the home screen ("Games" tile) — a fixed sleep
# races cold starts on fresh sims/emulators and fails the first tap blind.
source .idb_venv/bin/activate
wait_ios_home() {
  for _ in $(seq 1 45); do
    if idb ui describe-all --udid "$1" 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
sys.exit(0 if any((el.get('AXLabel') or '') == 'Games' for el in data) else 1)
"; then return 0; fi
    sleep 1
  done
  echo "WARNING: $1 never showed the home screen" >&2
  return 1
}
wait_and_home() {
  for _ in $(seq 1 90); do
    if adb -s "$1" exec-out uiautomator dump /dev/tty 2>/dev/null | grep -qE '(text|content-desc)="Shopping"'; then
      return 0
    fi
    sleep 1
  done
  echo "WARNING: $1 never showed the home screen" >&2
  return 1
}
echo "Waiting for all 4 home screens..."
wait_ios_home "$IOS_HOST"
wait_ios_home "$IOS_CLIENT"
# Android home: "Shopping" is always above the fold; Flutter labels arrive as
# content-desc on newer Android and text on older — accept either.
wait_and_home "$AND_CLIENT1"
wait_and_home "$AND_CLIENT2"
sleep 3   # let semantics settle: off-screen tiles start with zero-size frames

echo "== Host (iPhone 16): navigate to Liar's Dice lobby, host, add 2 AI bots =="
ios_tap_scroll "$IOS_HOST" "Games"
sleep 2
ios_tap_scroll "$IOS_HOST" "Multiplayer Mode"
sleep 1
ios_tap_scroll "$IOS_HOST" "Liar's Dice"
sleep 2
ios_tap "$IOS_HOST" "e.g. Frik"
sleep 1
ios_text "$IOS_HOST" "IOS-Host"
sleep 1
ios_tap "$IOS_HOST" "Host Game"
sleep 3
ios_tap "$IOS_HOST" "Add AI"
sleep 1
ios_tap "$IOS_HOST" "Add AI"
sleep 2
echo "Host ready with 3 players (host + 2 AI). Now joining 3 real clients..."

join_ios_client() {
  local udid="$1" name="$2"
  ios_tap_scroll "$udid" "Games"
  sleep 2
  ios_tap_scroll "$udid" "Multiplayer Mode"
  sleep 1
  ios_tap_scroll "$udid" "Liar's Dice"
  sleep 2
  ios_tap "$udid" "e.g. Frik"
  sleep 1
  ios_text "$udid" "$name"
  sleep 1
  ios_tap "$udid" "Join a Game"
  sleep 3
  # Tap the discovered-game entry (label is "Liar's Dice\n<host>:<port>") —
  # a plain "Liar's Dice" tap lands on the AppBar title instead.
  ios_tap_game_entry "$udid" "Liar's Dice"
  sleep 3
}

join_android_client() {
  local serial="$1" name="$2"
  and_tap_scroll "$serial" "Games"
  sleep 2
  # Toggle switch has no stable single-word label; tap the whole card text.
  and_tap_scroll "$serial" "Multiplayer Mode" -c
  sleep 1
  and_tap_scroll "$serial" "Liar's Dice"
  sleep 2
  adb -s "$serial" shell input tap 540 1165   # name EditText (see live_test_setup.md)
  sleep 1
  adb -s "$serial" shell input text "$name"
  sleep 1
  adb -s "$serial" shell input keyevent 111   # dismiss keyboard BEFORE tapping Join
  sleep 1
  and_tap "$serial" "Join a Game"
  sleep 3
  and_tap_game_entry "$serial" "Liar's Dice"
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
echo "If the list above shows IOS-Host, 2 AI seats (persona names like"
echo "'Bluffer 1 (Normal)'), IOS-2, Android1, Android2 and a Start Game"
echo "button, tap Start Game on the host to begin:"
echo "  bash scripts/idb_tap_label.sh $IOS_HOST 'Start Game'"
echo "Otherwise, see live_test_setup.md 'Troubleshooting' before re-running."
