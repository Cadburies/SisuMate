#!/usr/bin/env bash
# TEST20 AdMob real-device smoke (Android). On-demand GUI test — not part of
# run_full_suite.sh. Requires kForceProForTesting = false in
# lib/services/revenuecat_service.dart (temporarily flip it, run this, flip
# it back — see CLAUDE.md §7 "Commit & push"; never leave it flipped in a
# commit) so the app actually runs Free-tier instead of the on-device debug
# Pro override.
#
# Drives: Home banner (no FAB there — structurally can't overlap), a
# checklist's item list (native ad slot + FAB coexist here), and the
# free-tier Pro-gated "Complete" swipe action (triggers AdMobService's
# interstitial path). Screenshots + a flutter-log excerpt land in
# /tmp/test20/ for a human/agent to read the ad states off of.
#
# Usage:
#   bash scripts/android_run.sh <serial>            # start the app first
#   bash scripts/test20_admob_smoke.sh <serial> <flutter-run-log>
#
# Known gaps as of 2026-08-01 (see GitHub issues, do not re-discover blind):
#   - Native ads never render (missing NativeAdFactory platform registration).
#   - Interstitial rarely/never shows (AdMobService is not a singleton, so
#     each Complete tap discards any in-flight ad load — expect
#     "AdMob: No interstitial ad available to show" almost every time).
set -uo pipefail
cd "$(dirname "$0")/.."

SERIAL="${1:?usage: test20_admob_smoke.sh <serial> <flutter-run-log>}"
FLOG="${2:?usage: test20_admob_smoke.sh <serial> <flutter-run-log>}"
EVIDENCE="/tmp/test20"
mkdir -p "$EVIDENCE"
LOG="$EVIDENCE/results.log"
: > "$LOG"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

log "=== Home screen (banner check — no FAB on this screen) ==="
bash scripts/screencap.sh "$SERIAL" "$EVIDENCE/01_home.png"
sleep 1

log "=== Checklists list (module screen has a FAB, no ad) ==="
bash scripts/adb_tap_text.sh "$SERIAL" "Checklists"
sleep 2
bash scripts/screencap.sh "$SERIAL" "$EVIDENCE/02_checklists.png"

log "=== Open first checklist group (native ad + FAB coexist here) ==="
bash scripts/adb_tap_text.sh -c "$SERIAL" "On-Watch"
sleep 2
bash scripts/screencap.sh "$SERIAL" "$EVIDENCE/03_items_top.png"
adb -s "$SERIAL" shell input swipe 500 1500 500 400 300
sleep 1
bash scripts/screencap.sh "$SERIAL" "$EVIDENCE/04_items_scrolled.png"

log "=== Trigger free-tier Pro-gated Complete (interstitial path) x2 ==="
bash scripts/adb_swipe_reveal_action.sh "$SERIAL" "AIS Targets" "Complete"
sleep 3
bash scripts/adb_swipe_reveal_action.sh "$SERIAL" "Radar Watch" "Complete"
sleep 3
bash scripts/screencap.sh "$SERIAL" "$EVIDENCE/05_after_gate_taps.png"

log "=== flutter-log AdMob lines since script start ==="
grep -iE "AdMob:|Banner ad|Native ad|Interstitial" "$FLOG" | tee -a "$LOG" || true

log "Done. Read $EVIDENCE/*.png for banner/FAB/native-ad visuals; $LOG for ad-state prints."
log "Remember: flip kForceProForTesting back to true and confirm no banner (Pro collapse) before finishing."
