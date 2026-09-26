title: Sync conflicts
desc: Lists records that were edited on two devices while offline, so you can choose which version to keep.
layer: ux
keywords: conflicts, sync, merge, duplicate edits, offline, resolve
kind: screen
looks: "Sync Conflicts" screen; empty state reads "No pending conflicts."
reach: tip:Menu > text:Sync Conflicts
needs: -
action: Open a conflict to keep this device's copy, the other copy, or merge.
expect: "No pending conflicts." on a fresh install.
uses: system/sync/conflicts
script: home
source: lib/ui/conflicts/conflict_resolution_screen.dart (ConflictResolutionScreen)
