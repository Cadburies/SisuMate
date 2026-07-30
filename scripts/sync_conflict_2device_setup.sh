#!/usr/bin/env bash
# Two-device offline-edit sync-conflict smoke test (SUG2 / T5).
#
# Scenario: two devices already signed in to the SAME boat (Pro owner and/or
# anonymous crew — identity doesn't matter, only that both sync the same
# boat). One device edits a shared shopping item while offline; the other
# edits the SAME item online (so the remote copy moves on). When the first
# device reconnects, its stale outbox push must NOT silently overwrite the
# newer remote edit — it must surface a conflict in Settings ▸ Sync Conflicts
# for the user to resolve ("Keep mine" / "Keep cloud").
#
# This walks the real app UI end-to-end (no direct DB writes for the test
# item itself) via adb + uiautomator dumps — same technique as
# liars_dice_4sim_setup.sh, adapted for boat/crew Supabase sync instead of
# LAN multiplayer. See sync_conflict_2device_setup.md for mechanics,
# timestamps-and-timezones background, and troubleshooting.
#
# Usage: bash scripts/sync_conflict_2device_setup.sh
# Requires: both devices already on the same boat, unlocked, app installed.
set -euo pipefail
cd "$(dirname "$0")/.."

PKG="com.sailingsisu.sisumate"

# DEVICE_ONLINE stays connected the whole run (plays "still on the boat").
# DEVICE_OFFLINE is the one whose network gets toggled off/on — prefer an
# emulator here so a real phone's connectivity is never touched.
DEVICE_ONLINE="${1:-R5CX2036L1F}"
DEVICE_OFFLINE="${2:-emulator-5554}"

ITEM_NAME="SyncSmoke-$(date +%s)"
LOGDIR="${TMPDIR:-/tmp}/sisumate"
mkdir -p "$LOGDIR"

echo "== Devices: ONLINE=$DEVICE_ONLINE  OFFLINE=$DEVICE_OFFLINE  item=$ITEM_NAME =="

# ── UI helpers (uiautomator dump parsing) ───────────────────────────────────

dump_xml() {
  # $1=serial -> prints the current uiautomator dump XML to stdout
  adb -s "$1" exec-out uiautomator dump /dev/tty 2>/dev/null
}

# Tap the center of the first CLICKABLE node whose content-desc starts with
# $2. Needed for cards whose label is "Title\nSubtitle" (adb_tap_text.sh only
# does exact/contains match, which can hit the wrong node when a shorter
# label like an AppBar title is also a substring match).
tap_by_desc_prefix() {
  local serial="$1" prefix="$2"
  local xml coords
  xml="$(dump_xml "$serial")"
  coords="$(python3 - "$prefix" <<'PY'
import re, sys
prefix = sys.argv[1]
xml = sys.stdin.read()
for n in re.findall(r'<node[^>]*/>', xml):
    if 'clickable="true"' not in n:
        continue
    m = re.search(r'content-desc="([^"]*)"', n)
    if not m:
        continue
    desc = m.group(1).replace('&#10;', '\n').replace('&amp;', '&')
    if desc.startswith(prefix):
        b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
        x1, y1, x2, y2 = map(int, b.groups())
        print(f"{(x1 + x2) // 2} {(y1 + y2) // 2}")
        break
PY
<<<"$xml")"
  if [ -z "$coords" ]; then
    echo "NOTFOUND: no clickable node starting with '$prefix' on $serial" >&2
    return 1
  fi
  adb -s "$serial" shell input tap $coords
}

# Tap the FAB: the bottom-most clickable Button with no text/content-desc
# (Flutter's Add-Item FAB carries no accessible label, so text-matching
# scripts can't find it — this heuristic mirrors how a sighted tester would
# spot it, by position and roughly-square FAB size).
tap_fab() {
  local serial="$1"
  local xml coords
  xml="$(dump_xml "$serial")"
  coords="$(python3 - <<'PY'
import re, sys
xml = sys.stdin.read()
best = None
for n in re.findall(r'<node[^>]*/>', xml):
    if 'clickable="true"' not in n:
        continue
    desc = re.search(r'content-desc="([^"]*)"', n)
    text = re.search(r'text="([^"]*)"', n)
    if (desc and desc.group(1)) or (text and text.group(1)):
        continue
    b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
    if not b:
        continue
    x1, y1, x2, y2 = map(int, b.groups())
    if (x2 - x1) < 100 or (x2 - x1) > 300:
        continue
    if best is None or y2 > best[3]:
        best = (x1, y1, x2, y2)
if best:
    print(f"{(best[0] + best[2]) // 2} {(best[1] + best[3]) // 2}")
PY
<<<"$xml")"
  if [ -z "$coords" ]; then
    echo "NOTFOUND: no FAB-shaped node on $serial" >&2
    return 1
  fi
  adb -s "$serial" shell input tap $coords
}

# Replace the text in the topmost EditText on screen (the Name field in both
# the Add Item dialog and the item detail Edit screen is always first/topmost
# — more robust across devices/uiautomator versions than matching on the
# `hint` attribute, which some devices omit once the field has a value).
replace_topmost_field() {
  local serial="$1" new_text="$2"
  local xml field current len coords
  xml="$(dump_xml "$serial")"
  field="$(python3 - <<'PY'
import re, sys
xml = sys.stdin.read()
best = None
for n in re.findall(r'<node[^>]*class="android\.widget\.EditText"[^>]*/>', xml):
    b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
    if not b:
        continue
    x1, y1, x2, y2 = map(int, b.groups())
    t = re.search(r'text="([^"]*)"', n)
    current = t.group(1) if t else ""
    if best is None or y1 < best[0]:
        best = (y1, x1, y1, x2, y2, current)
if best:
    _, x1, y1, x2, y2, current = best
    print(f"{(x1 + x2) // 2} {(y1 + y2) // 2} {len(current)}")
PY
<<<"$xml")"
  if [ -z "$field" ]; then
    echo "NOTFOUND: no EditText on $serial" >&2
    return 1
  fi
  read -r cx cy len <<<"$field"
  adb -s "$serial" shell input tap "$cx" "$cy"
  sleep 1
  adb -s "$serial" shell input keyevent 123  # MOVE_END
  for _ in $(seq 1 "$len"); do
    adb -s "$serial" shell input keyevent 67  # DEL
  done
  sleep 1
  adb -s "$serial" shell input text "$new_text"
}

set_network() {
  local serial="$1" state="$2"  # enable|disable
  adb -s "$serial" shell svc wifi "$state"
  adb -s "$serial" shell svc data "$state"
}

relaunch() {
  local serial="$1"
  adb -s "$serial" shell am force-stop "$PKG"
  sleep 1
  adb -s "$serial" shell am start -n "$PKG/.MainActivity"
  sleep 6
}

# ── Scenario ─────────────────────────────────────────────────────────────

echo "== Relaunching app on both devices (clean slate) =="
relaunch "$DEVICE_ONLINE"
relaunch "$DEVICE_OFFLINE"

echo "== [$DEVICE_ONLINE] Navigate to Shopping, add test item '$ITEM_NAME' =="
bash scripts/adb_tap_text.sh "$DEVICE_ONLINE" "Shopping"
sleep 3
tap_fab "$DEVICE_ONLINE"
sleep 2
replace_topmost_field "$DEVICE_ONLINE" "$ITEM_NAME"
adb -s "$DEVICE_ONLINE" shell input keyevent 4  # dismiss keyboard, keep dialog open
sleep 1
bash scripts/adb_tap_text.sh "$DEVICE_ONLINE" "Add Item"
sleep 2

echo "== [$DEVICE_OFFLINE] Navigate to Shopping, wait for the item to sync in =="
bash scripts/adb_tap_text.sh "$DEVICE_OFFLINE" "Shopping"
sleep 3
echo "   (waiting up to 30s for realtime to deliver the new item...)"
for _ in $(seq 1 6); do
  if dump_xml "$DEVICE_OFFLINE" | grep -q "$ITEM_NAME"; then
    break
  fi
  sleep 5
done
# New items land in a collapsed category — expand "Spares" to reveal it.
tap_by_desc_prefix "$DEVICE_OFFLINE" "Spares" || true
sleep 2

echo "== [$DEVICE_OFFLINE] Taking offline, editing '$ITEM_NAME' -> '${ITEM_NAME}-OFFLINE' =="
set_network "$DEVICE_OFFLINE" disable
sleep 2
bash scripts/adb_tap_text.sh "$DEVICE_OFFLINE" "$ITEM_NAME"
sleep 2
bash scripts/adb_tap_text.sh "$DEVICE_OFFLINE" "Edit"
sleep 2
replace_topmost_field "$DEVICE_OFFLINE" "${ITEM_NAME}-OFFLINE"
sleep 1
bash scripts/adb_tap_text.sh "$DEVICE_OFFLINE" "Save"
sleep 2

echo "== [$DEVICE_ONLINE] Editing the SAME item -> '${ITEM_NAME}-ONLINE' (while still connected) =="
tap_by_desc_prefix "$DEVICE_ONLINE" "Spares" || true
sleep 2
bash scripts/adb_tap_text.sh "$DEVICE_ONLINE" "$ITEM_NAME"
sleep 2
bash scripts/adb_tap_text.sh "$DEVICE_ONLINE" "Edit"
sleep 2
replace_topmost_field "$DEVICE_ONLINE" "${ITEM_NAME}-ONLINE"
sleep 1
bash scripts/adb_tap_text.sh "$DEVICE_ONLINE" "Save"
sleep 2

echo "== [$DEVICE_OFFLINE] Bringing back online, waiting for outbox flush + conflict check (~30s) =="
set_network "$DEVICE_OFFLINE" enable
sleep 30

echo "== [$DEVICE_OFFLINE] Opening Sync Conflicts =="
bash scripts/adb_tap_text.sh "$DEVICE_OFFLINE" "Back" || true
sleep 1
bash scripts/adb_tap_text.sh "$DEVICE_OFFLINE" "Menu"
sleep 2
tap_by_desc_prefix "$DEVICE_OFFLINE" "Sync Conflicts"
sleep 2

echo ""
if dump_xml "$DEVICE_OFFLINE" | grep -q "${ITEM_NAME}-ONLINE"; then
  echo "PASS: conflict card found for '$ITEM_NAME' — resolve manually with:"
  echo "  bash scripts/idb_tap_label.sh / adb equivalent tap on 'Keep mine' or 'Keep cloud'"
  echo "Remote should read '${ITEM_NAME}-ONLINE' either way once resolved."
else
  echo "FAIL: no conflict card found for '$ITEM_NAME' on $DEVICE_OFFLINE."
  echo "Check: is sync_service.dart's _outboxItemConflicts check present? See"
  echo "sync_conflict_2device_setup.md troubleshooting."
fi
echo ""
echo "Cleanup: delete '$ITEM_NAME' via the app (Hide -> Delete) on either device"
echo "once you're done inspecting, to keep the boat's shopping list tidy."
