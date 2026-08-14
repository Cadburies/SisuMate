#!/usr/bin/env bash
# #267 — iOS counterpart to triage_error_logs.sh (#121/#122). Reads the app's
# local error log (ErrorLogTable) off a connected iPhone/iPad and files one
# deduped GitHub issue per new fingerprint, same as the Android script. Run
# on demand — NOT part of run_full_suite.sh; see CLAUDE.md's ops-automation
# table.
#
# Device-safe by design: pulls the sqlite file via idb (read-only container
# access), then does every remaining step (dump, dedupe-check, file issues)
# on the local copy only. Nothing is ever written back to the device.
#
# Idempotent: a fingerprint that already has a filed issue is found by
# searching for the "Fingerprint: <hash>" marker in issue bodies — safe to
# rerun as often as you like.
#
# Native/hard-crash .ips: handed to scripts/triage_ips_crashes.sh (copy
# into crash_store/, fingerprint, file one issue per new ips: hash, wipe
# crash_store/). ErrorLogTable never sees these — the process died first.
#
# Usage:
#   bash scripts/triage_error_logs_ios.sh <udid> [--skip-crashes]
#
# Requires: a debug build already run at least once on <udid> (so
# com.sailingsisu.sisumate's Documents/sisu_mate.sqlite exists on device),
# .idb_venv (repo-local, `pip install fb-idb` inside it if missing),
# idb_companion (`brew install facebook/fb/idb-companion`), this repo's
# `dart`, `gh` authenticated for this repo.
#
# Only reaches devices physically connected to this Mac. Does NOT reach a
# remote external tester's device — for that, use App Store Connect ->
# TestFlight -> Crashes, or have the tester pull their own
# Settings -> Privacy -> Analytics Data -> SisuMate .ips and send it over.
set -uo pipefail
cd "$(dirname "$0")/.."

UDID="${1:?usage: triage_error_logs_ios.sh <udid> [--skip-crashes]}"
SKIP_CRASHES=false
if [ "${2:-}" = "--skip-crashes" ]; then
  SKIP_CRASHES=true
fi

BUNDLE_ID="com.sailingsisu.sisumate"
SAFE_UDID="$(echo "$UDID" | tr -c 'A-Za-z0-9_-' '_')"
WORKDIR="/tmp/triage_error_logs"
mkdir -p "$WORKDIR"
DB_LOCAL="$WORKDIR/${SAFE_UDID}.sqlite"

VENV="$(dirname "$0")/../.idb_venv"
if [ ! -d "$VENV" ]; then
  echo "Missing $VENV — see this script's header for setup." >&2
  exit 1
fi
# shellcheck disable=SC1091
source "$VENV/bin/activate"

echo "==> Connecting idb companion to $UDID"
idb connect "$UDID" >/dev/null

echo "==> Pulling sisu_mate.sqlite from $UDID to $DB_LOCAL"
# Physical devices need the deprecated --bundle-id form; the newer
# --application form errors with "requires a rooted device" on real
# hardware (confirmed live against a physical iPhone on iOS 15.7.8).
idb file pull --udid "$UDID" --bundle-id "$BUNDLE_ID" Documents/sisu_mate.sqlite "$DB_LOCAL" 2>&1 \
  | grep -v "is deprecated, please use --application" || true
if [ ! -s "$DB_LOCAL" ]; then
  echo "Empty/missing DB pull — is the app installed and has it run at least once on $UDID?" >&2
  exit 1
fi

echo "==> Reading unprocessed rows (local copy only — device is not touched again)"
DUMP="$WORKDIR/dump_${SAFE_UDID}.jsonl"
dart run tool/error_log_admin.dart dump-unprocessed "$DB_LOCAL" > "$DUMP"

# Same stdout-pollution guard as the Android script: `dart run` prints
# "Running build hooks..." (sqlite3's native-asset build step) ahead of the
# tool's own output, landing on the same line as the first JSON object.
# Strip anything before the first '{' on each line.
sed -i.bak 's/^[^{]*{/{/' "$DUMP" && rm -f "$DUMP.bak"

if [ ! -s "$DUMP" ]; then
  echo "No unprocessed error-log rows."
else
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

    LABEL_ARGS=(--label bug)
    if printf '%s' "$line" | python3 -c 'import json,sys; msg=json.load(sys.stdin).get("message") or ""; sys.exit(0 if "RenderFlex overflowed" in msg else 1)'; then
      LABEL_ARGS+=(--label ui-overflow)
    fi

    URL="$(gh issue create --title "$TITLE" "${LABEL_ARGS[@]}" --body-file "$BODY_FILE")"
    echo "  filed $FINGERPRINT -> $URL"
    dart run tool/error_log_admin.dart mark-processed "$DB_LOCAL" "$FINGERPRINT" "$URL" >/dev/null
  done < "$DUMP"
fi

echo "==> $DB_LOCAL is marked processed locally for reference; the on-device DB was never modified."

if [ "$SKIP_CRASHES" = true ]; then
  echo "==> Skipping native .ips triage (--skip-crashes)"
  exit 0
fi

echo "==> Native .ips add-on (device pull → crash_store/ → file → wipe)"
bash scripts/triage_ips_crashes.sh --udid "$UDID"
