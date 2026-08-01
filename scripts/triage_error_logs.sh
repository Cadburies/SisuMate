#!/usr/bin/env bash
# #121 triage automation — reads the app's local error log (ErrorLogTable)
# off a connected Android device and files one deduped GitHub issue per new
# fingerprint, so pixel-overflow warnings / exceptions / caught-but-logged
# errors found by *anyone browsing the app* (not just tests) surface as
# agent-actionable issues automatically. Run on demand (cron or ad hoc) —
# NOT part of run_full_suite.sh; see CLAUDE.md's GUI-test-drivers table.
#
# Idempotent: a fingerprint that already has a filed issue (searched by the
# "Fingerprint: <hash>" marker in issue bodies, not just local processedAt —
# so a failed push-back on a prior run can't cause a duplicate) is skipped
# and just re-marked processed against the existing issue URL.
#
# Usage:
#   bash scripts/triage_error_logs.sh <serial>
#
# Requires: a debug build already run at least once on <serial> (so
# com.sailingsisu.sisumate/files/app_flutter/sisu_mate.sqlite exists on
# device), `adb`, this repo's `dart`, `gh` authenticated for this repo.
#
# Stop the app on <serial> before running this — it pulls the sqlite file
# and pushes a modified copy back; a live app write mid-swap would corrupt
# or lose data. (iOS: not yet supported — the pull/push step is Android
# `run-as`-specific; porting needs an idb/simctl file-copy equivalent.)
set -uo pipefail
cd "$(dirname "$0")/.."

SERIAL="${1:?usage: triage_error_logs.sh <serial>}"
PKG="com.sailingsisu.sisumate"
SAFE_SERIAL="$(echo "$SERIAL" | tr -c 'A-Za-z0-9_-' '_')"
WORKDIR="/tmp/triage_error_logs"
mkdir -p "$WORKDIR"
DB_LOCAL="$WORKDIR/${SAFE_SERIAL}.sqlite"

echo "==> Pulling sisu_mate.sqlite from $SERIAL"
adb -s "$SERIAL" exec-out run-as "$PKG" cat files/app_flutter/sisu_mate.sqlite > "$DB_LOCAL"
if [ ! -s "$DB_LOCAL" ]; then
  echo "Empty/missing DB pull — is the app installed and has it run at least once on $SERIAL?" >&2
  exit 1
fi

echo "==> Reading unprocessed rows"
DUMP="$WORKDIR/dump_${SAFE_SERIAL}.jsonl"
dart run tool/error_log_admin.dart dump-unprocessed "$DB_LOCAL" > "$DUMP"

if [ ! -s "$DUMP" ]; then
  echo "No unprocessed error-log rows. Nothing to do."
  exit 0
fi

echo "==> Filing issues (one per new fingerprint; already-filed fingerprints are skipped)"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  FINGERPRINT="$(echo "$line" | python3 -c 'import json,sys; print(json.load(sys.stdin)["fingerprint"])')"

  EXISTING="$(gh issue list --search "\"Fingerprint: $FINGERPRINT\" in:body" --state all --json url -q '.[0].url' 2>/dev/null || true)"
  if [ -n "$EXISTING" ]; then
    echo "  $FINGERPRINT already filed: $EXISTING"
    dart run tool/error_log_admin.dart mark-processed "$DB_LOCAL" "$FINGERPRINT" "$EXISTING" >/dev/null
    continue
  fi

  TITLE="$(echo "$line" | python3 scripts/_error_log_issue_body.py --title-only)"
  BODY_FILE="$WORKDIR/body_${FINGERPRINT}.md"
  echo "$line" | python3 scripts/_error_log_issue_body.py > "$BODY_FILE"

  URL="$(gh issue create --title "$TITLE" --label bug --body-file "$BODY_FILE")"
  echo "  filed $FINGERPRINT -> $URL"
  dart run tool/error_log_admin.dart mark-processed "$DB_LOCAL" "$FINGERPRINT" "$URL" >/dev/null
done < "$DUMP"

echo "==> Pushing updated processedAt/issueUrl back to $SERIAL"
adb -s "$SERIAL" exec-out run-as "$PKG" sh -c 'cat > files/app_flutter/sisu_mate.sqlite' < "$DB_LOCAL"

echo "==> Done"
