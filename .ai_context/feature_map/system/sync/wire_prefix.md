title: Wire prefix (boat-scoped IDs)
desc: Rows are sent to the cloud with a boat-scoped ID prefix so data from different boats never collides and crew see only their boat.
layer: sync
keywords: wire prefix, ids, boat scope, namespacing, restamp
kind: service
looks: -
reach: every upload and inbound apply
needs: -
action: Adds or strips the boat prefix when rows cross the wire; crew join restamps local rows to the captain's boat.
expect: Round-tripping an ID through the prefix is lossless.
uses: -
script: test/wire_prefix_test.dart
source: lib/services/wire_prefix.dart (WirePrefix)
