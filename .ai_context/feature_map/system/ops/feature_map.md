title: Feature Map tooling
desc: Lint, find, path, touches/overlap for the Feature Map, the host reach executor, and the fm.sh runner for host or device.
layer: ops
keywords: feature map, lint, reach, fm.sh, touches, parallel agents
kind: script
looks: -
reach: dart run tool/feature_map.dart lint|find|path|touches|overlap; scripts/fm.sh <id> [--reach] [--device <id>]
needs: -
action: Keeps every feature file's pointers and reach steps verified in the suite.
expect: "feature map: 0 errors".
uses: -
script: test/feature_map_lint_test.dart
source: tool/feature_map.dart; scripts/fm.sh; scripts/fm_device_reach.sh; test/feature_map/_reach.dart
