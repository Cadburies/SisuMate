title: Release secret scan (SEC3)
desc: Scans pubspec, assets, lib (and a built APK/IPA when present) for leaked credentials before release.
layer: ops
keywords: secrets, credentials, scan, release, security
kind: script
looks: -
reach: first stage of the full suite; also run scripts/scan_release_secrets.sh directly
needs: -
action: Fails on private keys, service-role keys or service-account paths in shipped files.
expect: "ok" lines for each check.
uses: -
script: test/release_secrets_scan_test.dart
source: scripts/scan_release_secrets.sh
