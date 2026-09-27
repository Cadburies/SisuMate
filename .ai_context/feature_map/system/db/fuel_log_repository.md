title: Fuel log repository
desc: Stores fuel and water fills and feeds the totals and burn estimate.
layer: db
keywords: fuel, water, repository, fills, log
kind: repo
looks: -
reach: Fuel & Water add, edit and delete
needs: -
action: Persists fills per boat and streams them to the Fuel screen.
expect: Totals and burn estimate update after each change.
uses: system/sync/outbox
script: test/fuel_screen_integration_test.dart
source: lib/data/repositories/fuel_log_repository_impl.dart
