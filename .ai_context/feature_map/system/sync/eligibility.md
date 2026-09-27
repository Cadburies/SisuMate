title: When sync runs
desc: Cloud sync starts only for Pro owners or anonymous crew who joined a boat; Free single-device users stay fully local.
layer: sync
keywords: sync, eligibility, pro, crew, start, realtime
kind: service
looks: -
reach: app start after Home, after a Pro purchase, or after joining a boat as crew
needs: -
action: ensureStarted checks eligibility and settings, then starts the queue monitor, connectivity listener and realtime subscriptions.
expect: Free users never start sync; Pro owners and crew do.
uses: system/pro/revenuecat, system/auth/join_boat
script: test/sync_service_test.dart
source: lib/services/sync_service.dart (SyncService)
