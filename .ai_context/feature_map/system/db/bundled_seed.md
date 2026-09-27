title: Bundled content seed
desc: Loads the bundled checklists, safety briefings, Yanmar service schedules, shopping categories and recipes into the local database, plus the deferred pantry/bar catalog after Home appears.
layer: db
keywords: seed, bundled data, catalog, checklists, recipes, pantry, bar, first run
kind: job
looks: -
reach: first launch (base seed) and every launch after Home (deferred catalog diff-insert)
needs: -
action: Base seed once; expansion catalog adds any newly shipped rows without touching user flags.
expect: Every core module has content; seeding twice creates no duplicates.
uses: -
script: test/seed_bundled_data_test.dart
source: lib/data/seed/bundled_data_seeder.dart (seedBundledData); lib/data/seed/seed_expansion_catalog.dart (seedExpansionCatalog)
