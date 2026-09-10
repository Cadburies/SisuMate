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
