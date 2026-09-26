#!/usr/bin/env bash
# Feature Map runner (#354). Rules: .ai_context/feature_map/FORMAT.md.
#
#   scripts/fm.sh <id>                     run the feature's script (host)
#   scripts/fm.sh <id> --reach             host: only reach it (generic reach test)
#   scripts/fm.sh <id> --device <serial|udid>   reach it on a running phone/sim
set -euo pipefail
cd "$(dirname "$0")/.."
ID="${1:?usage: fm.sh <id> [--reach] [--device <serial|udid>]}"
shift
REACH=false
DEVICE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --reach) REACH=true ;;
    --device) DEVICE="${2:?--device needs an id}"; shift ;;
    *) echo "fm: unknown flag $1" >&2; exit 64 ;;
  esac
  shift
done

FILE=".ai_context/feature_map/$ID.md"
[ -f "$FILE" ] || { echo "fm: no feature file $FILE (try: dart run tool/feature_map.dart find <word>)" >&2; exit 1; }

if [ -n "$DEVICE" ]; then
  exec bash scripts/fm_device_reach.sh "$ID" "$DEVICE"
fi
if $REACH; then
  exec flutter test test/feature_map/reach_all_test.dart --dart-define=FM_ID="$ID"
fi

SCRIPT="$(sed -n 's/^script: //p' "$FILE")"
# Test names are the id, optionally followed by " [variant]".
NAME_RE="^$(printf '%s' "$ID" | sed 's/[][\.*^$+?(){}|]/\\&/g')( \\[.*\\])?\$"
case "$SCRIPT" in
  -) echo "fm: $ID has script: - (nothing to run; use --reach)" >&2; exit 1 ;;
  *.sh) exec bash "$SCRIPT" ;;
  */*) exec flutter test "$SCRIPT" ;;
  *) exec flutter test "test/feature_map/${SCRIPT}_test.dart" --name "$NAME_RE" ;;
esac
