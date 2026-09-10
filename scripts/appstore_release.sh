#!/usr/bin/env bash
# Build a signed iOS IPA and upload it to App Store Connect (TestFlight).
#
# Usage:
#   ./scripts/appstore_release.sh --test
#   ./scripts/appstore_release.sh
#   ./scripts/appstore_release.sh --track testflight
#   ./scripts/appstore_release.sh --track testflight --skip-build
#   ./scripts/appstore_release.sh --track appstore   # same upload; review submit stays in Console
#
# Requires (gitignored):
#   secrets/appstore-connect.json   (issuer_id + key_id)
#   secrets/AuthKey_<key_id>.p8     (App Store Connect API key)
#   dart-defines.json               (FORCE_PRO_* must not live in this file.
#                                    TestFlight injects FORCE_PRO_UNTIL for 2026.)
#
# Issuer ID: App Store Connect → Users and Access → Integrations → App Store Connect API
#   https://appstoreconnect.apple.com/access/integrations/api
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TRACK=testflight
SKIP_BUILD=0
TEST_ONLY=0
DEFINES="$ROOT/dart-defines.json"
ASC_JSON="$ROOT/secrets/appstore-connect.json"
EXPORT_PLIST="$ROOT/ios/ExportOptions-appstore.plist"
IPA=""
KEYS_DIR="$HOME/.appstoreconnect/private_keys"
VENV="${PLAY_API_VENV:-/tmp/play-api-venv}"

usage() {
  sed -n '2,16p' "$0"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --track) TRACK="${2:?}"; shift 2 ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    --test) TEST_ONLY=1; shift ;;
    --ipa) IPA="${2:?}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown arg: $1" >&2; usage ;;
  esac
done

fail() { echo "appstore_release FAIL: $*" >&2; exit 1; }
ok() { echo "appstore_release: $*"; }

[[ -f "$ASC_JSON" ]] || fail "missing $ASC_JSON — copy issuer_id + key_id (see secrets/README.md)"
[[ -f "$DEFINES" ]] || fail "missing dart-defines.json"

ISSUER_ID="$(python3 -c "import json; print(json.load(open('$ASC_JSON')).get('issuer_id','').strip())")"
KEY_ID="$(python3 -c "import json; print(json.load(open('$ASC_JSON')).get('key_id','').strip())")"
BUNDLE_ID="$(python3 -c "import json; print(json.load(open('$ASC_JSON')).get('bundle_id','com.sailingsisu.sisumate').strip())")"
TEAM_ID="$(python3 -c "import json; print(json.load(open('$ASC_JSON')).get('team_id','D6WY6A2237').strip())")"

[[ -n "$KEY_ID" ]] || fail "secrets/appstore-connect.json is missing key_id"
P8="$ROOT/secrets/AuthKey_${KEY_ID}.p8"
[[ -f "$P8" ]] || fail "missing $P8 (App Store Connect API private key)"

if [[ -z "$ISSUER_ID" ]]; then
  fail "secrets/appstore-connect.json issuer_id is empty.
Paste the Issuer ID from:
  https://appstoreconnect.apple.com/access/integrations/api
(Users and Access → Integrations → App Store Connect API — UUID at the top of the page)."
fi

if python3 -c "
import json,sys
d=json.load(open('$DEFINES'))
bad=[k for k in d if k.upper().startswith('FORCE_PRO')]
if bad:
    print(','.join(bad)); sys.exit(1)
"; then
  ok "dart-defines has no FORCE_PRO_* (file stays production-safe)"
else
  fail "dart-defines.json contains FORCE_PRO_* — keep it out of the file; TestFlight injects it on the command line"
fi

TESTER_PRO_UNTIL="2026-12-31T23:59:59Z"
TESTER_DEFINE=""
case "$TRACK" in
  testflight)
    TESTER_DEFINE="--dart-define=FORCE_PRO_UNTIL=$TESTER_PRO_UNTIL"
    ok "tester Pro grant until $TESTER_PRO_UNTIL"
    ;;
  appstore)
    ok "appstore track — no FORCE_PRO_UNTIL (review binary)"
    ;;
esac

VERSION_LINE="$(python3 -c "
import re
t=open('pubspec.yaml').read()
m=re.search(r'^version:\s*([0-9.]+)\+(\d+)\s*$', t, re.M)
if not m: raise SystemExit('pubspec.yaml has no version: x.y.z+N')
print(m.group(1)+' '+m.group(2))
")"
VERSION_NAME="${VERSION_LINE%% *}"
VERSION_CODE="${VERSION_LINE##* }"
ok "version $VERSION_NAME+$VERSION_CODE track=$TRACK bundle=$BUNDLE_ID key=$KEY_ID"

mkdir -p "$KEYS_DIR"
install -m 600 "$P8" "$KEYS_DIR/AuthKey_${KEY_ID}.p8"
ok "installed API key at $KEYS_DIR/AuthKey_${KEY_ID}.p8"

if [[ "$TEST_ONLY" -eq 1 ]]; then
  ok "testing App Store Connect API credentials"
  xcrun altool --list-apps --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID" --output-format json
  ok "credentials OK"
  exit 0
fi

if [[ -z "$IPA" ]]; then
  IPA="$(ls -1 "$ROOT"/build/ios/ipa/*.ipa 2>/dev/null | head -1 || true)"
fi

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  ok "building signed IPA (this takes several minutes)"
  flutter build ipa --release \
    --dart-define-from-file="$DEFINES" \
    $TESTER_DEFINE \
    --export-options-plist="$EXPORT_PLIST"
  IPA="$(ls -1 "$ROOT"/build/ios/ipa/*.ipa 2>/dev/null | head -1 || true)"
else
  ok "skipping build"
fi

[[ -n "$IPA" && -f "$IPA" ]] || fail "IPA missing under build/ios/ipa/"
ok "IPA $(ls -lh "$IPA" | awk '{print $5, $9}')"

"$ROOT/scripts/scan_release_secrets.sh" "$IPA"

ok "uploading to App Store Connect (TestFlight processing)"
xcrun iTMSTransporter -m upload \
  -assetFile "$IPA" \
  -apiKey "$KEY_ID" \
  -apiIssuer "$ISSUER_ID" \
  -v informational

ok "uploaded $BUNDLE_ID $VERSION_NAME+$VERSION_CODE"
if [[ ! -x "$VENV/bin/python" ]]; then
  ok "creating API venv at $VENV"
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install --quiet 'google-auth>=2.0' 'requests>=2.0' 'PyJWT[crypto]>=2.0'
fi
ok "assigning Frik's Testers + What to Test (waits for Apple processing)"
"$VENV/bin/python" "$ROOT/scripts/_tester_notify.py" \
  --platform ios --version-code "$VERSION_CODE"
ok "Testers: App Store Connect → Sisu Mate → TestFlight"
if [[ "$TRACK" == "appstore" ]]; then
  ok "App Store review is not submitted automatically. In Console: App Store → + version → select this build → Submit for Review."
fi
