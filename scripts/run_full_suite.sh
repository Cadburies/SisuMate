#!/usr/bin/env bash
# Full post-task regression suite — green before claiming any task done.
#
# Order:
#   1) SEC3 secrets scan
#   2) flutter analyze
#   3) flutter test          (unit/widget/TEST6/P0/offline/import/AI/units/a11y…)
#   4) TEST8 live Supabase   (scripts/test_supabase_rls.sh; skips without dart-defines)
#   5) TEST9 integration_test (default device: flutter-tester)
#
# Usage:
#   ./scripts/run_full_suite.sh
#   ./scripts/run_full_suite.sh --skip-live
#   ./scripts/run_full_suite.sh --skip-integration
#   ./scripts/run_full_suite.sh --device <id>
#
# Docs: CLAUDE.md §5 Test · README.md → Testing · GitHub Issues label `test-gap`
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SKIP_INTEGRATION=0
SKIP_LIVE=0
DEVICE_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-integration)
      SKIP_INTEGRATION=1
      shift
      ;;
    --skip-live)
      SKIP_LIVE=1
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

echo "==> SEC3 secrets scan"
bash scripts/scan_release_secrets.sh

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test (unit/widget/TEST6/P0/offline/import/join/AI/units/a11y)"
flutter test

if [[ "$SKIP_LIVE" -eq 0 ]]; then
  echo "==> TEST8 live Supabase RLS (skips if no dart-defines / offline)"
  bash scripts/test_supabase_rls.sh
else
  echo "==> skipping live Supabase RLS (--skip-live)"
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

echo "==> full suite green"
