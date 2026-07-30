#!/usr/bin/env bash
# Background a debug flutter run on the given Android emulator/device.
set -euo pipefail
DEVICE="${1:?usage: android_run.sh <device-id>}"
cd "$(dirname "$0")/.."
LOGDIR="${TMPDIR:-/tmp}/sisumate"
mkdir -p "$LOGDIR"
SAFE_DEVICE="$(echo "$DEVICE" | tr -c 'A-Za-z0-9_-' '_')"
LOG="$LOGDIR/android_run_${SAFE_DEVICE}.log"
flutter run -d "$DEVICE" --dart-define-from-file=dart-defines.json --debug > "$LOG" 2>&1 &
echo "android run pid $!"
echo "log: $LOG"
