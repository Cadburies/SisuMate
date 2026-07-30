#!/usr/bin/env bash
# Taps the center of the first Android UI element whose accessibility text or
# content-desc exactly matches (or, with -c, contains) the given string.
# Avoids hand-computed pixel coordinates, which drift across devices/layouts
# (see liars_dice/live_test_setup.md).
set -euo pipefail
CONTAINS=false
if [ "${1:-}" = "-c" ]; then
  CONTAINS=true
  shift
fi
SERIAL="${1:?usage: adb_tap_text.sh [-c] <serial> <text>}"
TEXT="${2:?usage: adb_tap_text.sh [-c] <serial> <text>}"

DUMP="$(adb -s "$SERIAL" exec-out uiautomator dump /dev/tty 2>/dev/null)"

if [ "$CONTAINS" = true ]; then
  PATTERN="\"[^\"]*${TEXT}[^\"]*\""
else
  PATTERN="\"${TEXT}\""
fi

BOUNDS="$(echo "$DUMP" | grep -oE "${PATTERN}[^/]*bounds=\"\[[0-9,]+\]\[[0-9,]+\]\"" | head -1 | grep -oE '\[[0-9,]+\]\[[0-9,]+\]')"

if [ -z "$BOUNDS" ]; then
  echo "NOTFOUND: no element matching '$TEXT' on $SERIAL" >&2
  exit 1
fi

X1=$(echo "$BOUNDS" | sed -E 's/\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]/\1/')
Y1=$(echo "$BOUNDS" | sed -E 's/\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]/\2/')
X2=$(echo "$BOUNDS" | sed -E 's/\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]/\3/')
Y2=$(echo "$BOUNDS" | sed -E 's/\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]/\4/')
CX=$(( (X1 + X2) / 2 ))
CY=$(( (Y1 + Y2) / 2 ))

adb -s "$SERIAL" shell input tap "$CX" "$CY"
