#!/usr/bin/env bash
# Full post-task regression suite — green before claiming any task done.
#
# Order:
#   1) SEC3 secrets scan
#   2) factory guard tests   (scripts/_factory_test.py)
#   3) flutter analyze
#   4) flutter test          (unit/widget/TEST6/P0/offline/import/AI/units/a11y)
#   5) TEST8 live Supabase   (scripts/test_supabase_rls.sh; skips without dart-defines)
#   6) TEST9 integration_test (default device: flutter-tester)
#
# On green it writes build/suite_receipt.json (HEAD, flags, host test count, a
# blob hash per dirty file) and ratchets test/.test_floor. Agent commits are
# checked against that receipt (#420, scripts/_factory.py).
#
# Usage:
#   ./scripts/run_full_suite.sh
#   ./scripts/run_full_suite.sh --skip-live
#   ./scripts/run_full_suite.sh --skip-integration
#   ./scripts/run_full_suite.sh --device <id>
#
# Docs: AGENTS.md §6 Test · README.md → Testing · GitHub Issues label `test-gap`
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
STARTED="$(date +%s)"

SKIP_INTEGRATION=0
SKIP_LIVE=0
DEVICE_ARGS=()
FLAGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-integration)
      SKIP_INTEGRATION=1
      FLAGS+=("$1")
      shift
      ;;
    --skip-live)
      SKIP_LIVE=1
      FLAGS+=("$1")
      shift
      ;;
    --device)
      DEVICE_ARGS=(-d "$2")
      shift 2
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

# Hash dirty files now: anything edited while the suite runs is left out of the receipt.
python3 scripts/_factory.py snapshot

echo "==> SEC3 secrets scan"
bash scripts/scan_release_secrets.sh

echo "==> factory guard tests"
python3 scripts/_factory_test.py

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test (unit/widget/TEST6/P0/offline/import/join/AI/units/a11y)"
mkdir -p build
REPORT=build/flutter_test_report.json
rm -f "$REPORT"
flutter test --file-reporter "json:$REPORT"

if [[ "$SKIP_LIVE" -eq 0 ]]; then
  echo "==> TEST8 live Supabase RLS (skips if no dart-defines / offline)"
  bash scripts/test_supabase_rls.sh
  echo "==> live Supabase schema parity (boats.polar, polar samples, …)"
  # Soft: skips when offline / no creds. After a schema change, agents must
  # apply outstanding supabase/migrations/*.sql via Supabase MCP
  # (list_migrations → apply_migration) so this stays green.
  bash scripts/verify_supabase_schema.sh
else
  echo "==> skipping live Supabase RLS + schema parity (--skip-live)"
fi

if [[ "$SKIP_INTEGRATION" -eq 0 ]]; then
  echo "==> flutter test integration_test (TEST9)"
  # Prefer an explicit --device; otherwise flutter-tester (no native app build,
  # works when multiple phones/sims are attached). Use --device <id> for a real
  # simulator/emulator run of the same suite.
  if [[ ${#DEVICE_ARGS[@]} -eq 0 ]]; then
    DEVICE_ARGS=(-d flutter-tester)
  fi
  flutter test integration_test "${DEVICE_ARGS[@]}"
else
  echo "==> skipping integration_test (--skip-integration)"
fi

echo "==> writing suite receipt"
python3 scripts/_factory.py receipt-write --flags "${FLAGS[*]:-}" --report "$REPORT" --started "$STARTED"

echo "==> full suite green"
