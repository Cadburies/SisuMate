title: Store releases
desc: Builds and uploads signed Android (Play) and iOS (TestFlight / App Store) releases; tester tracks get time-limited Pro.
layer: ops
keywords: release, play store, app store, testflight, upload, build
kind: script
looks: -
reach: run scripts/play_release.sh (default internal track) or scripts/appstore_release.sh (default TestFlight) — only when asked
needs: -
action: Signs with gitignored secrets and uploads; never submits for App Review automatically.
expect: The build appears on the chosen track.
uses: -
script: -
source: scripts/play_release.sh; scripts/appstore_release.sh; scripts/_play_upload.py
