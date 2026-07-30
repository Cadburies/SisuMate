#!/usr/bin/env bash
# Background a debug flutter run on the given device (iOS sim or any device id).
# Owns cd / env / redirect / & so the invocation Claude sees is operator-free.
set -euo pipefail
DEVICE="${1:?usage: ios_run.sh <device-id>}"
cd "$(dirname "$0")/.."
LOGDIR="${TMPDIR:-/tmp}/sisumate"
mkdir -p "$LOGDIR"
SAFE_DEVICE="$(echo "$DEVICE" | tr -c 'A-Za-z0-9_-' '_')"
LOG="$LOGDIR/ios_run_${SAFE_DEVICE}.log"
flutter run -d "$DEVICE" --dart-define-from-file=dart-defines.json --debug > "$LOG" 2>&1 &
echo "ios run pid $!"
echo "log: $LOG"
