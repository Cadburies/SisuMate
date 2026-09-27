title: Sync conflict detection and resolution
desc: When the same record was edited on two devices offline, both versions are kept as a conflict with a field-by-field diff until someone chooses.
layer: sync
keywords: conflict, merge, offline edits, two devices, resolve
kind: service
looks: -
reach: inbound change for a row that also has an unsynced local edit
needs: -
action: Builds a diff report and merges non-overlapping fields; overlapping ones wait in Sync Conflicts.
expect: Conflicts appear in Sync Conflicts; resolving writes the chosen version everywhere.
uses: -
script: test/conflict_resolution_test.dart
source: lib/services/conflict_resolution_service.dart (ConflictResolutionService, ConflictDiffReport)
