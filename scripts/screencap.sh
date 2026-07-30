#!/usr/bin/env bash
# Capture a screenshot from an Android device to an absolute path.
# Owns the > redirect internally.
set -euo pipefail
DEVICE="${1:?usage: screencap.sh <device-id> <abs-outfile>}"
OUT="${2:?usage: screencap.sh <device-id> <abs-outfile>}"
mkdir -p "$(dirname "$OUT")"
adb -s "$DEVICE" exec-out screencap -p > "$OUT" 2>/dev/null
echo "saved $OUT"
