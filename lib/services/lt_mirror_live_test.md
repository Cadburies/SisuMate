# LT1–LT4 — Dual-device mirror live testing

Offline-first boat sync QA: one **driver** mutates data; one **mirror** must
show the same records after Supabase sync. Complements the offline-conflict
smoke test in `sync_conflict_2device_setup.md` (SUG2/T5).

| ID | Focus |
| --- | --- |
| **LT1** | Infra: both devices running, same Pro boat, home reachable |
| **LT2** | Module CRUD create → mirror → edit → mirror → delete → mirror clear |
| **LT3** | Side actions on the **same** record before delete (complete, shopping, …) |
| **LT4** | Test like a user: one marker name per module, reused; no delete-recreate shortcut |

## Devices (defaults)

| Role | Platform | Default id |
| --- | --- | --- |
| Driver | Android phone | `R5CX2036L1F` |
| Mirror | iOS Simulator | `43C4A261-F7F0-47FE-AC5B-C5313F7DFBEF` (iPhone 16 Plus) |

Override: pass serial/udid as args to the scripts.

**Dual-iOS** (recommended for unattended runs): both sims unlocked, same Pro boat:

```bash
bash scripts/lt_module_crud_sweep.sh \
  DCC47B42-BE62-4EBD-A6F2-B8A7E4C3A6D2 \
  43C4A261-F7F0-47FE-AC5B-C5313F7DFBEF \
  shopping
```

**Android lock screen:** secure lock blocks `adb` automation. Keep the phone unlocked, or use dual-iOS.

## Prerequisites

1. App installed on both devices (debug build with `dart-defines.json`).
2. Both **unlocked**, Pro, signed into the **same boat** (status strip shows
   Pro/Online and the same boat name).
3. From scratch: create boat on owner → drawer ▸ Share this boat → join on
   second device (or `bash scripts/supabase_cli.sh owner-select boats …`).
4. iOS: `idb` + companion (see `liars_dice/live_test_setup.md`).
5. Android: `adb` device online.

## Commands

```bash
# LT1 — bootstrap harness
bash scripts/lt_mirror_harness.sh
# optional: bash scripts/lt_mirror_harness.sh R5CX2036L1F 43C4A261-…

# LT2–LT4 — full module sweep
bash scripts/lt_module_crud_sweep.sh

# Single module
bash scripts/lt_module_crud_sweep.sh R5CX2036L1F 43C4A261-… shopping
```

Shared UI helpers: `scripts/lt_ui_helpers.sh` (sourced by both scripts).

Results + screenshots land under:

`${TMPDIR:-/tmp}/sisumate/lt*_result.txt`

## Module coverage

| Module | Flow | Live status (dual-iOS, 2026-07-30) |
| --- | --- | --- |
| Shopping | Full CRUD + Bought side action | **Full green** (Hide→Delete + mirror) |
| Inventory | Full CRUD + Add to shopping | **Full green** (hard-delete mirror via stream reconcile) |
| Crew & Contacts | Full CRUD | **Full green** |
| Documents | Full CRUD | **Full green** |
| Fuel & Water | Notes-as-title when set + volume create | **Full green path** (list title = notes for LT marker) |
| Captain's Log | Full CRUD | Catalog only — not re-run this pass |
| Safety / Maintenance / Checklists | Open + complete side action | Catalog only |
| Cocktails / Chef | Manual nested UI | Manual |

**Harness notes:** Flutter ListView keeps off-screen a11y nodes at 0×0 — use scroll-until-tappable. Avoid marker suffix `Inv` (iOS autocorrects to `Inc`).

## LT4 rule

For list modules the sweep uses **one** timestamped marker (`LT-<epoch>-Shop`)
and **edits that same row** before delete. It must never create a second row
just to exercise edit/delete.

## Troubleshooting

- **Mirror never sees create:** confirm both on same `activeBoatSupabaseId`,
  Pro, Online; check drawer ▸ Sync Status for outbox failures; wait for the
  30s queue monitor.
- **FAB not found:** layout changed — adjust size bounds in
  `and_tap_fab` (`lt_ui_helpers.sh`).
- **Delete path missing:** some modules use swipe-to-delete only; clean up
  the `LT-*-` marker manually and file a UI accessibility gap if needed.
- **iOS idb NOTFOUND:** restart companion; use
  `idb ui describe-all --udid <udid>` to see live labels.
- **PIN lock on phone:** unlock by hand; `wm dismiss-keyguard` only clears
  swipe locks.

## Relation to other scripts

| Script | Purpose |
| --- | --- |
| `lt_mirror_harness.sh` | LT1 bootstrap |
| `lt_module_crud_sweep.sh` | LT2–LT4 sweep |
| `sync_conflict_2device_setup.sh` | Offline edit conflict (SUG2) — different scenario |
| `mp_multiseat_stress_setup.sh` | Games multi-seat (LT6) — not boat sync |
