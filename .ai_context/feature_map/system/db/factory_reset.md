title: Factory reset
desc: Restores bundled content to its original state (and wipes user rows where required), keeping the app usable offline.
layer: db
keywords: factory reset, restore, wipe, baseline
kind: service
looks: -
reach: menu Reset to Factory or Settings Factory Reset, after confirmation
needs: -
action: Clears tables and reseeds, or resets bundled rows to the factory baseline.
expect: Bundled checklists and schedules are back to their shipped state.
uses: system/db/bundled_seed
script: test/factory_reset_test.dart
source: lib/core/factory_reset.dart; lib/services/database_service.dart (markFactoryBaseline)
