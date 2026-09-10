#!/usr/bin/env bash
# Build a signed Play App Bundle and upload it to a Google Play track.
#
# Usage:
#   ./scripts/play_release.sh
#   ./scripts/play_release.sh --track internal
#   ./scripts/play_release.sh --track internal --skip-build
#   ./scripts/play_release.sh --track production   # only when explicitly requested
#
# Requires (gitignored):
#   secrets/google-play-service-account.json
#   android/key.properties + the upload keystore it points at
#   dart-defines.json   (production credentials; FORCE_PRO_* is refused)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TRACK=internal
STATUS=completed
SKIP_BUILD=0
PACKAGE=com.sailingsisu.sisumate
DEFINES="$ROOT/dart-defines.json"
SA_JSON="$ROOT/secrets/google-play-service-account.json"
AAB="$ROOT/build/app/outputs/bundle/release/app-release.aab"
VENV="${PLAY_API_VENV:-/tmp/play-api-venv}"

usage() {
  sed -n '2,12p' "$0"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --track) TRACK="${2:?}"; shift 2 ;;
    --status) STATUS="${2:?}"; shift 2 ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    --package) PACKAGE="${2:?}"; shift 2 ;;
    --aab) AAB="${2:?}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown arg: $1" >&2; usage ;;
  esac
done

fail() { echo "play_release FAIL: $*" >&2; exit 1; }
ok() { echo "play_release: $*"; }

[[ -f "$SA_JSON" ]] || fail "missing $SA_JSON"
[[ -f "$ROOT/android/key.properties" ]] || fail "missing android/key.properties (upload signing)"
[[ -f "$DEFINES" ]] || fail "missing dart-defines.json"

if python3 -c "
import json,sys
d=json.load(open('$SA_JSON'))
email=d.get('client_email','')
print(email)
sys.exit(1 if email.startswith('boatchecks@') else 0)
" >/tmp/play_sa_email.txt; then
  ok "SA $(cat /tmp/play_sa_email.txt)"
else
  fail "refusing leftover Boat Checks service account $(cat /tmp/play_sa_email.txt 2>/dev/null)"
fi

if python3 -c "
import json,sys
d=json.load(open('$DEFINES'))
bad=[k for k in d if k.upper().startswith('FORCE_PRO')]
if bad:
    print(','.join(bad)); sys.exit(1)
"; then
  ok "dart-defines has no FORCE_PRO_* (production-safe)"
else
  fail "dart-defines.json contains FORCE_PRO_* — omit that for Play builds"
fi

VERSION_LINE="$(python3 -c "
import re
t=open('pubspec.yaml').read()
m=re.search(r'^version:\s*([0-9.]+)\+(\d+)\s*$', t, re.M)
if not m: raise SystemExit('pubspec.yaml has no version: x.y.z+N')
print(m.group(1)+' '+m.group(2))
")"
VERSION_NAME="${VERSION_LINE%% *}"
VERSION_CODE="${VERSION_LINE##* }"
ok "version $VERSION_NAME+$VERSION_CODE track=$TRACK status=$STATUS"

NOTES="$(python3 -c "
from pathlib import Path
p=Path('marketting/forms/whats-new.txt')
print(p.read_text().strip()[:500] if p.is_file() else '')
")"

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  ok "building signed app bundle (this takes several minutes)"
  flutter build appbundle --release --dart-define-from-file="$DEFINES"
else
  ok "skipping build"
fi

[[ -f "$AAB" ]] || fail "AAB missing: $AAB"
ok "AAB $(ls -lh "$AAB" | awk '{print $5, $9}')"

"$ROOT/scripts/scan_release_secrets.sh" "$AAB"

if [[ ! -x "$VENV/bin/python" ]]; then
  ok "creating Play API venv at $VENV"
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install --quiet 'google-auth>=2.0' 'requests>=2.0'
fi

ok "uploading to Play track=$TRACK"
"$VENV/bin/python" "$ROOT/scripts/_play_upload.py" \
  --aab "$AAB" \
  --package "$PACKAGE" \
  --track "$TRACK" \
  --status "$STATUS" \
  --version-name "$VERSION_NAME" \
  --version-code "$VERSION_CODE" \
  --notes "$NOTES" \
  --sa-json "$SA_JSON"

ok "done. Testers: Play Console → Sisu Mate → Test and release → Internal testing → Testers"
