---
name: device-evidence
description: Use when a change is visible on a phone (UI, navigation, ads, permissions, LAN games, crash fixes) and you need to prove it works on a real device or sim — before claiming done or when the user asks to "check it on the phone". Before/after captures on both iOS and Android.
---

# Device evidence

Idea from michaelshimeles/skills `evidence-driven-testing`, rewritten for SisuMate's device scripts. Host tests prove logic; this proves what the user sees.

**Rule:** a device claim needs a capture from **both** platforms, tied to the commit you tested. iOS-only launch crashes have been missed before. A screenshot alone is not proof for state bugs: pair it with the log line or `lsof`/console output that shows the state.

## Steps

1. **Pin it.** Note `git rev-parse --short HEAD` and whether the tree is dirty. Every capture is labelled with this.
2. **Before** (bugs only): reproduce the failure on the old build and capture it. A fix shown without the failure next to it isn't evidence.
3. **Run:** `scripts/android_run.sh <serial>` / `scripts/ios_run.sh <udid>`, then `scripts/wait_for_flutter.sh <logfile>`. Note the pid they print, and stop **only that pid** (`kill <pid>`), never `stop_flutter.sh` in the shared tree.
4. **Reach the feature** by meaning, not pixels:
   - `scripts/fm.sh <id> --device <serial|udid>` if it's in the Feature Map (`dart run tool/feature_map.dart find <word>`)
   - otherwise `scripts/adb_tap_text.sh` / `scripts/idb_tap_label.sh`, and `scripts/adb_swipe_reveal_action.sh` for swipe actions
5. **Capture after** to an absolute path under `/tmp/evidence/<issue>/`:
   - Android: `scripts/screencap.sh <serial> /tmp/evidence/<N>/android_after.png`
   - iOS Simulator: `xcrun simctl io <udid> screenshot /tmp/evidence/<N>/ios_after.png`
   - Open and look at every image yourself before citing it.
6. **Report** in the issue comment: the commit, the devices (model/OS), what each capture shows, the log lines, and anything **not** tested ("iPad not checked", "Pro path only").

## Multiplayer and other special cases

- LAN games: iOS Sim + real phone, never an Android emulator (NAT). Harnesses: `liars_dice_4sim_setup.sh`, `test18_rc_play.sh`.
- Ads: `test20_admob_smoke.sh` (needs `kForceProForTesting = false` for the run; flip it back).
- Permissions/cold resume: `test19_permissions_smoke.sh`. Perf: `test21_perf_smoke.sh`.

## Never

Capture secrets, real user data, or the contents of `dart-defines.json`. Don't post a capture you haven't looked at.
