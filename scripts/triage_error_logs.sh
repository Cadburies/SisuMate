#!/usr/bin/env bash
# #121 triage automation — reads the app's local error log (ErrorLogTable)
# off a connected Android device and files one deduped GitHub issue per new
# fingerprint, so pixel-overflow warnings / exceptions / caught-but-logged
# errors found by *anyone browsing the app* (not just tests) surface as
# agent-actionable issues automatically. Run on demand (cron or ad hoc) —
# NOT part of run_full_suite.sh; see CLAUDE.md's GUI-test-drivers table.
#
# Device-safe by design: force-stops the app, pulls the sqlite file, then
# does every remaining step (dump, dedupe-check, file issues) on the local
# copy only. Nothing is ever written back to the device — no risk of
# corrupting the live on-device database, and no need for the operator to
# manually stop the app first.
#
# Idempotent: a fingerprint that already has a filed issue is found by
# searching for the "Fingerprint: <hash>" marker in issue bodies (not local
# processedAt state, which no longer round-trips to the device at all) —
# safe to rerun as often as you like.
#
# Usage:
#   bash scripts/triage_error_logs.sh <serial>
#
# Requires: a debug build already run at least once on <serial> (so
# com.sailingsisu.sisumate/app_flutter/sisu_mate.sqlite exists on device),
# `adb`, this repo's `dart`, `gh` authenticated for this repo.
#
# iOS: see scripts/triage_error_logs_ios.sh (#267) — separate script, idb-based
# pull instead of `adb run-as`, plus a bonus native-crash-log pull.
set -uo pipefail
cd "$(dirname "$0")/.."

SERIAL="${1:?usage: triage_error_logs.sh <serial>}"
PKG="com.sailingsisu.sisumate"
SAFE_SERIAL="$(echo "$SERIAL" | tr -c 'A-Za-z0-9_-' '_')"
WORKDIR="/tmp/triage_error_logs"
mkdir -p "$WORKDIR"
DB_LOCAL="$WORKDIR/${SAFE_SERIAL}.sqlite"

echo "==> Stopping the app on $SERIAL (if running)"
adb -s "$SERIAL" shell am force-stop "$PKG"

echo "==> Pulling sisu_mate.sqlite from $SERIAL to $DB_LOCAL"
adb -s "$SERIAL" exec-out run-as "$PKG" cat app_flutter/sisu_mate.sqlite > "$DB_LOCAL"
if [ ! -s "$DB_LOCAL" ]; then
  echo "Empty/missing DB pull — is the app installed and has it run at least once on $SERIAL?" >&2
  exit 1
fi

echo "==> Reading unprocessed rows (local copy only — device is not touched again)"
DUMP="$WORKDIR/dump_${SAFE_SERIAL}.jsonl"
dart run tool/error_log_admin.dart dump-unprocessed "$DB_LOCAL" > "$DUMP"

# `dart run` prints "Running build hooks..." (sqlite3's native-asset build
# step) to stdout ahead of the tool's own output, landing on the same line
# as the first JSON object and breaking its parse (found live: corrupted
# the very first row of a real run, which then silently mis-filed against
# an unrelated issue via the empty-fingerprint fallback below). Strip
# anything before the first '{' on each line; JSONL is one full object per
# line here, so this is safe.
sed -i.bak 's/^[^{]*{/{/' "$DUMP" && rm -f "$DUMP.bak"

if [ ! -s "$DUMP" ]; then
  echo "No unprocessed error-log rows. Nothing to do."
  exit 0
fi

echo "==> Filing issues (one per new fingerprint; already-filed fingerprints are skipped)"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  FINGERPRINT="$(printf '%s' "$line" | python3 -c 'import json,sys; print(json.load(sys.stdin)["fingerprint"])')"
  if [ -z "$FINGERPRINT" ]; then
    echo "  SKIPPING a row: fingerprint extraction failed (malformed JSON line — see it in $DUMP)" >&2
    continue
  fi

  EXISTING="$(gh issue list --search "\"Fingerprint: $FINGERPRINT\" in:body" --state all --json url -q '.[0].url' 2>/dev/null || true)"
  if [ -n "$EXISTING" ]; then
    echo "  $FINGERPRINT already filed: $EXISTING"
    dart run tool/error_log_admin.dart mark-processed "$DB_LOCAL" "$FINGERPRINT" "$EXISTING" >/dev/null
    continue
  fi

  TITLE="$(printf '%s' "$line" | python3 scripts/_error_log_issue_body.py --title-only)"
  BODY_FILE="$WORKDIR/body_${FINGERPRINT}.md"
  printf '%s' "$line" | python3 scripts/_error_log_issue_body.py > "$BODY_FILE"

  # Pixel-overflow (RenderFlex) rows get a second, distinct label so they're
  # `gh issue list --label ui-overflow`-findable at a glance, independent of
  # whether sourceFile capture succeeded for that particular row.
  LABEL_ARGS=(--label bug)
  if printf '%s' "$line" | python3 -c 'import json,sys; msg=json.load(sys.stdin).get("message") or ""; sys.exit(0 if "RenderFlex overflowed" in msg else 1)'; then
    LABEL_ARGS+=(--label ui-overflow)
  fi

  URL="$(gh issue create --title "$TITLE" "${LABEL_ARGS[@]}" --body-file "$BODY_FILE")"
  echo "  filed $FINGERPRINT -> $URL"
  dart run tool/error_log_admin.dart mark-processed "$DB_LOCAL" "$FINGERPRINT" "$URL" >/dev/null
done < "$DUMP"

echo "==> Done. $DB_LOCAL is marked processed locally for reference; the on-device DB was never modified."
echo "==> Relaunch the app on $SERIAL if you want to keep testing."
