title: Database problem on launch
desc: If the local database is damaged or from an incompatible version, Sisu Mate offers to reset it to the bundled content.
layer: ux
keywords: corrupt, database, reset, crash on start, broken, recover
kind: dialog
looks: "Database Problem" dialog over the splash screen with a red Reset button.
reach: -
needs: platform=device
action: Reset deletes the local database and restores all bundled checklists, schedules and recipes. Your own additions are lost.
expect: After Reset the app continues to Home; if the database is still broken the dialog shows again.
uses: system/db/startup_init
script: test/startup_lifecycle_test.dart
source: lib/ui/startup/startup_screen.dart (_showCorruptionDialog)
