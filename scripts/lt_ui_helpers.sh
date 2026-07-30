#!/usr/bin/env bash
# Shared UI helpers for LT1–LT4 dual-device live testing (Android adb + iOS idb).
# Source from other scripts:  source "$(dirname "$0")/lt_ui_helpers.sh"
set -euo pipefail

PKG="${PKG:-com.sailingsisu.sisumate}"
LOGDIR="${LOGDIR:-${TMPDIR:-/tmp}/sisumate}"
mkdir -p "$LOGDIR"

# Repo root when sourced from scripts/
_LT_SRC="${BASH_SOURCE[0]:-$0}"
_LT_ROOT="$(cd "$(dirname "$_LT_SRC")/.." && pwd)"
_IDB_VENV="${_LT_ROOT}/.idb_venv"

# ── Android ──────────────────────────────────────────────────────────────────

and_dump() {
  adb -s "$1" exec-out uiautomator dump /dev/tty 2>/dev/null
}

and_has_text() {
  # $1=serial $2=substring
  and_dump "$1" | grep -qF "$2" || return 1
}

and_tap_text() {
  bash "$_LT_ROOT/scripts/adb_tap_text.sh" "$@"
}

and_tap_text_c() {
  bash "$_LT_ROOT/scripts/adb_tap_text.sh" -c "$@"
}

# Tap first clickable node whose content-desc starts with $2.
and_tap_desc_prefix() {
  local serial="$1" prefix="$2"
  local coords
  coords="$(and_dump "$serial" | python3 -c "
import re, sys
prefix = sys.argv[1]
xml = sys.stdin.read()
for n in re.findall(r'<node[^>]*/>', xml):
    if 'clickable=\"true\"' not in n:
        continue
    m = re.search(r'content-desc=\"([^\"]*)\"', n)
    if not m:
        continue
    desc = m.group(1).replace('&#10;', '\n').replace('&amp;', '&')
    if desc.startswith(prefix):
        b = re.search(r'bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"', n)
        x1, y1, x2, y2 = map(int, b.groups())
        print(f'{(x1 + x2) // 2} {(y1 + y2) // 2}')
        break
" "$prefix")"
  if [ -z "$coords" ]; then
    echo "NOTFOUND: no clickable desc starting with '$prefix' on $serial" >&2
    return 1
  fi
  adb -s "$serial" shell input tap $coords
}

# FAB: bottom-most unlabeled roughly-square clickable button.
and_tap_fab() {
  local serial="$1"
  local coords
  coords="$(and_dump "$serial" | python3 <<'PY'
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
)"
  if [ -z "$coords" ]; then
    echo "NOTFOUND: no FAB-shaped node on $serial" >&2
    return 1
  fi
  adb -s "$serial" shell input tap $coords
}

and_replace_topmost_field() {
  local serial="$1" new_text="$2"
  local field
  field="$(and_dump "$serial" | python3 <<'PY'
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
)"
  if [ -z "$field" ]; then
    echo "NOTFOUND: no EditText on $serial" >&2
    return 1
  fi
  read -r cx cy len <<<"$field"
  adb -s "$serial" shell input tap "$cx" "$cy"
  sleep 1
  adb -s "$serial" shell input keyevent 123
  local i
  for ((i = 0; i < len + 4; i++)); do
    adb -s "$serial" shell input keyevent 67
  done
  sleep 0.5
  adb -s "$serial" shell input text "$new_text"
}

and_relaunch() {
  local serial="$1"
  adb -s "$serial" shell input keyevent KEYCODE_WAKEUP 2>/dev/null || true
  adb -s "$serial" shell input keyevent 82 2>/dev/null || true  # menu / wake
  adb -s "$serial" shell wm dismiss-keyguard 2>/dev/null || true
  adb -s "$serial" shell am force-stop "$PKG"
  sleep 1
  adb -s "$serial" shell am start -n "$PKG/.MainActivity" \
    -a android.intent.action.MAIN -c android.intent.category.LAUNCHER
  sleep 8
  # Ensure app is foreground (Samsung may leave notification shade open).
  adb -s "$serial" shell input keyevent KEYCODE_HOME 2>/dev/null || true
  sleep 1
  adb -s "$serial" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 \
    >/dev/null 2>&1 || true
  sleep 4
}

and_screencap() {
  bash "$_LT_ROOT/scripts/screencap.sh" "$1" "$2"
}

and_go_home() {
  local serial="$1"
  # Pop until home tile "Shopping" is visible or max backs.
  local i
  for i in 1 2 3 4 5 6; do
    if and_has_text "$serial" "Shopping" && and_has_text "$serial" "Games"; then
      return 0
    fi
    adb -s "$serial" shell input keyevent KEYCODE_BACK
    sleep 1
  done
  and_relaunch "$serial"
}

# ── iOS (idb) ────────────────────────────────────────────────────────────────

ios_activate() {
  if [ -d "$_IDB_VENV" ]; then
    # shellcheck disable=SC1091
    source "$_IDB_VENV/bin/activate"
  fi
}

ios_ensure_companion() {
  local udid="$1" port="${2:-10882}"
  if ! pgrep -f "idb_companion --udid $udid" > /dev/null; then
    if [ "$port" = "10882" ]; then
      idb_companion --udid "$udid" > "$LOGDIR/idb_lt_${udid}.log" 2>&1 &
    else
      local dport=$((port + 1))
      idb_companion --udid "$udid" --grpc-port "$port" --debug-port "$dport" \
        > "$LOGDIR/idb_lt_${udid}.log" 2>&1 &
    fi
    sleep 2
  fi
  ios_activate
  idb connect "localhost:$port" > /dev/null 2>&1 || idb connect localhost "$port" > /dev/null 2>&1 || true
}

ios_labels() {
  local udid="$1"
  ios_activate
  idb ui describe-all --udid "$udid" 2>/dev/null | python3 -c "
import json,sys
data=json.load(sys.stdin)
for el in data:
    lab=el.get('AXLabel') or ''
    if lab: print(lab)
"
}

ios_has_text() {
  local udid="$1" needle="$2"
  ios_labels "$udid" | grep -qF "$needle"
}

ios_tap_label() {
  bash "$_LT_ROOT/scripts/idb_tap_label.sh" "$@"
}

ios_type() {
  local udid="$1" text="$2"
  ios_activate
  idb ui text "$text" --udid "$udid"
}

ios_relaunch() {
  local udid="$1"
  xcrun simctl terminate "$udid" "$PKG" 2>/dev/null || true
  sleep 1
  xcrun simctl launch "$udid" "$PKG"
  sleep 6
}

ios_screencap() {
  local udid="$1" out="$2"
  xcrun simctl io "$udid" screenshot "$out" >/dev/null
  echo "saved $out"
}

ios_go_home() {
  local udid="$1"
  local i
  for i in 1 2 3 4 5 6 7 8; do
    # Home grid has both Shopping and Games tiles.
    if ios_has_text "$udid" "Shopping" && ios_has_text "$udid" "Games"; then
      return 0
    fi
    ios_tap_label "$udid" "Back" 2>/dev/null || true
    sleep 1
    # Detail screens may only show Menu — still Back out.
    ios_tap_label "$udid" "Close" 2>/dev/null || true
  done
  ios_relaunch "$udid"
}

# ── Sync wait ────────────────────────────────────────────────────────────────

# Wait until $needle appears on platform device. platform=android|ios
wait_for_text() {
  local platform="$1" device="$2" needle="$3" max_s="${4:-45}"
  local elapsed=0
  while [ "$elapsed" -lt "$max_s" ]; do
    if [ "$platform" = android ]; then
      if and_has_text "$device" "$needle"; then return 0; fi
    else
      if ios_has_text "$device" "$needle"; then return 0; fi
    fi
    sleep 3
    elapsed=$((elapsed + 3))
  done
  echo "TIMEOUT: '$needle' not seen on $platform $device after ${max_s}s" >&2
  return 1
}

log_step() { echo ""; echo "== $* =="; }
log_pass() { echo "PASS: $*"; }
log_fail() { echo "FAIL: $*"; }
log_skip() { echo "SKIP: $*"; }
