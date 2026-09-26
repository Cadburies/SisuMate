title: Sync status
desc: Shows whether the boat's data is syncing: connection, items waiting to upload, conflicts and last success or failure.
layer: ux
keywords: sync, status, outbox, pending, upload, cloud, connection, flush
kind: screen
looks: "Sync Status" screen with Connection, Pending outbox, By priority and By table sections and a "Force flush queue" button.
reach: tip:Menu > text:Sync Status
needs: -
action: Shows sync health; Refresh updates it and "Force flush queue" retries uploads now.
expect: "Pending outbox" and "Force flush queue" are shown.
uses: system/sync/outbox
script: home
source: lib/ui/settings/sync_status_screen.dart (SyncStatusScreen)
