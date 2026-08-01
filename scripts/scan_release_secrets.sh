#!/usr/bin/env bash
# SEC3 — scan built release artifacts (and always-on source guards) for leaked
# credentials. Safe to run without a build: source/asset checks always run.
#
# Usage:
#   ./scripts/scan_release_secrets.sh
#   ./scripts/scan_release_secrets.sh path/to/app-release.apk
#
# Exit 0 = clean. Exit 1 = leak suspected.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAIL=0
fail() {
  echo "SEC3 FAIL: $*" >&2
  FAIL=1
}
ok() { echo "SEC3 ok: $*"; }

# ── Always-on: Flutter must never package secrets/ ──────────────────────────
if grep -nE 'secrets/|service-account|google-play.*\.json' pubspec.yaml \
  | grep -vE '^\s*#' | grep -qiE 'assets:|secrets/|service-account'; then
  # Narrower: any assets: entry that pulls secrets
  if grep -A200 '^flutter:' pubspec.yaml | grep -E '^\s+-\s+secrets/|service-account.*\.json' >/dev/null 2>&1; then
    fail "pubspec.yaml lists secrets or service-account JSON under flutter assets"
  else
    ok "pubspec assets do not list secrets/"
  fi
else
  ok "pubspec has no secrets asset paths"
fi

# ── Always-on: no private key / service_role blobs under assets/ ────────────
if [[ -d assets ]]; then
  if grep -rIlE 'BEGIN (RSA |OPENSSH )?PRIVATE KEY|service_role|eyJhbGciOi' assets 2>/dev/null \
    | grep -v README >/dev/null 2>&1; then
    fail "assets/ contains private-key or JWT-like material"
  else
    ok "assets/ has no private keys / service_role blobs"
  fi
fi

# ── Always-on: lib must not hardcode service_role or Play SA path as asset ──
if grep -rnE 'service_role|assets/service-account|google-play-service-account' lib \
  --include='*.dart' 2>/dev/null | grep -vE '^\s*//' >/dev/null 2>&1; then
  fail "lib/ references service_role or Play SA asset path"
else
  ok "lib/ has no service_role / Play SA asset references"
fi

# ── Optional: scan APK/IPA/AAB if provided or found ─────────────────────────
scan_archive() {
  local archive="$1"
  [[ -f "$archive" ]] || return 0
  echo "SEC3 scanning archive: $archive"
  local tmp
  tmp="$(mktemp -d)"
  # unzip -l is enough for path leaks; strings for content
  if unzip -l "$archive" 2>/dev/null | grep -E 'secrets/|service-account|google-play.*\.json' >/dev/null; then
    fail "archive lists secrets/ or service-account paths: $archive"
  fi
  # Extract small text-ish entries only when strings available
  if command -v strings >/dev/null 2>&1; then
    if strings "$archive" | grep -E 'BEGIN (RSA |OPENSSH )?PRIVATE KEY|"type":\s*"service_account"' >/dev/null; then
      fail "archive strings look like a private key or GCP service account: $archive"
    fi
  fi
  rm -rf "$tmp"
  ok "archive path scan clean: $archive"
}

if [[ $# -gt 0 ]]; then
  for a in "$@"; do scan_archive "$a"; done
else
  # Common Flutter output locations (may not exist yet)
  for a in \
    build/app/outputs/flutter-apk/app-release.apk \
    build/app/outputs/flutter-apk/app-debug.apk \
    build/ios/ipa/*.ipa \
    build/app/outputs/bundle/release/*.aab
  do
    # shellcheck disable=SC2086
    for f in $a; do
      [[ -f "$f" ]] && scan_archive "$f"
    done
  done
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "SEC3: secrets scan FAILED" >&2
  exit 1
fi
echo "SEC3: secrets scan clean"
exit 0
