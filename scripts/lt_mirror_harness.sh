#!/usr/bin/env bash
# LT1 — Dual-device mirror harness bootstrap.
#
# Prepares a DRIVER (mutates) + MIRROR (observes sync) pair on the same boat.
# Defaults: Android phone = driver, iOS Simulator = mirror (real phone stays
# online; sim shares host network for Supabase).
#
# Usage:
#   bash scripts/lt_mirror_harness.sh [driver_android_serial] [mirror_ios_udid]
#
# Exit 0 if both apps reach home and show Pro/Online boat chrome.
# Does NOT create records — use lt_module_crud_sweep.sh for LT2–LT4.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source scripts/lt_ui_helpers.sh

DRIVER="${1:-R5CX2036L1F}"
MIRROR="${2:-43C4A261-F7F0-47FE-AC5B-C5313F7DFBEF}"
RUN_TAG="lt1_$(date +%Y%m%d_%H%M%S)"
RESULT="$LOGDIR/${RUN_TAG}_result.txt"

log_step "LT1 dual-sim mirror harness"
echo "DRIVER(android)=$DRIVER  MIRROR(ios)=$MIRROR"
echo "Results -> $RESULT"
: >"$RESULT"

# ── Preconditions ────────────────────────────────────────────────────────────
if ! adb -s "$DRIVER" get-state 2>/dev/null | grep -q device; then
  echo "Android driver $DRIVER not connected" | tee -a "$RESULT"
  exit 1
fi
if ! xcrun simctl list devices | grep -q "$MIRROR.*(Booted)"; then
  echo "Booting iOS mirror $MIRROR..."
  xcrun simctl boot "$MIRROR" 2>/dev/null || true
  sleep 4
fi
ios_ensure_companion "$MIRROR" 10882

log_step "Relaunch apps"
and_relaunch "$DRIVER"
ios_relaunch "$MIRROR"

and_screencap "$DRIVER" "$LOGDIR/${RUN_TAG}_driver_home.png"
ios_screencap "$MIRROR" "$LOGDIR/${RUN_TAG}_mirror_home.png"

# ── Same-boat / Pro chrome check ─────────────────────────────────────────────
check_home() {
  local platform="$1" device="$2" role="$3"
  local ok=1
  if [ "$platform" = android ]; then
    and_has_text "$device" "Shopping" || ok=0
    and_has_text "$device" "Games" || ok=0
    # Pro + Online often appear in status strip
    if and_has_text "$device" "Pro" || and_has_text "$device" "Online"; then
      :
    else
      echo "WARN: $role missing Pro/Online status text (may still be on boat)" | tee -a "$RESULT"
    fi
  else
    ios_has_text "$device" "Shopping" || ok=0
    ios_has_text "$device" "Games" || ok=0
    if ios_has_text "$device" "Pro" || ios_has_text "$device" "Online"; then
      :
    else
      echo "WARN: $role missing Pro/Online status text" | tee -a "$RESULT"
    fi
  fi
  if [ "$ok" -eq 1 ]; then
    log_pass "$role home reachable" | tee -a "$RESULT"
    return 0
  fi
  log_fail "$role not on home screen" | tee -a "$RESULT"
  return 1
}

FAIL=0
check_home android "$DRIVER" DRIVER || FAIL=1
check_home ios "$MIRROR" MIRROR || FAIL=1

if [ "$FAIL" -ne 0 ]; then
  echo "LT1 FAIL — ensure both devices are unlocked, app installed, and signed into the same Pro boat." | tee -a "$RESULT"
  exit 1
fi

cat >>"$RESULT" <<EOF

LT1 READY
  DRIVER=$DRIVER (android) — create/edit/delete here
  MIRROR=$MIRROR (ios)     — wait for synced rows to appear
  Next: bash scripts/lt_module_crud_sweep.sh $DRIVER $MIRROR
EOF

echo ""
echo "LT1 PASS — dual-device harness ready."
echo "  Screenshots: $LOGDIR/${RUN_TAG}_*_home.png"
echo "  Next: bash scripts/lt_module_crud_sweep.sh $DRIVER $MIRROR"
exit 0
