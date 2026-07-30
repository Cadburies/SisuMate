#!/usr/bin/env bash
# Poll a flutter-run log until it reaches readiness or an error, then print the tail.
# Owns the loop / $(...) / grep / redirect internally.
set -euo pipefail
LOG="${1:?usage: wait_for_flutter.sh <logfile> [max_iters]}"
MAX="${2:-40}"
for i in $(seq 1 "$MAX"); do
  if grep -qiE "Dart VM Service|Flutter run key commands|BUILD FAILED|Could not build|Error launching|error:|Exception" "$LOG" 2>/dev/null; then
    break
  fi
  sleep 15
done
echo "=== waited ~$((i * 15))s ==="
tail -25 "$LOG"
