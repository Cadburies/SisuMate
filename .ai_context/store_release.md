# Store release (Play + App Store)

Agent-facing. Identity, secrets, and commands to ship a build. Do **not** submit Play production or App Review unless the user explicitly asks.

**Identity**

| | |
| --- | --- |
| Application / bundle id | `com.sailingsisu.sisumate` |
| Version | `pubspec.yaml` `version:` (`1.0.0+3` → name `1.0.0`, code `3`) |
| Apple team | `D6WY6A2237` (Automatic signing) |
| Play package | same as application id |

Bump `version:` (especially `+N`) before a second upload of the same binary identity. Play and Apple both reject reuse of a version code / CFBundleVersion.

## Commands

```bash
# Play — default internal testing
./scripts/play_release.sh --track internal
./scripts/play_release.sh --track internal --skip-build   # reuse existing AAB

# App Store Connect — default TestFlight (does not submit for review)
./scripts/appstore_release.sh --test                      # API key only
./scripts/appstore_release.sh --track testflight
./scripts/appstore_release.sh --track testflight --skip-build
```

`--track production` (Play) or `--track appstore` (iOS) still **uploads** only. Play production rollout and App Store “Submit for Review” stay Console clicks.

Both scripts: `--dart-define-from-file=dart-defines.json`, SEC3 scan, never copy credentials into `assets/`.

## Tester Pro (2026)

The next store uploads are **tester builds**. Play `internal`/`alpha`/`beta` and App Store `testflight` **must** grant full Pro until **2026-12-31T23:59:59Z**.

The scripts inject that themselves:

`--dart-define=FORCE_PRO_UNTIL=2026-12-31T23:59:59Z`

Keep `FORCE_PRO_*` **out of** `dart-defines.json` (that file is production credentials). Production / App Store review builds (`--track production` / `--track appstore`) must **not** get the define — the scripts refuse it in the json file and do not inject it.

`kForceProForTesting` only affects **debug** `flutter run`. Release tester APK/IPA/AAB need the dart-define.

## Required local files (all gitignored)

| File | Role |
| --- | --- |
| `dart-defines.json` | Production keys. Must **not** contain `FORCE_PRO_*` (that is tester-IPA only). |
| `secrets/google-play-service-account.json` | Play Android Developer API. Email must be `sisu-mate-ai@sisu-mate.iam.gserviceaccount.com` — refuse leftover `boatchecks@…`. |
| `android/key.properties` | Upload-key passwords; `storeFile` → `~/keystores/sisumate/sisumate-upload.jks` (outside git). |
| `secrets/appstore-connect.json` | `issuer_id`, `key_id`, `bundle_id`, `team_id`. |
| `secrets/AuthKey_<key_id>.p8` | App Store Connect API private key. Script copies it to `~/.appstoreconnect/private_keys/`. |

`secrets/**` is gitignored except `secrets/README.md`. Never commit `.p8`, Play SA JSON, `key.properties`, or `client_secret*.json`.

## After a successful upload

- **Play internal:** Console → Sisu Mate → Test and release → Internal testing → Testers (add Gmail / Google Group). Opt-in link; not public.
- **TestFlight:** App Store Connect → Sisu Mate → TestFlight. Apple processes 5–30 min, then Internal Testing. External testing needs Beta App Review.
- Flutter may warn that the iOS **launch image is the default placeholder** — not a TestFlight blocker; replace before App Review.

## If credentials are missing / 403

**Play 403 “The caller does not have permission”:** the JSON is valid but Play Console has not granted the SA. Invite `sisu-mate-ai@sisu-mate.iam.gserviceaccount.com` at [Users and permissions](https://play.google.com/console/developers/users-and-permissions) (account-level page — **not** inside the Sisu Mate app, **not** Google Cloud IAM). Account permissions → Admin (all permissions). Wait a few minutes.

**App Store `--test` fails:** paste Issuer ID from [App Store Connect API keys](https://appstoreconnect.apple.com/access/integrations/api) into `secrets/appstore-connect.json`. Key needs App Manager (or Admin).

Do not create an Android OAuth Client ID / SHA-1 for store upload. This app does not use Google Sign-In; SHA-1 is unrelated to Play API or TestFlight.

## First-time setup (already done on this machine; redo only if keys were rotated)

1. Play: GCP project `sisu-mate` → enable **Google Play Android Developer API** → service account JSON → invite that email in Play Console.
2. Apple: App Store Connect → Integrations → App Store Connect API → key + Issuer ID + `.p8`.
3. Android upload keystore already at `~/keystores/sisumate/sisumate-upload.jks`. Do not generate a second one. Play App Signing stays on; local `.jks` is the *upload* key.
4. Closed Boat Checks Play account is dead. Never upload a `com.sailingsisu.boatchecks` artifact or use a `boatchecks@` SA.

## Implementation

- Play: `scripts/play_release.sh` + `scripts/_play_upload.py`
- iOS: `scripts/appstore_release.sh` + `ios/ExportOptions-appstore.plist`
- Secret-scan: `scripts/scan_release_secrets.sh`
- More path notes: `secrets/README.md`
