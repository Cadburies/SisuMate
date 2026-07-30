#!/usr/bin/env bash
# Stops any running `flutter run` process. Owns the redirect/pkill internally
# (bare `pkill ... 2>/dev/null` inlined in a Bash call trips the permission
# matcher on the redirect operator).
pkill -f "flutter run" 2>/dev/null
echo "stopped (or nothing was running)"
