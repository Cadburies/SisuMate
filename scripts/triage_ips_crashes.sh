#!/usr/bin/env bash
# Add-on to triage_error_logs.sh / triage_error_logs_ios.sh.
#
# Native/hard crashes never reach ErrorLogTable (the process dies before
# Dart handlers run). This script:
#   1. Finds .ips files (already in crash_store/, optional connected iOS
#      device via idb, optional local Simulator DiagnosticReports)
#   2. Copies them into repo-root crash_store/ (gitignored)
#   3. Groups app crashes (Runner / SisuMate / Boat Checks) by a derived
#      fingerprint and files one GitHub issue per new fingerprint
#   4. Ignores Apple system processes (duetexpertd, aggregated, …)
#   5. Deletes every .ips out of crash_store/ when done
#
# Usage:
#   bash scripts/triage_ips_crashes.sh
#   bash scripts/triage_ips_crashes.sh --udid <udid>
#   bash scripts/triage_ips_crashes.sh --dry-run [--udid <udid>]
#   bash scripts/triage_ips_crashes.sh --keep          # skip the wipe
#
# --dry-run parses and prints groups but does not file issues or wipe.
# Device pull needs the same .idb_venv + idb_companion as
# triage_error_logs_ios.sh. Safe to rerun: idempotent via
# `Fingerprint: ips:<hash>` in issue bodies.
set -uo pipefail
cd "$(dirname "$0")/.."

UDID=""
DRY_RUN=false
KEEP=false
while [ $# -gt 0 ]; do
  case "$1" in
    --udid)
      UDID="${2:?--udid needs a value}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --keep)
      KEEP=true
      shift
      ;;
    -h|--help)
      sed -n '2,24p' "$0"
      exit 0
      ;;
    *)
      echo "usage: triage_ips_crashes.sh [--udid <udid>] [--dry-run] [--keep]" >&2
      exit 2
      ;;
  esac
done

STORE="crash_store"
mkdir -p "$STORE"
PY="python3 scripts/_ips_crash.py"

copy_into_store() {
  local src="$1"
  local dest="$STORE/$(basename "$src")"
  if [ -f "$dest" ]; then
    return 0
  fi
  cp "$src" "$dest"
}

# --- 1. Collect ----------------------------------------------------------
if [ -n "$UDID" ]; then
  VENV=".idb_venv"
  if [ ! -d "$VENV" ]; then
    echo "Missing $VENV — see scripts/triage_error_logs_ios.sh header." >&2
    exit 1
  fi
  # shellcheck disable=SC1091
  source "$VENV/bin/activate"
  echo "==> Connecting idb companion to $UDID"
  idb connect "$UDID" >/dev/null

  echo "==> Listing .ips crash reports on $UDID"
  LIST="$(mktemp)"
  idb crash list --udid "$UDID" 2>/dev/null | python3 -c '
import json, sys
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
    except json.JSONDecodeError:
        continue
    name = obj.get("name") or ""
    if name.endswith(".ips") or name.endswith(".IPS"):
        print(name)
' > "$LIST"
  COUNT="$(wc -l < "$LIST" | tr -d ' ')"
  echo "==> Pulling $COUNT .ips report(s) into $STORE/"
  while IFS= read -r NAME; do
    [ -z "$NAME" ] && continue
    OUT="$STORE/$NAME"
    if [ -s "$OUT" ]; then
      continue
    fi
    idb crash show --udid "$UDID" "$NAME" > "$OUT" 2>/dev/null \
      || echo "  failed to pull $NAME" >&2
  done < "$LIST"
  rm -f "$LIST"
fi

# Simulator / local Mac reports for the Flutter host only — not every
# first-party daemon on the development machine.
DIAG="$HOME/Library/Logs/DiagnosticReports"
if [ -d "$DIAG" ]; then
  FOUND=0
  for src in "$DIAG"/Runner-*.ips "$DIAG"/SisuMate-*.ips; do
    [ -f "$src" ] || continue
    copy_into_store "$src"
    FOUND=$((FOUND + 1))
  done
  if [ "$FOUND" -gt 0 ]; then
    echo "==> Copied $FOUND Simulator/Mac Runner/SisuMate .ips into $STORE/"
  fi
fi

shopt -s nullglob
IPS_FILES=("$STORE"/*.ips "$STORE"/*.IPS)
shopt -u nullglob
if [ ${#IPS_FILES[@]} -eq 0 ]; then
  echo "No .ips files in $STORE/. Nothing to process."
  exit 0
fi
echo "==> Processing ${#IPS_FILES[@]} .ips file(s) in $STORE/"

# --- 2. Group + file -----------------------------------------------------
SUMMARY="$(mktemp)"
$PY summarize "$STORE" > "$SUMMARY"

APP_GROUPS=0
SYSTEM_COUNT=0
FILED=0
SKIPPED=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  KIND="$(printf '%s' "$line" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("kind",""))')"
  COUNT="$(printf '%s' "$line" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("count",0))')"
  PROC="$(printf '%s' "$line" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("proc",""))')"
  if [ "$KIND" != "app" ]; then
    SYSTEM_COUNT=$((SYSTEM_COUNT + COUNT))
    echo "  ignore $KIND $PROC ×$COUNT"
    continue
  fi
  APP_GROUPS=$((APP_GROUPS + 1))
  FP="$(printf '%s' "$line" | python3 -c 'import json,sys; print(json.load(sys.stdin)["fingerprint"])')"
  SAMPLE="$(printf '%s' "$line" | python3 -c 'import json,sys; print(json.load(sys.stdin)["sample"])')"
  if [ "$DRY_RUN" = true ]; then
    TITLE="$(printf '%s' "$line" | $PY issue-title "$SAMPLE")"
    echo "  DRY-RUN $FP ×$COUNT  $TITLE"
    continue
  fi

  EXISTING="$(gh issue list --search "\"Fingerprint: $FP\" in:body" --state all --json url -q '.[0].url' 2>/dev/null || true)"
  if [ -n "$EXISTING" ]; then
    echo "  $FP already filed: $EXISTING (×$COUNT)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  TITLE="$(printf '%s' "$line" | $PY issue-title "$SAMPLE")"
  BODY_FILE="$(mktemp)"
  printf '%s' "$line" | $PY issue-body "$SAMPLE" > "$BODY_FILE"
  URL="$(gh issue create --title "$TITLE" --label bug --body-file "$BODY_FILE")"
  rm -f "$BODY_FILE"
  echo "  filed $FP ×$COUNT -> $URL"
  FILED=$((FILED + 1))
done < "$SUMMARY"
rm -f "$SUMMARY"

echo "==> App crash groups: $APP_GROUPS. Newly filed: $FILED. Already filed: $SKIPPED. System/other reports ignored: $SYSTEM_COUNT."

# --- 3. Wipe crash_store -------------------------------------------------
if [ "$DRY_RUN" = true ]; then
  echo "==> --dry-run: leaving $STORE/ intact"
  exit 0
fi
if [ "$KEEP" = true ]; then
  echo "==> --keep: leaving $STORE/ intact"
  exit 0
fi
echo "==> Cleaning $STORE/"
rm -f "$STORE"/*.ips "$STORE"/*.IPS
echo "==> $STORE/ is empty. Device crash logs were not deleted."
exit 0
