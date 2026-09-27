title: Shopping repository
desc: Stores shopping categories and items: add, mark bought, hide/soft-delete, permanent delete, pack merging from recipes, and outbox queuing for sync.
layer: db
keywords: shopping, repository, items, bought, hidden, packs
kind: repo
looks: -
reach: every Shopping screen action and "add missing to shopping" from Chef/Cocktails/Maintenance
needs: -
action: Writes Drift rows and enqueues sync when the boat is sync-eligible.
expect: The screen reflects each change immediately from the database stream.
uses: system/sync/outbox
script: test/shopping_screen_integration_test.dart
source: lib/data/repositories/shopping_repository_impl.dart
