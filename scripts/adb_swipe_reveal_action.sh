#!/usr/bin/env bash
# Swipes left across the Android list card matching <item-text> (by text or
# content-desc) to reveal its SwipeableListItem end action pane (theme.md
# §6.6: swipe LEFT = state toggle — Complete/Uncomplete, In stock/Out), then
# taps the revealed action whose label matches <action-text>.
#
# Coordinates are computed from the live uiautomator dump each call — never
# hand-entered pixel offsets, which drift across devices/layouts (see
# adb_tap_text.sh). Validated live on checklist/maintenance/safety item lists
# (TEST20, 2026-08-01): swiping a card and tapping "Complete" correctly
# triggers the free-tier Pro-gated interstitial path.
set -euo pipefail
SERIAL="${1:?usage: adb_swipe_reveal_action.sh <serial> <item-text> <action-text>}"
ITEM_TEXT="${2:?usage: adb_swipe_reveal_action.sh <serial> <item-text> <action-text>}"
ACTION_TEXT="${3:?usage: adb_swipe_reveal_action.sh <serial> <item-text> <action-text>}"

DUMP="$(adb -s "$SERIAL" exec-out uiautomator dump /dev/tty 2>/dev/null)"
BOUNDS="$(echo "$DUMP" | grep -oE "(text|content-desc)=\"[^\"]*${ITEM_TEXT}[^\"]*\"[^/]*bounds=\"\[[0-9,]+\]\[[0-9,]+\]\"" | head -1 | grep -oE '\[[0-9,]+\]\[[0-9,]+\]')"

if [ -z "$BOUNDS" ]; then
  echo "NOTFOUND: no card matching '$ITEM_TEXT' on $SERIAL" >&2
  exit 1
fi

X1=$(echo "$BOUNDS" | sed -E 's/\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]/\1/')
Y1=$(echo "$BOUNDS" | sed -E 's/\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]/\2/')
X2=$(echo "$BOUNDS" | sed -E 's/\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]/\3/')
Y2=$(echo "$BOUNDS" | sed -E 's/\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]/\4/')
CY=$(( (Y1 + Y2) / 2 ))
# Start near the card's right edge, end near its left edge — a full-width
# swipe reliably clears flutter_slidable's open threshold.
XSTART=$(( X2 - (X2 - X1) / 10 ))
XEND=$(( X1 + (X2 - X1) / 10 ))

adb -s "$SERIAL" shell input swipe "$XSTART" "$CY" "$XEND" "$CY" 400
sleep 1

"$(dirname "$0")/adb_tap_text.sh" -c "$SERIAL" "$ACTION_TEXT"
