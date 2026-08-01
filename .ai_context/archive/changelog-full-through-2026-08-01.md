# AI Context Changelog (hot window)

> Newest first. **≤ ~50 lines total. ≤ ~10 lines per new entry.**  
> Full history: `archive/changelog-full-through-2026-07-16.md` (through 2026-07-16) + `archive/changelog-full-through-2026-07-30.md` (2026-07-21 through 2026-07-30) — **never session-load**.

## [2026-07-30] — TEST16 dual-device conflict E2E fixed
- `test/conflict_resolution_e2e_test.dart` existed but 2/3 cases failed (test bugs, not app bugs).
- Fix 1: "keep mine" case resolved while connectivity mock was still online, so the follow-up push went out immediately instead of queuing — now forces offline before `resolveConflict` so the assert on `pendingQueueSize()` matches.
- Fix 2: "outbox path" case asserted device B's local row before B's own DB was ever updated (only the remote push happened) — now applies the local write alongside `queueOutgoingChange`.
- All 3 TEST16 cases + full suite (`run_full_suite.sh`) green. Risks: none.

## [2026-07-30] — TEST29 factory reset + provider invalidate (Grok B)
- `lib/core/factory_reset.dart`: `invalidateAfterFactoryReset` for settings/boats/activeBoat/logs.
- Wired into settings, checklist, safety, common_drawer after `factoryReset()`.
- `test/factory_reset_test.dart`: wipe user rows, reseed, freeEdits=0, baseline epoch, provider reload.
- Risks: none. 5/5 tests green.

## [2026-07-30] — TEST25 WirePrefix isolation fuzz (Grok B)
- Cross-boat distinct wire ids; round-trip all scoped tables; 80-iter fuzz; `decodeRecordId` + `scopedTables`/`fieldsFor`.
- Fix: `encodeRecordId` no longer prefixes empty local ids (`guid::` bleed surface).
- Files: `wire_prefix.dart`, `test/wire_prefix_test.dart`. TEST25 closed. Risks: none.

## [2026-07-30] — TEST26 weather offline + stale cache (Grok B)
- `fetch` returns any cache on network fail (stale OK); `isCacheFresh` / `networkTimeout`; MockClient tests.
- Files: `weather_service.dart`, `test/weather_service_test.dart`. TEST26 closed. Risks: none.

## [2026-07-30] — TEST17 checklist complete → Drift (Grok A)
- `test/checklist_items_screen_integration_test.dart`: real `ChecklistItemsScreen` + in-memory Drift; Pro swipe Complete persists `isCompleted`; Free gated (no Drift write).
- Pattern mirrors TEST6 shopping. Context: TEST17 closed; next TEST16/18. Docs: suite map + README smoke. Risks: none. 3/3 green.

## [2026-07-30] — Docs: suite + TEST13–15 map
- Full suite how-to: `CLAUDE.md` §5 suite map (TEST13/14/15 rows), `README.md` Testing (flags + targeted smoke), `outstanding.md` Testing gaps, INDEX Auth/crew → `join_boat_service.dart`, `screens.md` join restamp gotcha, `parallel_ai` hand-off checklist.
- Run: `./scripts/run_full_suite.sh` (± `--skip-live` / `--skip-integration` / `--device`). Risks: none (docs).

## [2026-07-30] — Docs: full suite run path
- Expanded how-to for `./scripts/run_full_suite.sh` in `CLAUDE.md` §5, `README.md` Testing, `outstanding.md` Testing gaps, INDEX Read-Next, `parallel_ai` suite rule, script header.
- Steps: SEC3 → analyze → flutter test → TEST8 live RLS → integration_test; flags `--skip-live` / `--skip-integration` / `--device`.
- Risks: none (docs only).

## [2026-07-30] — TEST27 unit conversion edges (Grok B)
- `test/unit_converter_test.dart`: null/empty units, null qty + canonicalize, zero/huge/neg °F, format nulls, temp range nulls, speed round-trip, isConvertible junk.
- No production bugs found — pure coverage of existing `UnitConverter` contracts.
- Context: TEST27 closed; parallel B idle. Risks: none.

## [2026-07-30] — TEST28 game AI determinism (Grok B)
- `GameAiRng.seeded` contract; pure/export AI policies for poker discard, cribbage keep, yatzy reroll/category; checkers `debugSelectAiBoard` + injectible RNG tie-break.
- `test/game_ai_determinism_test.dart` (12): same seed ⇒ same move across checkers/poker/cribbage/yatzy/backgammon + liar's bid helper.
- Context: TEST28 closed; parallel B idle. Risks: none.

## [2026-07-30] — BAI7 richer SuggestionEngine home rules (Grok B)
- New pure rules: fog/low-vis, lightning/thunder, missing/stale captain log (14d), fuel/water runway watch (≤5d / urgent ≤2d).
- `boatSuggestionsProvider` passes `lastLogDate`; optional `fuelEstimates` on `build` (unit-tested).
- Files: `suggestion_engine.dart`, `di.dart`, `test/suggestion_engine_test.dart` (+8). BAI7 closed; parallel B idle. Risks: none.

## [2026-07-30] — TEST15 share-code join (Grok A)
- `JoinBoatService`: redeem first then local upsert + active boat + restamp + ensureStarted; invalid codes never touch Drift.
- `BoatEnrollmentService.restampContentToBoat` public; join screen uses flow; `ensureStarted` swallows missing Supabase/plugin.
- Tests: `test/join_boat_flow_test.dart`. FakeAuthBackend invalid message aligned. Risks: none.

## [2026-07-30] — TEST13 offline kill/relaunch + outbox drain (Grok A)
- `test/offline_persistence_test.dart`: file-backed Drift close/reopen for checklist complete, shopping add, captain log, fuel fill, recipe favourite; Pro offline outbox survives relaunch; reconnect drains once (no dup/lost); fail-then-success keeps then drains.
- Context: removed TEST13; parallel_ai A idle → next TEST15. Risks: none. 3/3 green.

## [2026-07-30] — TEST14 import empty-DB round-trip (Grok A)
- `test/import_roundtrip_test.dart`: shopping + inventory pure export↔parse; empty Drift persist via repo paths matching screens; re-export names/counts; bad JSON / future format / all-or-nothing item errors user-safe.
- Context: removed TEST14 from outstanding; `parallel_ai.md` claim idle, wave queue → TEST13 ∥ BAI7.
- Risks: none. 10/10 tests green.

## [2026-07-30] — parallel_ai.md hand-off board
- Rewrote `parallel_ai.md`: Lane A (P1 tests) ∥ Lane B (BAI7/GAI/polish); Active claims; recommended TEST14 ∥ BAI7; ownership map; wave queue; hand-off checklist.
- INDEX: Read-Next row + NEXT points at claims. Risks: none (docs).

## [2026-07-30] — P0 ship blockers (SEC3, TEST8, TEST11, TEST12)
- SEC3: `scripts/scan_release_secrets.sh` + `test/release_secrets_scan_test.dart` (pubspec/assets/lib + optional APK).
- TEST8: `test/live_supabase_rls_test.dart` + `scripts/test_supabase_rls.sh` (owner auth, boats select, invalid share code, bogus JWT); skips without dart-defines.
- TEST11: `test/pro_free_gate_matrix_test.dart` (RM1/RM2 source gates, Free no-sync, Pro outbox, FreeEditGate, banner Pro collapse, ad cap).
- TEST12: `test/startup_lifecycle_test.dart` (seed/healthy/factoryReset + corrupt/hardReset + dart-defines contracts).
- Suite: `run_full_suite.sh` runs SEC3 + live RLS. Context: P0 rows removed; next is P1 (TEST13+). Risks: none.

## [2026-07-30] — Pre-launch test backlog in outstanding
- `outstanding.md`: SEC3 (release secrets scan); TEST8 elevated + TEST11–TEST29 under Testing gaps (P0–P3); Priority led by pre-launch pack.
- Files: `.ai_context/outstanding.md` only. Risks: none (docs).

## [2026-07-30] — macOS desktop build/run fix
- CocoaPods: `pod update PurchasesHybridCommon` (lock 17.23 → 17.30 for purchases_flutter 9.10.8).
- Entitlements: add `network.client` (+ file user-selected R/W) so sandbox allows Supabase outbound.
- Files: `macos/Podfile.lock`, `macos/Runner/DebugProfile.entitlements`, `Release.entitlements`.
- Verified: `flutter run -d macos --dart-define-from-file=dart-defines.json` launches; AdMob skipped on desktop (expected).
- Risks: none (macOS tooling only). Note: residual Riverpod setState-during-build on home is pre-existing, not a link error.

## [2026-07-30] — TEST3/4/9/10 full regression suite
- Seams: `AuthBackend` + Fake; `ProfileHeartbeat` debug hooks; Email pure mailto/MRU + `RecipientDialog`; `RecipeShareService.buildRecipeCardPdf`; `AdMobPlatform`/`FakeAdMobPlatform` load/show/retry.
- Tests: auth/profile/email/recipe_share/admob unit; inventory+fuel TEST6; a11y/perf/channel fallback (TEST10); `integration_test/app_smoke_test.dart` (TEST9).
- Post-task: `./scripts/run_full_suite.sh` (analyze + test + integration on flutter-tester). Claude.md test step updated.
- Small product: shopping FAB tooltips; TitleTile status line full opacity (WCAG).
- Context: closed TEST3/4/9/10; TEST8 remains. Risks: none. 1088+ unit tests + 2 integration green.

## [2026-07-30] — Context self-heal (hot changelog vs Tier A/B)
- `screens.md`: multiparty (GAME1 closed) + GAI1/GAI5 seats; added non-derivable gotchas for BAI1/BAI3, SUG6–7 fuel remaining, TEST6 screen+Drift pattern.
- `risks.md`: lobby debt → extension-point note (not “Liar's-only hard-wire”).
- `outstanding`: Priority + Local AI games blurb (GAI1/GAI5 paths); resolved TEST6/GAI5/SUG6–7/BAI3 rows stay deleted.
- INDEX NEXT + `parallel_ai.md` aligned. Risks: none (docs only).

## [2026-07-30] — TEST6: first real screen + provider tree + Drift integration test
- `test/shopping_screen_integration_test.dart`: backs `appDatabaseProvider` with a genuine in-memory Drift DB (`AppDatabase.forTesting(NativeDatabase.memory())`) and pumps the real `ShoppingScreen()` — the full Repository → Provider → ConsumerWidget stack runs for real, unlike every prior widget test (which pumps a dialog in isolation or overrides the terminal provider directly, e.g. `conflict_resolution_screen_test.dart`'s own comment on why).
- 3 tests: a row seeded straight into Drift renders on screen; adding via the real "Add Item" dialog reaches Drift through `ShoppingRepositoryImpl.addItem` (asserted by reading the row back from `db`, not just widget state); Free tier's FAB opens the paywall and never touches Drift.
- `RevenueCatService.debugProOverrideForTests` keeps `SyncService`'s Free/offline check from touching a real platform channel (same seam as TEST1b).
- Files: `test/shopping_screen_integration_test.dart` (new); outstanding TEST6 closed.
- Risks: none. Picked Shopping over Fuel — purest deps (Fuel SUG6/SUG7 shipped same day in Grok lane). Pattern is copy-paste-able to other screens later; TEST6 only asked for one.

## [2026-07-30] — GAI5 persona bots (Aggressive / Tight / Chaos)
- New `GameAiPersona` (orthogonal to GAI1 skill): balanced, aggressive, tight, chaos — seat names Bluffer / Rock / Wildcard + threshold biases.
- Lobby: Skill + Style chips; per-seat persona/difficulty on `LobbyPlayer` wire JSON.
- Dudo + Liar's Dice: each AI seat keeps its own skill/style; bid/call thresholds bias by persona (chaos samples near-best).
- Files: `game_ai_persona.dart` (new), `game_lan_service.dart`, `lobby_screen.dart`, dudo/liars helpers+logic, tests.
- Context: removed GAI5 from outstanding.
- Risks: none; related game/LAN tests green.

## [2026-07-30] — SUG6/SUG7 fuel burn estimator honesty + recency
- SUG6: single-fill (no burn rate) → `estimatedRemainingLiters` is **null** (unknown), not full capacity; summary/UI say "unknown — log another fill".
- SUG7: L/day uses last 6 fill intervals with linear recency weights (newer counts more) so seasonal usage shifts show up faster.
- Files: `fuel_burn_estimator.dart`, `fuel_screen.dart`, `test/fuel_burn_estimator_test.dart` (+2 tests; single-fill expectation updated).
- Context: removed SUG6/SUG7 from outstanding.
- Risks: none.

## [2026-07-30] — BAI3 checklist autopilot
- `SuggestionEngine.checklistAutopilot`: days-until-departure (nearest upcoming meal plan) + trip length + cached weather → keyword-matches existing checklist titles ("last minute", "one day", "one week", "document", "watch") to suggest which to run next. No schema change — same keyword-match style as `_looksStormy`. Never suggests the same group twice even if multiple rules match it.
- New `lib/providers/checklist_autopilot_provider.dart`: `nearestTripProvider` (days-until + length from the nearest not-yet-finished meal plan) + reuses BAI1's `cachedWeatherProvider`.
- Checklists screen: new `_ChecklistAutopilotBanner` ("Run before you go"), tap opens that checklist directly.
- Files: `suggestion_engine.dart`, `checklist_autopilot_provider.dart` (new), `checklist_screen.dart`, `test/suggestion_engine_test.dart` (+9 tests).
- Risks: none; 1017 tests green, analyzer clean. Live-verified end-to-end on a fresh sim (new dedicated "iPhone 16 (Claude)" device, since Grok's using the other one): empty-trip → no banner, created a same-day 7-day meal plan → banner correctly showed all 4 suggestions (last-minute, one-day, documents, on-watch/multi-day), tap-through opened the right checklist.

Older entries → `archive/changelog-full-through-2026-07-30.md` (newest-first, continues here) → `archive/changelog-full-through-2026-07-16.md`.

When hot grows past ~50 lines: move older `##` entries into `archive/`, leave the one-line pointer above.
