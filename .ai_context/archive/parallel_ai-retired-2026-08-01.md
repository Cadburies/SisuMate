# Parallel AI lanes — hand-off board

> **Living file.** Both concurrent agents (Grok × Grok, Claude × Grok, etc.) read this at session start and update **Active claims** before editing.
>
> Source of open work: `.ai_context/outstanding.md` · Priority truth lives there; this file only assigns **who owns which surface**.

**Last updated:** 2026-07-30 — Grok A claimed **TEST16**; B **TEST29**

---

## Ground rules

1. **One owner per hot file** in a wave — never dual-edit the same path.
2. **Claim before code:** set your lane’s row in **Active claims** to `in_progress` + short note; clear to `idle` when done.
3. **Do not steal a claim** still marked `in_progress` unless the other agent has been idle >1 session and the user reassigns.
4. **End of task:** delete resolved outstanding rows (Rule 1), short `changelog.md` prepend, update INDEX **NEXT**, set claim → `idle`, pick next from **Wave queue**.
5. **Suite:** after product/test changes, run **`./scripts/run_full_suite.sh`** and require green (see `CLAUDE.md` §5 / `README.md` → Testing / `outstanding.md` Testing gaps). Use `--skip-live` / `--skip-integration` only when justified and **note flags in the hand-off**. Only **one** agent edits suite/SEC3 scripts per wave.
6. Session budget still applies: `.ai_context/INDEX.md` + ≤2 topical files; never load hot changelog / archive by default.

---

## Lane defaults (this wave)

| Lane | Role | Preferred work | Does **not** touch (other lane owns) |
| --- | --- | --- | --- |
| **A — Pre-launch** | Confidence / ship gates | TEST13–TEST18 (P1), later P2/P3 tests | `suggestion_engine.dart` home-banner rules, pure game AI depth unless claim says TEST18/28 |
| **B — Product / Tier 0** | Offline “wow” + small polish | GAI depth, SUG5 / TEST27 (units), weather TEST26, WirePrefix TEST25 (BAI7 done) | sync/outbox if A owns TEST13/16; crew auth if A owns TEST15 |

Either agent may take either lane — **claim the lane**, don’t assume name→lane.

---

## Active claims (edit this first)

| Lane | Agent / session note | Status | Current task | Hot files (owner only) |
| --- | --- | --- | --- | --- |
| **A** | Grok A | `in_progress` | **TEST16** conflict E2E | `conflict_resolution_*`, sync conflict tests/scripts |
| **B** | Grok B | `in_progress` | **TEST29** factory reset wipe + reseed | `database_service.dart`, `test/startup_lifecycle_test.dart` or new factory-reset test |

**Status values:** `idle` | `in_progress` | `blocked` (add one-line reason).

**Example claim row:**

| A | Grok (session …) | `in_progress` | TEST14 import round-trip | `import_service.dart`, `import_export.dart`, `test/import_*` |

---

## Recommended pair (start here)

| Lane A | Lane B | Why safe | Priority |
| --- | --- | --- | --- |
| **TEST16** — conflict E2E | **TEST25** WirePrefix fuzz | Conflict vs pure wire | **Current wave** |
| ~~TEST13–15, 17~~ shipped | ~~BAI7 / TEST26–28~~ shipped | | Done |

### Acceptance (cut for “done”)

| Task | Done when |
| --- | --- |
| **TEST13** | Kill/relaunch persistence for listed modules; outbox drain without dup/lost rows; automated tests (or harness + scripted asserts). |
| **GAI / TEST28** | Cold-game AI improved or fixed-seed same-move tests green; no lobby dual-edit with TEST18. |
| ~~TEST14~~ / ~~BAI7~~ | Shipped — see **Shipped recently**. |

---

## Strong alternate pairs

| # | Lane A | Lane B | Why safe |
| --- | --- | --- | --- |
| 2 | **TEST13** offline kill/relaunch + outbox drain (no dup/lost rows) | **GAI depth** one *cold* game (Solitaire / Uno / Yatzy / Poker / Cribbage) **or** **TEST28** AI determinism | Sync/Drift vs pure game AI — avoid Dudo/Liars/lobby if A later needs TEST18 |
| 3 | **TEST15** share-code join (invalid → clear error; valid → boat switch + stamp) | **SUG5** wind vs boat speed prefs **or** **TEST27** unit edges | Auth/enrollment vs `units.dart` — **one** owner for units only |
| 4 | **TEST17** one screen+Drift integration (checklists complete → Drift preferred) | **TEST26** weather cache stale + offline never hangs | Checklists/module UI vs `weather_service.dart` |
| 5 | **TEST16** 2-device conflict harness + assertions (`scripts/sync_conflict_2device_setup.sh`) | **TEST25** WirePrefix / boat-scoped id fuzz | Conflict scripts/UI vs `wire_prefix.dart` |

---

## Ownership map (domain → files)

| Domain | Typical owner | Key paths |
| --- | --- | --- |
| Import / export | A if **TEST14** | `lib/services/import_service.dart`, `lib/ui/components/import_export.dart`, import tests |
| Offline / outbox / kill-relaunch | A if **TEST13** | `sync_service.dart`, Drift repos, module screens used in scenario |
| 2-device conflict | A if **TEST16** | `conflict_resolution_*`, `scripts/sync_conflict_2device_setup.sh` |
| Crew join | A if **TEST15** | `auth_service.dart`, `boat_enrollment_service.dart`, join boat UI |
| Screen+Drift integrations | A if **TEST17** | `test/*_integration_test.dart` + **that module only** |
| LAN MP smoke | A if **TEST18** | LAN scripts/services, dudo/liars + lobby for that run |
| Home suggestions (BAI7) | **B only** | `lib/services/suggestion_engine.dart`, related providers, `home_screen` banner hooks, `test/suggestion_engine_test.dart` |
| Game AI depth / TEST28 | **B** (or A only if TEST18/28 claimed and B stays off games) | `lib/services/game_ai/`, per-game `helpers`/`logic` AI paths — **not** both lanes |
| Units SUG5 / TEST27 | **one lane only** | `lib/core/units.dart`, settings prefs, `test/unit_converter_test.dart` |
| Weather TEST26 | lane that claimed it | `lib/services/weather_service.dart`, weather tests |
| WirePrefix TEST25 | lane that claimed it | `lib/services/wire_prefix.dart` (or actual path), `test/wire_prefix_test.dart` |
| Suite / SEC3 scripts | **one lane per wave** | `scripts/run_full_suite.sh`, `scripts/scan_release_secrets.sh` |
| Ads / Pro / startup P0 | Prefer **leave alone** (just shipped) | admob, revenuecat, free_edit, startup lifecycle tests unless bugfix |

---

## Do not parallelize

| Pair / surface | Reason |
| --- | --- |
| TEST13 ∥ TEST16 | Both sync / outbox / multi-device headspace |
| TEST15 ∥ any other auth/session work | Single owner for enrollment |
| BAI7 ∥ TEST24 home golden | Both touch `home_screen` |
| GAI / TEST28 ∥ TEST18 LAN | Same games + lobby + LAN stack |
| SUG5 ∥ TEST27 | Same `units.dart` |
| Dual `lobby_screen.dart` rewrites | One owner |
| Dual `suggestion_engine.dart` | BAI7 serial |
| Dual `mixologist_service.dart` invent paths | Historical hot file — one owner if touched |
| Both editing suite/SEC3 scripts | Merge thrash on shared tooling |
| LLM* / ML3 with anything urgent | Still deferred (see below) |

---

## Wave queue (after current pair finishes)

Prefer order from `outstanding.md` Priority; pick a **safe pair** from the table above.

| Order | A (pre-launch) | B (product / polish) |
| --- | --- | --- |
| 1 (done) | **TEST14** ✓ | **BAI7** ✓ |
| 2 | **TEST13** ✓ | **TEST28** ✓ |
| 3 | **TEST15** ✓ | **TEST27** ✓ |
| 4 | **TEST17** ✓ checklists complete→Drift | **TEST26** ✓ weather offline |
| 5 | **TEST16** (next A) | **TEST25** ✓ WirePrefix; B on **TEST29** |
| Later P2 | TEST19 device, TEST20 ads, TEST22 a11y… | Only if A not on same screens |
| Later P3 | TEST24 / 29 | Coordinate home / factory reset |

If one agent is free and the other is mid-claim: take the **next queue row’s free side**, or a solo task from **Solo / deferred**.

---

## Solo / deferred (either agent alone, or after Tier 0)

| Item | Notes |
| --- | --- |
| **SEC2** | Scrub project ref from `.mcp.json` if repo may go public — config-only, tiny |
| **LLM1–5** | Edge Function + client; greenfield under `supabase/functions/` — only after BAI/GAI feel enough |
| **ML3** | Optional TFLite — not default |
| **TEST19–20** | Real device / real test ads — human-in-the-loop |
| **TEST21 / 23 / 24 / 29** | Perf, deep link, golden home, factory reset — low urgency |

---

## Hand-off checklist (end of session)

Copy/adapt into your reply + update this file:

```
- Claim: A|B → idle | left in_progress (why)
- Shipped: <ids e.g. TEST14, BAI7 rules …>
- Files touched: <short list>
- Suite: ./scripts/run_full_suite.sh [flags] → green | not run (why)
- Docs: outstanding / INDEX / changelog / README or CLAUDE if suite or public API changed
- Outstanding: rows deleted / left open
- NEXT for partner: <pair # or queue row>
- Blockers: none | …
```

---

## Shipped recently (context only — do not re-open)

- TEST6 shopping(+) screen+Drift · GAI5 personas · SUG6/7 fuel honesty · BAI3 autopilot  
- TEST3/4/9/10 seams + suite · macOS pods/entitlements  
- **P0:** SEC3 secrets scan · TEST8 live RLS · TEST11 Free/Pro matrix · TEST12 startup lifecycle  
- **TEST14:** shopping + inventory empty-DB import round-trip · bad JSON / future version safe errors (`test/import_roundtrip_test.dart`)
- **BAI7:** fog / lightning / log stale-missing / fuel runway rules on `SuggestionEngine.build`
- **TEST13:** file-DB kill/relaunch (checklist/shop/log/fuel/fav) + Pro offline outbox drain once (`test/offline_persistence_test.dart`)
- **TEST28:** `GameAiRng` + pure/seeded AI policies; `test/game_ai_determinism_test.dart`
- **TEST27:** unit conversion edges (0/null/huge/neg) in `test/unit_converter_test.dart`
- **TEST15:** `JoinBoatService` + restamp on join; invalid no half-enroll; `test/join_boat_flow_test.dart`
- **TEST26:** weather offline/stale cache never hangs; any cache returned on network fail
- **TEST25:** WirePrefix cross-boat isolation + fuzz; empty id no-op on `encodeRecordId`
- **TEST17:** checklist swipe Complete → Drift (Pro); Free gated (`test/checklist_items_screen_integration_test.dart`)

---

## Quick pick (both idle)

| Free agent | Do this |
| --- | --- |
| Lane A free | Claim **TEST16** conflict E2E or **TEST18** LAN RC |
| Lane B free | Finish **TEST29** or claim **SUG5** / GAI depth / **TEST24** |
| Only one agent | Prefer remaining P1 (TEST16/18) then B polish |
| Both want product | Do **not** both take the same units or game AI paths |

When in doubt: **re-read Active claims + outstanding Priority**, then claim.
