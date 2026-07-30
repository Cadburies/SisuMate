# Two-device sync-conflict live test (SUG2 / T5)

Companion to `scripts/sync_conflict_2device_setup.sh`. Background, mechanics,
and troubleshooting for the offline-edit-conflict smoke test — read this
before rerunning the script if something doesn't match.

## What it proves

Two devices sync the same boat. One edits a shared record offline; the other
edits the *same* record online (so the remote row moves on). When the first
device reconnects, its stale queued edit must **not** silently overwrite the
newer remote edit — it must surface in Settings ▸ Sync Conflicts for the user
to resolve.

## Setup this assumes

- Both devices already installed, unlocked, and signed in to the **same**
  boat (Pro owner and/or anonymous crew — identity doesn't matter, only that
  `activeBoatSupabaseId` matches on both). If starting from scratch: create
  the boat account on one device (drawer ▸ "Boat account"), then join it on
  the second via drawer ▸ "Join a boat" with the share code (drawer ▸ "Share
  this boat" on the owner's device, or `bash scripts/supabase_cli.sh
  owner-select boats "select=shareCode"`).
- Prefer an **emulator** as the device whose network gets toggled — the
  script uses `adb shell svc wifi/data disable`, which you don't want run
  against a real phone's actual connectivity.

## Why an emulator, not two emulators or two phones

Nothing about the scenario requires a specific platform pairing — it only
needs one device that stays online and one whose connectivity can be safely
toggled off/on. Adjust the two serials passed as args if your setup differs.

## The three bugs this test caught (2026-07-22)

Running this scenario for the first time surfaced three real defects in
`sync_service.dart`, since fixed:

1. **Outbox push never conflict-checked.** `_processOutgoingQueue()` blindly
   `.upsert()`ed queued offline edits with no check against the record's
   current remote state — conflict detection only existed on the *inbound*
   realtime path. A stale offline edit would silently clobber a newer remote
   edit with **no conflict logged and no data-loss protection**. Fixed by
   `_outboxItemConflicts()`: before each outbox push, fetch the current
   remote row and compare `lastModified`; if remote is newer, record a
   conflict and drop the push instead of overwriting.

2. **`lastModified` timezone mismatch.** `DateTime.now()` (local time, no
   `.toUtc()`) was used at ~74 call sites across models/repositories/services
   for `lastModified` stamps. `.toIso8601String()` on a local `DateTime`
   carries no offset marker, so Postgres (and any later
   `DateTime.tryParse(...)` of that string) treats it as if it were already
   UTC — silently skewing the stored instant by the device's real UTC offset.
   On a device in AST (UTC−4), this produced a ~4-hour comparison error,
   enough to make bug #1's conflict check (and the pre-existing inbound
   `evaluate()` path) compare timestamps incorrectly for any user not in
   UTC+0. Fixed by using `DateTime.now().toUtc()` everywhere `lastModified`
   is stamped.
   - **Note:** rows written *before* this fix have their `lastModified`
     mistagged (naive local time labeled UTC). No backfill was attempted —
     old rows will read with an incorrect offset until next touched.

3. **Online deletes never actually deleted.** `queueOutgoingChange()`'s
   *online* branch called `.upsert()` unconditionally, ignoring the
   `isDelete` flag entirely (only the offline/outbox path branched on it
   correctly). Deleting a record while online — the common case — silently
   no-opped instead of removing the remote row. Fixed by branching on
   `isDelete` in the online path too, calling `.delete()` instead of
   `.upsert()`.

If this script ever again shows "FAIL: no conflict card found," suspect a
regression in #1 or #2 first — check `_outboxItemConflicts` still runs before
the upsert, and that `lastModified` timestamps in a fresh `Sync Status` dump
carry a `Z`/`+00:00` suffix.

## Troubleshooting

- **Tap on the FAB does nothing / "NOTFOUND: no FAB-shaped node":** Flutter's
  Add-Item FAB carries no accessible label, so it's found by a bottom-right,
  roughly-56dp-square heuristic (`tap_fab` in the script). If the Shopping
  screen's layout changes size/position of the FAB meaningfully, adjust the
  size bounds (`100`–`300` px) in that function.
- **New item not visible after adding:** it lands in a collapsed category
  (usually "Spares") — the script expands it via `tap_by_desc_prefix`, but if
  your item's origin/category differs, expand the right one manually.
- **"No pending conflicts" after reconnect, even after the fix:** give it
  longer — the queue monitor ticks every 30s (`_startQueueMonitor` in
  `sync_service.dart`), plus the connectivity-change listener fires an
  immediate flush attempt on reconnect. 30–40s total is usually enough; if
  not, check `Sync Status` (drawer) for `Pending outbox` / `Last failure` to
  see if the push is erroring out instead of just being slow.
- **`replace_topmost_field` clears the wrong field:** it assumes the Name
  field is the topmost `EditText` on screen, true for both the Add Item
  dialog and the item detail Edit screen as of this writing. If a screen ever
  puts something else above the Name field, this breaks — verify with a raw
  `adb exec-out uiautomator dump /dev/tty` first.
- **PIN-locked physical device:** `adb shell wm dismiss-keyguard` only
  bypasses a *non-secure* (swipe) lock. If a real PIN/pattern is set (this
  can appear after an idle timeout even on a device that previously unlocked
  freely), the script cannot proceed — unlock it by hand first.

## Cleanup

The script leaves the conflict **unresolved** on purpose (so you can inspect
the "Keep mine" / "Keep cloud" UI yourself) and does not delete the test item
it created. Clean up manually: open the item ▸ Hide ▸ Delete on either
device once you're done. If a raw item is ever orphaned server-side (e.g. a
delete was attempted against a pre-fix build), it can be removed directly:
```
supabase execute_sql: delete from shopping_items where "supabaseId" = '<boatGuid>::<localId>';
```
