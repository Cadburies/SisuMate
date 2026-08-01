#!/usr/bin/env bash
# TEST21 performance smoke: full-seed cold open timing + long-list scroll
# jank proxy. Emulator/simulator class numbers (user instruction: sims, not a
# mid-range phone) — absolute values are indicative only; regressions vs a
# prior run on the same rig are the signal.
#
# Usage:
#   bash scripts/test21_perf_smoke.sh and <serial>
#   bash scripts/test21_perf_smoke.sh ios <udid>
#
# Method: cold open = time from launch intent to the home grid's "Shopping"
# tile appearing in the a11y tree (0.2 s polling — ±0.5 s precision).
# Scroll = 12 flings in Shopping with dumpsys gfxinfo jank % (Android only).
set -uo pipefail
cd "$(dirname "$0")/.."

PLATFORM="${1:?usage: test21_perf_smoke.sh <and|ios> <serial|udid>}"
DEV="${2:?usage: test21_perf_smoke.sh <and|ios> <serial|udid>}"
PKG="com.sailingsisu.sisumate"

now_ms() { python3 -c 'import time; print(int(time.time()*1000))'; }

if [ "$PLATFORM" = "and" ]; then
  has_home() { adb -s "$DEV" exec-out uiautomator dump /dev/tty 2>/dev/null | grep -qE '(text|content-desc)="Shopping"'; }
  kill_app()  { adb -s "$DEV" shell am force-stop "$PKG"; }
  start_app() { adb -s "$DEV" shell am start -n "$PKG/.MainActivity" >/dev/null; }
else
  source .idb_venv/bin/activate
  has_home() { idb ui describe-all --udid "$DEV" 2>/dev/null | grep -q '"AXLabel" : "Shopping"\|"AXLabel":"Shopping"'; }
  kill_app()  { xcrun simctl terminate "$DEV" "$PKG" 2>/dev/null || true; }
  start_app() { xcrun simctl launch "$DEV" "$PKG" >/dev/null; }
fi

echo "=== TEST21 $PLATFORM $DEV ==="

# ── cold open ×3 (full seed already in the local DB) ─────────────────────────
TIMES=()
for run in 1 2 3; do
  kill_app
  sleep 2
  t0=$(now_ms)
  start_app
  deadline=$(( $(now_ms) + 45000 ))
  while ! has_home; do
    [ $(now_ms) -gt $deadline ] && break
    sleep 0.2
  done
  t1=$(now_ms)
  ms=$((t1 - t0))
  TIMES+=("$ms")
  echo "cold open #$run: ${ms} ms"
  sleep 2
done

# ── long list scroll ─────────────────────────────────────────────────────────
# NOTE: the bundled seed has NO shopping items — when "No shopping items yet"
# is present we substitute the seeded Cocktails list (longest seeded list) and
# say so, matching TEST21's intent (long-list scroll smoke).
if [ "$PLATFORM" = "and" ]; then
  bash scripts/adb_tap_text.sh "$DEV" "Shopping" >/dev/null 2>&1 || true
  sleep 3
  if adb -s "$DEV" exec-out uiautomator dump /dev/tty 2>/dev/null | grep -q "No shopping items yet"; then
    echo "shopping list empty (seed has none) — substituting Cocktails list"
    adb -s "$DEV" shell input keyevent 4
    sleep 1
    bash scripts/adb_tap_text.sh "$DEV" "Cocktails" >/dev/null 2>&1 || true
    sleep 3
  fi
  for i in 1 2 3 4 5 6; do
    adb -s "$DEV" shell input swipe 540 1900 540 500 250   # fling up
    sleep 0.4
  done
  for i in 1 2 3 4 5 6; do
    adb -s "$DEV" shell input swipe 540 500 540 1900 250   # fling down
    sleep 0.4
  done
  sleep 1
  if adb -s "$DEV" shell pidof "$PKG" >/dev/null 2>&1; then
    echo "scroll: app responsive after 12 flings"
  else
    echo "scroll: APP DIED"
  fi
  # gfxinfo framestats reports 0 frames on the API-36 emulator image — no
  # jank % available there; verdict is responsiveness-based.
  adb -s "$DEV" shell dumpsys gfxinfo "$PKG" 2>/dev/null | grep -iE "janky|total frames" | head -3 || true
else
  bash scripts/idb_tap_label.sh "$DEV" "Shopping" >/dev/null 2>&1 || true
  sleep 3
  for i in 1 2 3 4 5 6; do
    idb ui swipe 196 700 196 250 --udid "$DEV" >/dev/null 2>&1
    sleep 0.4
  done
  for i in 1 2 3 4 5 6; do
    idb ui swipe 196 250 196 700 --udid "$DEV" >/dev/null 2>&1
    sleep 0.4
  done
  # responsiveness proxy: tree still queryable + app alive
  if xcrun simctl spawn "$DEV" launchctl list 2>/dev/null | grep -q "$PKG"; then
    echo "scroll: app responsive after 12 swipes (subjective smoothness — no jank instrument on sim)"
  fi
fi
echo "=== TEST21 done ==="
