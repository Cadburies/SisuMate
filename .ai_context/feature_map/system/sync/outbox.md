title: Sync outbox
desc: Every local change is queued with a priority and uploaded when online; failures retry, deletes are queued too; the queue survives restarts.
layer: sync
keywords: outbox, queue, upload, retry, pending, offline changes
kind: job
looks: -
reach: any repository write while sync is eligible; drains every 30 s and when connectivity returns
needs: -
action: Uploads queued rows in priority order, records successes and failures for the Sync Status screen.
expect: Pending count falls to 0 once online; the title bar shows "Syncing (N)" meanwhile.
uses: system/sync/wire_prefix
script: test/sync_service_test.dart
source: lib/services/sync_service.dart (SyncService)
