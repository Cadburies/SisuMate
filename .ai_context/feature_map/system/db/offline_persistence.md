title: Offline persistence
desc: Everything is saved locally first; data survives the app being killed and relaunched offline, and queued changes upload later.
layer: db
keywords: offline, persistence, kill, relaunch, durable, local first
kind: service
looks: -
reach: any edit made with no connection
needs: -
action: Rows are written to the on-device database immediately; the sync outbox drains when a connection returns.
expect: After kill + relaunch offline, edits are still there and the outbox drains when online.
uses: system/sync/outbox
script: test/offline_persistence_test.dart
source: lib/services/database_service.dart (DatabaseService); lib/services/sync_service.dart (SyncService)
