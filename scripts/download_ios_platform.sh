#!/usr/bin/env bash
# Background the Xcode iOS platform/runtime download (needed once for iOS-sim builds
# on Xcode 26.x). Owns the redirect / & so the invocation is operator-free.
set -euo pipefail
LOGDIR="${TMPDIR:-/tmp}/sisumate"
mkdir -p "$LOGDIR"
LOG="$LOGDIR/ios_platform_download.log"
xcodebuild -downloadPlatform iOS > "$LOG" 2>&1 &
echo "download pid $!"
echo "log: $LOG"
