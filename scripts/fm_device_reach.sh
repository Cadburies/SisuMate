#!/usr/bin/env bash
# Feature Map device reach (#354): runs a feature's `reach:` steps on a phone or
# simulator that already has Sisu Mate running (scripts/android_run.sh or
# ios_run.sh). Label taps only (never pixel coordinates), with scroll-retry.
#
#   scripts/fm_device_reach.sh <id> <android-serial|ios-udid>
#
# Starts from Home (home/, shared/). launch/ features need a fresh install so
# onboarding shows. Not supported on device: `long:` everywhere, `swipe:` on
# iOS (see the ccdevice long-press gap); the script stops and says so.
set -euo pipefail
cd "$(dirname "$0")/.."
ID="${1:?usage: fm_device_reach.sh <id> <serial|udid>}"
DEV="${2:?usage: fm_device_reach.sh <id> <serial|udid>}"
# shellcheck disable=SC1091
source scripts/lt_ui_helpers.sh

FILE=".ai_context/feature_map/$ID.md"
[ -f "$FILE" ] || { echo "fm: no feature file $FILE" >&2; exit 1; }
REACH="$(sed -n 's/^reach: //p' "$FILE")"
case "$DEV" in *-*-*-*-*) PLAT=ios ;; *) PLAT=android ;; esac

swipe_up() {
  if [ "$PLAT" = android ]; then
    local size w h
    size="$(adb -s "$DEV" shell wm size | sed -n 's/.*: //p' | tail -1)"
    w="${size%x*}"; h="${size#*x}"
    adb -s "$DEV" shell input swipe $((w / 2)) $((h * 3 / 4)) $((w / 2)) $((h / 4)) 300
  else
    ios_activate
    idb ui swipe --udid "$DEV" 200 650 200 250
  fi
  sleep 1
}

tap_label() {
  local label="$1" i
  for i in 1 2 3 4 5 6 7 8; do
    if [ "$PLAT" = android ]; then
      and_tap_text "$DEV" "$label" 2>/dev/null && { sleep 1.5; return 0; }
    else
      ios_tap_label "$DEV" "$label" 2>/dev/null && { sleep 1.5; return 0; }
    fi
    swipe_up
  done
  echo "fm: '$label' not found on $DEV after scrolling (step $STEP)" >&2
  exit 1
}

if [ "${ID%%/*}" != launch ]; then
  if [ "$PLAT" = android ]; then and_go_home "$DEV"; else ios_go_home "$DEV"; fi
fi
[ "$REACH" = "-" ] && { echo "fm: $ID is the start screen"; exit 0; }

printf '%s\n' "$REACH" | sed 's/ > /\n/g' > "$LOGDIR/fm_steps.txt"
while IFS= read -r STEP; do
  echo "fm: $STEP"
  VERB="${STEP%%:*}"
  ARG="${STEP#*:}"
  case "$VERB" in
    text|tip|label) tap_label "$ARG" ;;
    wait) wait_for_text "$PLAT" "$DEV" "$ARG" 30 ;;
    back)
      if [ "$PLAT" = android ]; then adb -s "$DEV" shell input keyevent KEYCODE_BACK; else ios_tap_label "$DEV" Back; fi
      sleep 1 ;;
    type)
      tap_label "${ARG%%=*}"
      if [ "$PLAT" = android ]; then
        adb -s "$DEV" shell input text "$(printf '%s' "${ARG#*=}" | sed 's/ /%s/g')"
      else
        ios_type "$DEV" "${ARG#*=}"
      fi ;;
    swipe)
      if [ "$PLAT" = android ]; then
        bash scripts/adb_swipe_reveal_action.sh "$DEV" "${ARG%:*}" "${ARG##*:}"
        sleep 1.5
      else
        echo "fm: swipe is not supported on iOS devices yet; do '$STEP' by hand" >&2; exit 3
      fi ;;
    long) echo "fm: long-press is not supported on devices yet; do '$STEP' by hand" >&2; exit 3 ;;
    *) echo "fm: bad step '$STEP'" >&2; exit 1 ;;
  esac
done < "$LOGDIR/fm_steps.txt"
echo "fm: reached $ID on $DEV"
