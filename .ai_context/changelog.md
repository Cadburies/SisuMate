# AI Context Changelog (hot window)

> Newest first. **≤ ~250 lines total. ≤ ~10 lines per new entry.**  
> Full history through 2026-07-16: `archive/changelog-full-through-2026-07-16.md` (**never session-load**).

## [2026-07-30] — No-install-base policy + seed consolidation + schema/migration reset
- Policy: `CLAUDE.md` now says schema/model changes don't need back-compat migrations (dev phone + sims only, no real installs) — still cascade every DB change through model/repo/Supabase/sync/UI in one change.
- Seed: `seedBarIngredients`/`seedPantryIngredients` were called from both `seedBundledData()` and `runDeferredSeeds()` (duplicate). Moved to one call site: new `seed_expansion_catalog.dart`. Found + fixed a pre-existing dead-code redundancy: `runDeferredSeeds()` also called `seedCocktailsImport`/`seedMenusImport`/`seedCoverageCocktails`, but those are already seeded once, synchronously, inside `seed_recipes.dart` — the deferred calls were always no-ops. Removed.
- Drift: `schemaVersion` 11→1; deleted the 10-branch `onUpgrade` (dead now — `onCreate`/`createAll()` covers every case going forward). **Requires wiping local app data on every test device/sim** (old dbs are stamped `user_version=11`, an undefined downgrade) — not done automatically, do this by hand (Factory Reset / reinstall / delete the sqlite file).
- Supabase: local `supabase/migrations/` (9 files, already stale vs. the live project's 12 applied migrations) squashed into one `20260730120000_baseline.sql`, derived by introspecting the live schema via MCP (no local CLI link existed). Live project's `schema_migrations` bookkeeping table repointed to this one version — no application table/row/policy/function touched (verified row counts unchanged).
- Files: `CLAUDE.md`, `risks.md`, `data_models.md`, `lib/data/seed/seed_expansion_catalog.dart` (new), `bundled_data_seeder.dart`, `database_service.dart`, `app_database.dart`, `supabase/migrations/*`, `test/seed_bundled_data_test.dart`.
- Risks: none to app logic (893 tests green, analyzer clean). Manual step outstanding — see above.

## [2026-07-30] — Outstanding: local AI + online LLM backlog
- Captured product map of free local “clever AI” vs paid online LLM into `outstanding.md`.
- New sections: Local AI — Games (GAI1–8), Boat life (BAI1–7), Cocktails/Chef (MIX1–5), On-device ML (ML1–3), Online AI/LLM (LLM1–7); Priority reordered Tier 0→2.
- Files: `outstanding.md`, INDEX.
- Risks: none (backlog only).

## [2026-07-30] — RT2 ad first-paint defer + outstanding Rule 1 cleanup
- RT2: Adreno shader miss is AdMob WebView first paint (third-party); no shader fix. **Mitigation:** defer banner/native load until post-frame + 400ms; **collapse height** while loading/on fail (also closes SUG4 grey placeholder).
- `outstanding.md`: deleted closed LT/S4/S6/RT2/SUG4 blurbs and empty “_(none)_” sections — open work only (Rule 1).
- Files: `banner_ad_widget.dart`, `native_ad_widget.dart`, outstanding, INDEX.
- Risks: none; rare logcat Adreno lines may still appear once per session from GMS WebView.

## [2026-07-30] — LT2 Fuel notes-as-title + outstanding cleanup
- Fuel list/detail title uses **notes when set** (type stays as tag); LT2 fuel path opens by marker title for full CRUD + mirror clear.
- `outstanding.md`: removed completed LT1–7, S4/S6 v1, GAME1 archive, empty failure log; open work only.
- Files: `fuel_screen.dart`, `lt_module_crud_sweep.sh`, `lt_mirror_live_test.md`, outstanding/INDEX.
- Risks: none.

## [2026-07-30] — Bar seed: Baileys + pomegranate; coverage cocktails
- Bar: added **Baileys Irish Cream**, **Pomegranate Liqueur**; removed duplicate Peychaud's row.
- New pack `seed_coverage_cocktails.dart` (`cocktail_cov_*`, insert-missing via deferred seeds + first install) so every bar ingredient is used in **≥2** cocktails (no more "Not used in any cocktail" on catalog rows).
- Files: seed_bar_ingredients, seed_coverage_cocktails, seed_recipes, database_service.
- Risks: none; existing installs pick up via `runDeferredSeeds`.

## [2026-07-30] — Test coverage expansion (services, sync conflict, LAN multiplayer, widgets)
- Added: unit tests for previously-untested services (barcode, mixologist, recipe_allergen, image_fallback, seasonal, admob day-limit).
- Added: `sync_conflict_2device_test.dart` — first automated coverage of `_outboxItemConflicts` (2 devices sharing one `FakeSupabaseRemote`), the exact path a manual script (SUG2/T5) caught 3 regressions in on 2026-07-22.
- Added: `test/test_helpers/fake_lan_engine.dart` + `games_multiplayer_lan_test.dart` — first automated coverage of `GameLanService`/`LanEngine` message-passing (join handshake, broadcastState, moves, LT7 disconnect grace via `fake_async`), previously live-device-only.
- Added: widget tests for AddEdit dialogs (crew, fuel, inventory). Removed stale Isar-era `widget_test.dart` placeholder.
- Files: test/*.dart (9 new files), test/test_helpers/fake_lan_engine.dart.
- Risks: none; `flutter analyze` + `flutter test` (891 tests) green.

## [2026-07-30] — Hard-delete inbound reconcile (LT2 mirror clear)
- Bug: Supabase `.stream()` drops deleted rows from the snapshot, but `processIncomingChanges` only upserted — local Drift never removed hard-deletes (inv/crew/docs mirror stuck).
- Fix: after applying snapshot, delete local `isSynced` rows absent from remote (skip unsynced + pending outbox). `InboundSyncApplier.deleteLocal` / `listLocalSyncedIds`.
- Tests: inbound_sync_tables_test (+3). Live dual-iOS: Inventory 7/7, Crew 6/6, Documents 6/6 incl. mirror cleared after delete.
- Files: sync_service.dart, inbound_sync_applier.dart, tests, outstanding.
- Risks: none; Fuel notes path still residual.

## [2026-07-30] — Cribbage live re-pass + LT2 expand
- **Cribbage:** phone host + iOS sim guest — mDNS join, distinct hands, simultaneous discard, pegging turn sync, disconnect overlay ("Opponent disconnected", not bogus win). Cleared live-test failure log.
- **LT2 harness:** `idb_tap_label` exact+nonzero-frame; scroll until tappable; Spares expand idempotent; Name TextField focus + clear; Inv→I9 (iOS autocorrect); Fuel notes-based flow.
- **LT2 live (dual-iOS sailingsisu):** Shopping full CRUD 7/7; Inventory/Crew/Documents create+edit(+side) green; hard-delete mirror residual; Fuel create notes path still flaky.
- Files: `lt_module_crud_sweep.sh`, `idb_tap_label.sh`, outstanding/INDEX.
- Risks: hard-delete inbound/outbox may be product gap (logged).

## [2026-07-30] — TEST2: SupabaseRemote seam + network-success unit tests
- Seam: `lib/services/supabase_remote.dart` (`SupabaseRemote` / `LiveSupabaseRemote`); DI `supabaseRemoteProvider`.
- Wired: `CommunityRepositoryImpl` + `SyncService` outbox upsert/delete/fetch use remote (constructor / provider override).
- Fake: `test/test_helpers/fake_supabase_remote.dart`.
- Tests: community publish/rate/browse/update success; sync online upsert/delete + forceProcessQueue drain. Analyzer clean.
- Risks: none. Closed TEST2 in outstanding.

## [2026-07-30] — SHOP1: show hidden shopping items + hard-delete/unhide
- Bug: `watchItems` filtered `!isHidden`, so drawer **Show Hidden Items** could never list soft-deleted rows.
- Fix: repo returns hidden rows; UI still filters on `showHiddenItems`. Added `unhideItem`; list swipe Unhide + Delete; detail Unhide + hard Delete when hidden.
- Tests: shopping repo SHOP1 hide/unhide/delete. Analyzer clean.
- Risks: none.

## [2026-07-30] — S4 suggestions, S6 field-merge, GB7 doubling cube, GB14 closed
- **GB14:** already implemented (double-tap → foundation); help text + outstanding cleared.
- **GB7:** backgammon cube (offer/accept/decline, stake ×1–64, AI respond/offer, multiplayer moves, UI cube badge + buttons); tests + help.
- **S4:** `SuggestionEngine` offline rules (maintenance overdue/due-soon, weather notes/wind); home `Suggestions` banner; `boatSuggestionsProvider`.
- **S6:** `tryFieldMerge` auto-merge non-hard conflicts on inbound + outbox; Sync Conflicts **Merge fields**; tests.
- Files: backgammon logic/screen, conflict_resolution_service, sync_service, suggestion_engine, home_screen, di, tests.
- Risks: none; S4 LLM / S6 OT remain optional later.

## [2026-07-30] — LT1–LT4 dual-device mirror live-test harness
- Scripts: `lt_ui_helpers.sh`, `lt_mirror_harness.sh` (LT1), `lt_module_crud_sweep.sh` (LT2–4 create/edit/side/delete + marker reuse), doc `lib/services/lt_mirror_live_test.md`.
- Live: LT1 PASS (Android+iOS home when phone unlocked). Shopping smoke dual-iOS: create + mirror saw create + side action; Edit/Delete skipped (detail a11y). Supabase confirmed LT rows. Phone lock screen blocks unattended Android driver.
- Risks: none new; leftover `LT-*` shopping test rows may need manual cleanup.

## [2026-07-30] — LT6 multi-seat stress (Dudo) + LT7 same-seat reconnect
- LT7: `LanEngine.rebindPeerId` + mutable peer slots; `GameLanService` 15s mid-game grace, rejoin by name/preferredId, last-state rebroadcast, reject late strangers; liars_dice/dudo refresh `localPlayerId` on reconnect; `test/lan_reconnect_test.dart` (+4 integration tests, 11 total).
- LT6: `scripts/mp_multiseat_stress_setup.sh` for roster games; live Dudo 4-seat (iPhone 16 Plus host, iPhone 16, Android phone, + AI) — Start Game, hidden dice per seat, turn on AndPlayer. Liar's Dice already done 2026-07-13. 2-role titles scoped as 2-seat-only.
- GAME1 residual LT6/LT7 closed. Risks: none.

## [2026-07-30] — GAME1 live tests: Uno + Poker (phone host + iOS sim)
- Devices: Android SM S928U1 (`R5CX2036L1F`) host, iPhone 16 Plus sim (`43C4A261…`) guest.
- Uno: mDNS join, deal sync, host play → guest turn, guest draw/Wild/color → host state. Live bug: host saw "Opponent's turn" after guest wild while it was host's turn — fixed in `uno/screen.dart` (multiplayer messages always from `myTurn`).
- Poker: hidden distinct hands, bet without auto-call, guest call, simultaneous draw both confirms, betting2 → showdown → next round with correct chips.
- GAME1 live-test debt for Uno/Poker closed. Residual optional: LT6/LT7.
- Risks: none blocking.

## [2026-07-30] — GAME1: Solitaire permanently solo-by-design (descoped multiplayer)
- Decision: Klondike Solitaire has no opponent seat — multiplayer was never product scope. Closed the "maybe descope" row.
- Files: `app_router.dart` (`GameCatalog.soloOnlyByDesign = {solitaire}`), `games_screen.dart` (tooltip "Solo only — single-player by design" when hub multiplayer is on), `solitaire/gameflow.md` note, outstanding/INDEX.
- GAME1 implementation complete for all 8 multiplayer-capable titles; remaining debt is Uno + Poker live 2-device tests only.
- Risks: none.

## [2026-07-30] — GAME1: Poker multiplayer (8th title) — role-aware betting + simultaneous draw
- Files: `poker/logic.dart` (host/client/disconnect/broadcast, `toJson`/`fromJson`, role-aware bet/check/call/fold via `isPlayerTurn`, no AI auto-call when real guest, simultaneous draw via `selectedAiDiscard` + host/guest confirm flags), `poker/screen.dart` (identity model, `_sendOrApply`/`_sendOrApplyMine`, hidden-hand until showdown, perspective messages, disconnect-safe overlay), `lobby_screen.dart` (+'poker'), `app_router.dart` (`multiplayerReady` +'poker'), `poker_test.dart` (+8 multiplayer tests).
- Solo AI paths unchanged (auto-call on bet, 33% bet-back on check). Multiplayer reuses Cribbage's simultaneous-confirm pattern for the draw phase.
- Validated: 38/38 poker tests pass, analyzer clean on touched files. Live 2-device test not run (phone locked / deferred with Uno).
- Risks: none new; live-test gap for Uno + Poker noted in outstanding priority.

## [2026-07-27] — GAME1: Uno multiplayer (7th title) — every established lesson applied proactively
- Files: `uno/logic.dart` (host/client/disconnect/broadcast, `UnoCard.toJson`/`fromJson`, role-aware `selectCard`/`playSelected`/`_applyCard`(renamed from `_applyPlayerCard`)/`chooseColor`/`drawCard`), `uno/screen.dart` (identity model, `_sendOrApply`, hidden-hand rendering, perspective-aware legend/message, disconnect-safe win overlay, `_WaitingForColorChoice` for the non-acting side during a wild-card color pick), `lobby_screen.dart` (+'uno' dispatch), `app_router.dart` (`multiplayerReady` +'uno'), `uno_test.dart` (+9 tests).
- Same single-shared-entry-point shape as checkers/backgammon/cribbage's pegging phase — applied the role-hardcoding fix proactively (`isHostRole = state.isPlayerTurn` captured up front, since `chooseColor` relies on it still reflecting "who played the wild" from before `playSelected` set phase to `choosingColor` without touching `isPlayerTurn`). Also applied the cribbage-discovered disconnect-overlay fix (null `winner` → neutral "Game Ended" instead of a nonsensical "You Win!") from the start.
- Validated: 807/807 tests pass, analyzer clean. Live 2-device test was **not run this pass** — skipped by user request when the phone locked again. Given the pattern is identical to three already-live-validated titles and every known bug class was fixed proactively rather than found live, risk is assessed as low, but the live pass is still owed before this title is fully closed out (tracked in outstanding.md's priority list).
- Risks: none new in the code; live-test coverage gap noted above.

## [2026-07-23] — GAME1: Cribbage multiplayer (6th title) — simultaneous discard phase + cross-game disconnect-overlay fix
- Files: `cribbage/logic.dart` (host/client/disconnect/broadcast, `aiFullHand`/`selectedAiDiscard`/`hostDiscardConfirmed`/`guestDiscardConfirmed` for the simultaneous discard phase, role-aware `playPegCard`/`sayGo`), `cribbage/screen.dart` (identity model, `_sendOrApply`/`_sendOrApplyMine`, hidden-hand rendering, perspective-aware legend/message/win-overlay), `lobby_screen.dart` (+'cribbage' dispatch), `app_router.dart` (`multiplayerReady` +'cribbage'), `checkers/screen.dart` + `backgammon/screen.dart` (disconnect-overlay fix, see below), `cribbage_test.dart` (+11 tests).
- Hidden-hand design resolved (was an open question in outstanding.md): full-state broadcast, same as every title — opponent's real cards travel over the wire but render as face-down backs in the UI. Accepted as consistent with a casual/trusted LAN game; per-recipient server-side redaction was considered and rejected as bigger scope than anything else in GAME1.
- New architectural wrinkle vs. Liar's Dice/Dudo/Yatzy/Checkers/Backgammon: Cribbage's discard phase is **simultaneous**, not turn-based — both sides pick 2 cards independently and the round can't cut the starter until both confirm. No existing "whose turn" flag applies, so this needed its own mechanism (a 2nd method pair for the guest's own hand, 2 independent confirmation flags) rather than the turn-alternation pattern used everywhere else.
- Applied the Checkers/Backgammon role-hardcoding lesson proactively to the (turn-based) pegging phase — passed its regression test on the first run.
- Found live and fixed a **new bug class**: a disconnect ending the game leaves `winner` null (nobody actually won), and the win/lose overlay's `(winner == 'You') == amIHost` comparison then evaluates true for whichever side happens to match, showing a nonsensical "You Win! 0–0". Fixed in Cribbage and backported to Checkers/Backgammon, which had the identical latent bug (unexercised until this session's live test happened to hit a real disconnect).
- Validated: 798/798 tests pass; live testing confirmed the hidden-hand + simultaneous-discard mechanism works correctly (each side saw only their own hand, correct legend swaps, correct discard messaging) before an environmental disconnect (long idle gap backgrounding both apps) surfaced the overlay bug above. A follow-up live pass to confirm a full round post-fix hit unrelated mDNS flakiness that didn't resolve after several restarts — logged in the live-test failure table, not blocking.
- Risks: none new in the fix itself. The full post-fix live round (discard → pegging → counting → game-over) is unconfirmed end-to-end; worth a quick re-check next time this area is touched.

## [2026-07-23] — GAME1: Backgammon multiplayer (5th title) — fixed the role bug proactively
- Files: `backgammon/logic.dart` (host/client/disconnect/broadcast + JSON serialization — simpler than Checkers, no cached move lists to recompute), `backgammon/screen.dart` (identity model, `_sendOrApply`, perspective-aware legend/message/win-overlay, made the guest's own bar pieces tappable), `lobby_screen.dart` (+'backgammon' dispatch), `app_router.dart` (`multiplayerReady` +'backgammon'), `backgammon_test.dart` (+13 tests).
- Same absolute host=white/guest=black model and same single-shared-entry-point shape as Checkers (`selectPoint`/`bearOff`/`passTurn` serve both roles) — the Checkers changelog entry flagged this risk in advance, so `roll`/`selectPoint`/`bearOff`/`passTurn`/`_executeHumanMove` were rewritten role-aware (`isHumanRole = state.isHumanTurn`) *before* shipping, not after a live-test failure. The regression test (guest selects+moves their own black piece) passed on the first run.
- Found and fixed one new bug while reworking the screen (not present in Checkers): the AI/guest's own bar-entry pieces had no `GestureDetector` at all in solo code — only the human's bar pieces were tappable — so a guest could never tap their own bar piece to re-enter after being hit.
- Validated: 787/787 tests pass; live 2-device round-trip confirmed (phone hosts, iOS Simulator joins; roll/select/move/bear-off synced correctly both directions across many exchanges, ending in a correctly-translated win/loss overlay on both screens — host saw "Opponent wins!", guest saw "You win!" for the same event).
- Risks: none new. GAME1 build order now moves to the card games (Cribbage/Uno/Poker) — those need a hidden-hand design decision (full-state broadcast vs per-recipient filtering) that Liar's Dice/Dudo/Yatzy/Checkers/Backgammon didn't (no hidden information in any of them).

## [2026-07-22] — GAME1: Checkers multiplayer (4th title) — role-aware selectCell/_executeMove
- Files: `checkers/logic.dart` (host/client/disconnect/broadcast + JSON serialization recomputing allMoves/validMoves instead of shipping `CheckersMove` tuples), `checkers/screen.dart` (identity model, `_sendOrApply`, perspective-aware legend/message/win-overlay), `lobby_screen.dart` (+'checkers' dispatch), `app_router.dart` (`multiplayerReady` +'checkers'), `checkers_test.dart` (+16 tests).
- Design: same absolute host=red/guest=black model as Yatzy, but Checkers has ONE shared entry point (`selectCell`) for both roles instead of per-role methods — this exposed a class of bug Yatzy/Dudo didn't have.
- Live testing found + fixed 2 real bugs: (1) `selectCell`'s piece-selection check hardcoded `_isHumanPiece` (only ever true for red) — the guest could never select their own black pieces at all, since nothing distinguished "the active role's piece" from "the red piece" outside solo mode's implicit assumption. Fixed by checking against whichever role's turn it currently is. (2) `_executeMove` hardcoded "human moved → switch to AI" (turn flag + win-check side), so a guest's move would have handed the turn to the wrong side; fixed by capturing `activeIsHumanRole = state.isPlayerTurn` up front and computing the next turn/win-check symmetrically.
- Validated: 779/779 tests pass; live 2-device round-trip confirmed (phone hosts, iOS Simulator joins, moves both directions stay in sync, turn handoff correct both ways).
- Risks: Backgammon likely shares Checkers' single-shared-entry-point shape (not Yatzy's per-role-method shape) — check for the same class of hardcoded-role bug when implementing it.

## [2026-07-22] — GAME1: Yatzy multiplayer (3rd title) — absolute host/guest model
- Files: `yatzy/logic.dart` (host/client/disconnect/broadcast + JSON serialization, new for this file), `yatzy/screen.dart` (identity model, action dispatch, You/Opp. card swap), `lobby_screen.dart` (+'yatzy' dispatch), `app_router.dart` (`multiplayerReady` +'yatzy'), `yatzy_test.dart` (+8 tests).
- Design: unlike Dudo/Liar's Dice (player-list with stable IDs), Yatzy's state was relative (`playerCard`/`aiCard`, `isPlayerTurn: bool` from one screen's viewpoint) — broadcasting it as-is would make each device misread the other's side as its own. Fixed with an absolute host=`playerCard`/guest=`aiCard` model; each screen derives "is it MY turn" from `notifier.isClientMode`, no player-id roster needed since Yatzy is strictly 2-role.
- Live testing found + fixed 2 real bugs: (1) `initHostMode` never broadcast (no `startGame()`/`determineStarter()` step to naturally re-broadcast like the other two games have) — guest stuck on "Waiting for host..." forever; fixed with a 1s delayed broadcast. (2) turn-handoff message read backwards on whichever screen didn't just score (broadcast verbatim from the scorer's perspective) — changed to neutral text.
- Self-healed 2 stale outstanding.md rows found while touching this area: GB1 (Yatzy joker/bonus) and GB5 (Dudo palafico) were both already implemented+tested — deleted.
- Validated: 769/769 tests pass; live 2-device round-trip confirmed (phone hosts, iOS Simulator joins, full score→handoff→score cycle both directions).
- Risks: none new.

## [2026-07-22] — GAME1: Dudo multiplayer (2nd title) + lobby generalized
- Files: `lobby_screen.dart` (gameId-dispatch, no longer Liar's-Dice-only), `lan_providers.dart` (+shared `localPlayerIdProvider`), `dudo/logic.dart` (+host/client/disconnect/broadcast, mirrors `liars_dice/logic.dart`), `dudo/screen.dart` (+identity model, action dispatch, AI-timer gating), `app_router.dart` (`multiplayerReady` +'dudo'), `dudo_test.dart` (+12 tests).
- Validated: 762/762 tests pass; live host-side gameplay confirmed on-device (real dice, AI bidding, Dudo-call resolution, round progression); 2-device LAN join confirmed (real phone host + iOS Simulator join). Android emulator↔emulator/phone mDNS discovery flaked repeatedly during testing — separately known-flaky/NAT-isolated (see `liars_dice/live_test_setup.md`), not a Dudo defect; no outstanding.md row needed.
- Risks: shared multiplayer scaffolding is still hand-copied per game (not a mixin) — acceptable per outstanding.md's own "extract after 2nd title" note; revisit if a 3rd title makes the duplication costly.

## [2026-07-22] — TEST1b: outbox retry, Free-vs-Pro, seed counts, sync/weather UI pumps
- +15 tests: `sync_service_test.dart` (Pro-mocked outbox push/retry via new `RevenueCatService.debugProOverrideForTests` seam + connectivity_plus channel mock), `free_edit_gate_test.dart` (Pro bypasses the gate), `seed_bundled_data_test.dart` (exact group/category counts, user-only tables start empty), new `conflict_resolution_screen_test.dart` + `passage_planner_screen_test.dart`.
- Gotcha found: pumping a screen that constructs a real `SyncService` inside `testWidgets` deadlocks the fake clock — same root cause as `syncOutboxCountProvider` in `item_detail_shell_test.dart`. Fix: override the terminal provider (`pendingConflictsProvider`) directly instead of `appDatabaseProvider`.
- Not done: Community/outbox "network succeeds" tests — logged as TEST2 (needs a Supabase client-injection seam, out of scope for opportunistic tests).
- Risks: none — 756/756 tests pass, analyze clean.

## [2026-07-22] — SUG2: sync-conflict smoke test found + fixed 3 live sync bugs
- Built `scripts/sync_conflict_2device_setup.sh` (+ `lib/services/sync_conflict_2device_setup.md`); running it live found real defects.
- Files: `lib/services/sync_service.dart`, `lib/services/inbound_sync_applier.dart`, `lib/services/community_merge.dart`, ~35 models/repositories (lastModified stamps).
- Fixed: (1) outbox push never conflict-checked — stale offline edits silently overwrote newer remote edits; (2) `lastModified` used local `DateTime.now()` (no `.toUtc()`) at ~74 sites, causing timezone-skewed comparisons for non-UTC devices; (3) online deletes ignored `isDelete` and no-opped instead of deleting remotely.
- Risks: pre-fix rows have mistagged `lastModified` (naive local time labeled UTC) — no backfill attempted, self-heals as rows are next touched.

## [2026-07-21] — CONTEXT-LEAN: token-efficient AI memory overhaul
- Policy: Tier A/B only; no source mirrors; session = INDEX + ≤2 topical files; narrow self-heal; hot/archive changelog.
- Files: `Claude.md`, `.ai_context/*` (all warm files rewritten lean), `archive/changelog-full-through-2026-07-16.md`, root `AI_CONTEXT_PLAYBOOK.md`.
- Risks: none new. Removed stale schemaVersion/B8 mirrors by deleting mirrored claims.
- Dropped: model field tables, screen inventory, Pro code snippets, risks strikethroughs, outstanding build snapshot.

## Recent (detail in archive only)

| Date | Title |
| --- | --- |
| 2026-07-16 | GB2/GB3/GB4 Uno + Poker fixes |
| 2026-07-15 | GB11–13 Cribbage; GB6/8/9/10; S2 equality; CB1; S5 marketplace |
| 2026-07-14 | NAV2 remaining named routes |
| 2026-07-13 | Liar's Dice live multiplayer; iOS AdMob plist crash; SYN4; SEED-PATCH; UX7; GAME1 scoped |
| 2026-07-12 | CONTEXT-EFF audit; FREE-EDITS; STALE-*; SHARE4/5; title-bar standard |
| 2026-07-11 | Pro sync sharing phases; WIRE-PREFIX; SHARE-ENROLL; RLS cutover; SUG1 |
| earlier | May–July history in archive |

When hot grows past ~250 lines: move older `##` entries into `archive/`, leave a one-line index row here.
