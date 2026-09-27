title: Inbound realtime changes
desc: Changes made on another device of the same boat arrive by realtime subscription and are applied to the local database.
layer: sync
keywords: inbound, realtime, other device, crew edits, apply
kind: job
looks: -
reach: realtime events from Supabase while sync is running
needs: -
action: Maps each inbound row to its local table and upserts it, detecting conflicts with unsynced local edits.
expect: A crew member's edit shows on the captain's phone within seconds.
uses: system/sync/conflicts
script: test/inbound_sync_tables_test.dart
source: lib/services/inbound_sync_applier.dart (InboundSyncApplier)
