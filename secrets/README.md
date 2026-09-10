# Secrets (local / CI only)

**Never** put credentials under `assets/` or list them in `pubspec.yaml` `flutter.assets`.
Flutter packages those paths into every APK/IPA; anyone can extract them from the install.

## Google Play service account (SEC1)

| | |
| --- | --- |
| Local path | `secrets/google-play-service-account.json` (gitignored) |
| Used for | Play Console upload / Fastlane supply / CI release — **host machine only** |
| Not used by | The Flutter app runtime (no `rootBundle` / Dart import) |

### CI / release

Local upload: `./scripts/play_release.sh --track internal` (see script header). The JSON must belong to the current Sisu Mate Play account (`sisu-mate-ai@…`), never the closed Boat Checks SA.

1. Store the JSON as a CI secret (GitHub Actions secret, Codemagic env file, etc.).
2. Write it to a path **outside** `assets/` at job start, e.g. `$RUNNER_TEMP/play-sa.json`.
3. Point your upload tool at that path (`GOOGLE_APPLICATION_CREDENTIALS`, Fastlane `json_key`, …).
4. Do not copy the file into `assets/` or commit it.

### After SEC1

If this key was ever listed under `flutter.assets`, treat prior debug/release builds as
having leaked it: **rotate the Play service-account key** in Google Cloud / Play Console
and update the local/CI secret copy.

## App Store Connect API key

| | |
| --- | --- |
| Local path | `secrets/AuthKey_<KEY_ID>.p8` + `secrets/appstore-connect.json` (gitignored) |
| Used for | `scripts/appstore_release.sh` — TestFlight / App Store Connect upload |
| Not used by | The Flutter app runtime |

`appstore-connect.json` fields: `issuer_id` (UUID from the API Keys page), `key_id`, `bundle_id`, `team_id`.

Issuer ID: [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api) — UUID at the top of the page.

Local upload: `./scripts/appstore_release.sh --track testflight` (default). `--track appstore` still only **uploads** the IPA; submitting for App Review stays a Console click. `--test` checks the key without building.
