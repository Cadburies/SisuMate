# AI Context Changelog

This file is updated by Claude after every modification task.
Format: append newest entry at the top.

## [2026-07-16] — GB2/GB3/GB4: fixed Uno AI Wild +4 not skipping the human, Poker's missing uncalled-bet return, and wheel-straight tiebreak
- User asked to knock out GB2 (Uno, medium), GB3 (Poker, medium), and GB4 (Poker, medium) — the next-highest-severity remaining rows in the LT5 audit findings, all already root-caused, in two different games.
- **GB2 (Uno)** — `_aiTurn()`'s `wildDrawFour` case (`uno/logic.dart`) set `isPlayerTurn: true` after making the human draw 4 cards, letting them play immediately instead of losing their turn — asymmetric with the human-initiated path (`chooseColor()`), which already correctly sets `aiGetsSkipped = true` when the human plays a Wild +4. Fix: mirrors the `drawTwo` case immediately above it — `isPlayerTurn: false` plus a follow-up `Future.delayed(700ms, _aiTurn)` so the AI continues instead of handing the turn back.
- **GB3 (Poker)** — two related clamping bugs, both keyed off `state.playerChips`, in `poker/logic.dart`:
  - `playerBet()`: AI's call was `_betAmount.clamp(0, state.aiChips)` — always the nominal $20 bet, regardless of what the player actually bet. A short-stacked player going all-in for less (e.g. $5) still had the AI contribute the full $20, over-matching a bet that was never actually made. Fix: `aiCall = amount.clamp(0, state.aiChips)` — AI can never contribute more than what's needed to match the player's real bet.
  - `playerCall()`: the mirror case — when the player is short-stacked and can't fully call a bigger AI bet, the AI's already-committed excess (added to the pot when AI first bet) stayed in the pot uncontested instead of being returned. Fix: compute `uncalled = needed - diff` and return it to `aiChips`, deducting it back out of `pot` — the heads-up equivalent of an uncalled-bet return / missing side pot.
- **GB4 (Poker)** — `evaluateHand()`'s wheel-straight special case (A-2-3-4-5) correctly detected `isStraight = true` but reused the general `tieRanks` array (built from `groups`, sorted by raw rank key) for its `HandResult`, which put the Ace's rank index (12, the highest possible) first — making a wheel compare as if it were *Ace-high*, when by rule the Ace plays low in a wheel and it must be the *lowest*-ranking straight. This let a wheel wrongly beat or tie a King-high (or even a 6-high) straight. Fix: added an `isWheel` flag and a dedicated `straightTieRanks` (`const [3, 2, 1, 0, -1]`, representing a 5-high straight) used only for the wheel case, applied uniformly to both the plain-straight and straight-flush ("steel wheel") return paths — the general `tieRanks` used by four-of-a-kind/full-house/etc. is untouched.
- Tests: `test/uno_test.dart` — added a `_SeededUnoNotifier` + `_makeSeeded()` helper (same pattern as prior sessions' Checkers/Cribbage seeded-state tests) since forcing the AI to hold and play a specific Wild +4 needs exact hand control; 1 new case using `fake_async` to drain the real internal timer deterministically. `test/poker_test.dart` — added `_SeededPokerNotifier`/`_bettingState()` for GB3 (4 new cases: short-stacked `playerBet` and `playerCall`, plus a full-stack case for each proving the fix doesn't change normal-chip-count behavior); 2 new `HandResult.compareTo` cases for GB4 (wheel vs. 6-high straight, and steel-wheel vs. a higher straight flush).
- Verified live on the Android emulator: Poker — bet/call/draw/showdown flow (touching both the `playerBet()` AI-call path and `evaluateHand()`/`compareTo()` at showdown) completed normally with correct chip settlement, no crash. Uno — played a card through `_applyPlayerCard()` and watched the AI respond via `_aiTurn()` (the exact function GB2 modified) with no crash. The specific bug scenarios (AI forced to hold a Wild +4; a player chip stack low enough to clamp) are rare/hard to force via UI taps against random deals and 500-starting-chip stacks — verified precisely via the seeded unit tests instead, consistent with how the GB6/8/9/10 and GB11/12/13 rounds handled the same tradeoff.
- `flutter analyze` 0 · `flutter test` 721 (+7) · `flutter build apk --debug` succeeded.
- Context: `outstanding.md` (GB2/GB3/GB4 rows removed — all three resolved), `uno/gameflow.md` + `poker/gameflow.md` self-healed (see below).

## [2026-07-15] — GB11/GB12/GB13: fixed Cribbage pegging stall + double-scoring + wrong peg lead (all three interlinked)
- User asked to knock out GB11 (high, human "Go" never implemented), GB12 (medium, double-scoring on a stoppage), and GB13 (medium, peg lead hardcoded to dealer status) together, since all three live in the same pegging code and turned out to be structurally connected.
- **Root cause investigation** (before writing any fix): traced why GB12's double-score happens. `playPegCard`'s human-side "last card" stoppage check (`!aiCanPlay && newPegging.isEmpty`) awarded the player +1 but never reset `pegTable`/`pegCount`, then unconditionally scheduled `_aiPegTurn`, which **independently rediscovered** the same "neither side can play" condition and awarded AI another +1 for the identical stoppage. Investigating GB13 alongside it surfaced a second, unreported defect in the same "both can't play" branch: it **unconditionally credited `aiScore`**, even in cases (confirmed by tracing turn alternation) where the *player* had actually played the table's last card — meaning the point was misattributed, not just duplicated, in some paths. Fixing GB12 in isolation without addressing this would have left a related bug in place, so both were fixed together via one mechanism.
- **Fix**: added `CribbageState.lastToPlayWasHuman` (bool?, tracks who most recently added a card to `pegTable`, not a Go pass) — set at all 4 places a card is added to the table (both players' normal-continue and 31-hit branches). Introduced `_resolveGoStoppage()`, a single shared method that awards the point to whoever `lastToPlayWasHuman` says played last (not to whichever side's code path happened to detect the stoppage), resets the table/count, and sets the next leader to the *other* side — replacing two near-duplicate, subtly-wrong inline implementations (one in `_aiPegTurn`, and the missing human-side equivalent that GB11 needed). Also fixed the two `newCount == 31` branches (`playPegCard` and `_aiPegTurn`), which used `isPlayerPegging: !state.isPlayerDealer` for the post-reset lead — wrong whenever the player wasn't the dealer, since it could leave the same player leading twice in a row right after their own 31. Replaced with the simple, correct rule: the side that did NOT just play leads next.
- **GB11**: added `sayGo()` to `CribbageNotifier` — validates the player truly has no legal card, then either passes to AI (if AI can still play, no score) or calls `_resolveGoStoppage()` (if neither can). Added the missing UI affordance in `screen.dart`'s `_PeggingPhase`: a "Go" button appears (replacing "Your hand — tap to play" with "No legal play") whenever none of the player's pegging cards fit under 31 — previously the screen only dimmed the cards with no way to proceed at all.
- Tests: `test/cribbage_test.dart` — added a `_SeededCribbageNotifier` + `_peggingState()` helper (mirrors the Checkers/Backgammon seeded-state pattern from the earlier GB6/8/9/10 session) to construct exact mid-pegging scenarios rather than relying on random dealt hands. 9 new cases across 3 groups (`sayGo (GB11)`, `playPegCard stoppage handling (GB12)`, `peg lead after reset is independent of dealer status (GB13)` — the latter parameterized over both dealer states to prove the fix isn't accidentally dealer-dependent in a different way).
- **Test infrastructure finding**: the notifier schedules real `Future.delayed` timers (AI's peg turn, 600ms; counting transition, 400ms) that can chain up to 2 hops deep. Initial attempts using real `await Future.delayed(...)` in tests were flaky — a timer left pending when one test completes fires later against that test's already-disposed `ProviderContainer`, and because Dart's timer queue isn't test-scoped, a slow-draining test's dangling timer can also collide with a *different*, unrelated test running later in the same file. Switched every timer-touching test (including 3 pre-existing ones that predate this session and had the same latent issue, only now surfaced because these new tests made the suite run long enough for it to matter) to the `fake_async` package's `fakeAsync()`/`async.elapse()` — deterministic virtual time, zero real wall-clock wait, and no cross-test interference. Added `fake_async: ^1.3.3` as an explicit `dev_dependency` (was already resolved transitively, now direct since the test file imports it).
- `flutter analyze` 0 · `flutter test` 714 (+9) · `flutter build apk --debug` succeeded.
- Verified live on the Android emulator: played into a pegging count of 30, confirmed all three remaining hand cards correctly dimmed with "No legal play" and a working **Go** button (GB11); tapped it, and since the AI had played the table's last card, AI's score went from 0 to exactly **1** — not 2 (GB12) — and the turn correctly passed back to *me* to lead the next series, not hardcoded by dealer status (GB13) — one live sequence confirming all three fixes together.
- Context: `outstanding.md` (GB11/GB12/GB13 rows removed — all three resolved), `cribbage/gameflow.md` self-healed (see below).

## [2026-07-15] — GB6/GB8/GB9/GB10: fixed 4 high-severity game logic bugs found in the earlier LT5 gameflow audit (Dudo, Backgammon, Checkers ×2)
- User asked to knock out the 4 **high**-severity rows from the LT5 audit findings (`outstanding.md` "Games — logic bugs found via LT5 gameflow audit") — all four already root-caused with exact file/symptom, no scoping needed, unlike S4/S6.
- **GB6 (Dudo)** — `resolveChallenge()` (`dudo/logic.dart`) computed `loserIndex` correctly (bidder or caller depending on whether the bid held) but never wrote it back to `state.activePlayer`. `determineRoundOver()` then used `state.activePlayer` to pick the next round's starter — correct only when the *caller* lost (their index already equaled `activePlayer`), silently wrong when the *bidder* lost (the caller, not the bidder, wrongly started the next round). Fix: `resolveChallenge()` now sets `activePlayer: loserIndex` explicitly. Also trimmed a long stale comment block in `determineRoundOver()` that had rationalized around the bug ("use activePlayer as the round's loser signal *when* resolveChallenge left activePlayer as loser") rather than fixing it.
- **GB8 (Backgammon)** — `validHumanMoves`/`validAiMoves` (`backgammon/logic.dart`) accepted *any* die that overshot bearing-off (`dest < -1` / `dest > 24`) once all checkers were home, without checking whether a checker remained on a higher point (real backgammon requires bearing off the highest-point checker first, or using the exact die, before an overshoot from a lower point is legal). Fix: both functions now scan the home-board range between the moving checker and the far edge for a still-occupied higher point, rejecting the overshoot if one exists; exact bear-off (`dest == -1` / `dest == 24`) remains unconditionally legal.
- **GB9 (Checkers)** — `_executeMove` (`checkers/logic.dart`) promoted a piece to king *before* checking for a chain jump, so `getChainJumps` saw a king (bidirectional) and could offer a backward capture no plain man should get mid-move — real rules end the turn immediately on promotion, even mid-chain. Fix: added a `justPromoted` check (piece was a plain man, `move.toRow == 7`) that skips the chain-jump check entirely when true.
- **GB10 (Checkers)** — `selectCell`'s `mustJump` branch filtered `state.allMoves` by the *tapped* piece's coordinates, not the piece actually mid-chain, so tapping a different own piece with its own independent jump would silently steal the selection and abandon the forced continuation. Fix: added a new `CheckersState.mustContinueChain` bool (`true` only while `_executeMove` has just forced a chain continuation), and `selectCell` now ignores any tap while `mustContinueChain` is true unless it lands on one of the current piece's own `validMoves` destinations (handled by the existing top-of-function check). Also had to explicitly reset the flag to `false` at both of `_executeMove`'s turn-ending branches (win condition, switch-to-AI) — since it's a plain bool retained via `copyWith`'s `?? this.field` pattern, leaving either branch without an explicit reset would have permanently locked the player out of selecting any piece on their next turn.
- Tests: `test/dudo_test.dart` — 2 new cases (wrong-bid branch: `activePlayer` becomes the bidder, not left on the caller; correct-bid branch: unchanged behavior confirmed as a regression guard). `test/backgammon_test.dart` — 5 new cases across both `validHumanMoves`/`validAiMoves` (overshoot rejected with a higher/further-back checker present; overshoot still allowed from the highest/furthest-back point; exact bear-off always allowed regardless of other checkers). `test/checkers_test.dart` — a new `_SeededCheckersNotifier` test helper (subclasses `CheckersNotifier`, overrides `build()` to inject an arbitrary board/selection state via a Riverpod provider override) since the exact bug scenarios need specific board configurations unreachable from the standard starting position in a reasonable number of moves; 3 new cases covering GB9 (promotion mid-jump ends the turn) and GB10 (a different piece's independent jump is ignored mid-chain; continuing the forced chain still works normally).
- Verified live on the Android emulator: opened Dudo (3 players), called Dudo on an AI's honest bid, confirmed the correct branch (caller-loses) correctly set the caller as next-round starter live (matches the unit-tested wrong-bid branch's fix, which is far more precise to reproduce deterministically than via UI taps against AI randomness); opened Checkers, made a normal move, confirmed the AI responded and turn passed back cleanly (no crash/hang from the new `mustContinueChain` state field); opened Backgammon, rolled dice, selected and attempted moves, confirmed both valid-move and invalid-move taps were handled gracefully with no crash. The 4 exact bug scenarios themselves (specific rare board/dice configurations) are verified by the unit tests above rather than live UI reproduction — more reliable given they require precise, deterministic states that are impractical to force via taps against AI-driven and dice-random gameplay.
- `flutter analyze` 0 · `flutter test` 705 (+10) · `flutter build apk --debug` succeeded.
- Context: `outstanding.md` (GB6/GB8/GB9/GB10 rows removed — all four resolved).

## [2026-07-15] — S2: added value equality (==/hashCode/toString) to all 25 domain models — explicitly narrower than a full freezed migration, by user decision
- User asked to do S2 next (`freezed` + `json_serializable` migration for immutability, equality, generated `fromJson` — logged low severity, tied to T4's "silent mutation bugs" complaint). Before writing any code, checked the actual blast radius of the literal scope: 22 files (25 model classes across them), no `freezed`/`json_serializable` dependency in `pubspec.yaml` yet, and the `Model()..field = x` cascade-mutation construction pattern used **181 times across 72 files in `lib/`, plus 159 more in `test/`** (340 total) — every one of those would need rewriting to a full-constructor or `.copyWith()` call under freezed, since freezed classes are immutable. Flagged this size/risk mismatch (a low-severity backlog item implying a multi-day, whole-app-touching rewrite) before proceeding rather than guessing at scope.
- Asked the user to choose between: full migration now, a 2-3 model pilot first, a lighter equality-only version (skip freezed/immutability entirely), or skipping S2 for now. User asked what "freezing" a model actually means first (answered: immutable construction + generated `==`/`hashCode`/`toString`, at the cost of rewriting every mutation site to `copyWith`), then explicitly chose the **lighter equality-only version, declining immutability**, and confirmed this closes out S2 — a deliberate, binding scope decision, not a partial/interrupted migration.
- Implemented: hand-written `==`/`hashCode`/`toString` overrides on all 25 model classes (`BarIngredient`, `Boat`, `CaptainLogEntry`, `ChecklistGroup`, `ChecklistItem`, `CommunityTemplate`, `ConflictLog`, `CrewMember`, `Document`, `FuelLogEntry`, `GuestProfile`, `InventoryItem`, `MaintenanceTask`, `MealPlan`, `MealPlanSlot`, `PantryIngredient`, `PurchaseRecord`, `Recipe`, `RecipeCollection`, `RecipeIngredient`, `ShoppingCategory`, `ShoppingItem`, `SyncOutbox`, `TastingRecord`, `UserSettings`) — field-by-field comparison for scalars/`DateTime`/nullable fields; `List`-typed fields (`completionHistory`, `crewOnBoard`, `photos`, `flavorProfiles`, `cuisineTypes`, `allergenTags`, `dietaryTags`, `recentEmails`, `guestProfileIds`, `recipeSupabaseIds`, `cuisine`, and nested-model lists `purchaseHistory`/`tastingLog`/`slots`) use `listEquals` (from `package:flutter/foundation.dart`, newly imported in the `models.dart` barrel) in `==` and `Object.hashAll(list)` folded into the outer `Object.hashAll([...])` in `hashCode` — Dart's default `List.==`/`hashCode` are identity-based, so a naive field-by-field `==` would have silently failed to compare list content. Nested-model list fields (`purchaseHistory: List<PurchaseRecord>`, `tastingLog: List<TastingRecord>`, `slots: List<MealPlanSlot>`) work correctly only because `PurchaseRecord`, `TastingRecord`, and `MealPlanSlot` also got their own `==`/`hashCode` in this same pass — `listEquals`/`Object.hashAll` on a list of models delegates to each element's own equality. `toString()` omits a few long free-text fields (`CommunityTemplate.content`'s embedded JSON, `Recipe.instructions`/`story`, `SyncOutbox.data`) for log readability while still including them in `==`/`hashCode`.
- Models remain fully **mutable** — no `copyWith`, no constructor-enforced immutability, no codegen. This is a real, explicit reduction in scope from freezed's ask, documented so a future session doesn't assume T4/S2 means "do the immutability part too."
- Tests: `test/model_equality_test.dart` (new) — spot-checks the pattern rather than repeating it 25×: a scalar-only model (`CrewMember`) for basic equal/unequal + `toString` override sanity, a `List<String>` field (`ChecklistItem.completionHistory`) proving content-equality (not list reference identity) with an explicit `identical()` sanity check that the two lists really are distinct objects, a nested `List<Model>` field (`BarIngredient.purchaseHistory`) proving the nested `PurchaseRecord` equality cascades correctly, and an explicit equal-objects-have-equal-hashCodes contract check on a model with several list fields (`PantryIngredient`) — this is the check most likely to silently break if a field were added to `==` but forgotten in `hashCode` or vice versa.
- `flutter analyze` 0 · `flutter test` 694 (+8, all passing, zero regressions from switching every model from identity to value equality — confirms nothing in the app relied on two distinct-but-equal-content model instances being treated as different) · `flutter build apk --debug` succeeded.
- Context: `outstanding.md` (S2 row removed — resolved at the scope the user chose; T4 row removed too — its "lack of copyWith/equality/toString" complaint is now equality/toString-solved, and the "prefer freezed" half of its own recommendation was explicitly declined by the user rather than deferred, so re-opening it under a different number would just reintroduce the same already-declined debate; its now-empty "Navigation / architecture debt" section header removed), `data_models.md` (new note under "All Data Models" explaining the equality implementation and its deliberate immutability gap), `INDEX.md` NEXT pointer.

## [2026-07-15] — CB1: fixed the "Oven" cooking-method dropdown crash + a second latent spacing mismatch (verified on device)
- User asked to fix CB1 next (a real crash bug found and logged, not fixed, during NAV2's live verification): `AddEditRecipeDialog`'s "Cooking method" `DropdownButtonFormField` crashes on an assertion when editing any recipe whose stored `cookingMethod` isn't in `_methodOptions` (`cocktails_screen.dart`) — the list had `'Bake'` but seed data actually stores `'Oven'`.
- Investigated scope before fixing: seed data (`assets/seed/menus_import_seed.json`) uses exactly 5 `cookingMethod` values — `Grill`, `One-pot`, `Oven`, `Raw / No-cook` (with spaces), `Stovetop`. `chef_screen.dart`'s own (separate) browse-filter list already has the correct spellings for all of these. `_methodOptions` had two mismatches, not one: `'Bake'` instead of `'Oven'` (36 seeded recipes affected, not just the one found live) and `'Raw/No-cook'` (no spaces) instead of `'Raw / No-cook'` (6 more recipes affected) — the second mismatch wasn't in the original CB1 finding, found by cross-checking the seed JSON directly rather than trusting the single repro.
- Fix: renamed `'Bake'` → `'Oven'` and `'Raw/No-cook'` → `'Raw / No-cook'` in `_methodOptions` to match the seed data exactly (confirmed via grep that `'Bake'` and the no-space `'Raw/No-cook'` never appear as a *stored* value anywhere — only ever as this one dropdown's now-corrected labels — so no data migration was needed, a pure label fix).
- Tests: `test/add_edit_recipe_dialog_test.dart` — 2 new cases pumping the dialog with an existing recipe whose `cookingMethod` is `'Oven'` / `'Raw / No-cook'` respectively, asserting `tester.takeException()` is null (would have caught both mismatches pre-fix).
- Verified live on the Android emulator: Chef → "Traditional Bobotie" (the exact recipe from the original CB1 repro, `cookingMethod: 'Oven'`) → Edit → confirmed the Edit Recipe screen opens cleanly with "Cooking method" showing "Oven" selected, no crash.
- `flutter analyze` 0 · `flutter test` 686 (+2) · verified live (no `flutter build` needed — pure Dart/test change, already running via `flutter run` for the live check).
- Context: `outstanding.md` (CB1 row removed — resolved; its now-empty "Bugs found via NAV2 live verification" section header removed too), `INDEX.md` NEXT pointer.

## [2026-07-15] — S5 Community Marketplace round 2: ratings + template versioning (non-destructive merge) — S5 now fully shipped (verified on device)
- User asked to "continue with s5" — the two items round 1 explicitly deferred: ratings and template versioning. For the version-update merge behavior, user gave an exact binding spec: *"Merge as suggested, but add a warning off how many duplicates and that these would not be replaced, but rather merged. Add fields from source will be added, existing extra fields at destination will be kept."* — i.e. a pre-merge confirmation dialog with exact counts, new source items/fields added, matched items refreshed (text only, local state kept), and any local item with no match in the new source (a user's own addition, or something the author removed) kept, never deleted.
- **Ratings**: new Supabase `community_ratings` table (`id` bigint identity, `template_id` FK cascade, `user_id`, `rating` smallint 1–5, `unique(template_id, user_id)`, RLS: read-any-authenticated / upsert-update-delete-own) + `recompute_community_rating()` trigger maintaining denormalized `community_templates.avg_rating`/`rating_count` — mirrors the `download_count`/`community_downloads` pattern from round 1. `CommunityRepository.rateTemplate()`/`getMyRating()`. UI: tappable 5-star row + rate dialog on every `_TemplateCard`.
- **Template versioning**: `community_templates.version` (starts at 1, incremented client-side on `updateTemplate` — fetch-then-`+1`, not a raw SQL expression, since PostgREST needs an RPC for that; acceptable for a single-author-updates-own-row case). New `ChecklistGroup.communityTemplateId`/`communityTemplateVersion` fields, reused symmetrically for both the importer side (which template + version a copy came from) and the author side (which template this group publishes to, stamped via new `linkGroupToTemplate` after every publish/update) — disambiguated at read-time by `origin != 'community'` rather than adding a second pair of fields. The publish picker now detects "already published" and shows an Update flow (pre-filled from `getCachedTemplate`, a local-only Drift read) instead of a duplicate publish.
- **Non-destructive merge**: new pure function `computeCommunityMergeDiff` (`lib/services/community_merge.dart`, zero I/O) matches local items to source items by `title.toLowerCase().trim()` and returns `toAdd`/`toUpdate`/`keptCount` — reused by both the confirm dialog's preview and `CommunityRepositoryImpl.applyCommunityUpdate`'s actual apply, so there's exactly one diff computation, not a separate preview round-trip. The confirm dialog shows the user's exact required copy (counts of each bucket + "Nothing is replaced or deleted — this only adds and merges.") before a "Merge Update" button applies it.
- **Found and fixed a second real bug, this one via live testing of the new code** (separate from round 1's `id: null` bug): `CommunityRepositoryImpl.updateTemplate` sends `template.toJson()` on every republish, and a freshly-built `CommunityTemplate` defaults `isApproved` to `false` — `updateTemplate` never re-set it to `true` before sending, unlike `publishTemplate`. Every republish was silently flipping `is_approved` from `true` to `false` in Postgres, pulling the template out of everyone's browse/import list with no error, no warning, and no way to notice short of checking the DB directly. Caught live: republished a test template, confirmed via direct Supabase query that `is_approved` had flipped false, manually corrected the row, fixed the repository to force `isApproved = true` in `updateTemplate` (matching the "open community — publishes are live immediately" policy already used in `publishTemplate`), rebuilt, and re-verified the same live repro no longer regresses (`is_approved` stayed `true` through a second republish that also correctly bumped `version` 2→3). Not unit-testable in the offline test harness (the mutation sits after a `SupabaseClientWrapper.instance.auth` access that itself throws with no network), so this one relies on the live repro + fix + code review rather than an automated regression test — an explicit, deliberate exception to "write a test for every bug," logged here so the reasoning isn't lost.
- Drift `schemaVersion` 10→11: `CommunityTemplates.avgRating`/`ratingCount`/`version`, `ChecklistGroups.communityTemplateId`/`communityTemplateVersion`.
- Tests: `test/community_merge_test.dart` (new, 7 tests) — add-only, matched-unchanged (no-op), matched-changed (local state preserved), kept-not-deleted, case/whitespace-insensitive matching, empty/empty, and a realistic mixed one-add/one-update/one-kept scenario. `test/community_template_test.dart` — `fromJson` ratings/version mapping + defaults, `toJson` always includes `version`, `ChecklistGroup` `communityTemplateId`/`Version` round-trip (both set, and both null for a plain user-created group). `test/community_repository_test.dart` — 7 new S5-round-2 cases: 4 network-fallback-contract tests (`updateTemplate`/`rateTemplate`/`getMyRating`/`applyCommunityUpdate`), 3 genuine local-only positive tests (`getCachedTemplate` hit/miss, `linkGroupToTemplate` verified via a direct Drift read-back).
- Verified live end-to-end on the same Android emulator used for round 1: rated a template (tapped 4 stars → card updated to "4.0 (1)", proving client→trigger→UI round-trip), republished the author's own list (version 1→2, confirmed via direct Supabase query, "already published — tap to update" correctly appeared on re-open of the picker), imported a fresh copy of the v2 template into a second local checklist group, republished the source again (v2→3, content unchanged), confirmed the fresh copy's card correctly showed an "Update available" chip + Update button (comparing local `communityTemplateVersion: 2` against the live `version: 3`), and confirmed tapping Update correctly computed an empty diff (content genuinely unchanged between v2/v3) and showed "Already up to date" rather than a pointless empty merge dialog — confirming the whole detection → diff → branch pipeline, not just the happy path with real changes (which is covered by the unit tests instead).
- `flutter analyze` 0 · `flutter test` 666+29 (all community-area tests) · `flutter build` (Android debug) succeeded, rebuilt once after the `isApproved` fix.
- Context: `outstanding.md` (S5 row removed entirely — fully resolved, both rounds), `data_models.md` (`ChecklistGroup.communityTemplateId`/`Version`, `CommunityTemplate.avgRating`/`ratingCount`/`version`/`isApproved` open-community-policy note, `community_ratings` table, `computeCommunityMergeDiff`, `CommunityRepository`'s 6 new methods), `caching.md` (schemaVersion 10→11), `INDEX.md` NEXT pointer.

## [2026-07-15] — S5 Community Marketplace: fixed the core publish/import loop + shipped most-downloaded sort + boat/engine taxonomy (verified on device)
- User chose to focus this round on "the core loop" (real publish + category-correct import + most-downloaded sort + boat/engine search) over ratings/versioning, and asked for a real curated taxonomy (not free text) for engine/boat search.
- **Found and fixed a critical, previously-undiscovered bug**: `CommunityTemplate.toJson()` sent an explicit `'id': null` for a new (unpublished) template. Postgres only applies a column's `default gen_random_uuid()` when the column is *omitted* from an insert — an explicit `null` sets it to NULL instead, which violates the primary key's not-null constraint. Confirmed via `mcp__supabase__get_logs`: `null value in column "id" of relation "community_templates" violates not-null constraint`. This means **publishing had never worked, even once, before this fix** — the pre-S5 blank-form dialog would have hit this exact same failure and shown "Publish failed" every time (its `catch (_) { return template; }` fallback silently swallowed it). Fixed by omitting the `id` key entirely when `supabaseId` is empty (`if (supabaseId.isNotEmpty) 'id': supabaseId` instead of `'id': supabaseId.isEmpty ? null : supabaseId`).
- **Real "share an existing list" publish flow**, replacing the old blank-form dialog that always produced `content: {"items": []}` regardless of what was typed: Community screen's FAB now opens a bottom-sheet picker (`_pickListToShare`) listing the user's own checklist/maintenance/safety groups (via the existing `checklistGroupsProvider(null)`, no new provider needed) with an icon+category badge per group; tapping one opens a confirm dialog (description + engine/boat tag) that serializes the group's *real* items via the new `CommunityTemplate.fromChecklistGroup()` factory (`lib/models/community_template.dart`) — `category` comes from `group.appType`, not a user-picked dropdown, so browsing by category always matches what import creates.
- **Import already worked correctly** for all 3 categories (it reads `appType` from `content` and sets it on the created `ChecklistGroup`) — the "import only understands checklists" gap identified during research turned out to be a symptom of the publish bug above (content never had a real `appType` in it), not a separate import bug. No changes needed to `importTemplate`.
- **Most-downloaded sort**: new `CommunitySortOrder` enum (`recent` | `mostDownloaded`) on `CommunityRepository.browseCommunity()`; denormalized `download_count` column on `community_templates` (Supabase migration `0007_community_download_count.sql`, applied live) maintained by an `AFTER INSERT ON community_downloads` trigger — keeps browsing cheap (`order by download_count desc`) instead of a per-row count subquery. `CommunityTemplate.downloadCount` (new field, server-maintained, never sent by the client) flows through `fromJson`. UI: a `SegmentedButton` (Recent/Most Downloaded) plus a download-count chip on every `_TemplateCard`.
- **Boat/engine taxonomy** (real curated list, not free text, per explicit user choice): new `lib/core/boat_engine_taxonomy.dart` (`BoatEngineTaxonomy.makes` — Yanmar, Volvo Penta, Perkins, Beta Marine, etc.) drives both the publish confirm dialog's "Engine/Boat" dropdown and a new browse-screen filter dropdown, using the `subcategory` field that already existed end-to-end (model/Drift/Supabase/repo param) but was never surfaced in any UI before this.
- **Fixed a real (if minor) bug**: the category filter dropdown listed `'safety_briefing'`, but the actual discriminator value everywhere else (`ChecklistGroup.appType`, seed data, `importTemplate`'s parsing) is `'safety'` — browsing by "Safety Briefing" would never have matched anything. Unified to `'safety'`.
- Drift `schemaVersion` 9→10 (migration `from < 10`: adds `CommunityTemplates.downloadCount`).
- Tests: `test/community_template_test.dart` (new) — `fromChecklistGroup` category/field-mapping/content-JSON-shape/empty-items coverage, plus the `toJson` id-omission regression test (both the "new template omits id" and "existing template includes its real id" cases). `test/community_repository_test.dart` — added a `sortBy: mostDownloaded` fallback-contract test.
- Verified live end-to-end on an Android emulator, including the failure and the fix: first attempt hit the id:null bug ("Publish failed — try again"), root-caused via `mcp__supabase__get_logs`, fixed, rebuilt, republished successfully ("On-Watch Monitoring Checks" shared, 0 downloads), then imported it back and confirmed a new `community`-badged checklist group appeared with all 16 real items (not an empty shell) and the correct category — the full loop, not just individual pieces.
- `flutter analyze` 0 · `flutter test` 666 (+7) · `flutter build apk --debug` succeeded (x2, before/after the id-null fix).
- Context: `outstanding.md` (S5 narrowed to ratings + versioning only, both still unbuilt), `data_models.md`/`caching.md`/`screens.md` updated (see below).

## [2026-07-14] — NAV2: converted remaining anonymous Navigator.push routes to named GoRouter routes (verified on device)
- Completed the NAV2 backlog item — some of it (shopping/cocktail/chef nested routes, collections, ingredient details, barcode scanner path registration) had already landed in an earlier pass; this session finished the rest: registered the missing GoRoutes (`fuelDetail`, `crewDetail`, `inventoryDetail`, `documentsDetail`, `checklistItemDetail`, `safetyItemDetail`, `maintenanceItemDetail`) and converted every remaining `Navigator.push(MaterialPageRoute(...))` call site to `context.push(AppRoutes.x, extra: ...)`.
- New shared args classes (mirroring the existing `AddEditRecipeArgs` precedent) so closures/callbacks pass through GoRouter's `extra` cleanly: `RecordDetailArgs` (`record_detail_screen.dart`, shared by Fuel/Crew/Inventory/Documents — all four render the same `RecordDetailScreen`) and `CheckPageViewerArgs` (`check_page_viewer.dart`, shared by Checklists/Safety/Maintenance's `showCheckPageViewer` extension, which now takes a `routePath` param since the three modules push to different named routes but render the same `CheckPageViewer`). Added `_recordDetailBuilder`/`_checkPageViewerBuilder` shared route builders in `app_router.dart` to avoid 4x/3x duplicated unwrap logic.
- Converted call sites across `fuel_screen.dart`, `crew_screen.dart`, `inventory_screen.dart`, `documents_screen.dart`, `shopping_screen.dart`, `collections_screen.dart` (2 sites), `chef_screen.dart` (6 sites: 3× `AddEditRecipeDialog`→`recipeEditor`, `IngredientDetailScreen.pantry`→`pantryIngredientDetail`, `GuestProfilesScreen`→`guestProfiles`, `MealPlannerScreen`→`mealPlanner`), `cocktails_screen.dart` (9 sites: `CollectionsScreen`, 4× `AddEditRecipeDialog`, `CocktailBatchScreen`, 2× `IngredientDetailScreen.bar`, `BarcodeScannerScreen`). Cleaned up now-unused imports at each site (several were leftover from the earlier partial pass, e.g. `chef_screen.dart` importing `collections_screen.dart` for a call site that was already converted).
- Deliberately left one anonymous `Navigator.push` as-is: `RevenueCatService.showPaywall()` (`revenuecat_service.dart`) — a single centralized service method already called from dozens of screens (not scattered duplication, the exact problem NAV2 targeted), and outside NAV2's original described scope.
- **Found a real, pre-existing bug via live verification** (logged as CB1 in `outstanding.md`, not fixed — out of scope for a routing task): `AddEditRecipeDialog`'s "Cooking method" dropdown crashes when editing any recipe with `cookingMethod: 'Oven'`, because `_methodOptions` lists `'Bake'` but not `'Oven'` — a `DropdownButtonFormField` assertion failure, unrelated to routing (same crash would occur regardless of push mechanism). Confirmed unrelated by testing the clean "add new recipe" path (no existing data) on the same newly-converted `recipeEditor` route, which rendered correctly with no crash.
- Live-verified on an Android emulator: `checklistItemDetail` (tapped a real checklist item, confirmed the "On-Watch Monitoring Checks · 1 of 16" position header and full detail view render correctly through `CheckPageViewerArgs`), `recipeEditor` new-recipe path (Chef → Add manually → form renders cleanly), `chefRecipe` (pre-existing, confirmed still working), and confirmed the CB1 crash's Android back button still correctly unwound the GoRouter/Navigator stack back to the underlying screen (no frozen state) — i.e. the routing infrastructure itself stayed robust even when a pushed screen's internal state crashed.
- `flutter analyze` 0 · `flutter test` 659 (unchanged — pure navigation refactor, no new tests needed) · `flutter build apk --debug` succeeded.
- Context: `outstanding.md` (NAV2 row removed; new CB1 finding logged under "Bugs found via NAV2 live verification"), `INDEX.md` NEXT advanced past NAV2.

## [2026-07-13] — Liar's Dice: AI never held dice on reroll — blind full reroll every turn, fixed
- User feedback while watching a focused 2-player (1 human + 1 AI) live persistence test: "the AI should also hold dice — for a simple AI, hold the best hand and roll the rest." Checked the code and confirmed it: the AI's auto-roll timer in `screen.dart` called `rollDice()` (a totally fresh reroll of all 5 dice) every single turn, never `rollDiceWithHolds()` — so any inherited one-box hand (e.g. a pair passed from an accepted declare) was silently discarded and rerolled blind, every time, regardless of quality.
- Fixed: new `bestHoldMask(dice)` in `helpers.dart` — holds whichever face forms the largest group (ties broken by higher face value), reroll mask of all-false if nothing pairs up. Deliberately simple (no straight-completion logic) per the user's "simple AI" framing. Wired into the AI auto-roll timer: `rollDiceWithHolds(currentPlayer.dice, bestHoldMask(currentPlayer.dice))` instead of a blind `rollDice()`.
- Also self-healed `gameflow.md`'s "AI Strategy" section while updating it: it still described the pre-F7 (2026-05-... era) bidding behavior ("highest valid face") and didn't mention `getAIAccept`'s rarity-weighting — both were fixed 2026-07-04 (F7) but the doc was never updated. Corrected alongside the new rolling-strategy paragraph.
- Tests: 6 new deterministic `bestHoldMask` cases in `test/liars_dice_test.dart` (high card → hold nothing; one pair/three-of-a-kind → hold the group; two pair → higher face wins the tie-break; five-of-a-kind → hold everything).
- Verified live in solo mode (1 human + 1 AI, no LAN needed — same `GameStateNotifier` code path as multiplayer): the AI won the opening roll-off, and on its very first turn declared "Four of a Kind of Aces" — a claim rare enough (<2% of honest rolls) to be surprising after a single blind reroll. Challenged it and **lost the challenge** (the AI's hand was truthfully ≥ Four of a Kind), which is strong circumstantial confirmation the hold logic is working: building a four-of-a-kind by holding a strong group from the initial roll and rerolling 1-2 dice is far more plausible than landing it blind. Exact pre-reroll dice aren't independently observable (hidden AI state, by design, same restriction a real human opponent has), so this is the strongest live confirmation available short of temporary debug instrumentation — combined with the deterministic unit tests, sufficient confidence to close this out.
- `flutter analyze` 0 · `flutter test` 659 (+6).
- Context: `gameflow.md` AI Strategy section (rolling/holding behavior + 2 stale F7-era facts corrected).

## [2026-07-13] — Liar's Dice: lobby lifecycle (Cancel/clean teardown) — found a real bug in my own first fix via live-device verification
- User feedback while watching the live 4-sim test: the lobby needs visible Cancel/Retry affordances, and canceling a hosted session (or a single peer dropping) must be a clean teardown, not leave a "zombie" broadcasting host — exactly what I'd hit earlier setting up the test (a mis-tapped Host Game session kept appearing in every future scan, unreachable but listed, because nothing ever called `GameLanService.endSession()` when leaving the lobby without starting).
- Added: `GameLobbyScreen` now tracks `_gameStarted` (set right before navigating to the actual game screen) and calls `_lan.endSession()` in `dispose()` whenever the lobby is left *without* starting — covers hardware back, the AppBar back button, and new explicit "Cancel Hosting"/"Cancel" buttons added to `_HostingView`, `_JoiningView`, and `_WaitingView` (previously the waiting-for-host screen had no way to back out at all). `LanEngine.dispose()` (already correct, checked before relying on it) closes every peer socket, the host socket, the server, and stops the mDNS broadcast/discovery, fully resetting state so a later host/join works cleanly — confirmed by re-hosting from the same session after a cancel.
- **First fix attempt was silently broken — caught by verifying with OS-level ground truth, not just a screenshot.** Initial version used `GameLanService get _lan => ref.read(gameLanServiceProvider);` (a getter re-reading on every access, including from `dispose()`). A screenshot after tapping "Cancel Hosting" looked correct (cleanly back on the Games screen), so it was initially reported as fixed. It wasn't: a re-scan from a second device still found the "cancelled" host, still connectable. Tracked down via `lsof -nP -iTCP:<port>` (proved the WebSocket server was still bound and had an established connection) and `flutter run`'s live console (surfaced `EXCEPTION CAUGHT BY WIDGETS LIBRARY: Bad state: Using "ref" when a widget is about to or has been unmounted is unsafe` — Riverpod's own error message names the fix: cache provider state in a field, don't `ref.read()` inside `dispose()`). Flutter's widget-tree-finalization exception handling had swallowed this every time, so canceling always *looked* like it worked (correct navigation, no crash) while silently never running `endSession()`.
- Real fix: `late final GameLanService _lan = ref.read(gameLanServiceProvider);` — resolved once (lazily, on first access from `build()`/`_host()`/`_scan()`, long before `dispose()` runs), safe to reuse in `dispose()`. Re-verified the identical repro end-to-end via `flutter run` (to see the console): hosted, confirmed the port was bound (`lsof`), tapped Cancel Hosting, confirmed **no exception** in the console and the port **no longer bound** (`lsof` returned nothing), then a fresh scan from a second device found zero entries.
- Mid-game single-peer disconnect (not the lobby-cancel case above) was already clean at the transport layer — `LanEngine._attach()`'s `onDone` callback already removes the dead peer from `_peers` and emits `peerLeaves`, so `broadcast()` never touches a closed socket. **Not implemented**: reconnecting mid-game into your *same* seat (dice/counters/turn position) — a returning peer currently gets a brand-new `peer_N` id with no path back into `GameState.players`, since `GameLanService`'s lobby-level `join` handling has no hook into the already-started `GameStateNotifier`. This crosses a real architecture boundary (generic transport vs. game-specific state) and needs a deliberate design pass, not a quick patch — left as a scoped follow-up rather than rushed.
- `flutter analyze` 0 · `flutter test` 653 (unchanged — this bug required live-device verification, not something a widget test would have caught without deliberately simulating the dispose-during-unmount timing).
- Context: `outstanding.md`, `gameflow.md`, `live_test_setup.md` updated with the live 4-sim test results and this fix.

## [2026-07-13] — Liar's Dice live 4-sim multiplayer test: full run, all fixes verified end-to-end
- Executed the plan from the previous entry: 2 iOS Simulators (iPhone 16 host, iPhone 16e client) + 2 Android emulators (`emulator-5554`, `emulator-5556`), host added 2 AI bots — 6 total players, exactly the planned topology.
- **Cross-platform LAN discovery confirmed working on this machine** — including Android-to-Android and Android-to-iOS, resolving the environmental risk flagged in the test plan as unverified. Android emulators on this machine bridge to the host Mac's real LAN IP (`192.168.0.151`) rather than staying NAT-isolated, so real cross-platform mDNS discovery works; the one exception was a genuinely NAT-isolated `10.0.2.x` address from a differently-configured instance, which correctly failed with `SocketException: No route to host` — an emulator networking fact, not an app bug (documented in `live_test_setup.md`).
- **Bug A (the critical host-hijack fix from the previous session) verified live, twice**: after Android1's turn began, the host correctly displayed "Waiting for Android1 to roll…" and still hadn't auto-played 6+ seconds later (3× the old 2-second auto-timer window) — confirmed again at the declare phase. Before the fix, the host would have auto-rolled/auto-declared on the real player's behalf.
- Played a full round end-to-end across real devices: Android1 declared "One Pair of Fives" (honest, matching actual dice), Android2 correctly received the Accept/Challenge prompt (host waited, didn't auto-decide), challenged, `resolveChallenge` correctly ruled the challenge failed (declare was honest) and deducted Android2's counter (10→9), and the next round correctly started with Android2 as declarer (the "Common Hand" challenger-always-starts rule) with freshly-rolled dice.
- Found 2 real bugs along the way, both fixed same-session: the AdMob `GADApplicationIdentifier` iOS launch crash (separate changelog entry above) and this entry's lobby-lifecycle zombie-host bug.
- Built reusable test infrastructure per user request: `scripts/idb_tap_label.sh` / `scripts/adb_tap_text.sh` (tap by accessibility label/text via the live UI tree — `idb ui describe-all` / `uiautomator dump` — rather than hand-computed coordinates, which were wrong every single time they were tried by hand this session, for a different reason each time); `scripts/liars_dice_4sim_setup.sh` (one-shot: force-stop+relaunch all 4 devices for a clean slate, host + 2 AI bots, join all 3 real clients, leaves host on "Start Game (6 players)"); `lib/ui/games/games/liars_dice/live_test_setup.md` (device IDs, one-time `idb`/`idb_companion` install steps, why label-based taps are used, troubleshooting for every gotcha hit this session).
- One-time environment setup: installed `idb` + `idb_companion` (Facebook's iOS UI-automation CLI — `xcrun simctl` alone can't inject taps) via `brew tap facebook/fb` + `brew install idb-companion` + a `.idb_venv` Python venv with `fb-idb`.
- `flutter analyze` 0 · `flutter test` 653 · `flutter build` (iOS + Android) succeeded.
- Context: `outstanding.md` (LT6 marked done for Liar's Dice), `gameflow.md` Live Multiplayer Test Plan section, `CLAUDE.md` scripts table (3 new entries), `INDEX.md` NEXT pointer.

## [2026-07-13] — CRITICAL: iOS app crashed on launch for every real user (App Store/TestFlight/plain tap) — fixed
- Discovered while setting up the Liar's Dice 4-sim live test: launching the app via `xcrun simctl launch` (no debugger attached) crashed instantly with `SIGABRT` in `GADApplicationVerifyPublisherInitializedCorrectly` (Google Mobile Ads SDK). The user independently confirmed the same crash launching manually on their own iOS simulators ("the moment the sisu mate app starts, it pops up for a milli second and then disappears") — this is not specific to how I was launching it.
- **Root cause**: `ios/Runner/Info.plist` was missing the `GADApplicationIdentifier` key entirely. Android's `AndroidManifest.xml` has the equivalent `com.google.android.gms.ads.APPLICATION_ID` meta-data with the real App ID; iOS never had it. Google Mobile Ads SDK relaxes this integrity check when a debugger is attached (every `flutter run`/Xcode launch never showed the crash) but hard-crashes on any launch without one — i.e. every real-world launch path: App Store, TestFlight, ad-hoc, or literally tapping the Home Screen icon.
- **Why this was never caught**: per the user, iOS has never actually been live-tested in this project despite the standing dual-platform-testing instruction — all prior iOS verification in this changelog was via `flutter run`, which never exercises the no-debugger crash path.
- Fixed: added `<key>GADApplicationIdentifier</key><string>ca-app-pub-1941448979345601~3437747519</string>` to `ios/Runner/Info.plist` (the real iOS App ID, matching `AdHelper.deviceId`'s release branch — static and unconditional, same as Android's manifest entry, since Info.plist can't vary by Dart build mode).
- Verified: rebuilt (`flutter build ios --debug --simulator`), reinstalled, and cold-launched via `xcrun simctl launch` (deliberately no debugger, replicating a real user tap) — app now boots to the home screen normally (screenshot confirmed: status line, all 14 module tiles render). No new crash report generated (checked `~/Library/Logs/DiagnosticReports`).
- `flutter analyze` 0 · `flutter test` 653 (unchanged — this is a native config file, no Dart changed) · `flutter build ios --debug --simulator` succeeded both before (to reproduce) and after (to verify) the fix.
- Context: `risks.md` (added a critical-severity Platform-Specific Divergences row for `GADApplicationIdentifier` so this can never silently regress again).

## [2026-07-13] — Liar's Dice: fixed host-hijack bug + added AI-seat-in-multiplayer feature, wrote live 4-sim test plan
- User asked to focus on finishing Liar's Dice specifically (deferring the other-8-games GAME1 rollout) and to formulate + execute a live multi-simulator test plan. Investigated `liars_dice/logic.dart`+`screen.dart`, `lobby_screen.dart`, `game_lan_service.dart` to ground the plan in real code state before writing anything.
- **Critical bug found & fixed**: `_GameplayUIState`'s roll-phase and declare-phase auto-timers (screen.dart) gated only on `!declarerIsMe`, which is also true whenever it's a **real remote human's** turn on the host's own screen (not just an AI's) — the host would auto-roll/auto-declare on a real client's behalf after 2s if they hadn't acted yet. The sibling `_AcceptChallengeUIState` already had the correct `opponent.isAI` gate; the roll/declare timers were missing it. Fixed by adding `currentPlayer.isAI` to both conditions. This had never been caught because no prior changelog entry shows an actual multi-device LAN game was ever live-tested (only single-device AI-vs-AI + unit tests) — confirmed by searching this file.
- **Feature gap found & fixed**: multiplayer lobbies had no way to add an AI bot seat — `initHostMode` hardcoded every lobby player to `isAI: false`, and `GameLobbyScreen` had no equivalent of solo mode's "Add AI Player" button. Added: `LobbyPlayer.isAI` field (default false, JSON-compatible); `GameLanService.addLocalPlayer()`/`removeLocalPlayer()` (host-only, host-local seats with no network connection, re-broadcast the lobby list so connected clients see them too); `GameLobbyScreen._HostingView` gained an "Add AI Player" button + a delete icon on AI rows; `initHostMode` now reads `lp.isAI` instead of hardcoding false.
- Self-healed `liars_dice/gameflow.md`: the "Local UI State Reset" table claimed `myDiceProvider` resets to `[1,1,1,1,1]` every round — the actual code (One-box rule) seeds it from the inherited/shared dice; the "Reconnection" gap row claimed no reconnect logic exists at all, when `_handleHostDisconnect`/`_handleDisconnect` have existed since the 2026-07-04 F6 fix. Both corrected.
- Wrote a full **"Live Multiplayer Test Plan"** section into `liars_dice/gameflow.md`: the environmental risk that Android emulators' default NAT/SLIRP networking may not support mDNS multicast between instances (never tested on this machine — flagged as a Step-0 connectivity check, not assumed), the confirmed device topology (4 real peers: 2 iOS Simulators + 2 Android emulators, plus 2 host-added AI bots = 6 total players), join order, and a play-through checklist covering every state transition plus a mid-game disconnect.
- Tests: `liars_dice_test.dart` — 1 new test confirming `initHostMode` correctly maps `LobbyPlayer.isAI` to `Player.isAI` (a real host seat must never become AI; a bot seat must). `lan_reconnect_test.dart` — 3 new tests: `LobbyPlayer.isAI` JSON round-trip + missing-key default, and `addLocalPlayer`/`removeLocalPlayer` mutating `lobbyPlayers` correctly (works around `hostGame()`'s unmocked mDNS platform-channel throw by relying on `_isHost`/`_lobbyPlayers` already being set before that throw, same pattern this file's existing F6 tests use to avoid needing a real socket/mDNS environment).
- `flutter analyze` 0 · `flutter test` 653 (+4) · `flutter build apk --debug` succeeded.
- Live device verification: in progress — see next changelog entry once the 4-sim test completes.
- Context: `outstanding.md` (LT5 marked done for all 9 games including Liar's Dice; LT6 updated to reference the new test plan, live execution in progress), `liars_dice/gameflow.md` (Local UI State Reset, Reconnection gap, Auto-Advance Rules, Multiplayer Setup Sequence, new Live Multiplayer Test Plan section).

## [2026-07-13] — GAME1: scoped multiplayer-for-other-8-games effort (research only, no code changed)
- User chose "scope it, don't build yet" given the size jump from the prior small items. Explored `lib/services/lan/*`, `liars_dice/logic.dart`+`screen.dart`, `lobby_screen.dart`, `GameCatalog`, and all 8 other games' `logic.dart`+`gameflow.md`.
- Findings: LAN transport (`lan_engine.dart`+`game_lan_service.dart`) is already generic, needs no changes. Liar's Dice's multiplayer logic is hand-tangled into its own notifier with no reusable adapter — the pattern must be re-implemented per game (mode flags, `initHostMode`/`initClientMode`/`_applyRemoteMove`/`_broadcastIfHost`, per-model JSON, `_sendOrApply` in the screen). `lobby_screen.dart` hard-imports Liar's Dice's notifier directly — must be generalized before any 2nd game can use it. Dudo is the cheapest next game (already has JSON + an unwired `isMultiplayer` flag). Poker/Uno/Cribbage need a design decision first: broadcast full state (like Liar's Dice does) vs. filter hidden info per-recipient.
- Full scoping detail + recommended build order written into `outstanding.md`'s GAME1 row (replacing the one-line placeholder).
- No `flutter analyze`/`test`/build run — no code touched.
- Context: `outstanding.md` (GAME1 row expanded with the plan, not resolved — still open), `INDEX.md` NEXT set to NAV2 (same-sized task) while GAME1's actual build awaits a user go-ahead on the recommended order.

## [2026-07-13] — SYN4: dropped the never-wired SyncInboxItems staging table (verified on device, incl. live migration)
- Confirmed genuinely dead via grep: `SyncInboxItems`/`SyncInboxRow`/`SyncInbox` had zero references outside `app_database.dart`/`.g.dart`/`models.dart` — no repository, no `SyncService` usage. Inbound sync has applied directly via `InboundSyncApplier` since T5; this table was reserved staging that was never wired up.
- Removed: the `SyncInboxItems` Drift table class + its registration in `@DriftDatabase(tables: [...])`; the dead `SyncInbox` domain model (`lib/models/sync_inbox.dart`, deleted) + its `part` in `models.dart`.
- Drift **schemaVersion 8 → 9**: migration `from < 9` calls `m.deleteTable('sync_inbox_items')` so existing installs drop the table cleanly rather than carrying dead schema weight forever.
- Regenerated `app_database.g.dart` via `build_runner`.
- **Verified the actual upgrade path, not just a fresh install**: reused the emulator's existing v8 database from the prior SEED-PATCH session, installed the new v9 debug build directly over it, and confirmed the migration ran with no exceptions/crash and the app booted normally (Supabase init, AdMob init, first frame) — this exercises `m.deleteTable` against a real on-device v8 DB, which a fresh-install test would not catch.
- Self-heal (found while touching these files): `caching.md`/`risks.md`/`INDEX.md` still said `schemaVersion` 7 or 8 in several places (stale since FREE-EDITS/SHARE4); `risks.md` also had a stale "14 syncedTables (+ boats outbound-only)" claim — `boats` is one of the 15 (caching.md already had this right), and is inbound-supported now, not outbound-only. All corrected.
- `flutter analyze` 0 · `flutter test` 649.
- Files: `app_database.dart`, `models.dart`, `sync_inbox.dart` (deleted), `app_database.g.dart` (regenerated).
- Context: `outstanding.md` (SYN4 row + now-empty "Sync / multi-device gaps" section removed per Rule 1), `caching.md`/`risks.md`/`data_models.md`/`INDEX.md` schemaVersion + syncedTables count corrected, `INDEX.md` NEXT advanced to GAME1.

## [2026-07-13] — SEED-PATCH: baseline bar/pantry catalog-patch rows at insertion, not just on pristine DBs (verified on device)
- Root cause: `DatabaseService.markFactoryBaseline()` only re-stamped bar/pantry rows to the factory epoch when `_isPristine()` (whole-DB check), so a later app-update's catalog patch (`insertMissingBarIngredientsToDrift`/`insertMissingPantryIngredientsToDrift`, run every launch via `runDeferredSeeds`) got Drift's default "now" timestamp + unsynced on an already-used install — a newly-added catalog item could falsely beat an older, real remote change in inbound LWW.
- Fix moved to the single point of creation: `seedBarIngredientsToDrift`/`seedPantryIngredientsToDrift` in `ingredient_drift_seed.dart` (shared by both the fresh-install full seed and the later patch path) now explicitly stamp `lastModified: _factoryEpoch` (`DateTime.utc(2000)`) + `isSynced: true` on every insert, regardless of whether the rest of the DB is pristine. `DatabaseService.markFactoryBaseline()` simplified to drop the now-redundant bar/pantry re-stamp lines (checklist/shopping/recipe tables unchanged, still whole-table re-stamped since they have no equivalent per-row patch path).
- Tests: new `test/ingredient_drift_seed_test.dart` (3 tests) — the key regression case seeds one bar ingredient with a real "now"/unsynced row (simulating a used, non-pristine install), then runs the patch-insert path for a new catalog item and asserts the new row is still epoch-baselined despite the DB not being globally pristine.
- Verified on device: fresh debug build + install booted cleanly (Supabase init, AdMob init, first frame, no exceptions), confirming `runDeferredSeeds()` (which now calls the changed seed helpers on every launch) doesn't regress.
- `flutter analyze` 0 · `flutter test` 649 (+3).
- Files: `ingredient_drift_seed.dart`, `database_service.dart`, `ingredient_drift_seed_test.dart` (new).
- Context: `outstanding.md` (SEED-PATCH row removed), `INDEX.md` NEXT advanced to SYN4.

## [2026-07-13] — UX7: strip dead TitleTile.subtitle + resurface detail-view position context (verified on device)
- **Found a real regression while auditing, not just dead args**: `ItemDetailShell`/`CheckPageViewer`/`RecordDetailScreen`/`IngredientDetailScreen` all compute a "group name · N of M" string and pass it as `TitleTile.subtitle` — which the 2026-07-12 title-bar rework made a no-op. So every swipeable item-detail screen (Checklists, Maintenance, Safety, Crew, Inventory, Documents, Fuel, Shopping, Bar, Pantry) had silently lost its position/group indicator, not just cosmetic dead code.
- Fix: `ItemDetailShell` now renders that context as its own header row directly under the (unchanged, binding) `TitleTile` — consistent with theme.md §6.3's existing "header rows below the title bar" pattern, not a new one. `TitleTile` itself keeps §5.1 untouched.
- Removed the now-fully-dead `subtitle` field from `TitleTile` (not just its effect) and stripped the arg from all ~14 real call sites that still passed a static module blurb (Fuel/Shopping/Log/Chef/Checklists/Safety/Crew/Inventory/Maintenance/Cocktails/Games/Documents/Weather/Community screens) — `flutter analyze` catching every site (a stale arg would now be a compile error, not silently ignored) is the correctness proof that none were missed.
- Verified on device: item detail (Checklists → On-Watch → VHF Radio Watch) shows "On-Watch Monitoring Checks · 1 of 16" as its own row below the mandatory status line — position context fully restored.
- `flutter analyze` 0 · `flutter test` 646.
- Files: `title_tile.dart`, `item_detail_shell.dart`, + 14 screen files (subtitle arg removed).
- Context: `outstanding.md` (UX7 done), `INDEX.md` NEXT advanced to SEED-PATCH.

## [2026-07-12] — CONTEXT-EFF: audit all .ai_context files for staleness + token efficiency
- **INDEX.md** (done 2026-07-12, this pass unchanged): NEXT pointer at the very top (3 lines, priority-ordered, points to outstanding.md), tables compacted. 151→78 lines.
- **access_tiers.md**: fixed 2 real staleness bugs — §4 "Custom checklist FAB" claimed "stub SnackBar, not gated, TODO" when the code has actually gated it (isPro ternary / PRO1 dialog) for some time; corrected to describe the real gate.
- **caching.md**: fixed the "Tables that CAN be queued" list — only listed 7 of the 14 synced tables (missed documents/crew_members/inventory_items/fuel_logs/recipes/recipe_ingredients/bar_ingredients/pantry_ingredients entirely); also tightened the outbox-trigger line to say "sync-eligible (Pro or anonymous crew)" instead of just "Pro".
- **risks.md**: fixed **6** stale facts — schemaVersion said 6 (now 8); "7 tables" mentioned twice for inbound sync (now 14+boats); `revenueCatProvider` "defined twice" claim (now single definition in di.dart, the other copy is gone); custom-checklist-FAB anti-pattern entry (same stale claim as access_tiers.md — resolved); added `CheckPageViewer`/`FreeEditGate` to `RevenueCatService`'s dependents list.
- **theme.md** (binding — touched minimally): §6.2 and the definition-of-done checklist still described the old free-text title-bar subtitle model my own 2026-07-12 TitleTile rework superseded (§5.1); pointed both at §5.1 instead of restating stale details. No other content touched.
- **screens.md**: this file was severely out of date and actively misleading, not just verbose — full accuracy pass: (a) "No named routes, No GoRouter" → the app has used GoRouter since T3/NAV1, rewrote the whole nav-architecture intro + replaced the Navigator-only diagram with the real GoRouter route tree; (b) Games section described 7 of 9 games as unimplemented "Coming soon" stub screens with "no logic" — all 9 are actually fully implemented 1v1-vs-AI games (only multiplayer networking is Liar's-Dice-only, per the already-accurate GAME1 backlog item) — rewrote both Games sections; (c) Screen Inventory table was missing 10 real screens entirely (WeatherScreen, PassagePlannerScreen, GameLobbyScreen, SyncStatusScreen, ConflictResolutionScreen, AccountSetupScreen, JoinBoatScreen, AdminScreen) — added them; (d) HomeScreen tile count was wrong (said 13, it's 14) and the list order didn't match; (e) ChecklistScreen FAB and SmartImage "known bug" descriptions were stale (both fixed/resolved); (f) added the new FreeEditGate detail-view teaser to the checklist Pro-gate description (list-level hard gate was already accurately documented and unchanged). 259→248 lines despite adding a lot — cut verbose filler elsewhere.
- **data_models.md** (largest file, 598 lines): fixed **`isProProvider`'s documented type** (said `FutureProvider<bool>`, is actually `StreamProvider<bool>` — direct contradiction with access_tiers.md/risks.md's correct descriptions elsewhere in the same doc set); added **9 missing providers** (pendingConflicts/Count, shoppingItemNames, syncIngredientCounts, crewMember/inventoryItem/fuelLog repository providers, boatEnrollmentService, syncOutboxCount); added **4 missing services** (WirePrefix, BoatEnrollmentService, ProfileHeartbeat, FreeEditGate) and fixed 2 stale service descriptions (AuthService said "magic-link sign-in/out" only; ConflictResolutionService said "dead code, never instantiated" — it's a `const` field on `SyncService` and actively used); added `Boat.ownerId`/`shareCode`, `BarIngredient`/`PantryIngredient.boatSupabaseId`, `UserSettings.freeEditsUsed` to their field tables; added 5 missing repository interfaces; **rewrote the "API Layer (Supabase)" section**, which was drastically wrong (described unresolved sync TODOs that were fixed in 2026-05, no mention of WirePrefix/RLS/crew-sharing/community at all) — now points to caching.md's "Supabase Backend" section as the source of truth instead of duplicating it, specifically to stop this exact kind of drift recurring.
- `flutter analyze` 0 · `flutter test` 646 (docs-only changes; ran gates for hygiene).
- Context: `outstanding.md` (CONTEXT-EFF done, "Docs / Process" section removed per Rule 1), `INDEX.md` NEXT advanced to UX7.

## [2026-07-12] — FREE-EDITS: Free-tier upgrade teaser (5 free completions/notes) (verified on device)
- **Self-heal / latent bug found & fixed:** `CheckPageViewer` (the shared item-detail shell for Checklists/Maintenance/Safety) had **zero Pro gating** — `_toggleCompletion`/`_saveEdit` ran unconditionally, so a Free user opening an item's detail view could already complete it and edit notes for free, contradicting access_tiers.md's "Mark items complete / add notes: Free ❌" row. (The list-level tile `onComplete` was correctly gated; the detail view was not.) Confirmed hide/delete/photo are NOT listed as Pro-exclusive anywhere and already work for Free at the list level too, so left those alone — scope stayed to completion + notes-save, matching the documented policy exactly.
- Drift schemaVersion 7→8: `UserSettingsTable.freeEditsUsed` (int, default 0) — local-only counter, Free never syncs. `UserSettings` model + repo mapping updated.
- New `lib/services/free_edit_gate.dart` (`FreeEditGate`): `tryConsume(ref)` — Pro always returns true (unlimited); Free returns true and increments the counter while under `freeEditAllowance` (5), false once exhausted. `remaining(ref)` — tries left, or null for Pro (nothing to show).
- Wired into `CheckPageViewer._toggleCompletion` and `._saveEdit` via a shared `_checkFreeEditGate()`: on success shows "Free preview: N edit(s) left — upgrade for unlimited" (skipped entirely for Pro); once exhausted, blocks the mutation and shows a "Sisu Mate Pro Required" dialog (same shape as the existing per-screen ones) → Upgrade routes to the paywall.
- Tests: `free_edit_gate_test.dart` (exactly 5 consumes succeed then the 6th is rejected; counter persists in Drift).
- **Verified on a real device as an actual Free user** (temporarily flipped `kForceProForTesting` false + cleared app data to get a genuine first-run Free state, reverted after): tapped Complete on a fresh Free install → snackbar "Free preview: 4 edit(s) left"; toggled through the remaining allowance (history log confirmed each completion recorded); the 6th attempt was **blocked before any state change** and showed the "Sisu Mate Pro Required" dialog. `kForceProForTesting` restored to `true` before finishing.
- `flutter analyze` 0 · `flutter test` 646.
- Files: `app_database.dart`, `user_settings.dart`, `user_settings_repository_impl.dart`, `free_edit_gate.dart` (new), `check_page_viewer.dart`, `free_edit_gate_test.dart` (new).
- Context: `outstanding.md` (FREE-EDITS done), `INDEX.md` NEXT advanced to CONTEXT-EFF.

## [2026-07-12] — STALE-WARN: warning-email action in the Developer console (verified on device)
- **Decision (owner):** warning delivery is manual mailto: compose (open the developer's own mail app, review, hit send), not an automated Resend/edge-function pipeline — zero new infrastructure, no third-party account/API key, matches the existing "Share this boat" email pattern. Automated bulk-send was the alternative offered and declined for now.
- Migration `stale_warn` (+ `stale_warn_add_column`, `stale_warn_fix` — the first attempt's `alter table` rolled back with an unrelated function-signature error, re-applied cleanly): `profiles.warnedAt` column; `admin_mark_warned(p_guid)` (SECURITY DEFINER, `admin_check()`-gated) stamps the boat owner's `warnedAt` — updates by `profiles.boatGuid` first, falls back to an upsert via `boats.ownerId` if the owner has no profile row yet; `admin_stale_boats` extended to also return `warnedAt` (same signature, function dropped+recreated since the return-row shape changed).
- `AdminScreen`: each stale-boat tile now shows grace status ("Not yet warned" / "Warned — N day(s) left" / "grace period elapsed, safe to purge") computed client-side from `warnedAt` + a new grace-period dropdown (7/14/30 days, default 7). A mail-icon "Warn" action composes the email (subject + body: inactivity duration, hard deadline date, warm-but-clear tone) via `url_launcher`'s `mailto:`, then asks "did you send it?" before calling `admin_mark_warned` — never auto-records without developer confirmation. The purge confirm dialog now also surfaces grace status as a soft warning (e.g. "⚠ Grace period still has N day(s) left") without hard-blocking the purge — developer judgment call stays final.
- Verified: backend round-trip via `supabase_cli.sh` against the real Sisu boat (mark-warned → `profilesUpdated:1` → `warnedAt` populated in `admin_stale_boats`; anon crew call → `Not authorized`); on-device the full UI loop (mail icon → Gmail app opens via mailto: → back → confirm dialog → "Yes, sent" → snackbar "marked as warned" → list reloads) against a synthetic ownerless test boat (which correctly stayed "Not yet warned" since it had no owner to stamp — expected for that fixture, not a bug). Test boat + its RPC test artifacts cleaned up afterward.
- `flutter analyze` 0 · `flutter test` 644.
- Files: `supabase/migrations/0006_stale_warn.sql`, `lib/ui/admin/admin_screen.dart`.
- Context: `outstanding.md` (STALE-WARN done, empty "Admin / Ops" section header removed per Rule 1), `INDEX.md` NEXT advanced to FREE-EDITS.

## [2026-07-12] — STALE-DATA: subscription heartbeat + hidden developer console (verified)
- **How lapse detection works (answering the owner's questions):** the stores never expose the subscriber's Apple/Google account email (privacy) — RevenueCat is the subscription source of truth, and its subscriber id already IS the Supabase auth uid (PRO3), so there is no better "original subscriber" identity to store. Instead of webhooks, the **app stamps its own profile on every signed-in launch**: new `ProfileHeartbeat.stamp()` (called from `startup_screen._afterHomeReady`) upserts `profiles.lastSeenAt` + `profiles.proUntil` (= REAL RevenueCat entitlement expiration via new `RevenueCatService.proExpiresAt()` — deliberately NOT covered by the debug Pro bypass). Stale = not Pro now AND unseen for N months.
- **Migration `stale_data_admin`:** `profiles.proUntil`/`lastSeenAt`; `app_admins` (locked table, dev uid seeded); SECURITY DEFINER RPCs gated by `admin_check()`: `admin_stats()` (active subs, accounts, anon crew, boats, community, DB size MB, per-table row counts), `admin_stale_boats(p_months)` (lapsed+unseen boats w/ owner email + row counts), `admin_purge_boat(p_guid)` (deletes `<guid>::%` content + memberships + boat row; profile/auth user stay so re-enroll works).
- **Hidden Developer console:** drawer entry visible only for `AuthService.developerEmail` (`isDeveloper`) → `/admin` (`AdminScreen`): stats chips, synced-row counts, stale-boats list with 6/12/24-month selector and per-boat confirm+purge. UI gate is cosmetic — every RPC re-verifies against `app_admins` server-side (verified: anonymous crew gets "Not authorized").
- **Verified:** pre-heartbeat SQL showed Sisu as stale (null stamps) → after launch, `lastSeenAt` stamped and the console shows "None — everyone is active 🎉"; synthetic "Ghost Boat" appeared in the stale list and `admin_purge_boat` removed it (content + boat), Sisu untouched. Stats render live on-device.
- `flutter analyze` 0 · `flutter test` 644.
- Files: `profile_heartbeat.dart` (new), `admin_screen.dart` (new), `revenuecat_service.dart`, `auth_service.dart`, `startup_screen.dart`, `app_router.dart`, `common_drawer.dart`, `supabase/migrations/0005_stale_data_admin.sql`.
- Future upgrade path (optional): RevenueCat webhook → edge function for real-time lapse events; current heartbeat is launch-driven, which is sufficient for a yearly purge cadence.

## [2026-07-12] — SHARE4 complete (boat-stamp bar/pantry writes) + SHARE5 community live (verified)
- **SHARE4 (final piece):** `_stampBoatScope` in `bar/pantry_ingredient_repository_impl` — every `_put` (add/update/toggle/recordPurchase) stamps an empty `boatSupabaseId` with the active boat GUID from `UserSettings` before persist + outbound `toJson`. Tests added in both repo test files (also self-healed stale "local-only" comments → SYN2).
- **SHARE5 (community publish/import):** migration `community_tables` — `community_templates` (snake_case wire format matching the existing `community_repository_impl`, `id` DB-generated, `is_approved` default **true** = open community per owner's vision; moderation deferred to S5) + `community_downloads`. RLS: read = approved-or-own (authenticated); publish = non-anonymous users as themselves (`author_id = auth.uid()`, anonymous crew blocked); update/delete = author; downloads read/insert = any signed-in. Global tables — deliberately NOT wire-prefixed / not in syncedTables.
- App: `publishTemplate` now stamps `author_id` from the real auth uid (was the local settings id — would fail RLS) and sets `isApproved = true`; publish snackbar "submitted for review" → "shared with the community".
- **Verified**: HTTP — owner publish 201, anonymous crew browse OK + publish 403, no-session `[]`, download insert 201. In-app — Community Library lists "Test Anchor Checks" → Import → "Anchor Checks" group (community badge, 1 item) in Checklists and synced up wire-prefixed (`<guid>::community_…`), so imports propagate to crew. (Test template + imported group left in place as demo data — delete freely.)
- `flutter analyze` 0 · `flutter test` 644.
- Files: bar/pantry repo impls + tests, `community_repository_impl.dart`, `community_browser_screen.dart`, `supabase/migrations/0004_community_tables.sql`.

## [2026-07-12] — Title-bar standard (theme.md §5.1): mandatory status line + back arrow + icon order
- Owner set a binding title-bar standard; implemented once in `TitleTile` (the universal plug, 22 screens): **(1)** line 2 is ALWAYS the status line `boat • Pro/Free • Online/Offline • email user`, with `• Syncing (N)` appended while the outbox is non-empty (new `syncOutboxCountProvider` in di.dart watching `SyncOutboxItems`); per-screen subtitles retired (`TitleTile.subtitle` now ignored — dead args tracked as UX7); **(2)** **back arrow far left** whenever `Navigator.canPop` (home is root → never); layout reworked from Stack to Row; **(3)** trailing icons right→left: **drawer, import/export, share** — fixed crew/inventory/documents screens which listed share after import/export.
- Test fix: `item_detail_shell_test` stubs `syncOutboxCountProvider` (`Stream.value(0)`) — real Drift I/O deadlocks under `testWidgets`' fake clock.
- Verified on emulator: Checklists shows arrow + status line (was module blurb), arrow pops to home (home has no arrow), Crew order menu←import/export(←share when visible). `flutter analyze` 0 · `flutter test` 642 · `flutter build ios --simulator` ✓ (validates the new `share_plus` pod too).
- Context: `theme.md` §5.1 (new binding standard), `outstanding.md` (UX7), `INDEX.md`.

## [2026-07-12] — Crew sync verified across two devices + factory baseline + GUID recovery (SHARE-ENROLL-2)
- **Factory-baseline fix (crew-join bug):** a crew member's freshly-seeded rows (dirty `isSynced=false` + `lastModified=now`) beat the owner's earlier changes in the inbound LWW/conflict logic, masking shared progress. Fix: `DatabaseService.markFactoryBaseline()` — after any fresh full seed (`_seedFresh`, i.e. first install / factory / hard reset) all factory content rows get `lastModified = DateTime.utc(2000)` + `isSynced = true` ("factory is older than any user change, nothing to push"). `runDeferredSeeds` re-baselines only when the DB is still pristine (`_isPristine`, no row newer than the epoch) so expansion packs on first launch are covered without touching user rows. Known edge: bar/pantry catalog patch rows added by a later app-update launch keep now-timestamps (noted in outstanding.md).
- **SHARE-ENROLL-2:** new `profiles` table (migration `profiles_boat_guid`: `id uuid PK → auth.users`, `boatGuid`, own-row RLS). `BoatEnrollmentService.enroll` now recovers the GUID prefs → `profiles` → mint, and saves it back (best-effort, test-safe). A second device / reinstall adopts the SAME boat instead of forking.
- **Debug bootstrap crew-aware:** an anonymous session marks the device as deliberate crew — bootstrap is a no-op (crew survives relaunches); owner sign-in only happens with no session at all.
- **Verified end-to-end on two emulators** (A=owner emulator-5554, B=crew emulator-5556, both fresh `pm clear`): A recovered its GUID from `profiles` after wipe; B's fresh install adopted the same boat (Supabase still 1 boat); B saw A's pre-join completion (1/16); after sign-out + join `7ED75D` as anonymous crew, A's live completion arrived on B (2/16); B's crew completion (`radar_watch`) passed RLS, landed in Supabase and turned green on A in realtime.
- `flutter analyze` 0 · `flutter test` 642.
- Files: `database_service.dart`, `boat_enrollment_service.dart`, `debug_bootstrap.dart`, `supabase/migrations/0003_profiles_boat_guid.sql`.

## [2026-07-11] — SHARE6 RLS cutover + share-boat via email/WhatsApp (verified on device)
- **SHARE6 (RLS cutover):** migration `rls_cutover` — replaced the permissive `sisu_allow_all` policies with membership-scoped ones. New SECURITY DEFINER `accessible_boat_ids()` (owned ∪ member boats). Content tables: `for all to authenticated` scoped by the wire-prefix GUID (`split_part("supabaseId",'::',1) in accessible_boat_ids()`). `boats`: owner writes (insert/update/delete `ownerId = auth.uid()`), owner+crew read. Access now requires a session — the **anon key alone is locked out**.
  - App prereq: `Boat.toJson` now pushes `ownerId` (only owners write boats) so RLS can validate on insert/update; `shareCode` stays inbound-only.
  - Verified on device: anon-key-only reads → `[]`, insert → 401; owner session reads only its Sisu boat and a completed checklist item still syncs (`c967b2e0-…::watchId_vhf_radio_watch`). Advisors: permissive-RLS warnings gone; remaining (anonymous-access policies, SECURITY DEFINER callable, leaked-password toggle) are intentional/pre-existing.
- **Share this boat via email/WhatsApp:** the code dialog gained a privacy note + **Share** and **Email** actions (added `share_plus`). Share (chat/WhatsApp) sends **just the code** (easy paste) — verified the OS sheet shows only `7ED75D`. Email opens the composer: subject "Share <boat> code", body = warm invite + sensitivity warning + the code on its own prominent line + "Thank you & warm regards, <name>" (name from `AuthService.displayName` — metadata name or email local-part). Plain-text mail can't bold, so the code stands alone on its own line.
- `flutter analyze` 0 · `flutter test` 642.
- Context: `INDEX.md`, `outstanding.md` (SHARE6 done), `plans/pro-sync-sharing.md`, `supabase/migrations/0002_rls_cutover.sql`.

## [2026-07-11] — RESET-SYNC: Pro factory reset wipes local + remote, keeps the GUID (verified on device)
- `SyncService.wipeRemoteBoatContent(guid)` deletes the boat's wire-prefixed content (`.like('supabaseId','<guid>::%')`) from all synced tables except `boats` — keeps the boat row + `boat_members` so crew stay linked.
- `common_drawer._performReset` orchestrates the Pro-aware reset: capture GUID + boat name → wipe remote content (if signed in) → local `factoryReset()` (wipe + reseed) → **re-enroll with the SAME persisted GUID** (re-stamps reseeded content, restores name) → set active boat. A never-enrolled (Free) boat just does the plain local reset.
- Fixes the trap where the old local-only reset would repopulate from stale Supabase rows via realtime.
- Pro-aware confirm dialog: when the boat is synced (enrolled + signed in), the warning is stronger — "…wipes this boat's data in the cloud, so it also disappears from any crew devices sharing this boat…". Free/unenrolled keeps the plain local-reset message. Verified on device.
- Verified on device: pre-reset `checklist_items`=1 → **post-reset 0**; `boats` stays 1 with the **same** GUID `c967b2e0-…` + shareCode `7ED75D`; app re-lands on active boat "Sisu" (name preserved), no conflicts. `flutter analyze` 0 · `flutter test` 642.
- Context: `INDEX.md`, `outstanding.md` (RESET-SYNC done), `plans/pro-sync-sharing.md`.

## [2026-07-11] — WIRE-PREFIX: per-boat item-id uniqueness on the wire (verified on device)
- New `lib/services/wire_prefix.dart` (`WirePrefix`): on outbound, prefixes id-ref fields (`supabaseId` + parent refs `groupSupabaseId`/`categorySupabaseId`/`recipeSupabaseId`) with the boat GUID (`<guid>::<id>`); on inbound, strips it. `boatSupabaseId` and the `boats` table are left untouched. Idempotent (never double-prefixes).
- Applied in `sync_service.dart` at all sync boundaries: `queueOutgoingChange` upsert, `_processOutgoingQueue` upsert + delete (`encodeRecordId`), and inbound `processIncomingChanges` (decode). GUID source = `_boatGuid()` = active boat's `supabaseId` (owner's enrolled GUID or crew's joined GUID).
- **Fixes the collision** where two Pro accounts touching the same deterministic bundled item id (`watchId_vhf_radio_watch`) would land on one Supabase row (delete-by-supabaseId / realtime-by-id both need global uniqueness).
- Verified on device: completing "VHF Radio Watch" pushed `supabaseId` = `c967b2e0-…::watchId_vhf_radio_watch`, `groupSupabaseId` = `c967b2e0-…::watchId`, `boatSupabaseId` = `c967b2e0-…` (unprefixed). Local ids stay deterministic (decode strips on inbound).
- Tests: `wire_prefix_test.dart` (encode/decode round-trip, idempotent, boats/empty-guid no-op). `flutter analyze` 0 · `flutter test` 642.
- Context: `INDEX.md` (+WirePrefix), `outstanding.md` (WIRE-PREFIX done), `plans/pro-sync-sharing.md`.

## [2026-07-11] — SHARE-ENROLL: adopt-and-rename the default boat into a GUID (verified on device)
- New `lib/services/boat_enrollment_service.dart` (`boatEnrollmentServiceProvider`): `enroll({name, ownerId})` mints a GUID (persisted in SharedPreferences key `boat_guid`, survives Drift wipe), adopts-and-renames the seeded default boat `00000000-…` into it (or reuses the persisted GUID — idempotent), and re-stamps `boatSupabaseId` across all 13 sync-participating content tables to the GUID (single-boat model). `currentGuid()` exposes the GUID (the future wire-prefix source).
- `debug_bootstrap` + `account_setup_screen` now **enroll** instead of `addBoat`-ing a fresh boat, then push the boat (so Supabase DB-generates its `shareCode`) and claim ownership.
- Verified on Android emulator (fresh app data): seed → enroll → Supabase has ONE boat with a real GUID (`c967b2e0-…`), name Sisu, `shareCode` 7ED75D, `ownerId` = sailingsisu; Checklists still shows all seeded groups (content re-stamped, not orphaned).
- Tests: `boat_enrollment_service_test.dart` (rename+re-stamp+persist, idempotent). `flutter analyze` 0 · `flutter test` 637 · earlier `flutter build apk`/`build ios --simulator` ✓.
- Also excluded `docs/**` from the analyzer (13 pre-Drift Isar-era files with dangling imports — dead reference code, not app source) so `flutter analyze` reflects real code.
- Context: `INDEX.md` (+enrollment service), `outstanding.md` (SHARE-ENROLL done, WIRE-PREFIX added), `plans/pro-sync-sharing.md`.

## [2026-07-11] — Sharing model decisions (design, no code): single-boat + duplicate-per-boat + GUID
- Settled the multi-boat/sharing model (details in `plans/pro-sync-sharing.md` "Revised model"): **one boat per account for now** (multi-boat deferred); **duplicate-per-boat** content sync (whole item = definition + state + history, so crew see completion AND edits); bundled content is boat-scoped, not shared across boats.
- **Pro onboarding = adopt-and-rename the seeded default boat** (`00000000-…`), minting a **GUID** as its permanent id (tied to the email account, persisted in SharedPreferences + Supabase `profiles`); re-stamp its content to the GUID so owners don't collide in Supabase. Replaces the "create a new boat" flow.
- New backlog items: SHARE-ENROLL (onboarding adopt/rename), RESET-SYNC (factory reset must wipe+reseed BOTH local & Supabase, keep GUID), STALE-DATA (lapse/uninstall leaves orphaned Supabase copies — retention TBD), FREE-EDITS (Free upgrade teaser). SHARE4 narrowed to "stamp active boat GUID on writes".
- No source changed; `plans/pro-sync-sharing.md` + `outstanding.md` + `changelog.md` only.

## [2026-07-11] — Pro sync sharing Phase 4 (plumbing): boat ownership + per-boat bar/pantry
- Drift **schemaVersion 6 → 7** (migration `from < 7`: adds `Boats.ownerId`, `Boats.shareCode`, `BarIngredients.boatSupabaseId`, `PantryIngredients.boatSupabaseId`). Regenerated `app_database.g.dart`.
- `Boat` model: `ownerId` + `shareCode` — **inbound-only** (read in `fromJson`, persisted locally, but deliberately NOT in `toJson`), so the app never null-overwrites the server-stamped owner or DB-generated code. Mapped in `boat_repository_impl` (`_toDomain`/`_toCompanion`) + `inbound_sync_applier` (`_boatDomain`/`_upsertBoat`).
- `BarIngredient` + `PantryIngredient`: `boatSupabaseId` — a **normal bidirectional synced** field (in both `toJson`/`fromJson`), mapped in both repos + the inbound applier. Supabase columns already existed (Phase 2a).
- Self-healed a stale Drift comment: PantryIngredients is sync-participating (SYN2), not "local-only".
- Tests: `boat_repository_test` (ownerId/shareCode round-trip), `bar`/`pantry` repo tests (boatSupabaseId round-trip). `flutter analyze` 0 · `flutter test` 634+ · `flutter build apk --debug` ✓.
- Context: `INDEX.md` + `caching.md` schemaVersion → 7; `outstanding.md` SHARE4 updated.
- **Still open in SHARE4** (see outstanding.md): stamping the active boat onto bar/pantry writes (currently `boatSupabaseId` stays `''`), needs the per-boat-vs-global decision for bundled ingredients; and the owner/crew boat dropdown filter.

## [2026-07-11] — Remove recipe photo-OCR (CF15) + `google_mlkit_text_recognition`
- Dropped the "Import from photo" recipe OCR (low value; also the only thing blocking iOS-simulator builds — MLKit ships no arm64 simulator slice on Apple Silicon).
- Removed: `lib/services/recipe_ocr_service.dart`, `test/recipe_ocr_service_test.dart`, the Chef FAB "Import from photo" tile + `_showImportFromPhotoOptions` in `chef_screen.dart`, and the `google_mlkit_text_recognition` dependency in `pubspec.yaml`.
- **Unaffected**: general photo capture/upload (`image_picker` + `photo_source_picker.dart` + `ImageService`) for meals/cocktails/check items/crew/inventory/documents — independent of MLKit, fully intact. "Import from URL" (CF11) recipe import also remains.
- `RecipeImportService.parseIngredientLine` stays public (still reusable); comment de-referenced from the deleted OCR service.
- Context: removed CF15 rows from `INDEX.md` + `data_models.md`.
- `flutter analyze` 0 issues; `flutter test` 634 pass; `flutter build apk --debug` ✓.

## [2026-07-11] — Pro sync sharing Phase 3: owner sign-up + crew join UI (verified on device)
- New screens: `lib/ui/account/account_setup_screen.dart` (owner create-account+boat / sign-in) and `lib/ui/account/join_boat_screen.dart` (crew enter share code). Routes `/account` (`accountSetup`) and `/join` (`joinBoat`) in `app_router.dart`.
- `AuthService` gained `joinBoat(code)` (anon sign-in + redeem + fetch name), `claimBoatOwnership(boatId)` (stamps `ownerId`), `fetchBoatShareCode(boatId)`.
- `BoatRepository.upsertLocal(boat)` — local-only insert/update (no outbound sync) so a crew member joining never pushes the owner's boat back (would null-overwrite fields). Test added in `boat_repository_test.dart`.
- **Sync gate widened**: `SyncService._syncAllowed()` = Pro **or** an anonymous (crew) session; guarded so tests (no Supabase) stay offline. `_init` → idempotent `ensureStarted()` so sync can start mid-session after a purchase or a join. Callers: join/account screens call `ensureStarted()`.
- Drawer `AccountSection` reworked: signed-out → "Boat account" + "Join a boat"; owner → email + "Share this boat" (code dialog, copy); crew → "Crew member" + "Join another boat". Old magic-link dialog removed here. Paywall "Get Started" now routes to `/account` when no session (point 2).
- Debug bootstrap hardened: uses the app-global `ProviderContainer` (widget ref was unsafe post-navigation → "Using ref … unmounted" crash), signs out a leftover anon session to deterministically restore the owner, and best-effort `claimBoatOwnership`.
- **Verified on Android emulator (emulator-5554)**: debug boot → owner `sailingsisu` + `Sisu` boat synced (`shareCode` shown in-app = Supabase) + `ownerId` stamped; sign-out → join screen → code `256923` → anonymous crew membership created in `boat_members` → "Joined Sisu. Syncing…". Test artifacts cleaned up. (iOS simulator blocked by `google_mlkit_text_recognition` lacking arm64 sim support — Android is the verify target.)
- `flutter analyze` 0 issues; `flutter test` 639 pass.
- Files: new account screens + `debug_bootstrap.dart`; edited `auth_service.dart`, `sync_service.dart`, `boat_repository{,_impl}.dart`, `app_router.dart`, `common_drawer.dart`, `paywall_screen.dart`, `startup_screen.dart`; `boat_repository_test.dart`.
- Remaining: Phase 4 (ownerId/boatSupabaseId on the model layer + Drift bump for bar/pantry), Phase 5 (community tables), Phase 6 (RLS cutover — still permissive).

## [2026-07-11] — Pro sync sharing: unblocked + owner account + debug bootstrap
- External blockers cleared: **anonymous sign-ins enabled**; owner account `sailingsisu@outlook.com` created (signup API) + email-confirmed (SQL) — password sign-in verified.
- Full crew-join path verified end-to-end over HTTP: seed boat → anon sign-in → `redeem_boat_code` (case/space-tolerant, rejects bad codes) → membership inserted → crew reads boat. Test data cleaned up.
- Debug bootstrap: new `lib/services/debug_bootstrap.dart` (`DebugBootstrap.run`) — in `kDebugMode && kForceProForTesting`, signs in the owner (creds via `SUPABASE_DEBUG_EMAIL`/`SUPABASE_DEBUG_PASSWORD` dart-defines) and ensures a boat named `Sisu` (`kDebugBoatName`) is the active boat, so on-device Pro sync runs without the unbuilt sign-up/boat UI. Wired into `startup_screen._afterHomeReady()` before `syncServiceProvider`.
- `dart-defines.json`: added `SUPABASE_DEBUG_EMAIL` + `SUPABASE_DEBUG_PASSWORD` (gitignored).
- `flutter analyze`: 0 issues (full project). **Not yet run on-device** — needs a debug launch to confirm the bootstrap signs in + syncs the Sisu boat.
- Files changed: `lib/services/debug_bootstrap.dart` (new), `lib/ui/startup/startup_screen.dart`, `dart-defines.json`, `.ai_context/changelog.md`
- Remaining: Phase 3 join/sign-up UI, Phase 4 ownerId/boatSupabaseId wiring (+ Drift bump for bar/pantry), Phase 5 community tables, Phase 6 RLS cutover.

## [2026-07-11] — Pro sync sharing: plan + backend structure (Phase 1–2a) + auth groundwork
- Agreed model: Free offline/no-account; Pro = email+password account owning boats; crew join a boat via a rotatable per-boat share code (anonymous auth + membership + RLS); crew inherit the owner's Pro for that boat only; community = global publish/browse tables. Full plan in `plans/pro-sync-sharing.md`.
- Backend (migration `boat_ownership_and_sharing`): `boats` gained `ownerId uuid` + `shareCode text unique` (DB-generated default); new `boat_members` table (PK boat+member) with owner/member RLS; `redeem_boat_code(p_code)` SECURITY DEFINER RPC (validates code → inserts membership for `auth.uid()` → returns boatSupabaseId); `boatSupabaseId` added to `bar_ingredients`/`pantry_ingredients`. Non-breaking; permissive RLS on the 15 sync tables kept until the app populates ownership (Phase 6 cutover).
- Verified over HTTP: shareCode auto-generates; redeem RPC rejects unauthenticated. **Crew-join blocked externally**: anonymous sign-ins disabled on the project (dashboard toggle needed).
- App groundwork: `AuthService` gained `signUp`, `signInAnonymously`, `redeemBoatCode`, `isAnonymous`. `revenuecat_service.dart` gained debug bootstrap consts `kDebugAccountEmail='sailingsisu@outlook.com'`, `kDebugBoatName='Sisu'`. `flutter analyze` on changed files: 0 issues.
- Context self-healed: entitlement id `sisu_mate_pro` → `Boat Checks Pro` in `INDEX.md` + `screens.md` (code has said `'Boat Checks Pro'` since 2026-05-12).
- Files changed: `lib/services/auth_service.dart`, `lib/services/revenuecat_service.dart`, `supabase/migrations/*`, `plans/pro-sync-sharing.md`, `.ai_context/{INDEX,screens,caching,changelog}.md`
- New risks: permissive RLS still live (tighten at Phase 6). Remaining: Phases 3–6 (auth UI, ownership/Drift schema bump for bar/pantry, community tables, RLS cutover).

## [2026-07-11] — Provision Supabase backend + migrate app to MCP project
- Migrated the app off retired project `biorjpeijlktivcjymrb` onto `mvjgenxntirjgmwrsmmv` (the project the Supabase MCP is wired to in `.mcp.json`).
- Built the live sync schema: 15 tables matching `InboundSyncApplier.syncedTables`, columns = exact camelCase keys from each model's `toJson()`. `supabaseId` PK (idempotent parameterless upsert), trigger-mirrored `id` column for realtime, jsonb for list fields, `replica identity full`, all added to `supabase_realtime`. Permissive RLS (`sisu_allow_all`).
- Verified end-to-end over HTTP with the app's anon key: upsert-without-id → row + mirrored id; repeat upsert same `supabaseId` → in-place update (idempotent); delete-by-`supabaseId` → row removed.
- Files changed in project: `dart-defines.json`, `.env` (URL + anon key repointed), new `supabase/migrations/0001_sync_schema.sql`, new `supabase/migrations/0002_harden_trigger_function_search_path.sql` (implicit via MCP)
- Context files updated: `caching.md` (new "Supabase Backend" section), `changelog.md`
- New risks introduced: **permissive RLS on all synced tables** — no ownership column in wire format, so tighten before release (advisor `rls_policy_always_true`). `.env` `SUPABASE_PWD` is the OLD project's DB password (stale, unused by app).
- Removed/deprecated: project `biorjpeijlktivcjymrb` no longer referenced

---

## [2026-07-11] — SUG1: testing bypasses gated behind kDebugMode (release-safe)

Instead of a CI script that fails when the flags are `true` (original SUG1), the
bypasses now **structurally cannot affect a release build**:
- `RevenueCatService.isPro()` — bypass condition is now `kDebugMode && kForceProForTesting && !FLUTTER_TEST`. `kDebugMode` is a compile-time const (false in profile/release), so release builds always use the real entitlement. `FLUTTER_TEST` guard kept because `flutter test` runs in debug mode.
- `hasSeenOnboarding()` (`onboarding_screen.dart`) — now `kDebugMode && kBypassOnboardingForTesting`; release builds always show onboarding. Added explicit `package:flutter/foundation.dart` import for `kDebugMode`.
- Both flags stay `true` for convenient debug testing; doc comments updated to say they are debug-only.
- **RM1/RM2 downgraded from critical release blockers → low** (debug-only conveniences). Removed SUG1; updated the "Release Blockers" section + priority list in outstanding.md.
- Existing guard test (`isPro is false in unit tests even when kForceProForTesting is true`) still passes.
- Verify: analyze **0** · `flutter test` **638** passed · `flutter build apk --debug` success.
- Files: `revenuecat_service.dart`, `onboarding_screen.dart`; context: `outstanding.md`, `changelog.md`.

---

## [2026-07-11] — Backlog: GAME1/SUG6 · SUG5 · TEST1b (seed regression tests)

Continued the previous session's "best next engineering" list after SUG7.

- **GAME1 / SUG6 (Games multiplayer clarity):** when the hub's Multiplayer toggle is on, solo-only games are now shown **dimmed (opacity 0.45) + a "Solo only" badge** instead of only revealing unavailability via a snackbar on tap. `_GameTile` gained a `multiplayerActive` flag; badge uses `SisuColors.getListSurface`/`getTextSecondaryColor` (no inline colours, theme.md-compliant). Underlying networking for the other 8 games is still unbuilt (GAME1 stays open, narrowed).
- **SUG5 (self-heal risks.md):** struck three stale "Known fragile points" that contradict shipped work — `activeBoatProvider` is a real `FutureProvider<Boat?>` (not a null stub, resolved 2026-05-12); RevenueCat user id is linked to the Supabase UUID via `linkSupabaseUserId`/`logIn` (PRO3); `isProProvider` is a re-emitting `StreamProvider`, not a stale `FutureProvider` (PRO2).
- **TEST1b (partial — full seed row counts):** added `AppDatabase.setInstanceForTesting` (test-only singleton override) and `test/seed_bundled_data_test.dart` — asserts exactly one default boat, non-empty catalogs per core module, **referential integrity** (no checklist item points at a missing group), and **seeder idempotency** (re-run adds no rows). Guards the recurring seed-bug class in this project's history. Discovered/documented: the shopping trip list seeds empty by design (only categories ship).
- **NAV2 deliberately deferred:** ~40 anonymous `Navigator.push` sites, low priority, no concrete acceptance beyond "when touched"; a blind sweep is high-churn/low-value and violates smallest-change. Left for incremental conversion.
- Removed SUG5 and SUG6 from outstanding; narrowed GAME1.
- Verify: analyze **0** · `flutter test` **638** passed · `flutter build apk --debug` success.
- Files changed: `lib/ui/games/games_screen.dart`, `lib/data/drift/app_database.dart`, `test/seed_bundled_data_test.dart` (new); context: `risks.md`, `outstanding.md`, `changelog.md`.

---

## [2026-07-11] — SUG7 import snackbar “inserted N / updated M” (finish interrupted refactor)

Previous session was force-stopped mid-refactor: it introduced `ImportPersistResult`
(`lib/ui/components/import_export.dart`) and changed the `persist` callback to return it,
but left 7 call sites still returning/typed as `int` → 7 analyze errors, build broken.
Completed the refactor:
- **shopping_screen**: `_importShopping` return type `Future<int>` → `Future<ImportPersistResult>` (body already built the result).
- **checklists / maintenance / safety / documents / inventory**: closures now track `inserted`/`updated` counters and return `ImportPersistResult` instead of `batch.*.length`.
- Snackbar now reads `result.snackbarMessage` (“Imported 3 (2 new, 1 updated)” etc.).
- Test: `test/import_persist_result_test.dart` covers `snackbarMessage` singular/plural/mixed + `total` + `allInserted`.
- Removed SUG7 from outstanding.
- Verify: analyze **0** · `flutter test` **634** passed · `flutter build apk --debug` success.
- Files: shopping/checklists/maintenance/safety/documents/inventory screens, new test, outstanding.md, changelog.md.

---

## [2026-07-09] — Medium backlog: SYN3 · WX1 · IMG1 · TEST1

- **SYN3:** `ImportService.parse(boatSupabaseId:)` + `ImportBatch.applyBoatId`; import sheet resolves active boat via `activeBoatProvider`. Chef URL/OCR imports stamp boat too.
- **WX1:** `geolocator` — Weather “Use GPS” / my-location; first launch tries device location. Android/iOS location permissions.
- **IMG1:** `ImageService.persistPickedPath` copies picks into `user_images/` under app documents; `pickPhotoFromCameraOrGallery` always persists.
- **TEST1:** SYN3 import tests, image_service tests, GoRouter path smoke; residual gaps demoted to TEST1b (low).
- Removed SYN3/WX1/IMG1/TEST1 from outstanding mediums.
- Files: import_service, import_export, image_service, photo_source_picker, weather_screen, chef_screen, manifests, tests, outstanding, changelog.

---

## [2026-07-09] — Menu ingredient ↔ My Pantry navigation

Mirror of cocktail ↔ My Bar links for Chef:
1. Menu/meal recipe ingredient tap → `IngredientDetailScreen.pantry` (snackbar if not tracked).
2. My Pantry list + pantry detail show tappable **Used in menus** chips → `AppRoutes.chefRecipe`.
- `PantryIngredientRepository.menusUsingIngredient` + `menuRecipesForIngredientProvider`.
- Test: pantry repo menusUsingIngredient filters to `menu` type only.
- Files: pantry repo + provider, chef_screen, ingredient_detail_screen, tests, data_models, changelog.

---

## [2026-07-09] — PRO1–PRO3 Pro gates & RevenueCat identity

- **PRO1:** Custom item FAB on Checklists / Maintenance / Safety is real: Pro → add dialog (title + notes) via `showAddCustomChecklistItemDialog`; Free → paywall. Lock icon when Free.
- **PRO2:** `isProProvider` is a `StreamProvider` that re-emits on `RevenueCatService.onCustomerInfoUpdated` (purchase, restore, customer-info listener, login).
- **PRO3:** RevenueCat `appUserId` prefers Supabase auth UUID; `linkSupabaseUserId` on auth state changes in `SisuMateApp`. Anonymous `user_<ts>` when signed out.
- Tests: checklist custom item; revenuecat stream/link safety. Removed PRO1–3 from outstanding.
- Files: `add_checklist_item_dialog.dart`, checklist/maintenance/safety item screens, `revenuecat_service.dart`, `di.dart`, `main.dart`, access_tiers, outstanding, changelog.

---

## [2026-07-09] — Shopping add fix · cocktail↔bar nav · unified photo picker

1. **Shopping manual add vanished** — items were saved under `default_category` / empty category ids that the list never streams. `addItem` now resolves empty/`default_category` (and missing ids) to `cat-misc`, creating that category if needed. Dialog seeds `cat-misc`.
2. **Cocktail ingredient → My Bar** — recipe ingredient tiles open `IngredientDetailScreen.bar` when the ingredient exists in the bar catalog.
3. **My Bar → cocktail** — list chips + ingredient detail “Used in cocktails” chips navigate via `AppRoutes.cocktailRecipe` (`cocktailRecipesForIngredientProvider`).
4. **Unified photo UX** — `pickPhotoFromCameraOrGallery` (`lib/ui/components/photo_source_picker.dart`) is the single Camera/Gallery bottom sheet. Wired on ingredient detail, checklists/maintenance/safety (`CheckPageViewer`), record detail, crew/docs/inventory dialogs, bar edit, recipe/cocktail/menu edit, pantry edit, chef OCR import.
- Tests: shopping repo category resolve + cat-misc. Analyze 0.
- Files: shopping_repository_impl, shopping_screen, cocktails_screen, ingredient_detail_screen, photo_source_picker, check_page_viewer, record_detail_screen, crew/documents/inventory/chef screens, shopping_repository_test, context.

---

## [2026-07-09] — SYN1/SYN2 two-way sync table coverage

- **SYN1:** Inbound apply + realtime subscribe for `documents`, `crew_members`, `inventory_items`, `fuel_logs` (were outbound-only).
- **SYN2:** Recipes / recipe_ingredients / bar / pantry queue outbound; inbound apply + `BarIngredient`/`PantryIngredient` `fromJson`/`toJson`. Repos take optional `SyncService`; DI wires it.
- `InboundSyncApplier.syncedTables` is the single list used by subscribe + apply + conflict mark-unsynced.
- Tests: `test/inbound_sync_tables_test.dart`.
- Removed SYN1/SYN2 from outstanding.
- Verify: analyze 0 · tests green.

---

## [2026-07-09] — NAV1 detail/game routes · POL1 servings · POL2 settings

- **NAV1:** GoRouter detail routes — checklist/maintenance/safety items (`extra: ChecklistGroup`); chef/cocktail recipe detail (`extra: Recipe`); games `play/:gameId`, `lobby/:gameId`, `help`; `GameCatalog` + lobby uses `gameId` not Widget.
- **POL1:** Chef recipe servings use same `1,2,4,6,8,10,12` ChoiceChips Wrap as cocktails.
- **POL2:** Removed settings “More settings coming soon…” filler.
- Still anonymous push: full-screen editors, cooking mode, barcode, record details, etc.
- Tests: app_router NAV1 paths. Removed NAV1/POL1/POL2 from outstanding.
- Verify: analyze 0 · tests green.

---

## [2026-07-09] — Full analysis → outstanding.md refresh

Audit after recent ship train (T3/T5/RT1/UX/IMP/S3/S7). Analyze 0 · **607** tests.

**Added to outstanding:** SYN1–4 (outbound/inbound table mismatch; recipes/bar/pantry not synced; import boat id; unused SyncInbox), PRO1–3 (custom checklist FAB stub; isPro refresh; RC↔auth link), WX1 (no GPS), IMG1 (temp image paths), NAV1 (partial GoRouter), TEST1 (coverage gaps), POL1–2, GAME1, SUG1–7.

**Self-healed risks.md:** navigation = GoRouter top-level; `activeBoatProvider` no longer documented as null stub.

- Context only: outstanding.md, risks.md, changelog.md.

---

## [2026-07-09] — T3 GoRouter named routes

- **`go_router`** dependency; `lib/core/app_router.dart` — `AppRoutes` path constants + `createAppRouter()`.
- **`MaterialApp.router`** in `main.dart` (`appRouter`); initial `/` = Startup.
- Named routes for home modules (shopping…games), settings/boats/sync/conflicts, weather/passage, onboarding.
- Migrated: startup/onboarding (`context.go`), home grid + drawer, settings, sync/conflicts drawer tiles, weather → passage.
- Detail/game flows may still use `Navigator.push` + `extra` where domain objects are required.
- Tests: `test/app_router_test.dart`.
- Removed T3 from outstanding.
- Verify: analyze 0 · **607** tests.

---

## [2026-07-09] — S7 Sync dashboard · T6 tests · S3 Weather & passage

**S7:** `SyncStatusScreen` — outbox depth, conflicts, last success/fail, by-table/priority, force flush. Entry: drawer **Sync Status** + Settings. Pro-gated display.

**T6:** `test/sync_service_test.dart` (outbox status, Free gate no-op queue); `test/seed_integrity_test.dart` (import samples / content keys).

**S3:** Weather module — Open-Meteo + marine waves, SharedPreferences cache, OSM map pin; Passage planner (waypoints, NM, hours, fuel L). Home tile **Weather**. Deps: `flutter_map`, `latlong2`.

- Files: sync_status_screen, weather_service, weather_screen, passage_planner_screen, home_screen, common_drawer, settings_screen, pubspec; tests; outstanding (removed S7/T6/S3), changelog, INDEX.
- Verify: analyze 0 · tests green.

---

## [2026-07-09] — UX6 Games theme + IMP2 import upsert

**UX6:** Games hub aligned to theme.md — `SisuColors` scaffold, TitleTile subtitle, end drawer, raised game tiles, multiplayer switch card; lobby scaffold themed; help cards use SisuColors.

**IMP2:** Re-import no longer always duplicates:
- Parse honours optional `supabaseId` / `id` (except **fuel** — always mint, identical fill-ups are valid).
- Export includes `supabaseId` for round-trip.
- Content-key match (`matchExisting`) + update on crew, inventory, documents, shopping, recipes, checklist/maintenance/safety items.
- 4 new unit tests.

- Files: games_screen, lobby, game_help; import_service + all module persist sites; import_service_test; outstanding (removed UX6/IMP2), theme, changelog.
- Verify: analyze 0 · **592** tests.

---

## [2026-07-09] — RT1 Startup jank: defer non-critical init

Faster first paint on cold start:

- **`main.dart`** — only `Supabase.initialize` before `runApp`; RevenueCat + AdMob start in a post-frame callback (parallel).
- **`StartupScreen`** — waits one frame before opening Drift; after home/onboarding navigation, runs deferred catalog seeds + starts `SyncService`.
- **`DatabaseService`** — `init()` only health-check / fresh seed; `runDeferredSeeds()` does cocktail/menu packs + bar/pantry patches (idempotent).
- **Banner/Native ads** — `await AdMobService.init()` before creating ads (SDK may still be warming up).
- Removed RT1 from outstanding.
- Files: main.dart, startup_screen.dart, database_service.dart, banner_ad_widget, native_ad_widget, startup_deferred_init_test; outstanding, changelog, caching.
- Verify: analyze 0 · tests green.

---

## [2026-07-09] — T5 Offline conflict resolution

Inbound sync is live on Drift with user-facing conflict resolution:

- **`processIncomingChanges`** — applies remote rows for boats, checklist_groups/items, shopping_categories/items, captain_logs, maintenance_tasks via `InboundSyncApplier`.
- **Clean local + newer remote** → last-write-wins upsert (no conflict).
- **Dirty local (`!isSynced` / pending outbox) + newer remote** → write **ConflictLog** (local/remote JSON snapshots); local row is **not** overwritten until the user chooses.
- **UI** — drawer **Sync Conflicts** badge (`ConflictsDrawerTile` in `DataManagementSection`) → `ConflictResolutionScreen` (Keep mine / Keep cloud). Buttons use `Wrap` to avoid overflow.
- **Schema v6** — `ConflictLogs.localData`, `remoteData`, `resolvedAt`.
- **Services** — `ConflictResolutionService` (pure evaluate), `InboundSyncApplier`, extended `SyncService` (`watchPendingConflicts`, `resolveConflict`).
- **Providers** — `pendingConflictsProvider`, `pendingConflictCountProvider` in `di.dart`.
- **Tests** — 10 cases in `conflict_resolution_test.dart` (evaluate + in-memory inbound/resolve).
- Files: sync_service, conflict_resolution_service, inbound_sync_applier, app_database, conflict_log model, conflict_resolution_screen, common_drawer, di; outstanding (removed T5), caching, INDEX, changelog.
- Verify: analyze 0 · **586** tests.

---

## [2026-07-09] — Cocktail servings 1–12 chips

Cocktail detail servings: **1, 2, 4, 6, 8, 10, 12** as compact `ChoiceChip`s in a `Wrap` (not `SegmentedButton`) to avoid horizontal pixel overflow.
- Files: cocktails_screen.dart, changelog.md.

---

## [2026-07-09] — Cocktail edit: explicit camera + gallery buttons

`AddEditRecipeDialog` photo hero (cocktails, menus, house recipes) now shows clear **Camera** and **Gallery/upload** buttons (plus remove when a user photo is set) on the image, same pattern as bar ingredients — not a single low-visibility FAB.
- Files: cocktails_screen.dart, changelog.md.

---

## [2026-07-09] — Main-list overflow + full-screen recipe editors

1) **Safety / Checklists / Maintenance overflow** — `MainListTile` body no longer uses a min-size Column that overflows fixed-aspect grid cells; non-scrollable `SingleChildScrollView` clips safely. `GroupGrid` aspect ratio 0.58, compact header (56).
2) **Edit cocktail / recipe full-screen** — all `AddEditRecipeDialog` open sites (Chef + Cocktails, including Mixologist “save as”) use `Navigator.push` + `fullscreenDialog: true` with Scaffold AppBar.
3) **Garnish overflow** — Optional/Garnish checkboxes in `_IngredientFormField` use `Wrap` (not a tight horizontal Row).
4) **Recipe image** — camera/gallery (and clear); persists `Recipe.localPath` on save; hero preview on the form.
- Files: main_list_tile.dart, group_grid.dart, cocktails_screen.dart, chef_screen.dart; theme.md, risks.md, changelog.md.
- Verify: analyze 0 · 578 tests · debug APK.

---

## [2026-07-09] — UX3 main lists on theme

Bring main-list screens to theme.md §5 (Chef reference):

- **`MainListTile` / `MainListSearchBar`** — shared 2-col card (icon, title, tags, count, meta, attention, badges) + search chrome.
- **`GroupGrid`** — 2-col (was 3); live `done/total` from `checklistItemsProvider`; Checklists / Maintenance / Safety.
- **Record lists** — Crew, Documents, Inventory, Fuel, Logbook: 2-col main tiles + search where useful; multi-select keeps list mode.
- **Chef / Cocktails** — high-contrast card titles (`getTextPrimaryColor`); module subtitles on TitleTile.
- Shopping subtitle for trip context.
- Removed UX3 from outstanding; theme.md §5 marked done.
- Files: main_list_tile.dart, group_grid.dart, checklist/maintenance/safety screens, crew/docs/inventory/fuel/logbook, chef/cocktails, outstanding, theme, INDEX, changelog.
- Verify: analyze 0 · 578 tests.

---

## [2026-07-09] — Tag combobox (suggested + user library) for Chef & Cocktails

Product decision (user #1): cuisine/flavor tags use a type-to-filter combobox listing suggested tags for uniformity; novel tags the user types are saved to a SharedPreferences library and reappear next time.

- `TagLibraryService` — suggested sets + `remember` / `options` for cuisine & flavor.
- `TagCombobox` — multi-select chips + autocomplete field; Enter / + adds novel tags.
- `AddEditRecipeDialog` — cocktails **and** menus use comboboxes (menus no longer single cuisine dropdown).
- Filter chips merge library + tags used on recipes.
- Removed open product item from `outstanding.md`.
- Files: tag_library_service.dart, tag_combobox.dart, cocktails_screen, chef_screen, tag_library_service_test, outstanding, changelog, INDEX.

---

## [2026-07-09] — Shopping trip costs from seed/catalog prices

Shopping list shows unit prices and predicted trip spend for **pending** (to-buy) items.

- `ensureInShopping` copies `lastKnownPrice` + `lastPurchasePlace` from bar (then pantry) seed catalog.
- Line estimate = unit price × quantity; section totals + **Trip estimate** strip sum only outstanding lines.
- Shopping item detail: edit unit price + store/location; `updateItem` syncs back to matching bar/pantry catalog.
- Ingredient (bar/pantry) detail edit of price/place pushes to pending shopping lines via `applyPricePlaceToPendingByName`.
- Schema v5: `ShoppingItems.lastPurchasePlace`. One-shot `backfillMissingPricesFromCatalog` on Shopping open.
- Tests: shopping_repository price copy/sync. Verify: analyze 0.
- Files: shopping_item, app_database, shopping_repository(+impl), shopping_screen, ingredient_detail_screen, tests, INDEX/data_models/changelog.

---

## [2026-07-09] — Integrate seed patches + bar-style imperial oz

1. **No more separate startup patch functions** for cocktails/metric (logic lives in seeders).
2. **Preserve user state between restarts**: healthy `init` does **not** re-purge recipes. Expansion packs are idempotent (no-op if present). Bar/pantry only insert missing rows and keep `inMyBar` / `inMyPantry`. Full recipe reseed only on first install / factory reset via `seedRecipes`.
3. **Bar units for cocktails**: `preferBarUnits: true` — 30 ml = 1 oz (jigger), display `¼`/`½`/`¾`/`1`/`1½` oz (never tbsp). Chef keeps culinary cup/tbsp.
- Files: units.dart, recipe_drift_seed, seed_recipes, seed_cocktails_import, seed_menus_import, database_service, cocktails_screen, import_service, tests.
- Context: INDEX, changelog.
- Verify: analyze 0 · tests + build.

---

## [2026-07-09] — Metric / imperial toggle (storage always metric)

Drawer **Imperial units** switch (next to Dark theme). Database, seeds, and sync stay metric; UI and export convert when imperial is on; import always converts to metric before save.

- **Core:** `lib/core/units.dart` — `UnitSystem`, `UnitConverter` (volume/weight/length/temp + fuel L↔gal + °F/°C in prose), `unitSystemProvider`.
- **Settings:** `UserSettings.useImperial` + Drift `schemaVersion` 4 migration; restore on startup with theme.
- **Import/export:** `ImportService` + URL/OCR `parseIngredientLine` normalize ingredients to metric; export takes `unitSystem`.
- **UI:** Chef/Cocktails ingredient rows, instructions temps, Fuel volume entry/display, export paths.
- **Seeds:** menus pack + classic menus/syrups converted tsp/tbsp/cup/oz → ml/g; generator enforces metric; startup `patchRecipeIngredientsToMetric` for existing installs.
- Tests: `test/unit_converter_test.dart`; recipe import tests expect metric storage.
- Files: units.dart, user_settings, app_database, repos, import_service, recipe_import_service, home/startup/fuel/chef/cocktails/shopping/inventory screens, seed_recipes, menus seed JSON + generator, recipe_drift_seed, database_service, tests.
- Context: outstanding (removed #1 metric/imperial), INDEX, data_models, changelog.
- Verify: analyze 0 · 566 tests · debug APK OK.

---

## [2026-07-09] — USDA macros for all pantry seed items

Filled `_macrosPer100g` for every pantry catalog row (243/243) — USDA-style kcal / protein / fat / carbs per 100g on the auto-added proteins, veg, cheeses, grains, SA staples, sauces, spices, etc. Startup `patchMissingPantryMacrosInDrift` backfills null macros on existing installs without overwriting non-null values.

- Files: `seed_pantry_ingredients.dart`, `ingredient_drift_seed.dart`

---

## [2026-07-09] — Expand bar/pantry catalogs from recipe seeds

Compared cocktail + menu recipe ingredients to `seed_bar_ingredients` / `seed_pantry_ingredients` and added missing catalog rows:

- **+32 bar** (Egg White, Chartreuse, Peychaud’s, Amaro Nonino, Apricot Liqueur, Crèmes, Port/Sherry, etc.)
- **+~170 pantry** (proteins, veg, cheeses, grains, SA staples, condiments, spices)
- Existing installs **upsert by supabaseId** on startup (`insertMissing*`) so `inMyBar` / `inMyPantry` are preserved.

- Files: `seed_bar_ingredients.dart`, `seed_pantry_ingredients.dart`, `ingredient_drift_seed.dart`, `database_service.dart`

---

## [2026-07-09] — Chef menus expansion pack (recipe_import → seed)

Processed `lib/recipe_import.json` (128 dishes) into `assets/seed/menus_import_seed.json` and seeded as bundled menus (`menu_imp_*`):

- Base quantities for **2 people**; imperial bulk → metric where possible; °F → °C in instructions.
- Course types (`main|side|braai|…`) stored as **menu** + cuisine tags (Main, Braai, …).
- Ingredient lists patched from description/instructions (e.g. Wellington + prosciutto/mushroom).
- **Story** field: guest-friendly wine/beer pairing + Caribbean-friendly grape/style substitutes.
- Classic 10 yacht menus scaled to 2p + pairing stories; Chef filter chips include course tags.
- `ImportService` accepts meal-course `recipeType` aliases. Startup + factory seed via `seedMenusImport`.
- Regenerator: `tool/generate_menus_import_seed.py`. Tests: `menus_import_seed_test.dart`.

- Files: generator, seed JSON, `seed_menus_import.dart`, `seed_recipes.dart`, `database_service.dart`, `import_service.dart`, `chef_screen.dart`, `pubspec.yaml`, tests
- Context: outstanding (removed user #3/#4), changelog, INDEX

---

## [2026-07-09] — Shopping Done swipe + Complete shopping run

1. Bar/Pantry (and ingredient detail): when item is blue on-list, swipe action is green **Done** → `markPendingBoughtByName` (marks shopping bought + stocks bar/pantry).
2. Shopping drawer: **Complete shopping run** permanently deletes all bought (green) items so the next trip starts clean; pending lines kept. Confirm dialog explains this.
3. Advice: delete bought lines (not soft-hide) — trip-based list; stock history lives on Bar/Pantry after buy.

- Files: shopping repo + impl, `swipeable_list_item.dart`, cocktails/chef tiles, shopping drawer, ingredient detail, tests

---

## [2026-07-09] — Bar/Pantry sort options + sticky list order

My Bar and My Pantry no longer auto-jump when toggling stock (repo sort is name-only). Drawer adds **sort modes**: A–Z, Z–A, Category, Availability (stock → shopping → other). Order is **sticky** until the user changes sort so colour updates stay in place. Small “Sorted: …” hint under search.

- Files: `ingredient_list_sort.dart`, `cocktails_screen.dart`, `chef_screen.dart`, bar/pantry repository watches

---

## [2026-07-09] — Chef menus: scrollable search/filter chrome

Chef menus tab uses `CustomScrollView` so search + Favourites/cuisine/method chips scroll away with the 2-col grid (same pattern as Cocktails).

- Files: `chef_screen.dart` (`_ChefTab`)

---

## [2026-07-09] — Cocktails grid + shared tag colours + Chef favourites

1. Flavor tags: **green cuisine / orange flavor** on Cocktails (was purple) to match Chef.
2. Cocktails list: **2-column grid** cards (`_CocktailCard`) like Chef; availability sort uses sectioned sliver grids.
3. Chef favourites: filter chip, heart on menu cards, detail TitleTile + drawer (same pattern as Cocktails).

- Files: `cocktails_screen.dart`, `chef_screen.dart`

---

## [2026-07-09] — Recipe detail ingredients: no stock prose (Chef + Cocktails)

Recipe-detail ingredient rows no longer print stock/shopping status prose (colour + snackbar carry state). Tertiary line shows catalog **flavor profiles** (Chef also allergens when present; plus Optional / garnish notes / Try substitute when useful).

- Files: `cocktails_screen.dart` (`_IngredientAvailabilityTile`), `chef_screen.dart` (`_PantryIngredientAvailabilityTile`)

---

## [2026-07-09] — Bar/Pantry: shopping blue state, buy→stock, UX5 detail

Cross-module stock/shopping via Drift streams + idempotent cart adds.

1. **`ensureInShopping`** — no duplicate pending rows by name; swipe-spam safe.
2. **`watchAllItemNames`** — pending only (`!bought && !hidden`) → blue cart state clears when bought.
3. **`toggleBought`** — when marked bought, sets matching **Bar + Pantry** rows in-stock by name and runs `syncMissingIngredientCounts` so cocktail/menu availability updates on `recipesProvider` / bar / pantry streams.
4. **Bar/Pantry list tiles** — green stocked · blue on shopping list · grey default; leading icon tinted by state (no bag status icon); tap → **`IngredientDetailScreen`** PageView.
5. **Recipe ingredient rows** (Chef/Cocktails detail) — same state colours via `ThemedStateTile`; bag trailing icon removed.
6. Tests: shopping repo ensure + names + stock-on-buy.
- Verify: analyze 0 · `flutter test` 550/550 · debug APK OK.

- Files: `shopping_repository.dart` + impl, `ingredient_detail_screen.dart`, `cocktails_screen.dart`, `chef_screen.dart`, `shopping_repository_test.dart`
- Context: changelog, INDEX, theme.md §7

---

## [2026-07-09] — UX5 item detail + residual recipe drawers

Shipped theme.md §7 swipeable editable detail + residual UX4 recipe detail menus.

- **`ItemDetailShell`:** PageView between items (locked while editing), optional image + photo FAB, content builder, sticky action bar above history, TitleTile + endDrawer.
- **`RecordDetailScreen`:** generic fields/edit for Crew, Inventory, Documents, Fuel (replaces AlertDialog details).
- **Checklists/Maintenance/Safety:** `CheckPageViewer` rebuilt on the shell; theme state colours; history from `completionHistory` + createdAt.
- **`toggleComplete`:** appends ISO timestamp to `completionHistory` (repo + test).
- **Shopping:** tap tile → `ShoppingItemDetailScreen` (buy/hide/delete/edit).
- **Chef/Cocktail recipe detail residual:** TitleTile menu + endDrawer (edit, share, sync ingredient counts; cocktails also favourite + delete custom).
- **Removed** orphaned `item_detail_screen.dart`.
- Tests: `test/item_detail_shell_test.dart`; checklist history test updated.
- Verify: analyze 0 · `flutter test` 547/547 · debug APK OK.
- Note: Bar/Pantry still use edit dialogs (not full UX5 PageView); recipe details keep rich layouts with new menus rather than generic shell.
- Context: outstanding (removed UX5), theme.md §7 done, INDEX, screens.md, changelog.

---

## [2026-07-09] — UX4 complete: themed item-list tiles + light state palette

Rolled **colour-tells-state** item lists to every remaining module (closes UX4 + B1 already closed by ChecklistItemTile rollout).

- **`SisuColors`:** light-theme `lightState*Bg/Desc/Title` mirrors for all five `ItemListState`s; `itemStateColors(isDark, state)` is the single resolver.
- **`ThemedStateTile`:** shared raised Card + title/subtitle/tertiary; used by Shopping, Bar, Pantry, Crew, Inventory, Documents, Fuel.
- **State mapping:** Shopping hidden/bought/to-buy → hidden/stocked/shopping; Bar/Pantry in-stock → stocked; Documents expired → unavailable (red); record lists (crew/inventory/fuel) → defaults.
- **Swipe:** `SwipeableListItem` on checklist/shopping/bar/pantry; record lists remain tap-to-detail (no hide/stock semantics).
- **Residual (not UX4):** Chef/Cocktail recipe detail TitleTile still no list-options drawer; full swipeable detail = UX5.
- Verify: `flutter analyze` 0 · `flutter test` 545/545 · `flutter build apk --debug --dart-define-from-file=dart-defines.json` OK.
- Files: `colors.dart`, `themed_state_tile.dart`, `checklist_item_tile.dart`, `shopping_screen.dart`, `cocktails_screen.dart` (bar), `chef_screen.dart` (pantry), `crew_screen.dart`, `inventory_screen.dart`, `documents_screen.dart`, `fuel_screen.dart`
- Context: `outstanding.md` (removed UX4 + B1), `theme.md` §0 + §6 marked done, `changelog.md`

---

## [2026-07-09] — Cocktails list: scrollable chrome + availability 0/N

Cocktails tab header (Today's special, search, Sort+Favourites side-by-side, cuisine/flavor chips) now scrolls away with the list so small screens keep cocktail rows visible. Availability section titles use `count/total` (e.g. `Can make now · 0/162`). Sync missing counts on tab open + after seed (defaults were 0, so empty bar incorrectly showed all as makeable).

- Files: `cocktails_screen.dart`, `seed_recipes.dart`

---

## [2026-07-09] — Cocktail favourites seed + cuisine/flavor tags & filters

#2 Seed favourites: Mai Tai, Zombie, Three Dots and a Dash, Beachbum's Own, Tradewinds (Hinky Dinks Fizzy not in seed library — will favourite if added later). Startup patch promotes seeded names without un-favouriting user picks.

#3/#4 Tags & filters: classic seeder gets cuisine + flavorProfiles; import pack already had them; ingredient flavorProfiles roll up onto the cocktail on import (deduped). Cocktails tab: horizontal multi-select cuisine + flavor chips (AND). Add/edit cocktail: multi-select tags + custom tags. List/detail show tags. Import/export/template already include cuisine/flavorProfiles lists.

- Files: `cocktail_tags.dart`, `seed_recipes.dart`, `seed_cocktails_import.dart`, `import_service.dart`, `cocktails_screen.dart`, `database_service.dart`, tests
- Context: outstanding (removed #2/#3/#4; renumbered), changelog
- Note: "rummy spicy" filtering = select both rum-forward + spicy chips

---

## [2026-07-09] — Offline cocktail images (bundled assets + SmartImage)

Offline-first cocktail art: `Recipe.imageAsset` (bundled) + `localPath` (user photo). SmartImage priority is local file → bundled asset → icon (remote URLs ignored). Assets under `assets/cocktails/` max 720×480 JPEG for the detail hero (200px tall). Glassware defaults always present; a few Commons photos when rate-limits allow. Drift schemaVersion 3.

- Files: `smart_image.dart`, `recipe.dart`, `app_database.dart`, `recipe_repository_impl.dart`, `cocktail_image_assets.dart`, `seed_recipes.dart`, `seed_cocktails_import.dart`, `cocktails_screen.dart`, `pubspec.yaml`, `assets/cocktails/*`
- Context: INDEX/data_models/risks/changelog
- Note: Wikimedia blocked bulk fetch; defaults cover all drinks; more named photos can be added later via slow re-fetch

---

## [2026-07-09] — Cocktail prose: quantities on ingredients only

Instructions/description/story no longer embed drink measures (e.g. "Top with 60 ml soda water" → ingredient `Soda Water 60 ml` + "Top with soda water"). Generator enforces this; classic Doctor Funk / Jet Pilot prose updated; `patchCocktailMeasureProse()` rewrites stale installs at startup without wiping favourites.

- Files: `seed_recipes.dart`, `tool/generate_cocktails_import_seed.py`, `assets/seed/cocktails_import_seed.json`, `seed_cocktails_import.dart` (`patchCocktailMeasureProse`), `database_service.dart`, `test/cocktails_import_seed_test.dart`
- Verification: analyze clean · cocktail seed tests pass

---

## [2026-07-09] — Seed cocktails_import.json expansion pack (metric, one-glass)

Added 146 cocktails from `cocktails_import.json` into the seeder as a processed expansion pack.

- Processing rules: skip classics already in `seed_recipes.dart`; collapse near-identical name+recipe dupes; disambiguate true variants (e.g. Singapore Sling Trader Vic vs Raffles); convert oz→ml snapped to whole bar volumes (5/10/15/20/25/30/…); scale multi-serve punches to one glass (≤~165–220 ml liquid); ensure garnish (from file, instructions, or inference) with `isGarnish`; keep concrete descriptions; store cuisine + flavorProfiles lists.
- Files changed in project:
  - `tool/generate_cocktails_import_seed.py` — regenerator
  - `assets/seed/cocktails_import_seed.json` — processed payload
  - `lib/data/seed/seed_cocktails_import.dart` — loader/seeder (`cocktail_imp_*` ids)
  - `lib/data/seed/seed_recipes.dart` — calls expansion seeder; classic cocktail ingredients converted oz→ml
  - `lib/data/seed/recipe_drift_seed.dart` — `purgeSeededRecipesFromDrift`
  - `lib/services/database_service.dart` — runs expansion seeder on healthy startups (idempotent)
  - `pubspec.yaml` — registers seed asset
  - `test/cocktails_import_seed_test.dart` — asset invariants
- Context files updated: `INDEX.md`, `outstanding.md` (removed user #6 seeder item), `changelog.md`
- New risks introduced: first-run expansion path on existing installs via `DatabaseService.init` — only inserts when no `cocktail_imp_*` rows exist
- Removed/deprecated: none
- Verification: `flutter analyze` clean · `flutter test` 540/540 · debug APK OK

---

## [2026-07-09] — Recipe cuisine + flavorProfiles as lists (import/export + Drift)

Recipe tags needed to match `cocktails_import.json` (`cuisine`/`flavorProfiles` as string lists). Domain + Drift + ImportService now treat both as lists.

- Files changed in project:
  - `lib/models/recipe.dart` — `cuisine`/`flavorProfiles` are `List<String>`; helpers `stringListFromJson` / `dedupeStrings`
  - `lib/data/drift/app_database.dart` — `schemaVersion` 2; `Recipes.flavorProfiles` JSON column; cuisine default `[]`; migration rewrites plain cuisine → JSON list
  - `lib/data/repositories/recipe_repository_impl.dart`, `lib/data/seed/recipe_drift_seed.dart`, `lib/data/seed/seed_recipes.dart`
  - `lib/services/import_service.dart` — `_optStringList`; import/export/sample for list cuisine + flavorProfiles (string still accepted); ingredient `flavorProfiles`/`isFloat` ignored
  - UI/services consumers: `cocktails_screen.dart`, `chef_screen.dart`, `collections_screen.dart`, `recipe_import_service.dart`, `recipe_share_service.dart`
  - Tests: `test/import_service_test.dart`, `test/recipe_import_service_test.dart`
- Context files updated: `data_models.md`, `INDEX.md`, `risks.md`, `outstanding.md` (notes on #3/#4/#6), `changelog.md`
- New risks introduced: first real Drift `onUpgrade` path (v1→v2) — must keep migration ordered for older installs
- Removed/deprecated: `Recipe.cuisine` as `String?` (now always a list; empty = unset)
- Verification: `flutter analyze` clean · `flutter test` 538/538 · debug APK OK · structural check: `cocktails_import.json` (165 items) has 0 field-type problems for current ImportService rules

---

## [2026-07-09] — Cocktail recipe import/export: description, glassware, story

Recipe JSON template + export were dropping cocktail narrative fields that the UI already stores (`Recipe.description`, `Recipe.glassware` / Barman's Tale `story`). Import already mapped them; export and `sampleFor(recipe)` did not.

- Files changed in project: `lib/services/import_service.dart` (export + sample include description/glassware/story; import accepts `glasstype` as alias for `glassware`); `test/import_service_test.dart` (sample presence, export round-trip, glasstype alias); `lib/ui/maintenance/maintenance_items_screen.dart` (removed unused `_scaffoldKey` so analyze stays clean)
- Context files updated: `INDEX.md` (ImportService recipe field note), `outstanding.md` (removed user item #2; renumbered remaining; note on item #6 that story/description/glassware already round-trip), `changelog.md`
- New risks introduced: none
- Removed/deprecated: none
- Verification: `flutter analyze` zero issues · `flutter test test/import_service_test.dart` 30/30 · `flutter build apk --debug --dart-define-from-file=dart-defines.json` OK

---

## [2026-07-07] — UX4 pilot: themed state-colour tiles on Checklist items

Established the item-list tile pattern on `checklist_items_screen.dart` (pilot, pending owner review before rolling to the other ~9 list screens): each item is now a **raised `Card` whose colour is the state** (theme.md §6.5) — `SisuColors.stateStockedBg` green = completed, `stateHiddenBg` = hidden, `stateDefaultBg` = default — with matching title/description text tiers; the **trailing tick box is removed** (colour tells the state, §6.4). Swipe actions still go through `SwipeableListItem`. Local `_stateBg/_stateTitle/_stateDesc` helpers map item→palette. This is also the direction that resolves B1 (Maintenance) once rolled out. `flutter analyze` clean · `flutter test` 532/532. Not yet screenshotted on-device (device was disconnected).

---

## [2026-07-07] — UX2: main (home) screen on the theme

Home screen now follows the standard (owner reviewed on-device, approved): 3-column grid on the `#0D0D0D` darkest scaffold, module tiles now a **uniform dark blue-grey** `SisuColors.getHomeTile` (`#2E3D45` dark / `#CFD8DC` light) with the standard elevation, replacing the old per-module 10%-tinted backgrounds. Each tile keeps its accent colour on the **icon only** for identity. Added `darkHomeTile`/`lightHomeTile`/`getHomeTile` to `SisuColors`; `_AppTile` reads it via `Theme.of(context).brightness`. `theme.md` §4 updated to record the blue-grey tile decision (owner preferred it over a neutral `#121212`). `flutter analyze` clean.

---

## [2026-07-07] — UX4 rollout: shared ChecklistItemTile across Checklist/Maintenance/Safety (closes B1)

Extracted `lib/ui/components/checklist_item_tile.dart` — the themed, state-coloured, no-tick-box, swipe-wrapped tile (theme.md §6) — and adopted it in all three checklist-family item screens so they look and swipe identically:
- **Checklist items**: replaced the inline tile; removed local `_stateBg/_stateTitle/_stateDesc/_buildItemImage`; added `_proGatedComplete`/`_openViewer` helpers.
- **Maintenance items**: replaced the old **tick-box** tile (fallback icon `Icons.build`) → **closes B1** (colour tells state, no checkbox); removed `_getItemBackgroundColor/_getItemTextColor/_buildItemImage`.
- **Safety items**: same treatment (fallback `Icons.health_and_safety`).

Each keeps its own `onComplete` (Pro-gated ad prompt for Free), `onTap` (checklist/safety → CheckPageViewer; maintenance → its detail dialog), and hide/unhide. `flutter analyze` clean · `flutter test` 532/532 · build + install OK.

Remaining UX4 lists (different models, separate treatment): Shopping, Crew, Inventory, Fuel, Documents, Bar, Pantry.

---

## [2026-07-07] — Checklist detail viewer polish (owner round 2)

- **Removed the redundant status pill** in the detail AppBar (status is conveyed by the state-colour tint + snackbar).
- **Dark snackbars**: added `SnackBarThemeData` (dark surface + light text, floating) — the M3 default inverted to near-white on the dark theme.
- **Edit form clears the keyboard**: while editing, the image shrinks (flex 3→2) and the title/description move into a `SingleChildScrollView` (`_buildEditForm`), so the focused description auto-scrolls above the keyboard instead of being hidden.
- **History pane status (answer):** the active detail screen (`CheckPageViewer`) has **no history pane**. A separate `lib/ui/checklists/item_detail_screen.dart` (`ItemDetailScreen`) contains a Pro-gated **placeholder** "Item History" ("Additional history snapshots will be displayed here") and is the only place that appends to `completionHistory` — but it is **orphaned/unused** (nothing navigates to it), so history is effectively unbuilt and `completionHistory` is never populated in practice. Real history = UX5 detail-screen work (record completion timestamps in `toggleComplete` + a history list with the action buttons pinned above it). The dead `ItemDetailScreen` should be removed or repurposed.

`flutter analyze` clean · build (with dart-defines) + install OK.

---

## [2026-07-07] — Checklist detail viewer (CheckPageViewer) reworked

Owner feedback on the item detail screen:
- **Toggle now updates the UI** — `_toggleCompletion`/`_toggleHidden` were mutating the item but never calling `setState`, so the status pill + buttons never flipped. Added `setState`.
- **Bottom buttons now mirror the list swipe actions**: Complete⇄Uncomplete (state-aware label/colour); Hide when visible, **Unhide + Delete (red)** when hidden; plus Edit. Delete pops back to the list.
- **State colours** applied: the status pill and the content section are tinted with the shared `SisuColors.state*` palette (green completed / dark hidden / grey default), so the detail screen shows status the same way tiles do.
- **Change photo** (owner: take with camera OR pick from gallery): added an `add_a_photo` FAB overlapping the image; a bottom sheet offers **Take a photo** (`ImageSource.camera`) / **Choose from gallery** (`ImageSource.gallery`) via `image_picker`, saving to `item.userPhotoPath` and `updateItem`.

`flutter analyze` clean · build (with dart-defines) + install OK. On-device screenshot verification was blocked by a very slow roaming-network cold start (RT1), not a crash — pending owner check.

---

## [2026-07-07] — Theme refinements batch (owner on-device feedback) + testing bypasses

Addressed a round of on-device feedback on the checklist pilot + globals:
- **Group screens are now 3-column tile grids** (owner: "does not show three columns"). Extracted a shared `GroupGrid` widget (`lib/ui/components/group_grid.dart`); Maintenance, Checklists, and Safety group pickers all use it (icon+title tiles on `getHomeTile`, `childAspectRatio 0.82`, `Flexible` title so long Yanmar names don't overflow).
- **Swipe convention corrected** to match theme.md §6.6 (owner: "slides are wrong way round"): swipe RIGHT → Hide/Delete on the left; swipe LEFT → Complete on the right. **Complete is now a real toggle** (was nulled once completed, so you couldn't un-complete). **Hide side** shows Hide when visible; **Unhide + Delete (red)** when hidden. Rewrote `SwipeableListItem`.
- **State tile colours** tuned: default is now a clearly-visible grey (`stateDefaultBg #2E373D`), hidden clearly darker (`stateHiddenBg #16191B`) — the two were too close.
- **Title bar darkened** to read as part of the dark theme (owner: "app title too light"): status colours `proOnline/proOffline/freeOnline/freeOffline` all deepened.
- **Hide action colour** lightened to a visible slate (`hideAction #546E7A`) — the old dark tone "looked disabled".
- **Dark tooltips**: added `TooltipThemeData` (the default near-white was too bright).
- **Checklist items title bar** now has the **drawer/menu button** (theme.md §6.2) so Show Hidden Items is reachable.
- **CheckPageViewer (item detail)**: fixed inverted hidden/completed snackbar wording; replaced the redundant "Details" button with **Edit** — Edit turns the same title/description fields editable in place with **Save/Cancel** (paging locked while editing), persisting via `updateItem`.
- **Build lesson**: `flutter build`/install must pass `--dart-define-from-file=dart-defines.json` — without it the APK crashes on the "Missing Supabase credentials" assertion (hangs on native splash). Updated CLAUDE.md's build step.

**Testing bypasses (RM1/RM2 — must remove before release, tracked in outstanding.md):** `kForceProForTesting` makes `isPro()` return true at runtime (never in unit tests — gated on `FLUTTER_TEST`); `kBypassOnboardingForTesting` skips onboarding. Lets on-device testing run as Pro without re-purchasing or re-onboarding.

`flutter analyze` clean · `flutter test` 532/532 · build (with dart-defines) + install OK.

---

## [2026-07-07] — UX1: theme foundation (tokens + default-dark + drawer toggle)

First step of the theme epic (see `theme.md` / outstanding.md UX1–UX6), additive so no screen regresses:
- **`SisuColors` tokens added:** three-layer greys with helpers — `getAppBackground` (scaffold `#0D0D0D` dark / `#E8E8E8` light), `getListSurface` (`#121212` / `#f5f5f5`), `getTileColor` (`#1e1e1e` / white); a `tileElevation(isDark)` `BoxShadow` helper (the "elegant separator"); and the full **item-state palette** (§6.5) `state*Bg/Desc/Title` for default-grey, in-stock/completed-**green**, shopping-**blue**, deleted/not-available-**red**, hidden-grey (dark-theme tuned; light variants deferred to UX4). Existing tokens untouched, so current screens are unaffected until migrated.
- **`theme.dart`:** default `ThemeMode` is now **dark**; `ThemeData` wired to the three-layer greys (scaffold = app background, `colorScheme.surface` = list surface, `cardColor` = tile).
- **Default-dark end to end:** `UserSettings.isDarkMode` domain default + the Drift `isDarkMode` column default flipped to `true`; startup restore fallback `?? true`.
- **Theme toggle moved to the main-screen drawer** (home `_buildEndDrawer` → new "Appearance" `SwitchListTile`), per the standard that the toggle lives only there. (The settings-screen toggle still works; it's not the canonical location.)
- Added `test/theme_test.dart` (defaults to dark; `restoreTheme(false)` → light).

`flutter analyze` clean · `flutter test` 532/532 · `flutter build apk --debug` succeeds. UX2–UX6 (screen migrations) remain.

---

## [2026-07-07] — Theme/GUI consistency standard + B2/B3 fixes

**New binding standard:** created `.ai_context/theme.md` — the authoritative theme & layout consistency spec for **every** screen in **every** module (Games included), set by the product owner after on-device testing surfaced widespread inconsistency (divergent layouts, non-uniform swipe actions, inconsistent title bars, missing drawer buttons, title overflows, screens ignoring the dark theme). Captures: dark-default/light-selectable themes (toggle only in the main-screen drawer), three-layer grey backgrounds + elegant tile separators, the Chef main-list reference layout, item-list anatomy, **colour-tells-state** tile colours (green in-stock/completed, blue shopping-basket, red deleted, etc.), the uniform swipe convention, and a swipeable/editable item-detail screen with a pinned action bar over a history list. Added a **mandatory CLAUDE.md rule** to read `theme.md` before any GUI colour/layout change, and routed it at the top of INDEX.md's Read-Next table. Tracked the (large, incremental) implementation as epic **UX1–UX6** in outstanding.md.

**Bugs fixed (from the 2026-07-06 on-device pass):**
- **B2** — My Bar ingredient tile was a bespoke `Card`-wrapped `Slidable`, giving it a different look and swipe feel from the rest of the app. Removed the `Card` wrapper so it's structurally identical to the My Pantry tile (bare `Slidable`: swipe right = Shopping + toggle stock, swipe left = Delete for custom items). `lib/ui/cocktails/cocktails_screen.dart`.
- **B3** — Captain's Log had no way to add entries (read-only). Added a Pro-gated FAB → new `_AddEditLogDialog` (date, notes, weather, wind kt/dir, lat/lng, comma-separated crew) persisting via `CaptainLogRepository.addLog`, plus Edit/Delete actions on the detail dialog. `lib/ui/logbook/logbook_screen.dart`.

**B1 folded into the theme epic** (outstanding.md): the Maintenance and Safety item screens are code-identical (both show the trailing checkbox), so the reported divergence is part of the broader inconsistency — it resolves under UX4 (colour-tells-state, no status icons on tiles), not as a one-off.

**Note (owner Q):** Drift's reactive `.watch()` streams already propagate state changes across screens automatically — screens built on the `StreamProvider`s update when any other screen writes; no manual cross-list notification needed.

`flutter analyze` clean · `flutter test` 530/530.

---

## [2026-07-06] — On-device verification + T7 doc/comment Isar purge

S1 migration verified on-device (Samsung SM-S928U1): fresh-install boot + seed, seeded data rendering, reactive reads, insert/update/delete, and factory reset all confirmed working with the Drift DB; no crashes/DB errors in logcat.

Then completed **T7** (was tracked in outstanding.md; now removed per its Rule 1): swept the transitional "migrated off Isar (S1)" annotations out of `lib/**` code comments and the current-state `.ai_context/` docs (`INDEX.md`, `risks.md`, `caching.md`, `data_models.md`, `screens.md`), `CLAUDE.md`, and `plans/offline-conflict-resolution.md`, so they read as if Drift were always the store. Consolidated all of `risks.md`'s Isar content into a **single footnote** ("why the local DB is Drift, not Isar" — abandoned original, uncertain-maintenance fork, experimental `buildQuery()`, unreliable reactive streams; "do not reintroduce Isar"). `flutter analyze` clean, `flutter test` 530/530.

**Deliberately kept (historical records, not current-state docs):** this `changelog.md` and `plans/s1-drift-migration.md` still reference Isar — they *are* the dated record of the migration itself; scrubbing them would erase what happened. Flagged to the user; scrub on request.

Also logged three pre-existing UI bugs found during the same on-device pass (not migration regressions): **B1** Maintenance list has stray tick boxes, **B2** My Bar swipe UX is inverted/merged, **B3** Captain's Log has no add-entry affordance — see outstanding.md.

---

## [2026-07-06] — S1 Drift migration COMPLETE: Isar fully retired

The local database is now **100% Drift (SQLite)**; `isar_community` has been removed entirely. Final two steps on top of the 20 migrated collections:

**Sync infrastructure → Drift.** `SyncOutbox` moved to the Drift `SyncOutboxItems` table and `SyncService` was rewritten to read/write it (ordered by priority, retry with backoff, cleanup). `SyncService` no longer depends on `IsarService` — it reads `appDatabaseProvider` for the outbox and `userSettingsProvider` (Drift) in `_init()`. `pendingQueueSize` changed from a synchronous getter to `Future<int> pendingQueueSize()` (no external callers). `SyncInbox`/`ConflictLog` were unused (never read/written) but were migrated to reserved Drift tables `SyncInboxItems`/`ConflictLogs` to keep the local schema fully on Drift. NOTE: the Drift column for the outbox's table name is `targetTable` (not `tableName`, which is reserved on Drift's `Table` base class); the domain `SyncOutbox.tableName` field is unchanged.

**Isar retired.** `IsarService` → **`DatabaseService`** (`lib/services/database_service.dart`, Drift-backed; keeps `DbInitResult` + `init`/`factoryReset`/`hardReset`). `isarServiceProvider` → `databaseServiceProvider`. `factoryReset` wipes every Drift table then re-seeds; `hardReset` calls `AppDatabase.deleteAndRecreate()` (closes the connection, deletes `sisu_mate.sqlite`, reopens) — `AppDatabase.instance` is now a mutable singleton for this. All 4 UI factory-reset call sites + `startup_screen` updated. Every bundled seeder dropped its `Isar isar` parameter (and the `isar.writeTxn` wrapper in `bundled_data_seeder`); `seedBundledData()` takes no args. `models.dart` dropped `import isar_community` + `part 'models.g.dart'` (deleted — no annotations left); all domain models are plain classes. `pubspec.yaml` dropped `isar_community`, `isar_community_flutter_libs`, `isar_community_generator`. Test helper `isar_test_helper.dart` → `db_test_helper.dart`: `openTestIsarService` deleted, `testSyncService()` now takes no args (creates its own in-memory Drift DB + overrides `appDatabaseProvider`); all 9 sync-repo tests updated. `build_runner` now runs `drift_dev` only.

**Verification (final):** `flutter analyze` clean · `flutter test` **530/530** · `flutter build apk --debug` succeeds.

---

## [2026-07-06] — S1 Drift migration underway: Drift added + 20 collections migrated

Migrating isar_community→Drift incrementally (per `plans/s1-drift-migration.md`), collection by collection, keeping the build green throughout. Per the user (app is phone-only/not public, will uninstall + start fresh), **no Isar→Drift data migration** — each collection is de-registered from Isar as it moves (model loses `@collection`, `Id id` → `int id`, its `*Schema` leaves `IsarService.schemas`). Isar and Drift coexist until Isar is fully retired.

**Migrated (18):** GuestProfile, RecipeCollection, CrewMember, InventoryItem, FuelLogEntry, Document, MealPlan (embedded `MealPlanSlot` + `guestProfileIds` → JSON columns), Boat, CaptainLogEntry (`crewOnBoard`/`photos` → JSON), MaintenanceTask, ShoppingCategory, ShoppingItem, ChecklistGroup, ChecklistItem (`completionHistory` → JSON), Recipe (embedded `TastingRecord` `tastingLog` → JSON), RecipeIngredient, BarIngredient (`flavorProfiles`/`purchaseHistory` → JSON), PantryIngredient (`flavorProfiles`/`cuisineTypes`/`allergenTags`/`dietaryTags`/`purchaseHistory` → JSON), UserSettings (singleton `id`=1, single-row table `UserSettingsTable`; `recentEmails` → JSON), CommunityTemplate (local cache, write-only today — `browseCommunity` reads Supabase; `CommunityRepositoryImpl` dropped its Isar dependency, now `CommunityRepositoryImpl(db, [syncService])`). `TastingRecord` and `PurchaseRecord` lost `@embedded` and gained `toJson`/`fromJson`. Sync-participating repos keep queueing `toJson()` into the outbox. Each has an in-memory-Drift repo test (`AppDatabase.forTesting(NativeDatabase.memory())`). Repository interfaces unchanged → no UI callers touched. `List<String>`/`List<int>`/embedded lists become JSON text columns; `@DataClassName('XRow')` avoids clashing the Drift row class with the domain model.

**Couplings handled as they surfaced:**
- `SyncService._handleIncomingChanges` wrote inbound records straight into Isar collections. The `boats`/`captain_logs`/`maintenance_tasks`/`shopping_categories`/`shopping_items` cases (now Drift) were removed with a note — inbound sync is dormant pre-release (placeholder backend) and outbound (`queueOutgoingChange`, table-name based) still works; these get re-wired through Drift when the sync layer itself migrates.
- `IsarService.init()` and `bundled_data_seeder`'s dedup guard both used a checklist-group count as the seed sentinel; now that ChecklistGroup is on Drift, the sentinel reads Drift's `checklistGroups`. `bundled_data_seeder` seeds the default "My Boat" into Drift (`insertOrIgnore`); `shopping_seeder` seeds the 12 default shopping categories into Drift (`insertOrIgnore`).
- The 15 bundled checklist seeders (`seed_*_checks.dart`, `seed_yanmar_*`, safety briefings, documents) still build domain `ChecklistGroup`/`ChecklistItem` objects; their two Isar write lines (`isar.checklistGroups.put` / `isar.checklistItems.putAll`) now call shared `seedChecklistGroupToDrift` / `seedChecklistItemsToDrift` helpers in `lib/data/seed/checklist_drift_seed.dart`. `CommunityRepositoryImpl.importTemplate` writes its imported checklist to Drift via the same helpers (its `CommunityTemplate` cache stays on Isar for now).
- Hardening (found via the faster Drift tests): `SyncService._init()` now guards `ref` after its `await`s via an `onDispose` flag — the fire-and-forget init could otherwise touch a disposed `Ref` if the scope tears down during startup.

The sync inbound switch (`_handleIncomingChanges`) is now empty — every real-time table has moved to Drift, so there is no Isar collection left to upsert inbound records into. The method is a documented no-op until the sync layer itself migrates to Drift; inbound sync is dormant pre-release, outbound still works for all tables.

Recipe/Bar/Pantry were migrated together because of their tight coupling: `RecipeRepositoryImpl.syncMissingIngredientCounts` reads bar+pantry stock, and each ingredient repo's `recipeNamesForIngredient` reads recipes+recipeIngredients. Migrating them in one step let `RecipeRepositoryImpl` drop its Isar dependency entirely (now `RecipeRepositoryImpl(db)`, `BarIngredientRepositoryImpl(db)`, `PantryIngredientRepositoryImpl(db)`). Seeders: `seed_recipes.dart` swaps its Isar writes for `recipe_drift_seed.dart` helpers (`purgeSeededRecipeIngredientsFromDrift` / `seedRecipesToDrift` / `seedRecipeIngredientsToDrift`); `seed_bar_ingredients.dart` + `seed_pantry_ingredients.dart` use `ingredient_drift_seed.dart` (`barIngredientCountInDrift` / `seedBarIngredientsToDrift` / `syncBarSubstitutesInDrift`, and pantry equivalents). These seeders run only on fresh install/factory-reset (guarded), so plain inserts into the empty Drift DB match old `putAll` behaviour.

UserSettings seeding moved from `IsarService._seedInitialUserSettings` (Isar `put`) to a Drift `insertOrIgnore` of the default `id`=1 row; `watchSettings` is now a reactive Drift `watchSingleOrNull()` (was a 1-second poller). The shared **test helper** `testSyncService` now also overrides `appDatabaseProvider` with an in-memory Drift DB — `SyncService._init()` reads `userSettingsProvider`, which now resolves through Drift, so without the override the fire-and-forget init hit the real on-device sqlite path and failed every sync-repo test.

**Verification at this checkpoint:** `flutter analyze` clean · `flutter test` 530/530.

**Still on Isar (remaining):** the **sync infrastructure** `SyncOutbox`/`SyncInbox`/`ConflictLog` (which `SyncService` itself is built on — the most delicate, do last). Then retire Isar + the `buildQuery()` helper.

**This is in progress — Isar still backs the collections above; the two coexist.** Below is the original increment-1 detail.

- De-risk gates (all passed): (1) `drift` + `drift_dev` **resolve** alongside `isar_community_generator` (feared analyzer conflict didn't materialize); (2) the pinned **Android build survives** `sqlite3_flutter_libs`; (3) `build_runner` runs **both** generators together and emits `app_database.g.dart` + `models.g.dart`.
- Files changed in project:
  - `pubspec.yaml` — added `drift ^2.20.0` + `sqlite3_flutter_libs ^0.5.24` (runtime) and `drift_dev ^2.20.0` (dev).
  - `lib/data/drift/app_database.dart` — new. `AppDatabase` (`@DriftDatabase`) with a `GuestProfiles` table. Singleton `AppDatabase.instance` (mirrors `IsarService()`) opening a `sisu_mate.sqlite` `NativeDatabase.createInBackground`; `AppDatabase.forTesting(NativeDatabase.memory())` for tests. Table uses `@DataClassName('GuestProfileRow')` to avoid clashing with the Isar-registered `GuestProfile` domain class; the two `List<String>` fields are JSON text columns.
  - `lib/data/repositories/guest_profile_repository_impl.dart` — rewritten to Drift: `watchProfiles` is a reactive Drift `.watch()` (sorted in Dart to preserve the case-insensitive order); add/update/delete via companions; rows mapped to/from the domain `GuestProfile`. The `GuestProfileRepository` **interface is unchanged**, so no caller changed.
  - `lib/data/drift/isar_to_drift_migration.dart` — new. `migrateIsarToDrift()` one-time copies Isar guest profiles into Drift, idempotent (skips if the Drift table already has rows / Isar is empty).
  - `lib/ui/startup/startup_screen.dart` — calls the migration once after `IsarService().init()` succeeds.
  - `lib/core/di.dart` — new `appDatabaseProvider`; `guestProfileRepositoryProvider` now injects `AppDatabase` instead of `IsarService`.
  - `test/repositories/guest_profile_repository_test.dart` — rewritten to run against `AppDatabase.forTesting(NativeDatabase.memory())` through the repo interface (confirmed `NativeDatabase.memory()` works under plain `flutter test` on the host — the Drift analogue of `Isar.initializeIsarCore(download: true)`).
- Context files updated: `INDEX.md` (Drift rows, GuestProfile now Drift-backed), `outstanding.md` (S1 increment 1 done), `plans/s1-drift-migration.md` (status).
- New risks introduced: two databases now open at runtime during the transition (Isar + Drift) — acceptable and planned. `GuestProfile` stays registered in `IsarService.schemas` so the one-time migration can read old data; remove it from Isar only once all users have migrated.
- Removed/deprecated: nothing (GuestProfile's Isar path is dormant, not deleted).
- Verification: `flutter analyze` zero issues; `flutter test` 522/522 (the 4 guest-profile tests now run on in-memory Drift); `flutter build apk --debug` clean. **Not yet run on-device** — the in-memory tests don't exercise `NativeDatabase.createInBackground` on Android or the live Isar→Drift startup copy; that's the next check.
- Next increments (per the plan): migrate the remaining leaf/non-synced collections (`MealPlan`, `RecipeCollection`, `Document`, `CrewMember`, `InventoryItem`, `FuelLogEntry`), then the sync-participating ones (keeping each model's `toJson()` for the sync outbox), then retire Isar + the `buildQuery()` helper. Fold in S2/T4 (freezed-like immutability comes free with Drift data classes).

---

## [2026-07-06] — IMP1 COMPLETE: Maintenance + Shopping wired (all 10 list modules)

Finished the bulk JSON import/export fan-out. Every importable list module now has it.

- Files changed in project:
  - `lib/ui/maintenance/maintenance_items_screen.dart` — added the `TitleTile` import/export icon using the **`checklist` kind** (option A, import into current group). **Self-heal discovery:** the Maintenance UI is built on `ChecklistGroup`/`ChecklistItem` (`maintenance_items_screen` watches `checklistItemsProvider(group)`), i.e. maintenance items *are* checklist items with `appType='maintenance'`. The `MaintenanceTask` Isar model is **not surfaced by the current UI** (orphaned). So the maintenance screen imports as checklist; the `maintenance` (MaintenanceTask) ImportService kind remains as dormant support for that registered-but-UI-less model.
  - `lib/domain/repositories/shopping_repository.dart` + `_impl.dart` — added `addCategory(ShoppingCategory)` (uniform CRUD; shopping had `addItem` but no way to create a category). `put` + sync `shopping_categories`.
  - `lib/services/import_service.dart` — added the `shopping` kind (**8 kinds** total). Shopping is category-nested: `ImportedShoppingItem` carries the parsed `ShoppingItem` + its target `category` name; the screen match-or-creates the category (option B). **The `category` name is also written to the item's `origin` field** — the shopping screen's *visible* top-level grouping is `origin` (it iterates categories only to find items, then groups them by `origin`); routing the group only to `categorySupabaseId` made every import pile under "Spares" (caught in live testing, fixed). Export uses `origin`. + sample.
  - `lib/ui/shopping/shopping_screen.dart` — `TitleTile` import/export icon. `_importShopping` match-or-creates categories by name (case-insensitive, deduped within the batch, defaults to "Imported") so the item's category exists in the iterated list; `_exportShopping` gathers every category's items.
  - `test/import_service_test.dart` — +2 shopping tests. 29 import tests total.
- Context files updated: `INDEX.md` (maintenance rows self-healed to note it uses ChecklistItem; import_export wired list → all 10; ImportService 8 kinds), `outstanding.md` (**IMP1 removed** per Rule 1 — done).
- New risks introduced: none. `addCategory` mirrors the standard `put`+sync.
- Removed/deprecated: nothing (IMP1's earlier CsvExportService removal already recorded).
- Verification: `flutter analyze` zero issues; `flutter test` 527/527 (import tests now 29 incl. the shopping origin assertion); `flutter build apk --debug` clean. **Live-verified on device**: Fuel (full import happy path + error-reason + all-or-nothing + Pro gate + export-to-Downloads) and **Shopping** (imported a 3-item file with two categories → confirmed **Deck Gear** with 2 items + **Engine** with 1 item appear as separate groups — this is what caught the origin-vs-category bug above). Other modules use the identical shared component + unit-tested kinds.
- IMP1 status: **complete** across Fuel, Inventory, Crew, Documents, Chef, Cocktails, Checklists, Safety, Maintenance, Shopping. Two optional future enhancements noted (not blocking): (1) an on-screen worked-example view in the sheet (today the example is delivered via "Export sample template"); (2) upsert/dedupe on re-import (today re-importing a file adds duplicates). Tracked as low item IMP2.

---

## [2026-07-05] — IMP1: Checklists + Safety (JSON, option A) + uniform CRUD + CsvExportService removed + S1 plan

- Files changed in project:
  - `lib/domain/repositories/checklist_repository.dart` + `_impl.dart` — added `addItem(ChecklistItem)` for a uniform `add*/update*/delete*` surface (checklist only had `updateItem`). Implemented as `addItem => updateItem` since Isar `put` is an upsert (add==update everywhere — see the S1 plan). This is the "uniform CRUD" the user asked for as S1/Drift groundwork.
  - `lib/services/import_service.dart` — added the `checklist` kind (7 total). `_parseChecklist` requires `title` (defaults `name` to it), reads `description`/`notes`/`sortOrder`; `groupSupabaseId` is left empty and set by the importing screen (option A). + export + sample.
  - `lib/ui/checklists/checklist_items_screen.dart`, `lib/ui/safety/safety_briefing_screen.dart` — added the `TitleTile` import/export icon (both are per-group screens sharing ChecklistGroup/ChecklistItem). Import sets each item's `groupSupabaseId` to the current group (option A — a multi-item file lands in the open checklist/briefing). **Removed the "Export to CSV" menu item + `_handleCsvExport`** from checklist_items_screen (replaced by JSON export).
  - `lib/services/csv_export_service.dart` — **deleted** (its only user was the checklist CSV export, now JSON). `pubspec.yaml` — removed the now-unused `csv` dependency.
  - `plans/s1-drift-migration.md` — new: up-front plan for the S1 isar_community→Drift migration (why, incremental order, landmines, how uniform CRUD + the model `fromJson`/`toJson` de-risk it, bundling with S2/T4).
  - `test/import_service_test.dart` — +2 checklist tests (title required + name default + empty group; missing-title rejection). 27 import tests total.
- Context files updated: `INDEX.md` (removed the deleted CsvExportService row, updated import_export wired list, noted csv dep removed), `outstanding.md` (IMP1 progress; S1 now references the plan doc).
- New risks introduced: none. `addItem` is behaviourally identical to the existing `updateItem` (same `put`+sync).
- Removed/deprecated: `CsvExportService` + the `csv` package + the Checklist "Export to CSV" UI (replaced by the uniform JSON export).
- Verification: `flutter analyze` zero issues; `flutter test` 520/520 (+2); `flutter build apk --debug` clean. Not separately live-driven (Fuel was the end-to-end live proof; Checklists/Safety use the identical component + option-A group assignment).
- Remaining IMP1 (last two, both need a bit more than copy-paste): **Shopping** (`ShoppingItem` is category-nested; the shopping screen shows all categories, so import needs a target-category — add an `addCategory` repo method + a `category` name field that match-or-creates); **Maintenance** (`maintenance` kind exists and is flat, but confirm how `maintenance_items_screen`'s per-group view relates to the group-less `MaintenanceTask` model before wiring).

---

## [2026-07-05] — IMP1 fan-out: Crew, Documents, Chef, Cocktails wired; ImportService → 6 kinds

After the Fuel + Inventory first cut was live-verified end-to-end (see below), extended the shared import/export to more modules.

- Files changed in project:
  - `lib/services/import_service.dart` — added kinds `crew`, `document`, `maintenance` (parsers, exports, samples, `ImportBatch` lists). `ImportService` now covers 6 kinds: `fuelLog`, `inventory`, `recipe`, `crew`, `document`, `maintenance`. Import ignores unknown/extra fields (only required fields are enforced) — an LLM adding e.g. `"station"` to a fuel row is harmless.
  - `lib/ui/components/import_export.dart` — `exportCurrent` is now `Future<String> Function()` (async) so modules with related rows (recipe → ingredients) can gather them; capture the messenger before the async gap.
  - `lib/ui/crew/crew_screen.dart`, `lib/ui/documents/documents_screen.dart` — folded the `Icons.import_export` action into each `TitleTile` `actionsBuilder` (alongside the existing multi-select share icon).
  - `lib/ui/chef/chef_screen.dart`, `lib/ui/cocktails/cocktails_screen.dart` — import/export action on the recipe tab (tab 0 only). Export gathers each recipe's ingredients via `RecipeRepository.getIngredientsOnce`; import forces `recipeType` to the screen (`menu` on Chef, `cocktail` on Cocktails) so a generic recipe file lands where the user is, then `syncMissingIngredientCounts()`.
  - `lib/ui/fuel/`, `lib/ui/inventory/` — updated their `exportCurrent` to the new async signature.
  - `test/import_service_test.dart` — +6 tests (extra-fields-ignored; crew/document/maintenance mapping + required-field rejection). 24 import tests total.
- Context files updated: `INDEX.md`, `outstanding.md` (IMP1 progress).
- New risks introduced: none.
- Live verification (Fuel & Water, physical Samsung SM-S928U1, Pro): drove the full flow — header ⇅ sheet (Import locked on Free / open on Pro; Export + Template open to all); **Export sample template** → system Downloads save dialog (`file_picker`) → confirmed `sisu_fuel_template.json` written with the correct JSON envelope; **Import from file** (Pro) → OS document picker → picked the template → "Import 2 Fuel & Water item(s)?" → imported → 40 L Fuel + 200 L Water landed with cost $80.00 and notes "Marina top-up" (full round-trip incl. notes); **error path** → picked a file whose 2nd item had `type:"Petrol"` → "Couldn't import — Item 2: type must be Fuel or Water", **nothing imported** (all-or-nothing confirmed); **Pro gate** → Import on Free showed the Pro dialog. Zero exceptions. Crew + Documents use the identical wired component (not separately live-driven this pass); the ImportService kinds are unit-tested.
- Remaining fan-out (group-scoped, option A confirmed = import into the current group): **Checklists + Safety** (share the ChecklistGroup/ChecklistItem infra; `ChecklistItem` has `groupSupabaseId` + `sortOrder` — import sets both from `widget.group`; **note: the checklist repo has no `addItem` — need to confirm how items are created (likely `updateItem`/put) before wiring**), **Shopping** (`ShoppingItem` is category-nested — pick a target category), **Maintenance** (`maintenance` kind exists; but `MaintenanceTask` has no group field yet the items screen is per-group — confirm how tasks scope to a group). Checklist swap to JSON export + delete of `CsvExportService` (its only user is the Checklist "Export to CSV") happens with that group. `flutter analyze` clean; `flutter test` 518/518; `flutter build apk --debug` clean. Chef/Cocktails wired but not separately live-driven; the ImportService kinds are unit-tested and Fuel was live-verified end-to-end.

---

## [2026-07-05] — IMP1 first cut: shared JSON bulk import/export (Fuel + Inventory)

Started IMP1 (cross-module bulk import/export). Design locked with the user: **JSON**, one envelope for the whole app; import is **all-or-nothing with a user-facing error reason**; file selection via an OS **file picker** (Downloads → pick), export via a save dialog; export doubles as the LLM template. First cut wires **Fuel & Water** and **Inventory**; Recipe/Chef (nested) and the rest are the fan-out.

- Files changed in project:
  - `lib/services/import_service.dart` — new. Pure `ImportService`: `parse()` validates the envelope + every item (all-or-nothing) and throws `ImportException` (user-facing message + optional 0-based `itemIndex`); returns an `ImportBatch` of mapped domain objects (import mints internal ids, never trusts them from the file). `exportFuelLogs/exportInventory/exportRecipes` + `sampleFor(kind)` produce files/templates. Kinds: `fuelLog`, `inventory`, `recipe`.
  - `lib/ui/components/import_export.dart` — new. `ModuleImportExport` config + `showImportExportSheet()`: a reusable bottom sheet (Import from file / Export to file / Export sample template). Import is Pro-gated (writes data); export + template are open. Uses `file_picker` (`pickFiles` with `withData` for import, `saveFile` with bytes for export). On import: pick → `ImportService.parse` (catch → error dialog with the reason) → confirm → persist via the module's repo → "Imported N".
  - `lib/ui/fuel/fuel_screen.dart`, `lib/ui/inventory/inventory_screen.dart` — added an `Icons.import_export` action in the `TitleTile` header opening the sheet with that module's config (Inventory folds it in beside the existing multi-select share icon; always shown so you can import into an empty list).
  - `pubspec.yaml` — added `file_picker: ^8.1.4` (we only had `image_picker`, photos-only). Confirmed the pinned Android build survives it.
  - `test/import_service_test.dart` — new: 17 tests (envelope validation; fuel/inventory/recipe mapping; all-or-nothing with index+reason; sample templates + export round-trip back through `parse`).
- Context files updated: `INDEX.md` (new `import_service.dart` + `import_export.dart` rows; self-healed the `CsvExportService` note — see below).
- New risks introduced: a new native plugin (`file_picker`) on a pinned Android toolchain — verified `flutter build apk --debug` clean with it. `ImportService.parse` mints new `supabaseId`s on import, so re-importing the same file creates duplicates (no upsert/dedupe yet — acceptable for the first cut; note for the fan-out).
- Removed/deprecated: nothing yet. **Correction to prior context:** `CsvExportService` was documented as "not wired to any UI" — it is actually the Checklist screen's live "Export to CSV" (`_handleCsvExport`). Per user direction it will be **replaced by the shared JSON export and then removed** during the fan-out (Checklist gets JSON export). Self-healed the INDEX note. Separately, the `csv:` pubspec dep looks unused (nothing imports `package:csv`).
- Verification: `flutter analyze` zero issues; `flutter test` 512/512 (495 + 17 new); `flutter build apk --debug` clean (twice — once right after adding `file_picker` to isolate build risk, once after wiring the UI). Not yet exercised on-device — handed to the user to live-test Fuel + Inventory import/export. Remaining: wire Recipe/Chef (nested), swap Checklist CSV→JSON + delete `CsvExportService`, then fan out to Shopping/Crew/Documents/Cocktails/Maintenance for "same import/export throughout".

---

## [2026-07-05] — Implement LAN content sharing (F14 — ShareLanService)

Implemented the `ShareLanService` stub so recipes and crew lists can be shared device-to-device over the LAN, following the `GameLanService` pattern. (Built by a background subagent; verified and documented here by the main session.)

- Files changed in project:
  - `lib/services/lan/share_lan_service.dart` — implemented the stub: `ShareLanService` + `SharePayload` + `ShareKind`. Sits on the shared `LanEngine` using a distinct `'share'` channel, mirroring `GameLanService`'s init → host/join → dispatch → dispose shape. Session-less one-shot **pull** model: a host calls `hostShare(shareName:, payload:)` to broadcast over mDNS and hold one `SharePayload`; a client runs `scanForShares()` → `joinShare(service:)`, sends a `request`, and the host replies with a `content` message; clients receive the decoded payload on the `incomingContent` stream (hosts see pullers on `recipients`). `discoveredShares` mirrors the engine's resolved services; `endSession()` tears down. Callers build a payload with `SharePayload.recipe(recipe, ingredients)` or `SharePayload.crew(members)` and persist received domain objects through the normal repositories — the service never touches Isar/Supabase.
  - `lib/services/lan/lan_providers.dart` — refreshed the stale "stub" comment on the already-wired `shareLanServiceProvider` (no structural change).
  - `lib/models/recipe.dart`, `lib/models/recipe_ingredient.dart`, `lib/models/tasting_record.dart` — added `toJson`/`fromJson` (these three lacked them; `CrewMember` already had them). Plain methods, not Isar fields → no schema change / no `build_runner` run. Each required re-declaring the implicit default constructor (e.g. `Recipe();`).
  - `test/share_lan_service_test.dart` — new: 4 tests (recipe + crew round-trip serialization; no-socket `isHost`/broadcast-stream checks), following `test/lan_reconnect_test.dart`.
- Context files updated: `INDEX.md` (share_lan_service.dart described as implemented; folder-structure note updated), `outstanding.md` (F14 removed; the Games — Remaining Polish section is now empty and removed per Rule 1).
- New risks introduced: none. No new packages; reuses `LanEngine`/`LanMessage`. `toJson`/`fromJson` were added to 3 models following the existing hand-written convention (relevant to the future S2 freezed migration and the IMP1 bulk-import item, which both build on model serialization).
- Removed/deprecated: the ShareLanService stub.
- Deviations from the GameLanService pattern: (1) added serialization to 3 models that lacked it rather than inventing service-local serialization; (2) no lobby/handshake/state loop — sharing is a one-shot `request`/`content` pull, not a persistent authoritative session, matching the stub's own doc-comment intent; (3) no UI added (optional; a service + provider + tests were prioritised — a future task can add a share entry point on the Chef/Crew screens).
- Verification: `flutter analyze` zero issues; `flutter test` 495/495 (491 + 4 new); `flutter build apk --debug` clean. Verified by the main session against the merged tree (F22/USD + F14 together): analyze clean, 495/495. Not exercised on a live two-device socket (needs a second device); the socket-independent paths are covered by the new tests.

---

## [2026-07-05] — Build out Fuel & Water Log (F22) + USD cost display

Replaced the last "Coming Soon" stub with a full Fuel & Water Log, then (follow-up on user request) surfaced all monetary values in USD.

- Files changed in project:
  - `lib/models/fuel_log_entry.dart` — the model already existed but (a) had **no** `toJson`/`fromJson` (the repo pattern needs `toJson`) and (b) had no fuel/water distinction. Added a `type` field (`'Fuel'`/`'Water'`, default `'Fuel'`) plus `fromJson`/`toJson`. Regenerated Isar (`models.g.dart`) for the new field.
  - `lib/domain/repositories/fuel_log_repository.dart` + `lib/data/repositories/fuel_log_repository_impl.dart` — `FuelLogRepository` watch/add/update/delete (mirrors `CaptainLogRepository`); sorts by `date` desc; sync table `fuel_logs`.
  - `lib/core/di.dart` — added `fuelLogRepositoryProvider` (+ imports).
  - `lib/ui/fuel/fuel_screen.dart` — replaced the 54-line stub with a real screen: `fuelLogEntriesProvider`, a running-totals summary strip (Fuel L / Water L / Spend), a list (fuel-pump vs water-drop icon, date, cost line), detail dialog, public `AddEditFuelEntryDialog` (type dropdown, date picker, volume, price/litre — `totalCost` computed as `liters × pricePerLiter` on save, notes). Pro-gated add/edit/delete, Free read-only.
  - USD display: added `_formatUsd()` (`$` + 2dp); applied to the summary "Spend (USD)", the list "Cost: $…", and the detail "Price/L: $…" / "Total cost: $…"; the add/edit price field label is now "Price per litre (USD)". Currency is hardcoded USD per user request (the app has no currency setting).
  - `test/repositories/fuel_log_repository_test.dart` — new: full CRUD (incl. the fuel→water `type` change) against a real temp-dir Isar via the shared harness (+4 tests).
- Context files updated: `INDEX.md` (fuel screen row STUB→real, `FuelLogEntry` gains `type`, new repository + provider rows), `outstanding.md` (F22 removed; Stub Modules section now empty and removed per Rule 1).
- New risks introduced: none. Follows the repository→provider→ConsumerWidget + Pro-gate conventions. New sync table `fuel_logs` queues into `SyncOutbox` like every other table (no Supabase-side table yet — harmless, same status as `documents`/`crew_members`/`inventory_items`).
- Removed/deprecated: the "Fuel & Water Log - Coming Soon" stub. This was the **last** stub module.
- Verification: `flutter analyze` zero issues; `dart run build_runner build` clean; `flutter test` 491/491 (487 + 4 new); `flutter build apk --debug` clean. Live-verified on the physical Samsung SM-S928U1 with Pro: added a Fuel entry (40 L) and a Water entry (200 L @ $0.50 → cost $100.00); summary strip correctly showed **40 L Fuel · 200 L Water · $100.00 Spend (USD)**; the two types render with distinct icons and sort by date; opened the detail dialog (Date/Volume/Price/L/Total cost, with USD `$`), edited a fuel entry to add $2.00/L (cost recomputed to $80.00, list + summary updated live), and deleted entries (summary recomputed to $0.00). Zero exceptions from `com.sailingsisu.sisumate` in logcat. Note: RevenueCat test-store Pro dropped again on APK reinstall and the user re-enabled it (RevenueCat is the sole source of truth). Also self-healed a stale `IsarService._schemas` reference in `CLAUDE.md` (the field was renamed to public `schemas` earlier).

---

## [2026-07-05] — Cleaned up outstanding.md (removed resolved items + relocated Build Verification)

Housekeeping on `.ai_context/outstanding.md` per user request: (1) removed every resolved/struck-through "done" row so the file only contains open work, and strengthened the file's rules to enforce this going forward; (2) relocated the running "Build Verification" section (current analyze/test/build status + the full live-device verification history) out of outstanding.md and into the changelog — its content is preserved verbatim below. No open items were lost; the removed rows were all already-completed work whose resolution was already recorded in earlier changelog entries.

- Files changed in project: none (context-file housekeeping only).
- Context files updated: `outstanding.md` (removed all `~~done~~` rows: F15/F16/F17, F6/F7/F8, SH1–SH5, BC11, CF15/CF13/CF16/CF23/CF12/CF11, F20/F21; removed the now-empty "Shopping List — Email & Share", "Bar (Cocktails) — Features", "Chef (Food) — Features", and parent "Bar & Chef App — Planned Features" sections; removed the "Build Verification" section; added two enforcement rules to the header).
- New rules added to outstanding.md: **Rule 1** — resolved items are deleted entirely (never left struck-through); **Rule 2** — build/test/live-verification status lives in changelog.md, not outstanding.md.

### Relocated "Build Verification" content (was the tail of outstanding.md)

`flutter analyze` — zero issues as of 2026-07-05 (post record-share feature).
`flutter test` — 487/487 pass as of 2026-07-05 (up from 482; +5 new tests in `test/record_share_service_test.dart` — PDF builders for the Documents/Crew/Inventory share feature). Earlier: 482 (up from 474; +8 new tests in `test/repositories/` — full CRUD for the two new F16/F17 repositories: CrewMember, InventoryItem — bringing the non-network repository count to 15). Earlier: +55 new tests in `test/repositories/` — full Create/Read/Update/Delete coverage for the 13 pre-existing non-network repositories: Document, CaptainLog, Boat, Maintenance, Collection, GuestProfile, MealPlan, UserSettings, Shopping, Checklist, Recipe (+ RecipeIngredient), BarIngredient, PantryIngredient. `CommunityRepository` deliberately excluded — it's Supabase-network-only, not a fit for the local-Isar CRUD harness). See `test/test_helpers/isar_test_helper.dart` for the shared harness (`Isar.initializeIsarCore(download: true)` + a fresh temp-dir Isar instance per test, assigned onto the app's real `IsarService` singleton).
`flutter build apk --debug` — clean build as of 2026-07-03. AGP 8.9.1, NDK 28.2.13676358, purchases packages pinned to 9.10.x (9.11–9.16 broken with Kotlin 2.1).
**Note**: `flutter build apk --debug` / `flutter run` without `--dart-define-from-file=dart-defines.json` compiles cleanly (satisfies the "zero errors" bar) but the installed APK crashes immediately on launch — `main.dart` asserts on `SUPABASE_URL`/`SUPABASE_ANON_KEY` being non-empty. Always add the flag when actually installing/running the app on a device or emulator, not just when compile-checking.
**Live verification history** (physical Samsung SM-S928U1, Android 16, via adb):

- 2026-07-05 (Documents/Crew/Inventory share): live-verified the new multi-select PDF share on the physical Samsung SM-S928U1 with Pro. **Documents:** tapped the header select icon (visible only on Pro — confirmed absent on Free earlier this session), checked the "boat/Registration" doc (which has an attached photo), tapped Share → Android's native share sheet opened showing `boat_documents.pdf` with WhatsApp/Gmail/Messages/Quick Share (Save to Downloads) as targets. Pulled the generated file from `/data/data/com.sailingsisu.sisumate/cache/share/boat_documents.pdf` and opened it: renders "Boat Documents" heading + the doc title + "Type: Registration" + notes + the **embedded photo scan** — exactly the "hand registration + insurance to authorities" deliverable. **Inventory:** added "Life Raft" (Cockpit locker), selected + shared → `inventory.pdf` rendered "Inventory / Life Raft / Quantity: 1 / Location: Cockpit locker" (test item deleted afterwards; list back to empty and the share icon correctly disappeared, confirming the `isPro && list.isNotEmpty` gate). Crew shares via the identical code path (unit-tested). Note: the device lost its RevenueCat test-store Pro entitlement on APK reinstall (RevenueCat is the sole source of truth — no local override) and the user re-enabled Pro to complete this pass. Zero exceptions from `com.sailingsisu.sisumate` in logcat throughout.
- 2026-07-05 (F16/F17): full live CRUD pass on both new modules with an active Pro entitlement (device already showed "No Boat • Pro • Online"). **Crew:** empty state ("No crew members yet") → FAB opens `AddEditCrewMemberDialog` (all fields render, no overflow) → Role dropdown confirmed to list all 6 options (Captain/First Mate/Engineer/Cook/Crew/Guest) → added "Skipper Ada" / Captain / +358401234567 (phone field correctly shows a numeric keypad) → "Skipper Ada saved" snackbar + immediate list refresh (live StreamProvider against real Isar) → detail dialog (Role/Phone rows, Delete/Edit/Close since Pro) → Edit pre-filled correctly (Captain highlighted), changed role to First Mate, saved, list updated live → Delete reverted to empty state. **Inventory:** empty state ("No inventory items yet") → added "Fenders" / Lazarette / qty 14 / unit pcs → "Fenders saved" + list row "Qty: 14 pcs" (integer formatting confirmed — 14.0 renders as "14", not "14.0") → detail dialog (Quantity/Location rows only; null serial/notes rows correctly omitted) → Delete reverted to empty state. Exercises the real add/update/delete round-trip through `CrewMemberRepositoryImpl` / `InventoryItemRepositoryImpl` against the device's Isar instance. Zero exceptions from `com.sailingsisu.sisumate` in logcat across the whole session (one `FlexPanelStartController` NPE seen belongs to a Samsung system process, not the app). One non-bug UX note: tapping the pre-filled Quantity field lands the cursor at the end rather than selecting-all, so typing a digit appends (got "14" when "4" was intended) — standard Flutter `TextFormField` behaviour, not a defect.
- 2026-07-03 (CF1/CF24): created a meal plan, assigned a recipe, generated a provision list, copied it to clipboard. Caught and fixed 2 layout bugs only visible at runtime: `_RecipeCard` (chef_screen.dart) overflowed by ~40px with CF4's dietary badges + allergen row — fixed by lowering the Chef grid's `childAspectRatio` from 0.65 to 0.56; `_MealSlotRow`'s meal-type label wrapped ("Breakfast" → "Breakfa/st") at `width: 64` — widened to 76.
- 2026-07-03 (CF25/CF26): verified flexible start date + trip length (Monday now shows Snack/Lunch/Dinner, last day shows Breakfast only), and provision-list grouping of a recipe assigned to 2 slots ("2 × 24 fillets" instead of two separate lines). Caught and fixed 2 more runtime-only bugs: (1) a `MealPlan` saved before `numberOfDays` existed deserialized it as `0` (Isar fills missing int fields with 0, not the Dart-declared default) — end date showed "Jun 28" for a "Jun 29" start and "2/0 slots planned"; fixed with an in-memory normalize-to-7 in `MealPlanRepositoryImpl.watchPlans()`. (2) A slot from before CF25 existed (`dayOffset=0, mealType='breakfast'`) was invisible in the grid (Monday no longer offers breakfast) but still silently counted by `ProvisionCalculator`, inflating a 2-occurrence dish to 3×; fixed by filtering orphaned slots (invalid day/meal-type combo for the plan's current shape) in both the repository and the calculator.
- 2026-07-03 (CF13/CF16/CF23): verified calorie display on a recipe detail screen (Fresh Ginger 4oz contributing to "~91 kcal for 1 serving (1/8 ingredients)", correctly wrapped), created a collection ("Boat Party Menu"), added a recipe to it via the recipe picker, navigated from the collection into the recipe detail, and removed the recipe via the X button (reverted to "No recipes yet" empty state). Caught and fixed 3 runtime-only bugs, one of them pre-existing and unrelated to this session's own changes: (1) **the entire Chef screen end drawer was unreachable** — `chef_screen.dart` was missing the `Builder(builder: (context) => ...)` wrapper that every other screen in the app already has around its `Scaffold` body, so `Scaffold.of(context).openEndDrawer()` was called with a context that is an ancestor, not a descendant, of the `Scaffold` — it silently failed to find it (tap registered fine at OS level, no exception, drawer just never opened); fixed by adding the wrapper, confirmed via live device test that Account/Data Management/Sync/Factory Reset/Pro/About/Collections are all now reachable again. (2) Chef grid card overflow on "American Steakhouse Classic" (2-line title + 2 dietary badges + allergen row) — `childAspectRatio` lowered from 0.56 to 0.48. (3) Calorie/cost estimate `Text` rows overflowed horizontally once real macro data populated — wrapped both in `Expanded`. Also discovered (not a bug, an architectural limitation): `seedPantryIngredients()`'s one-time seed guard means CF13's new macro fields are `null` on any pantry seeded before this change — only a fresh install/factory reset backfills them.
- 2026-07-04 (SH1–SH5): verified swipe-to-email on a shopping item (revealed Complete/Stock/Email actions, opened "Send to" dialog, launched Gmail compose with correct subject/body), swipe-to-email on a section header (scoped correctly to just that origin's items), "Email All Lists" from the Shopping drawer (all origins as labelled blocks in one email), the recent-email chip appearing on a second send, the Settings screen's new "Email & Sharing" fields (rendered and persisted across navigation), and the Meal Planner provision list's new mail icon (correct subject falling back to plan name when no boat name is set, per the `boatName ?? plan.name` logic). Caught and fixed 3 runtime-only bugs: (1) **`mailto:` subject/body rendered literal `+` instead of spaces** — `Uri(queryParameters:)` form-encodes spaces as `+`, which Gmail (an RFC 6068 consumer) shows literally rather than decoding; fixed by hand-building the query string with `Uri.encodeComponent` per value instead of the `queryParameters:` constructor param. (2) **Nested `Slidable` gesture conflict** — wrapping the whole `ExpansionTile` (header + item children) in a `Slidable` for the section-level email action broke both it and every child item's own `Slidable`, since both compete for the same horizontal-drag gesture; fixed by scoping the outer `Slidable` to only the header `Row`. (3) **End-drawer overflow in both `home_screen.dart` and `shopping_screen.dart`** — adding a new drawer section pushed the fixed `Column`+`Spacer()`+`DrawerFooter()` layout past its available height (Settings became completely untappable in Home's drawer); fixed by wrapping the scrollable content in `Expanded(child: SingleChildScrollView(...))` above the pinned footer in both screens.
- 2026-07-04 (CF12/BC11): verified the new share/print icon on both `ChefRecipeDetailScreen` ("Mediterranean Seafood Feast") and `CocktailRecipeDetailScreen` ("Mai Tai") — tapping it opens the native Android print/share preview via `Printing.layoutPdf()`, rendering a one-page PDF recipe card with title, cuisine/description, prep/cook time, glassware (cocktails), ingredients, and instructions. Caught and fixed 1 runtime-only bug: **ingredient bullets rendered as tofu boxes (□)** — the `pdf` package's default core font (Helvetica) has no glyph for `•` (U+2022), logged as "Unable to find a font to draw '•' (U+2022)"; fixed by using a plain `-` prefix instead of `•`, confirmed correct rendering on rebuild for both screens. No other exceptions in logcat.
- 2026-07-04 (CF11): live-verified up to the feature's Pro gate — the Chef FAB's new "Add manually" / "Import from URL" bottom sheet is reachable, and tapping "Import from URL" on a Free-tier test device correctly shows the same "Sisu Mate Pro Required" dialog as the pre-existing manual-add flow (this device has no active Pro entitlement and there's no local override — RevenueCat is the sole source of truth, so the actual fetch-and-parse dialog could not be exercised on-device this session). The parsing engine itself (the real business logic: JSON-LD extraction incl. `@graph` traversal, `HowToStep`/`HowToSection` instruction flattening, ISO 8601 duration parsing, quantity/unit/name ingredient-line parsing, optional/garnish detection from wording, and all error paths) is covered by 6 passing unit tests in `test/recipe_import_service_test.dart` exercising `RecipeImportService.parseHtml()` directly against realistic sample HTML. Also discovered (not caused by this change, found while confirming how ingredients get persisted): `AddEditRecipeDialog._save()` never saves manually-entered ingredients — see F20 above and risks.md #16.
- 2026-07-04 (CF11, follow-up): unlocked Pro on-device via RevenueCat's debug-mode "Test Store Purchase" flow (a developer-intended test path, distinct from a real Play Store transaction) to exercise the actual fetch-and-parse dialog end-to-end against a real, stable public recipe URL (AllRecipes.com). Found and fixed a real parsing gap: `_knownUnits` only recognized abbreviated unit words (tsp, tbsp, oz, lb, ...), not spelled-out forms, so "2 teaspoons vanilla extract" parsed with `unit: null, name: "teaspoons vanilla extract"` instead of splitting out the unit. Fixed by expanding `_knownUnits` with spelled-out forms (teaspoon(s), tablespoon(s), ounce(s), pound(s), gram(s), kilogram(s), milliliter(s)/millilitre(s), liter(s)/litre(s)) and added a regression test. Re-ran the full analyze/build_runner/build/test cycle and reinstalled to confirm the fix on-device.
- 2026-07-04 (CF15): unlocked Pro the same way as the CF11 follow-up, then verified the Chef FAB's 3-option bottom sheet ("Add manually" / "Import from URL" / "Import from photo") and the Camera/Gallery picker under "Import from photo". Ran on-device OCR against a real photo (a "Easy spaghetti carbonara" screenshot added to the device gallery) — the source image turned out to be a webpage screenshot (phone status bar + intro prose above the actual recipe content, not a clean recipe-card photo), so the result was an honest exercise of the documented fallback path: first line ("11:01", the status bar clock) became the recipe name, no "Ingredients"/"Instructions" headings were found, so everything else was kept as freeform instructions with 0 ingredients — no crash, result editable via the pencil icon. Confirmed via `uiautomator dump` navigation and a follow-up screenshot of the recipe detail screen. Checked logcat immediately after: the only errors present (`SQLiteLog: POSIX Error 11 / SQLite Error 3850`) belonged to an unrelated process (`com.microsoft.appmanager`), not Sisu Mate — zero exceptions from `com.sailingsisu.sisumate` during the OCR run or subsequent navigation. The pure parsing core (heading detection, section-boundary logic, ingredient-line reuse from CF11, freeform-fallback, and the no-text-recognized error path) is covered by 5 passing unit tests in `test/recipe_ocr_service_test.dart`.
- 2026-07-04 (F20): fixed `AddEditRecipeDialog`'s dropped-ingredients bug (see risks.md #16, now resolved). Rebuilt and reinstalled the debug APK on the physical device after a user-initiated uninstall/reinstall (confirmed fresh state: "No Boat • Free", 3 bundled "Spares" items visible in Shopping — expected seed data, see `data_models.md` §Seeded Data). Since Pro doesn't survive a fresh install without re-running the RevenueCat test-purchase flow, the fix itself was verified via 3 new widget tests in `test/add_edit_recipe_dialog_test.dart` that drive the real dialog widget (not mocks): adding a new ingredient and saving includes it in `onSave`'s `ingredients` list with the correct `recipeSupabaseId`/`sortOrder`; removing a pre-existing ingredient reports it via the new `removedIngredients` param; an empty recipe name still blocks save (regression check on existing validation). While writing these tests, discovered the dialog's ingredients `ListView` renders in only an ~80px viewport (see F21/risks.md #17) — a real but low-severity usability rough edge, left as a separate low-priority item rather than expanding scope here.
- 2026-07-04 (shopping seed data): removed the 3 seeded "Filters" spares items (see changelog.md) after the user questioned why a genuinely fresh install had 3 pre-populated shopping items. Live-verified via a real `adb uninstall` + fresh install (not `install -r`): onboarding flow appeared (confirming the install was truly clean), and after skipping it the Shopping screen showed no "Spares" section at all. No exceptions in logcat.
- 2026-07-04 (F8): added tied-player re-roll visuals to Liar's Dice's `_DetermineStarterUI` (amber border + spinner + "Tied — re-rolling…" caption + a brief shake transform on the dice row, via new `GameState.rerollingPlayerIds`, set by `determineStarter()` whenever a tie is detected and cleared once a sole starter is found). Verified the state logic deterministically via 2 new unit tests in `test/liars_dice_test.dart` (identical dice on both players forces a guaranteed tie — not a probabilistic retry — confirming `rerollingPlayerIds` is set/cleared correctly). Live-played several full AI-vs-AI games on the physical device after rebuilding/reinstalling (including a 4-AI-player game that ran through rollDice → declareHand → challenge → resolution with no crashes); however, the exact tie-animation frame was not visually caught on-screen during this session — exact-rank ties are relatively rare per game and AI-vs-AI games resolve in well under a second per phase, making it hard to time a manual screenshot capture within the ~2s window. No exceptions in logcat across 8 separate game-start attempts specifically aimed at reproducing a tie, nor during the full games that did complete.
- 2026-07-04 (F21): fixed `AddEditRecipeDialog`'s ~80px ingredients-list viewport (see risks.md #17, now resolved) — grew the dialog to `height: 600`, wrapped its form in a `SingleChildScrollView`, and replaced the ingredients `Expanded` with a fixed `SizedBox(height: 220)`. Added a widget test confirming 2 pre-existing ingredients are both findable on first pump with no scroll call needed (previously only the first was ever built at all, per F21's original diagnosis). Rebuilt, reinstalled, and launched on the physical device: clean startup, no exceptions in logcat. Did not re-verify the dialog's full visual layout live on-device (would require re-unlocking Pro via the RevenueCat test-purchase flow again) — relied on the widget test plus a clean launch/logcat check, consistent with how F20 itself was verified.
- 2026-07-04 (F7): fixed the Liar's Dice AI's bid/accept logic to reason about hand-rank probability rather than only the AI's own dice in isolation. Rebuilt and reinstalled on the physical device, but the device was stuck on its lock screen this time (an environmental issue, unrelated to the change — swiping/waking repeatedly didn't get past it) so a live play-through wasn't completed. Verified instead via 5 new deterministic unit tests in `test/liars_dice_test.dart` covering: the AI now bids the smallest valid face for its own rank rather than always the maximum (a real, everyday-impact fix — previously every AI turn overbid to face 6 regardless of context); and the AI now challenges a declared rank that's inherently rare (e.g. Four of a Kind, true on <2% of honest rolls) even when its own hand doesn't directly rule it out (previously a flat 70/30 coin-flip in that band regardless of how implausible the specific claim was). Also discovered while investigating: the game's "escalate above the last bid" code path is effectively dead in normal play, since each round has exactly one bid before an immediate accept/challenge — see risks.md #18 (not a bug, just a documented architectural note). No exceptions in logcat despite the lock-screen issue.
- 2026-07-04 (F6): investigated the reported "silent" disconnect and found the actual gap was narrower and more specific than the original description assumed — a re-check of `game_lan_service.dart`/`lan_engine.dart` showed the HOST already handles a client disconnecting reasonably (removes them, shows a message, ends the game if too few remain); the completely unhandled case was the CLIENT losing its connection _to the host_ — `initClientMode()` never subscribed to `playerLeaves` at all, so nothing happened whatsoever (no message, no state change, screen just froze on the last-known state forever). Fixed by: `LanEngine.reconnectToLastHost()` (remembers the last-connected host address, retries the socket), `GameLanService.reconnect()` (retries + re-sends the join handshake under the same remembered player name), and `GameStateNotifier.initClientMode()` now listens for a `'host'` leave event, shows "Connection lost. Reconnecting…", retries 3× with a 2s gap, and either recovers ("Reconnected!") or cleanly ends the session with an explicit message instead of freezing silently. The physical Samsung SM-S928U1 briefly dropped off adb entirely (environmental — cable/USB debug timeout, not a regression) but came back after `adb kill-server`/`start-server`; rebuilt, reinstalled, woke/unlocked the device, and launched the app cleanly (Home screen renders normally, no exceptions in logcat). A full end-to-end reconnect test (an actual mid-game drop between a host and a joining client) would need a second physical device to host/join against, which wasn't available this session — covered instead by 3 new unit tests in `test/lan_reconnect_test.dart` for the parts that don't require a live socket (both `reconnectToLastHost()` and `reconnect()` correctly return `false`, not throw, when there's nothing to reconnect to).
- 2026-07-05 (F15): built out Documents Vault end to end — new `Document` Isar model, `DocumentRepository`/`DocumentRepositoryImpl` (mirroring `CaptainLogRepository`'s pattern), `documentRepositoryProvider`/`documentsProvider`, and a real `DocumentsScreen` (list with expiry-aware coloring, a public `AddEditDocumentDialog` for title/type/notes/expiry/photo, Pro-gated add/edit/delete, Free read-only) replacing the "Coming Soon" stub. While researching this, discovered `fuel_screen.dart` is _also_ an undocumented stub (same 54-line shell shape) despite `FuelLogEntry` already existing as a registered Isar model with no repository — added as new item F22 in the Stub Modules table (self-healed; this wasn't previously tracked). Live-verified on the physical Samsung SM-S928U1 after a genuine multi-attempt device wake/unlock struggle (the device kept re-locking mid-session; eventually resolved via `input keyevent 224` immediately followed by a swipe, confirmed via `dumpsys window | grep isKeyguardShowing`): the Documents tile now opens a real screen ("No documents yet" empty state, not "Documents App"), the FAB correctly shows the "Sisu Mate Pro Required" dialog on the Free tier, and the paywall screen renders normally.
- 2026-07-05 (F15, follow-up): user unlocked Pro on-device via RevenueCat's "Test valid Purchase" test-store flow (the earlier same-session attempt hadn't taken effect; this one did), enabling a full live CRUD pass: added a document ("Boat", type Registration via the dropdown — all 6 type options rendered correctly), confirmed the "Boat saved" snackbar and immediate list update (StreamProvider live-refresh confirmed working against real Isar), opened the detail dialog (Delete/Edit/Close visible since Pro), and deleted it — list correctly reverted to "No documents yet". This exercises the real add + delete path against the physical device's Isar instance (not just the widget tests' in-memory `onSave` capture), including a genuine round-trip through `DocumentRepositoryImpl.addDocument()`/`deleteDocument()`. No exceptions in logcat across the whole sequence. Edit itself wasn't separately clicked through live (delete uses the identical dialog/repository plumbing, and its pre-fill/save logic is already covered by the widget tests), but the add/list/delete cycle now has full live-device confirmation, closing the gap noted in the previous entry.

---

## [2026-07-05] — Backlog: added IMP1 (cross-module file-based bulk import with on-screen sample)

Documentation-only. Recorded a new outstanding feature request: an "Add & Import" action across every item-list module (Cocktails, Chef, Fuel & Water, Inventory, Documents, and the other lists), where the Import screen shows a worked example of the expected file and can export a blank sample template. Driving use case: hand a fuel slip (etc.) plus the exported sample to an AI, get back a ready-to-import file. Requires a **single** global file format.

- Files changed in project: none (backlog entry only).
- Context files updated: `outstanding.md` (new "Cross-Module — Bulk Import" section, item IMP1).
- Open design decision flagged for the user: **file format not yet chosen.** Recommendation in the entry is **JSON** (every model already has a hand-written `fromJson`; nested/relational entities like recipe→ingredients map cleanly; most reliable for an LLM to emit). Noted that a `CsvExportService` with CSV import already exists but is unwired — the "one format" requirement means CSV shouldn't also be surfaced if JSON is chosen.
- New risks introduced: none.
- Removed/deprecated: nothing.

---

## [2026-07-05] — Share selected records (Documents/Crew/Inventory) via PDF + OS share sheet

Added a multi-select "share" flow to the Documents, Crew, and Inventory screens so a chosen subset of records can be exported as a PDF and sent via the native Android share sheet (email, WhatsApp, Save to Downloads, Quick Share, …). Primary use case: authorities ask for boat registration + insurance → select those two documents → share one `boat_documents.pdf` with the scans embedded.

- Files changed in project:
  - `lib/services/record_share_service.dart` — new. `shareDocuments()/.shareCrew()/.shareInventory()` wrap `Printing.sharePdf(bytes:, filename:)` (same platform share path as `RecipeShareService`, no new dependency — `pdf`/`printing` already present). Pure `buildDocumentsPdf()/buildCrewPdf()/buildInventoryPdf()` return `Uint8List` for unit testing. Documents embed each attached photo via `pw.MemoryImage(File(localPath).readAsBytesSync())`, guarded by `existsSync()` so a missing/deleted scan is skipped rather than throwing. Uses `-`/plain text (pdf core font has no `•` glyph).
  - `lib/ui/documents/documents_screen.dart`, `lib/ui/crew/crew_screen.dart`, `lib/ui/inventory/inventory_screen.dart` — converted each from `ConsumerWidget` to `ConsumerStatefulWidget` and added selection mode: a Pro-only `Icons.ios_share` icon in the `TitleTile` header (via the existing `actionsBuilder`, shown only when `isPro && list.isNotEmpty`) toggles selection; title becomes "N selected"; rows swap their leading avatar for a `Checkbox` and tap toggles instead of opening detail; header shows share + close actions; FAB hidden while selecting. Share gathers the selected records by Isar `id`, calls the service, and exits selection (empty selection → snackbar).
  - `test/record_share_service_test.dart` — new. 5 tests: each builder produces valid `%PDF` bytes; a missing photo path is ignored without throwing; empty selection is handled.
- Context files updated: `INDEX.md` (new `record_share_service.dart` row; the three screen rows note the multi-select share + `ConsumerStatefulWidget`), `outstanding.md` (Build Verification 487/487; new Live verification history entry).
- New risks introduced: none. Share is a read/export path; it's Pro-gated to match these modules (add/edit/delete already Pro, Free is read-only and has no records to share anyway). No new dependency.
- Removed/deprecated: nothing.
- Verification: `flutter analyze` zero issues; `flutter test` 487/487 (482 + 5 new); `flutter build apk --debug` clean. Live-verified on the physical Samsung SM-S928U1 with Pro: Documents → select the "boat/Registration" doc (with a photo) → Share → native share sheet showed `boat_documents.pdf` with WhatsApp/Gmail/Messages/Quick Share; pulled the generated PDF from `cache/share/` and confirmed it renders "Boat Documents" + title + "Type: Registration" + notes + the **embedded photo scan**. Repeated for Inventory ("Life Raft") → `inventory.pdf` rendered "Inventory / Life Raft / Quantity: 1 / Location: Cockpit locker". Crew uses the identical code path (covered by the unit tests). Confirmed the Pro gate live: the share icon is absent on the Free tier and when the list is empty. Zero exceptions from `com.sailingsisu.sisumate` in logcat.

---

## [2026-07-05] — Build out Crew Management (F16) and Inventory (F17) modules

Replaced the two remaining "Coming Soon" stub screens with full end-to-end modules, both following the F15 (Documents Vault) pattern: model → part registration → Isar schema → domain interface → impl → di provider → ConsumerWidget screen → real-Isar CRUD tests.

- Files changed in project:
  - `lib/models/crew_member.dart` — new `CrewMember` Isar model (name, role, phone, email, iceContact, certifications, localPath photo; + standard supabaseId/boatSupabaseId/isSynced/lastModified) with `fromJson`/`toJson`
  - `lib/models/inventory_item.dart` — new `InventoryItem` Isar model (name, location, quantity (double), unit, serialNumber, notes, localPath photo; + standard fields) with `fromJson`/`toJson`
  - `lib/models/models.dart` — registered both as `part` files
  - `lib/models/models.g.dart` — regenerated (build_runner) to add `CrewMemberSchema` / `InventoryItemSchema` and the `.crewMembers` / `.inventoryItems` collection accessors
  - `lib/services/isar_service.dart` — registered `CrewMemberSchema` and `InventoryItemSchema` in `IsarService.schemas`
  - `lib/domain/repositories/crew_member_repository.dart` + `lib/data/repositories/crew_member_repository_impl.dart` — `CrewMemberRepository` watch/add/update/delete (mirrors `DocumentRepository`); sync table `crew_members`
  - `lib/domain/repositories/inventory_item_repository.dart` + `lib/data/repositories/inventory_item_repository_impl.dart` — `InventoryItemRepository` watch/add/update/delete; sync table `inventory_items`
  - `lib/core/di.dart` — added `crewMemberRepositoryProvider` and `inventoryItemRepositoryProvider` (+ imports)
  - `lib/ui/crew/crew_screen.dart` — replaced 54-line stub with a real screen: list (avatar/initial, role, phone), `crewMembersProvider`, detail dialog, public `AddEditCrewMemberDialog`, Pro-gated FAB + add/edit/delete, Free read-only (lock icon)
  - `lib/ui/inventory/inventory_screen.dart` — replaced 54-line stub with a real screen: list (icon/photo, quantity+unit, location), `inventoryItemsProvider`, detail dialog, public `AddEditInventoryItemDialog` (quantity/unit on one row), Pro-gated add/edit/delete, Free read-only
  - `test/repositories/crew_member_repository_test.dart`, `test/repositories/inventory_item_repository_test.dart` — new: full Create/Read/Update/Delete against a real temp-dir Isar instance via the shared harness (+8 tests)
- Context files updated: `INDEX.md` (crew/inventory rows rewritten from STUB to real, added model + repository rows for both), `outstanding.md` (F16/F17 struck out and moved out of the Stub Modules table; Build Verification updated to 482/482 and analyze zero-issues)
- New risks introduced: none — both follow the established repository→provider→ConsumerWidget pattern and Pro-gate convention. The two new sync tables (`crew_members`, `inventory_items`) have no Supabase-side schema yet; writes queue into `SyncOutbox` like every other table and are harmless until the backend tables exist (same status the Documents `documents` table was left in by F15).
- Removed/deprecated: the two "Coming Soon" stub screens.
- Verification: `flutter analyze` zero issues; `dart run build_runner build` clean; `flutter test` 482/482 pass (474 + 8 new); `flutter build apk --debug` built cleanly. Live-verified on the physical Samsung SM-S928U1 (Android 16) with an active Pro entitlement — full CRUD pass on both modules (see `outstanding.md` Live verification history for detail): Crew add ("Skipper Ada"/Captain/phone) → list refresh → detail dialog → edit (role → First Mate) → delete → empty state; Inventory add ("Fenders"/Lazarette/14 pcs) → list refresh → detail dialog → delete → empty state. Confirmed the Role dropdown renders all 6 options, the phone field uses a numeric keypad, quantity formats as an integer ("14 pcs", not "14.0"), and null serial/notes rows are omitted from the detail dialog. Zero exceptions from `com.sailingsisu.sisumate` in logcat across the whole session (the only `E/` line seen, a `FlexPanelStartController` NPE, belongs to a Samsung system process, not the app).

---

## [2026-07-05] — Add real-Isar repository CRUD test suite

- Files changed in project:
  - (F15's live Pro-unlocked verification — add/list/detail/delete all confirmed working on-device — is recorded in the F15 entry below rather than repeated here; no production code changed for that part)
  - `lib/services/isar_service.dart` — renamed the private `_schemas` list to public `schemas`, so tests can open a real Isar instance with the exact same schema set the app registers, rather than duplicating (and risking drift from) the list
  - `test/test_helpers/isar_test_helper.dart` — new: `openTestIsarService()` (opens a fresh temp-dir Isar instance using `IsarService.schemas` and points the app's `IsarService` singleton at it — confirmed `Isar.initializeIsarCore(download: true)` works fine inside plain `flutter test`, no device/emulator required) and `testSyncService()` (a real `SyncService` via a `ProviderContainer`, whose writes safely no-op since RevenueCat has no entitlement in a test process)
  - `test/repositories/` — new: one test file per repository (13 total: `document`, `captain_log`, `boat`, `maintenance`, `collection`, `guest_profile`, `meal_plan`, `user_settings`, `shopping`, `checklist`, `recipe` (+ RecipeIngredient), `bar_ingredient`, `pantry_ingredient`), each covering Create/Read/Update/Delete against the real Isar instance — 55 tests total. `CommunityRepository` deliberately excluded (Supabase-network-only, not a fit for local-Isar CRUD tests)
- Context files updated: `outstanding.md` (T6 rewritten to describe the new real-Isar testing convention and the actual remaining coverage gaps; Build Verification updated to 474/474), `INDEX.md` (new "Testing" section documenting the harness and how to use it)
- New risks introduced: none
- Removed/deprecated: none
- Verification: `flutter analyze` zero issues, `flutter test` 474/474 pass (419 + 55 new), `flutter build apk --debug --dart-define-from-file=dart-defines.json` installs and runs cleanly (confirms the `_schemas` → `schemas` rename didn't break the production Isar.open() call site)

---

## [2026-07-05] — Build Documents Vault (F15)

- Files changed in project:
  - `lib/models/document.dart` — new: `Document` Isar model (`title`, `type`, `fileUrl` for a future remote URL, `localPath` for an attached photo, `notes`, `expiry`, plus the standard `supabaseId`/`boatSupabaseId`/`isSynced`/`lastModified`), added to `models.dart`'s `part` list
  - `lib/services/isar_service.dart` — added `DocumentSchema` to `_schemas`
  - `lib/domain/repositories/document_repository.dart` / `lib/data/repositories/document_repository_impl.dart` — new: `DocumentRepository` interface + impl, mirroring `CaptainLogRepository`'s watch/add/update/delete pattern exactly, including `syncService.queueOutgoingChange('documents', ...)` on writes/deletes
  - `lib/core/di.dart` — new `documentRepositoryProvider`
  - `lib/ui/documents/documents_screen.dart` — replaced the "Coming Soon" stub with a real screen: `documentsProvider` (StreamProvider), a list showing each document's type and an expiry-aware label (red "Expired", orange "Expires in N days" when ≤30 days out, grey otherwise), a FAB gated behind `isProProvider` (Free tier sees the standard "Sisu Mate Pro Required" dialog), a detail dialog (view-only for Free, Edit/Delete added for Pro), and a public `AddEditDocumentDialog` (title/type dropdown/notes/expiry date picker/photo via `image_picker` camera or gallery) — made public rather than private specifically so it's testable, following the same convention established for `AddEditRecipeDialog`
  - `test/documents_screen_test.dart` — new: 3 widget tests (saves a new document with the expected fields; blocks save when the title is empty; pre-fills fields from an existing document when editing)
- Context files updated: `data_models.md` (new `Document` collection entry, `DocumentRepository` row, `documentRepositoryProvider`/`documentsProvider` rows), `INDEX.md` (new entries for the model/repository/screen; also self-healed a previously-undocumented gap — `fuel_screen.dart` is a stub despite `FuelLogEntry` already existing as a registered model), `outstanding.md` (removed F15, added new F22 for the `fuel_screen.dart` gap, updated Build Verification to 419/419, new live-verification entry)
- New risks introduced: none
- Removed/deprecated: the "Coming Soon" placeholder body of `documents_screen.dart`
- Verification: `flutter analyze` zero issues, `dart run build_runner build` generated `DocumentSchema` cleanly, `flutter test` 419/419 pass (416 + 3 new), `flutter build apk --debug --dart-define-from-file=dart-defines.json` installs and runs cleanly. Live-verified on the physical Samsung SM-S928U1 (after a multi-attempt device wake/unlock struggle this session — the device kept re-locking): Documents tile opens the real screen, empty state renders, the FAB's Pro gate correctly blocks Free-tier users and opens the paywall. Pro was then unlocked on-device via RevenueCat's test-store purchase flow, enabling a full live create → list → delete pass against the real Isar database (added "Boat"/Registration, confirmed the save snackbar and immediate list refresh, opened the detail dialog, deleted it, list correctly emptied) — no exceptions in logcat throughout

---

## [2026-07-04] — Investigate RT2 (Vulkan shader compile failure) — no code change

- Files changed in project: none — investigation only
- Findings: re-captured logcat on a cold start and confirmed the `AdrenoVK-0` "Shader compilation failed"/"Pipeline create failed" lines still occur (4× per cold start), but narrowed the root cause: they fire ~15-20ms after `flutter: Banner ad loaded.`, in the same window as the AdMob SDK's internal WebView's first paint (`com.google.android.gms.ads.internal.webview.ai` / `WebViewChromium.onDraw` calls immediately surround them in logcat). This points to the Google Mobile Ads SDK's own Chromium WebView hitting a first-use Adreno shader-cache miss, not Flutter/Impeller rendering as the original RT2 entry assumed. Confirmed one-time per session: a second ad load later in the same run produced no further shader-failure lines (the driver caches the fallback pipeline after the first miss). No visible glitch observed in either case
- Context files updated: `outstanding.md` (RT2 description refined with the above; kept open since it's a third-party/driver behavior with no app-code fix available, not something to mark "done")
- New risks introduced: none
- Removed/deprecated: none
- Verification: not applicable — no code changed

---

## [2026-07-04] — Client-side LAN disconnect detection + reconnect (F6)

- Files changed in project:
  - `lib/services/lan/lan_engine.dart` — `connectToService()` now remembers the connected `BonsoirService` in `_lastConnectedService`; new `Future<bool> reconnectToLastHost()` retries the WebSocket connection against that same address (returns `false` if there's nothing to retry, or the retry itself throws). `dispose()` clears the remembered service
  - `lib/services/lan/game_lan_service.dart` — `joinGame()` now remembers the player's own name in `_myPlayerName` (exposed via `myPlayerName`); new `Future<bool> reconnect()` calls `LanEngine.reconnectToLastHost()` and, on success, re-sends the `join` handshake under the same name so the host's bookkeeping still works. `endSession()` clears `_myPlayerName`
  - `lib/ui/games/games/liars_dice/logic.dart` — `initClientMode()` now also subscribes to `lan.playerLeaves`, previously listened to only in host mode; a `'host'` leave event triggers `_handleHostDisconnect()`, which sets `gameMessage: 'Connection lost. Reconnecting…'`, retries `GameLanService.reconnect()` up to 3 times (2s apart), and either recovers (`'Reconnected!'`) or cleanly ends the session (`currentState: gameOver`, `'Connection to host lost. Game ended.'`) instead of the previous total silence. A new `_sessionGeneration` counter (bumped on every `initHostMode`/`initClientMode`/`exitMultiplayerMode` call) lets a stale retry loop detect it's no longer relevant and stop touching `state`
  - `test/lan_reconnect_test.dart` — new: 3 tests covering the parts of this flow that don't require a live socket (`reconnectToLastHost()`/`reconnect()` both correctly return `false`, not throw, when there's no prior connection to retry)
- Context files updated: `outstanding.md` (removed F6, updated Build Verification to 416/416, new live-verification entry explaining the narrower actual gap found), `INDEX.md` (updated the existing `lan_engine.dart`/`game_lan_service.dart` entries to mention the new reconnect methods)
- New risks introduced: none
- Removed/deprecated: none
- Verification: `flutter analyze` zero issues, `flutter test` 416/416 pass (413 + 3 new), `flutter build apk --debug --dart-define-from-file=dart-defines.json` installs cleanly. Live device verification wasn't possible this round — the physical Samsung SM-S928U1 disconnected from adb entirely between sessions (environmental, not caused by this change), and a full end-to-end test would need a second physical device to host/join against regardless. Relied on the 3 new unit tests plus a clean analyze/build/test cycle

---

## [2026-07-04] — Rarity-aware AI bid/accept logic in Liar's Dice (F7)

- Files changed in project:
  - `lib/ui/games/games/liars_dice/logic.dart` — added a `static const Map<DiceRank, double> _rankProbability` (standard 5d6 "poker dice" hand-rank probabilities, e.g. Five of a Kind ≈ 0.08%, One Pair ≈ 46%). `getAIBid()`'s face search now iterates 1→6 instead of 6→1, so it returns the *smallest* valid face for whichever rank it lands on rather than the largest — previously the AI always overbid to the maximum face (e.g. "Two Pair of 6s") regardless of context, which was both strategically wasteful (burns escalation room) and an obvious tell. `getAIAccept()` now also weighs the declared rank's absolute rarity: a claim that's inherently a long shot (< 2% of honest rolls, e.g. Four/Five of a Kind) is challenged even when the AI's own hand doesn't directly contradict it, and a small escalation over a fairly common rank leans more toward trusting it (85/15 instead of the flat 70/30) rather than one blanket ratio for every "ambiguous" case
  - `test/liars_dice_test.dart` — new: 1 test for the minimal-face bid fix, 1 test for the rarity-aware challenge fix (both deterministic — fixed dice, no retry loop needed for the bid test; a 20x repeat asserting all-challenge for the accept test, matching the file's existing convention for probabilistic branches)
- Context files updated: `outstanding.md` (removed F7, corrected its original description which assumed a pooled-dice mechanic this game variant doesn't have, updated Build Verification to 413/413, new live-verification entry), `risks.md` (new entry #18: the "escalate above the last bid" code path is dead in normal play since each round has exactly one bid — discovered while implementing this fix, not a bug)
- New risks introduced: none (risks.md #18 is a documented architectural observation, not an outstanding problem)
- Removed/deprecated: none
- Verification: `flutter analyze` zero issues, `flutter test` 413/413 pass (411 + 2 new), `flutter build apk --debug --dart-define-from-file=dart-defines.json` installs cleanly. Reinstalled on the physical Samsung SM-S928U1, but the device was stuck on its lock screen (environmental, unrelated to this change) so a live play-through wasn't completed this session; relied on the 2 new deterministic unit tests plus a clean logcat (no exceptions) instead

---

## [2026-07-04] — Fix AddEditRecipeDialog's cramped ingredients viewport (F21)

- Files changed in project:
  - `lib/ui/cocktails/cocktails_screen.dart` — `AddEditRecipeDialog`'s content `SizedBox` grew from `height: 500` to `height: 600`; its `Form` child is now wrapped in a `SingleChildScrollView` so the dialog scrolls as a whole rather than squeezing internals if content ever exceeds the box again; the ingredients `ListView` changed from `Expanded` (which left only ~80px once the cuisine/method dropdowns were added) to a fixed `SizedBox(height: 220)`
  - `test/add_edit_recipe_dialog_test.dart` — new: 1 widget test confirming 2 pre-existing ingredients are both findable immediately after pump, with no scroll/drag call — the direct regression check for F21 (previously only the first ingredient card was even built, per the F21 diagnosis)
- Context files updated: `risks.md` (struck through #17 as resolved), `outstanding.md` (removed F21, updated Build Verification to 411/411, new live-verification entry)
- New risks introduced: none
- Removed/deprecated: none
- Verification: `flutter analyze` zero issues, `flutter test` 411/411 pass (410 + 1 new), `flutter build apk --debug --dart-define-from-file=dart-defines.json` installs and launches cleanly on the physical Samsung SM-S928U1 with no exceptions in logcat. Full on-device visual re-verification of the dialog itself wasn't repeated (would require re-unlocking Pro via the RevenueCat test-purchase flow again) — relies on the new widget test plus a clean launch/logcat check, same approach used for F20

---

## [2026-07-04] — Animate tied-player re-roll in Liar's Dice (F8)

- Files changed in project:
  - `lib/ui/games/games/liars_dice/logic.dart` — added `GameState.rerollingPlayerIds` (`List<String>`, default `const []`, wired through `copyWith`/`toJson`/`fromJson` for LAN sync). `determineStarter()` now sets it to the tied players' ids alongside their re-rolled dice when a tie is detected, and clears it (`const []`) once a sole starter is resolved
  - `lib/ui/games/games/liars_dice/screen.dart` — `_DetermineStarterUI` now highlights any player in `rerollingPlayerIds` with an amber card border, a small spinner + "Tied — re-rolling…" caption under their name, and wraps their `DiceRow` in a new `_ShakingDice` widget (a brief looping horizontal shake via `AnimationController`) so the re-roll reads as visibly in-motion rather than a silent number swap
  - `test/liars_dice_test.dart` — new: 2 tests using identical dice for both players (a deterministic, non-probabilistic tie) confirming `rerollingPlayerIds` is set to both player ids on a tie and cleared once a starter resolves
- Context files updated: `outstanding.md` (removed F8, updated Build Verification to 410/410, new live-verification entry)
- New risks introduced: none
- Removed/deprecated: none
- Verification: `flutter analyze` zero issues, `flutter test` 410/410 pass (408 + 2 new), `flutter build apk --debug --dart-define-from-file=dart-defines.json` installs and runs cleanly. Live-played several full AI-vs-AI games on the physical Samsung SM-S928U1 with no exceptions in logcat; the tie-animation frame itself wasn't visually caught during manual screenshot timing (exact-rank ties are relatively rare and AI-vs-AI phases resolve in well under a second), so this fix leans on the 2 deterministic unit tests (which force a guaranteed tie via identical dice) for logic correctness rather than an on-screen capture

---

## [2026-07-04] — Remove seeded "Filters" spares from fresh-install shopping list

- Files changed in project:
  - `lib/data/seed/shopping_seeder.dart` — removed the `spare()` helper and the 3 `ShoppingItem`s it created ("Yanmar Fuel Filter 129574-55711", "Yanmar Oil Filter 129150-35170", "Racor 2010PM-OR 30 Micron (x2)"), all seeded under the "Filters" category only. `seedShoppingData()` now creates the 11 `ShoppingCategory` rows and nothing else
- Context files updated: `data_models.md` (§Seeded Data updated to reflect categories-only seeding)
- New risks introduced: none
- Removed/deprecated: the 3 seeded spares items. Prompted by the user noticing 3 unexplained "Spares" items after a real uninstall/reinstall and questioning whether that's actually desirable — investigation confirmed it was deliberate bundled seed data (not a bug), but only for one category out of eleven, which reads as leftover test data rather than intentional sample content. Existing installs already carrying this seeded data are unaffected (the seed guard means `seedBundledData()` won't re-run for them); only new fresh installs and factory resets get the clean behavior
- Verification: `flutter analyze` zero issues, `flutter test` 408/408 pass (no new test added — this is a one-line seed-data removal in a file with no existing test coverage, consistent with how the other `seed_*.dart` files are untested), `flutter build apk --debug --dart-define-from-file=dart-defines.json` installs and runs cleanly. Live-verified on the physical Samsung SM-S928U1 via a genuine `adb uninstall` + fresh install (not just `install -r`): onboarding flow appeared, and after skipping it the Shopping screen showed no "Spares" section at all — confirmed empty. No exceptions in logcat.

---

## [2026-07-04] — Fix AddEditRecipeDialog dropping manually-entered ingredients (F20)

- Files changed in project:
  - `lib/ui/cocktails/cocktails_screen.dart` — `AddEditRecipeDialog.onSave` changed from `Function(Recipe)` to `void Function(Recipe, List<RecipeIngredient> ingredients, List<RecipeIngredient> removedIngredients)`; added an `existingIngredients` constructor param (populated into `_ingredients` in `initState()` for edit mode, previously always empty even when editing a recipe with existing ingredients); `_save()` now stamps each ingredient's `recipeSupabaseId`/`sortOrder` before handing the full `_ingredients` list plus a tracked `_removedIngredients` list (pre-existing ingredients the user deleted from the form) to `onSave`
  - `lib/ui/chef/chef_screen.dart` / `lib/ui/cocktails/cocktails_screen.dart` — all 7 `AddEditRecipeDialog` call sites updated: the 5 create-flow sites now loop `addIngredient()` over the returned list; the 2 edit-flow sites (`_showEditDialog` in both files) now `await getIngredientsOnce()` before opening the dialog, pass it as `existingIngredients`, and on save loop `addIngredient()` (upsert, since `RecipeIngredient`s fetched from Isar retain their internal `id` so `addIngredient`/`updateIngredient` both just `put()` in place) plus `deleteIngredient()` per removed ingredient
  - `test/add_edit_recipe_dialog_test.dart` — new: 3 widget tests driving the real `AddEditRecipeDialog` widget (add-then-save includes the ingredient with correct `recipeSupabaseId`/`sortOrder`; remove-then-save reports it via `removedIngredients` and excludes it from the final list; empty name still blocks save)
- Context files updated: `risks.md` (struck through #16 as resolved; added #17 for a newly-found low-severity issue — the ingredients `ListView`'s ~80px viewport, discovered while widget-testing this fix), `outstanding.md` (removed F20, added F21 for the ListView viewport issue, updated Build Verification to 408/408, new live-verification entry), `data_models.md` (corrected the "Seeded Data" section's description of `IsarService.init()`'s seed-trigger logic, which omitted the partial-seed-recovery path and `UserSettings` seeding — found while investigating an unrelated user question about fresh-install shopping list contents), `changelog.md`
- New risks introduced: F21 / risks.md #17 (ingredients list viewport too short — usability, not data loss)
- Removed/deprecated: none
- Verification: `flutter analyze` zero issues, `flutter test` 408/408 pass (405 + 3 new widget tests), `flutter build apk --debug --dart-define-from-file=dart-defines.json` installs and runs cleanly on the physical Samsung SM-S928U1 after a user-initiated uninstall/reinstall. The fix itself is verified via the 3 widget tests (which exercise the real dialog widget end-to-end, not mocks) rather than a live manual click-through, since Pro entitlement did not survive the fresh install and re-running the RevenueCat test-purchase flow wasn't necessary to confirm this particular fix

---

## [2026-07-04] — Recipe import from photo / OCR (CF15)

- Files changed in project:
  - `pubspec.yaml` — added `google_mlkit_text_recognition: ^0.15.1`
  - `lib/services/recipe_ocr_service.dart` — new: `RecipeOcrService.importFromImage(File)` runs on-device, offline OCR (`TextRecognizer(script: TextRecognitionScript.latin)`) and hands the recognized text to the pure `parseText(rawText)` core. Heuristic: first non-empty line is the recipe name; scans for `Ingredients`/`Instructions`/`Directions`/`Method`/`Steps` headings as section boundaries; falls back to treating everything after the title as freeform instructions when no headings are found, rather than discarding unstructured OCR output. Reuses `RecipeImportService.parseIngredientLine()` (made `public`, no longer `_parseIngredientLine`, specifically for this reuse) for per-line ingredient parsing. Throws `RecipeOcrException` when no text is recognized at all
  - `lib/ui/chef/chef_screen.dart` — Chef FAB's bottom sheet now has 3 options: "Add manually" / "Import from URL" / "Import from photo" (the last opens a Camera/Gallery picker via `image_picker`); new `_showImportFromPhotoOptions()` and `_importFromPhoto()` mirror the URL-import dialog's persist/snackbar pattern
  - `test/recipe_ocr_service_test.dart` — new: 5 tests covering a well-structured card, "Directions"/"Method" heading recognition, the no-headings freeform fallback, an Ingredients-only card, and the no-recognizable-text error path
  - `lib/services/recipe_import_service.dart` — `_parseIngredientLine` renamed to public `parseIngredientLine` so `RecipeOcrService` can share it; also fixed a real bug found via live testing against a real recipe URL (AllRecipes.com): `_knownUnits` only recognized abbreviated unit words, not spelled-out ones (teaspoon(s), tablespoon(s), ounce(s), pound(s), gram(s), kilogram(s), milliliter(s)/millilitre(s), liter(s)/litre(s)) — expanded the set and added a regression test to `test/recipe_import_service_test.dart`
- Context files updated: `data_models.md` (new `RecipeOcrService` row in Services table, documenting the known screenshot-vs-recipe-card limitation found live), `INDEX.md` (`recipe_ocr_service.dart` entry), `outstanding.md` (removed CF15, updated Build Verification to 405/405, two new live-verification history entries — the CF11 units-fix follow-up and the CF15 on-device OCR run), `changelog.md`
- New risks introduced: none — the screenshot-vs-recipe-card limitation is documented as expected fallback behavior in `data_models.md`'s `RecipeOcrService` entry rather than a risks.md entry, since it matches the feature's designed and tested fallback path (no crash, user-editable result)
- Removed/deprecated: none
- Verification: `flutter analyze` zero issues, `flutter test` 405/405 pass (399 + 1 units regression test + 5 new OCR tests), `flutter build apk --debug --dart-define-from-file=dart-defines.json` installs and runs cleanly. Live-verified end-to-end on a physical Samsung SM-S928U1 (Android 16) via adb, with Pro unlocked through RevenueCat's debug-mode "Test Store Purchase" flow: the 3-option FAB bottom sheet, the Camera/Gallery picker, and a real on-device OCR run against a gallery photo (a "Easy spaghetti carbonara" webpage screenshot) that exercised the freeform-fallback path exactly as designed (0 ingredients, status-bar clock as name, everything else as instructions) with zero exceptions in logcat from `com.sailingsisu.sisumate`

---

## [2026-07-04] — Import recipe from URL (CF11)

- Files changed in project:
  - `pubspec.yaml` — added `http: ^1.2.2`
  - `lib/services/recipe_import_service.dart` — new: `RecipeImportService.importFromUrl(url)` fetches a page's HTML and calls the pure, testable `parseHtml(html)`, which extracts `schema.org/Recipe` JSON-LD from `<script type="application/ld+json">` tags via regex (no `html`-parsing package dependency added), searching plain objects, `@graph` arrays, and lists for a `Recipe`-typed node. Builds an unsaved `ParsedRecipe(recipe, ingredients)`: flattens `recipeInstructions` (string / string list / `HowToStep` / `HowToSection`) into a numbered list, parses ISO 8601 `prepTime`/`cookTime` durations to minutes, and parses each ingredient line's leading quantity (plain, decimal, or fraction incl. mixed numbers like "1 1/2") + a known-unit-word into `quantity`/`unit`/`name`, flagging `isOptional`/`isGarnish` from the word appearing in the line. Throws `RecipeImportException` for unreachable URLs, non-200 responses, missing Recipe JSON-LD, or a missing name
  - `lib/ui/chef/chef_screen.dart` — FAB on the Chef tab now opens a bottom sheet ("Add manually" / "Import from URL") instead of going straight to `AddEditRecipeDialog`; new `_showImportFromUrlDialog()` shows a URL field + loading state, calls `RecipeImportService.importFromUrl()`, then persists the result via `recipeRepositoryProvider.addRecipe()` + `addIngredient()` per parsed ingredient. Gated behind the same Pro check as manual recipe creation
  - `test/recipe_import_service_test.dart` — new: 6 tests covering a plain Recipe object, `@graph` array traversal, `HowToStep` instruction flattening, optional/garnish detection, and both error paths (no JSON-LD found, missing name)
- Context files updated: `data_models.md` (`RecipeImportService` entry in Services table; **self-healed** `RecipeType` enum, which was missing the `syrup` value, and `Recipe.tastingLog`'s type, which was mis-typed as `String?` instead of `List<TastingRecord>` — added the missing `TastingRecord` embedded-model section), `INDEX.md` (`recipe_import_service.dart` entry), `outstanding.md` (removed CF11, updated Build Verification, new live-verification history entry, new F20 bug entry), `risks.md` (new Known Anti-Patterns entry #16: `AddEditRecipeDialog` drops manually-entered ingredients), `changelog.md`
- New risks introduced: none directly from this feature. Discovered (pre-existing, unrelated): `AddEditRecipeDialog._save()` never persists the ingredients built in its own form — see risks.md #16 / outstanding.md F20
- Removed/deprecated: none
- Verification: `flutter analyze` zero issues, `flutter test` 399/399 pass (393 + 6 new), `flutter build apk --debug --dart-define-from-file=dart-defines.json` installs and runs cleanly. Live-verified on a physical Samsung SM-S928U1 (Android 16) via adb up to the feature's Pro gate (this test device has no active Pro entitlement); the "Add manually"/"Import from URL" bottom sheet and the Pro-required dialog both work correctly. Full fetch-and-parse UI flow not exercised on-device this session — covered instead by the 6 unit tests against realistic sample HTML

---

## [2026-07-04] — Shared recipe print/share PDF service (CF12/BC11)

- Files changed in project:
  - `pubspec.yaml` — added `pdf: ^3.11.3`, `printing: ^5.14.2`
  - `lib/ui/components/title_tile.dart` — added optional `actionsBuilder: List<Widget> Function(Color iconColor)?` param, rendered as extra icon buttons before the existing menu icon when set; non-breaking default `null`, all ~20+ existing call sites unaffected
  - `lib/services/recipe_share_service.dart` — new: `RecipeShareService.shareRecipeCard({recipe, ingredients})` builds a one-page `pw.Document` recipe card (title, cuisine, description, prep/cook time, glassware, ingredients, instructions) and opens the OS print/share preview via `Printing.layoutPdf()` — one API call covers both printing and sharing
  - `lib/ui/chef/chef_screen.dart` / `lib/ui/cocktails/cocktails_screen.dart` — wired a share icon (`Icons.ios_share`, tooltip "Print / Share") into each recipe detail screen's `TitleTile` via `actionsBuilder`, calling `RecipeShareService.shareRecipeCard`
- Context files updated: `data_models.md` (added `RecipeShareService` to Services table; **self-healed** the `Recipe` table, which was missing `missingIngredientCount`/`isFavourite`/`glassware`/`prepMinutes`/`cookMinutes`/`story`/`tastingLog`/`cuisine`/`cookingMethod`, and the `RecipeIngredient` table, which was missing `garnishNotes` — both discrepancies found while re-reading the model files for this task), `INDEX.md` (`recipe_share_service.dart` entry), `screens.md` (`TitleTile`'s new `actionsBuilder` param), `outstanding.md` (removed CF12/BC11, updated Build Verification, new live-verification history entry), `risks.md` (new Known Anti-Patterns entry: `pdf` package core fonts have no Unicode glyph coverage), `changelog.md`
- New risks introduced: any future PDF content added via `recipe_share_service.dart` (or a similar `pdf`-package use elsewhere) must stick to ASCII-only glyphs unless a Unicode font is explicitly bundled — see risks.md #15
- Removed/deprecated: none

---

## [2026-07-04] — Shopping/provision list email & share infrastructure (SH1–SH5)

- Files changed in project:
  - `pubspec.yaml` — added `url_launcher: ^6.3.1`
  - `lib/models/user_settings.dart` — added `List<String> recentEmails`, `String? fromName`, `String? replyToEmail`, `String? boatName`
  - `lib/services/email_service.dart` — new: `EmailService.composeAndSend()`, a "Send to" dialog (recipient field + recent-email chips) followed by a hand-built `mailto:` launch. Percent-encodes subject/body by hand (`Uri.encodeComponent` per value) rather than using `Uri(queryParameters:)`, which form-encodes spaces as `+` — a bug found live where Gmail rendered literal `+` characters instead of spaces. Appends `fromName` as a signature, sets `replyToEmail` as the `reply-to` param, records the recipient into `UserSettings.recentEmails` (cap 5) on success (SH1/SH2/SH4)
  - `lib/ui/components/swipeable_list_item.dart` — added `onEmail` callback + a new indigo "Email" `SlidableAction` to the constructive (right-swipe) action pane; added to the `.shoppingItem` factory
  - `lib/ui/shopping/shopping_screen.dart` — `ShoppingItemTile`: swapped the dead `onAddToShopping` placeholder (only ever showed an "already in shopping list" snackbar) for a real `onEmail` action (SH1). `ShoppingOriginTile`: wrapped only the section header `Row` (not the whole `ExpansionTile`) in a `Slidable` with a single "Email" action covering that origin's items — wrapping the whole `ExpansionTile` breaks per-item swipes via a gesture conflict, found live (SH1). Added a "Share → Email All Lists" section to the end drawer, compiling every origin into one labelled email (SH3). Wrapped the drawer's scrollable content in `Expanded(child: SingleChildScrollView(...))` above `DrawerFooter()` — the new Share section overflowed the previous fixed `Column`+`Spacer()` layout, found live
  - `lib/ui/settings/settings_screen.dart` — new "Email & Sharing" section with 3 `TextField`s (from name, reply-to, boat name) saved via `onEditingComplete`/`onTapOutside`, backed by a new `_EmailSettingsFields` `ConsumerStatefulWidget` (SH4)
  - `lib/ui/chef/provision_planner_screen.dart` — added a mail `IconButton` next to the existing clipboard-copy button; `_copyToClipboard`'s text-building logic factored into a shared `_buildProvisionText()` used by both actions; email subject follows the "Provisions for X for N guests — week of Y" format from `UserSettings.boatName ?? plan.name` (SH5)
  - `lib/ui/home/home_screen.dart` — **found and fixed a pre-existing, unrelated bug**: the end drawer's fixed `Column`+`Spacer()`+`DrawerFooter()` layout overflowed once its content grew, making "Settings" completely untappable (not caused by this session's changes, but blocked verifying SH4); fixed with the same `Expanded`+`SingleChildScrollView` pattern
- Context files updated: `data_models.md` (`UserSettings` new fields, `EmailService` entry in Services table), `INDEX.md` (`email_service.dart` entry), `risks.md` (2 new Known Anti-Patterns entries: end-drawer overflow pattern, nested-`Slidable` gesture conflict), `screens.md` (`HomeScreen`/`ShoppingScreen` drawer notes in Widget Tree Depth Notes), `outstanding.md` (removed SH1–SH5, updated Build Verification, new live-verification history entry), `changelog.md`
- New risks introduced: any future end-drawer content addition should default to the `Expanded`+`SingleChildScrollView` pattern rather than a fixed `Column`+`Spacer()`, or verify live before shipping. Any future per-section swipe action must scope its `Slidable` to the header only, never the whole expandable container.
- Removed/deprecated: `ShoppingItemTile`'s `onAddToShopping` callback usage (was dead code, replaced by `onEmail`); `home_screen.dart`'s `Spacer()` before `DrawerFooter()`; `shopping_screen.dart`'s `Spacer()` before `DrawerFooter()`
- Verification: `flutter analyze` zero issues, `flutter test` 393/393 pass (no new tests — UI/service wiring only), `flutter build apk --debug --dart-define-from-file=dart-defines.json` installs and runs cleanly, live-verified on a physical Samsung SM-S928U1 (Android 16) via adb — item email, section email, Email All Lists, recent-email chip persistence, Settings fields persistence, and the provision list's mail icon all confirmed working end-to-end; logcat clean of app exceptions throughout.

---

## [2026-07-03] — Pantry calorie macros, recipe-detail calorie display, themed recipe collections (CF13/CF23/CF16)

- Files changed in project:
  - `lib/models/pantry_ingredient.dart` — added `double? caloriesPer100g`, `proteinPer100g`, `fatPer100g`, `carbsPer100g` (CF13)
  - `lib/data/seed/seed_pantry_ingredients.dart` — added a 72-entry `_macrosPer100g` lookup map, wired into the seed loop
  - `lib/services/calorie_calculator.dart` — new: `CalorieCalculator.compute()`, weight-units-only (g/kg/oz/lb — deliberately excludes volume/count to avoid fabricating density-based estimates), returns partial results when ingredients lack a pantry match or weight unit (CF23)
  - `test/calorie_calculator_test.dart` — new, 6 tests
  - `lib/ui/chef/chef_screen.dart` — wired calorie display into `ChefRecipeDetailScreenState` recipe detail (orange fire icon + "Est. calories: ~N kcal for M servings (x/y ingredients)"); renamed `_RecipeDetailScreen`/`_RecipeDetailScreenState` → `ChefRecipeDetailScreen`/`ChefRecipeDetailScreenState` (public, needed for CF16 cross-module navigation); added "Collections" drawer entry; lowered Chef grid's `childAspectRatio` 0.56 → 0.48 (card overflow fix); wrapped calorie/cost `Text` rows in `Expanded`; **fixed a pre-existing bug** where the entire end drawer was unreachable — wrapped the `Scaffold` body in `Builder(builder: (context) => ...)` (was using the outer `build()` context directly, which is an ancestor, not descendant, of the `Scaffold`, so `Scaffold.of(context).openEndDrawer()` silently failed)
  - `lib/ui/cocktails/cocktails_screen.dart` — renamed `_RecipeDetailScreen`/`_RecipeDetailScreenState` → `CocktailRecipeDetailScreen`/`CocktailRecipeDetailScreenState` (public); added "Collections" drawer entry (already had the `Builder` wrapper, no fix needed)
  - `lib/models/recipe_collection.dart` — new: `RecipeCollection` collection (`name`, `recipeSupabaseIds`, `createdAt`, `lastModified`). Named `RecipeCollection` rather than `Collection` to avoid colliding with Isar's own generic `CollectionSchema<T>` (CF16)
  - `lib/models/models.dart` — added `part 'recipe_collection.dart';`
  - `lib/services/isar_service.dart` — registered `RecipeCollectionSchema` in `_schemas`
  - `lib/domain/repositories/collection_repository.dart`, `lib/data/repositories/collection_repository_impl.dart` — new repository (watch/add/update/delete)
  - `lib/core/di.dart` — added `collectionRepositoryProvider`, `collectionsProvider`
  - `lib/ui/collections/collections_screen.dart` — new: `CollectionsScreen` (list/create/rename/delete) + `CollectionDetailScreen` (add/remove recipes via a bottom-sheet picker spanning both Chef and Cocktails recipes, navigates to the correct detail screen by `recipe.recipeType`)
- Context files updated: `data_models.md` (`PantryIngredient` macro fields + seeding note, `RecipeCollection` model + naming-collision note, `calorie_calculator.dart` service entry, 2 new providers), `risks.md` (`RecipeCollection` in `_schemas` list, new naming-collision gotcha), `screens.md` (renamed detail screens, `CollectionsScreen`/`CollectionDetailScreen` entries, `ChefScreen` drawer bug note in Widget Tree Depth Notes), `outstanding.md` (removed CF13/CF16/CF23, updated Build Verification test count, new live-verification history entry), `INDEX.md` (`recipe_collection.dart`, `calorie_calculator.dart`, `collections/` folder), `changelog.md`
- New risks introduced: naming an Isar model `Collection` collides with Isar's generated `CollectionSchema<T>` — always pick a more specific name. CF13's macro fields are `null` on any pantry seeded before this change (one-time seed guard doesn't backfill existing installs).
- Removed/deprecated: none
- Verification: `flutter analyze` zero issues, `flutter test` 393/393 pass (+6 new), `flutter build apk --debug --dart-define-from-file=dart-defines.json` installs and runs cleanly, live-verified on a physical Samsung SM-S928U1 (Android 16) via adb — created a collection, added/removed a recipe, confirmed calorie display renders correctly and wraps without overflow, confirmed the previously-unreachable Chef drawer now opens with all entries including the new "Collections" item, checked logcat clean of app-related exceptions.

---

## [2026-07-03] — Meal Planner: flexible trip length/start day + provision list grouping (CF25/CF26)

- Files changed in project:
  - `lib/models/meal_plan.dart` — added `int numberOfDays = 7` field; `startDate` no longer implies Monday
  - `lib/services/trip_schedule.dart` — new: `mealTypesForDay(dayOffset, numberOfDays)` (day 0 = snack/lunch/dinner, no breakfast since guests board mid-day; last day = breakfast only; middle days = full breakfast/lunch/dinner; 1-day trips get the full set) and `totalSlotsForTrip(numberOfDays)`. Shared by both the meal planner grid and the provision calculator.
  - `lib/services/provision_calculator.dart` — `provisionDayMealLabel` now takes the `MealPlan` and computes the real weekday from `startDate.add(Duration(days: dayOffset))` via a new public `isoWeekdayNames` (previously a fixed Mon-Sun array indexed directly by `dayOffset`, which broke as soon as a trip could start on a non-Monday or run past 7 days). `portionedItems` changed from a flat `List<ProvisionItem>` (one entry per occurrence) to `List<PortionedGroup>` (grouped by name+unit) — CF26: repeats of the same dish now read as "Fresh Sea Bass — 2 × 24 fillets (Mon Lunch, Wed Dinner)" instead of two separate lines; non-uniform-quantity repeats list each occurrence under one heading. Also now skips slots whose `(dayOffset, mealType)` isn't valid for the plan's current shape.
  - `lib/data/repositories/meal_plan_repository_impl.dart` — `watchPlans()` now self-heals two migration issues in memory on every read: (1) old plans saved before `numberOfDays` existed deserialize it as `0`, not the Dart-declared default of `7` (confirmed live — Isar fills missing int fields with their zero value, not the field's initializer) — normalized to `7`; (2) slots whose `(dayOffset, mealType)` no longer corresponds to a valid combo (e.g. `dayOffset=0, mealType='breakfast'` from before CF25 existed) are dropped so they can't silently inflate the provision list while being invisible in the grid
  - `lib/ui/chef/meal_planner_screen.dart` — removed `mondayOf()` snapping; `_PlanEditDialogState` gained a "Trip length (days)" stepper (1–30) alongside the existing guest-count stepper; default plan name is now length-aware ("Week of X" only when exactly 7 days, else "N-Day Trip — X"); `MealPlanDetailScreen`'s day grid now iterates `numberOfDays` (not hardcoded 7) and computes each day's weekday from the actual date instead of a fixed Mon-Sun array; local `mealTypesForDay`/`totalSlotsForTrip`/weekday-array definitions removed in favor of the shared `trip_schedule.dart`/`provision_calculator.dart` versions
  - `test/provision_calculator_test.dart` — updated for the `PortionedGroup` API; added tests for CF26 grouping (uniform and non-uniform quantities), CF25's real-weekday computation, and the orphaned-slot exclusion bug found during live testing
  - `test/trip_schedule_test.dart` — new (replaces `test/meal_planner_day_slots_test.dart`): unit tests for `mealTypesForDay`/`totalSlotsForTrip` across day 0, last day, middle days, 1-day trips, and trips beyond a week
- Context files updated: `outstanding.md` (removed CF25/CF26; expanded Build Verification with the two migration bugs found live), `data_models.md` (`MealPlan.numberOfDays` + migration gotcha, `MealPlanSlot.mealType` now includes `snack` and is day-dependent), `INDEX.md` (`trip_schedule.dart` entry; updated `provision_calculator.dart` description for grouping + orphan-slot skipping), `changelog.md`
- New risks introduced: adding a field to an existing Isar collection does NOT give existing rows the Dart-declared default — new int fields deserialize as `0` for pre-existing data. Any future field addition to a populated collection needs the same kind of in-memory normalize-on-read the way `MealPlanRepositoryImpl` now does, or a real migration.
- Removed/deprecated: `mondayOf()` in `meal_planner_screen.dart`; `test/meal_planner_day_slots_test.dart` (moved to `test/trip_schedule_test.dart`)
- Verification: `flutter analyze` zero issues, `flutter test` 387/387 pass, `flutter build apk --debug` succeeds, live-verified on a physical Samsung SM-S928U1 (Android 16) via adb — confirmed the day grid's per-day meal sets, the real-date weekday labels, the provision list's "2 ×" grouping, and that both migration self-heals fixed the pre-existing test plan from the earlier CF1/CF24 session.

---

## [2026-07-03] — Renamed Menus module to Chef (file/directory/class names now match the "Chef" UI naming)

- Files changed in project:
  - `lib/ui/menus/` → `lib/ui/chef/` (directory renamed)
  - `lib/ui/menus/menus_screen.dart` → `lib/ui/chef/chef_screen.dart`; `MenusScreen` → `ChefScreen`, `_MenusScreenState` → `_ChefScreenState`
  - Inside `chef_screen.dart`: the first tab (UI label "Chef") `_MenusTab`/`_MenusTabState` → `_ChefTab`/`_ChefTabState`. This collided with the existing third tab (UI label "Chef's Corner"), so that one was renamed first: `_ChefTab`/`_ChefTabState` → `_ChefsCornerTab`/`_ChefsCornerTabState`. Every tab's internal class name now matches its own UI label.
  - `lib/ui/chef/guest_profiles_screen.dart`, `lib/ui/chef/meal_planner_screen.dart`, `lib/ui/chef/provision_planner_screen.dart` — moved (no internal renames needed, only live in the same directory as `chef_screen.dart`)
  - `lib/ui/home/home_screen.dart` — import path + `MenusScreen()` → `ChefScreen()`
- Context files updated: `INDEX.md` (folder tree entry, `RecipeAllergenService` file reference), `data_models.md` (all `menus_screen.dart`/`ui/menus/`/`MenusScreen` references, plus fixed the `GuestProfile` "Load Profile" reference which was pointing at the wrong tab class after the rename — it's `_ChefsCornerTabState`, not `_ChefTabState`), `outstanding.md` (CF11/CF15/CF23/CF25/CF26/BC+CF shared-file mentions, build verification note), `screens.md` (routing table row `MenusScreen`→`ChefScreen`, added missing rows for `GuestProfilesScreen`/`MealPlannerScreen`/`MealPlanDetailScreen`/`ProvisionPlannerScreen` which had never been added when those screens were built, navigation diagram, HomeScreen tile list "Menus"→"Chef"), `changelog.md`
- New risks introduced: none
- Removed/deprecated: `lib/ui/menus/` directory (contents moved, not deleted)
- Verification: `flutter analyze` zero issues, `flutter test` 376/376 pass, `flutter build apk --debug` succeeds

---

## [2026-07-03] — Meal Planner + Provision Planner (CF1/CF24)

- Files changed in project:
  - `lib/models/meal_plan.dart` — new `MealPlan` Isar collection (name, startDate, guestCount, guestProfileIds, createdAt, lastModified, slots). Local-only, not synced.
  - `lib/models/meal_plan_slot.dart` — new `@embedded` `MealPlanSlot` (dayOffset, mealType, recipeSupabaseId, recipeName), nested in `MealPlan.slots`
  - `lib/models/models.dart` — added `part 'meal_plan_slot.dart';` and `part 'meal_plan.dart';`
  - `lib/services/isar_service.dart` — registered `MealPlanSchema` in `_schemas`
  - `lib/domain/repositories/meal_plan_repository.dart` + `lib/data/repositories/meal_plan_repository_impl.dart` — new repository (watch/add/update/delete), sorted by `startDate` ascending
  - `lib/domain/repositories/recipe_repository.dart` + `lib/data/repositories/recipe_repository_impl.dart` — added `getIngredientsOnce(recipeId)`, a one-shot (non-stream) ingredient fetch needed by the provision calculator
  - `lib/core/di.dart` — added `mealPlanRepositoryProvider`, `mealPlansProvider`
  - `lib/services/recipe_allergen_service.dart` — new shared service extracted from `_RecipeCard`'s inline allergen/dietary-badge derivation logic (menus_screen.dart), now reused by the meal planner's recipe picker
  - `lib/services/provision_calculator.dart` — new pure `ProvisionCalculator.compute()`: scales `RecipeIngredient.quantity` by `MealPlan.guestCount`, splits into "to portion individually" (protein/seafood) vs. "consolidated" (summed by name+unit), and flags allergen conflicts against the plan's selected `GuestProfile`s. Protein classification uses `PantryIngredient.category == 'protein'` **plus** a name-keyword fallback (steak/fish/shrimp/mussel/etc.) — required because the pantry seed only stocks shelf-stable goods, so fresh proteins in recipes essentially never have a pantry match (confirmed live: "Fresh Sea Bass" and "Mussels" both fell into "Consolidated" until the keyword fallback was added)
  - `lib/ui/menus/meal_planner_screen.dart` — new `MealPlannerScreen` (list/create/delete plans) and `MealPlanDetailScreen` (7-day × 3-meal grid, recipe picker with allergen warning icon)
  - `lib/ui/menus/provision_planner_screen.dart` — new `ProvisionPlannerScreen` (renders `ProvisionCalculator` output; "Copy to clipboard" action pending full email support — see SH5)
  - `lib/ui/menus/menus_screen.dart` — `_RecipeCard` refactored to call `RecipeAllergenService.assess()` instead of inline logic; added a "Meal Planner" button to the Chef's Corner header; fixed a pre-existing `_RecipeCard` overflow (Chef grid `childAspectRatio` 0.65 → 0.56, caused by CF4's allergen row + dietary badges not fitting in the fixed-height card)
  - `test/provision_calculator_test.dart` — new unit tests: guest-count scaling, protein-vs-consolidated split (including the no-pantry-match keyword fallback), allergen-conflict detection, plan-scoped guest profile filtering, empty-slot handling
- Context files updated: `outstanding.md` (removed CF1/CF24; added SH5 follow-up for provision-list email support), `data_models.md` (added `MealPlan`/`MealPlanSlot` model sections + 2 new providers), `INDEX.md` (added model files + 2 new services to Navigation Map; also fixed 2 unrelated stale entries found while reading — see below), `risks.md` (fixed stale schema-registration note), `changelog.md`
- New risks introduced: none
- Removed/deprecated: none
- Self-healed while working (unrelated to this feature, found via the continuous self-heal rule):
  - `INDEX.md` / `risks.md` said Supabase config loads from a `.env` Flutter asset via `flutter_dotenv` — false; the real (and only) mechanism is `--dart-define-from-file=dart-defines.json` read via `String.fromEnvironment` in `main.dart`, which asserts non-empty and crashes on launch if omitted. Confirmed live in this session's device verification pass.
  - `INDEX.md` said `SyncInbox`/`ConflictLog`/`CommunityTemplate` schemas were NOT registered in `IsarService._schemas` — false, all three (plus `GuestProfile`) are registered.
  - `INDEX.md`'s model file table was missing `BarIngredient`, `PantryIngredient`, `GuestProfile` entries.
  - `risks.md` still referenced the pre-move `lib/sisu_mate_theme.dart` path.
- Verification: `flutter analyze` zero issues, `flutter test` 376/376 pass, `flutter build apk --debug` succeeds, and live-verified on a physical Samsung SM-S928U1 (Android 16) via adb — created a plan, assigned a recipe, generated and copied a provision list, confirmed the protein/consolidated split and guest-count scaling render correctly.

## [2026-07-03] — Chef's Corner: dietary badges, leftover ideas, seasonal highlights, guest profiles (CF4/CF8/CF9/CF5)

- Files changed in project:
  - `lib/ui/menus/menus_screen.dart` — `_RecipeCard` derives `dietaryBadges` via intersection of matched non-garnish pantry ingredients' `dietaryTags`, rendered as a `_MiniChip` row (CF4); `_RecipeDetailScreen` adds a "Got Leftovers? Get Ideas" button calling `_showLeftoverIdeas()`, which runs `MixologistService.suggestDish()` against current pantry and shows the result in a `DraggableScrollableSheet` (CF8); `_ChefTabState` shows an "In season now" banner sourced from `SeasonalService.getInSeasonNow()` (CF9); `_ChefTabState` adds a "Load Profile" button next to the allergen header that opens a bottom sheet listing `guestProfilesProvider` profiles (tap to pre-fill `_allergenRestrictions`/`_dietaryRequirements`) with a "Manage Profiles" row navigating to `GuestProfilesScreen` (CF5)
  - `lib/services/seasonal_service.dart` — new static service; NH month→ingredient map, SH offset by 6 months via `((m + 5) % 12) + 1`
  - `lib/models/guest_profile.dart` — new Isar collection `GuestProfile` (name, allergenRestrictions, dietaryRequirements, createdAt); local-only, not synced
  - `lib/models/models.dart` — added `part 'guest_profile.dart';`
  - `lib/services/isar_service.dart` — registered `GuestProfileSchema` in `_schemas`
  - `lib/domain/repositories/guest_profile_repository.dart` + `lib/data/repositories/guest_profile_repository_impl.dart` — new repository (watch/add/update/delete), alphabetical sort, standard `writeTxn`/`buildQuery().findAll()` pattern
  - `lib/core/di.dart` — added `guestProfileRepositoryProvider` and `guestProfilesProvider`
  - `lib/ui/menus/guest_profiles_screen.dart` — new screen: list + add/edit/delete dialog for guest profiles (allergen + dietary chip pickers)
- Context files updated: `data_models.md` (added `GuestProfile` model section, `guestProfileRepositoryProvider`/`guestProfilesProvider` rows), `outstanding.md` (removed CF4/CF5/CF8/CF9; updated CF24 to reference `GuestProfile` as done), `changelog.md`
- New risks introduced: none
- Removed/deprecated: none
- Verification: `flutter analyze` zero issues, `dart run build_runner build` clean, `flutter build apk --debug` succeeds, `flutter test` 370/370 pass

## [2026-07-03] — Moved `lib/sisu_mate_theme.dart` to `lib/core/theme.dart`

- Files changed in project:
  - `lib/core/theme.dart` — new file (moved from `lib/sisu_mate_theme.dart`), same content, imports updated to co-locate with `colors.dart` and `di.dart`
  - `lib/main.dart`, `lib/ui/settings/settings_screen.dart`, `lib/ui/startup/startup_screen.dart` — import path updated to `core/theme.dart`
- Context files updated: `INDEX.md` (3 stale `sisu_mate_theme.dart` references fixed, incl. Key File Locations), `data_models.md` (`themeModeProvider` file column), `CLAUDE.md` (Key File Locations table), 4 game `gameflow.md` files, `changelog.md`
- New risks introduced: none
- Removed/deprecated: `lib/sisu_mate_theme.dart` (moved, not duplicated)

## [2026-07-03] — Full UI consistency pass: swipe direction, tile styles, colors, leading sizes

- Files changed in project:
  - `lib/ui/components/swipeable_list_item.dart` — swapped pane directions (RIGHT=constructive, LEFT=destructive), replaced `Color(0xFF40e0d0)` and `Colors.green` with `SisuColors.completedBackground`
  - `lib/ui/checklists/check_page_viewer.dart` — completion badge uses `SisuColors.completedBackground/incompleteBackground`, Hide button uses `SisuColors.hiddenBackground`, detail modal status row uses SisuColors, Close button uses `SisuColors.incompleteBackground`
  - `lib/ui/checklists/item_detail_screen.dart` — completion icon/text colors, FAB uses `SisuColors.completedBackground/hiddenBackground`, Pro-gate icons use `SisuColors.incompleteBackground`
  - `lib/ui/menus/menus_screen.dart` — allergen row uses `colorScheme.error`, Track action uses `SisuColors.completedBackground`, `_PantryIngredientTile` panes swapped + `isThreeLine: true` + textTheme + price badge SisuColors, `_PantryIngredientAvailabilityTile` `isThreeLine: true` + textTheme, `Colors.grey` leading icons → `SisuColors.incompleteBackground`
  - `lib/ui/cocktails/cocktails_screen.dart` — `_BarIngredientTile` wrapped in `Card`, panes swapped, `Color(0xFF40e0d0)` → `SisuColors.completedBackground`, `isThreeLine: true`, textTheme titles, `Colors.grey` → `colorScheme.outline`/`SisuColors.incompleteBackground`; `_IngredientAvailabilityTile` `isThreeLine: true` + textTheme + `colorScheme.outline`
  - `lib/ui/shopping/shopping_screen.dart` — tile title/subtitle use textTheme
  - `lib/ui/maintenance/maintenance_items_screen.dart` — leading 60→40, title/subtitle textTheme, drawer header `primaryColor` → `colorScheme.surfaceContainerHighest`
  - `lib/ui/safety/safety_briefing_screen.dart` — leading 60→40, title/subtitle textTheme, drawer header `primaryColor` → `colorScheme.surfaceContainerHighest`, `_buildItemImage` 60→40
  - `lib/ui/logbook/logbook_screen.dart` — added leading book icon + textTheme for title/subtitle, lock icon uses `colorScheme.outline`
- Context files updated: `changelog.md`
- New risks introduced: None
- Removed/deprecated: `Color(0xFF40e0d0)` turquoise eliminated from codebase

## [2026-07-03] — Unified SisuColors status palette across all non-game screens

- Files changed in project: `lib/ui/maintenance/maintenance_items_screen.dart`, `lib/ui/checklists/item_detail_screen.dart`, `lib/ui/cocktails/cocktails_screen.dart`, `lib/ui/menus/menus_screen.dart`
- Semantic mapping applied consistently:
  - completed / in-bar / in-pantry / in-shopping → `SisuColors.completedBackground` (#006666 teal)
  - incomplete / pending / market item / not-tracked → `SisuColors.incompleteBackground` (#546e7a blue-grey)
  - garnish / hidden / optional → `SisuColors.hiddenBackground` (#37474f dark blue-grey)
  - missing / not-in-bar / not-in-pantry / expired → `SisuColors.notAvailableBackground` (#cc0000 dark red)
  - hidden item text → `SisuColors.hiddenText`; completed item text → `SisuColors.completedText`
- Kept as-is (non-status): `Colors.amber` for star ratings, `Colors.orange[700]` for substitute/allergen/method labels, `Colors.orange` for expiry ≤7d warning, `Colors.grey[200/300]` for image placeholder surfaces, `Colors.grey` for secondary/footer text, `Colors.red` on destructive action buttons
- Context files updated: `changelog.md`
- New risks introduced: none

---

## [2026-07-03] — Bar/Chef outstanding issues: CF27, CF14, CF7, CF10, CF26

- Files changed in project: `lib/ui/menus/menus_screen.dart`, `lib/services/mixologist_service.dart`, `lib/ui/cocktails/cocktails_screen.dart`
- CF27 fixed: `childAspectRatio` lowered from 0.75 → 0.65; `Spacer()` → `SizedBox(height:4)` in `_RecipeCard` to eliminate bottom overflow
- CF14 done: `suggestDish()` score function gives +100 boost to pantry ingredients expiring within 7 days; "Use soon" amber banner in Chef's Corner shows expiring items sorted by date
- CF7 done: recipe detail watches `pantryIngredientsProvider`; computes sum of `lastKnownPrice` across matched ingredients × servings; displays "Est. cost" row below ingredient list when any prices are set
- CF10 done: static `_cuisineCocktailKeywords` map (10 cuisines); recipe detail shows "Pairs well with" chip row using `recipesProvider('cocktail')` filtered by keyword match on `recipe.cuisine`
- CF26 done: `AddEditRecipeDialog` now shows Cuisine + Cooking method `DropdownButtonFormField` when `recipeType == RecipeType.menu`; values wired into `_save()` as `..cuisine` / `..cookingMethod`
- Context files updated: `outstanding.md` (removed CF27, CF14, CF7, CF10, CF26), `changelog.md`
- New risks introduced: none

---

## [2026-07-03] — Add left-swipe "Track" to market pantry ingredients in Chef screen

- Files changed in project: `lib/ui/menus/menus_screen.dart`
- Change: `_PantryIngredientAvailabilityTile` `endActionPane` now always rendered; for catalog items (`existsInSeed`) shows "In Pantry"/"Remove" toggle as before; for market items (`!existsInSeed`) shows a teal "Track" action that creates a custom `PantryIngredient` with `inMyPantry = true, isBundled = false`
- Context files updated: `changelog.md`
- New risks introduced: none

---

## [2026-07-03] — Add CF27 bug: recipe card bottom overflow in Chef grid

- Files changed in project: none
- Context files updated: `.ai_context/outstanding.md` (added CF27)
- New risks introduced: none
- Note: `_RecipeCard` in `lib/ui/menus/menus_screen.dart` overflows at bottom due to too many widgets in fixed `childAspectRatio: 0.75` cells

---

## [2026-07-03] — Fix banner ad overlapping title bar on home screen

- Files changed in project: `lib/ui/home/home_screen.dart`
- Root cause: `BannerAdWidget` was a sibling child in a `Stack` with no `Positioned` wrapper, so it defaulted to top-left, overlapping the `TitleTile`
- Fix: replaced `Stack` with a plain `Column`; `BannerAdWidget` is now the last child — it renders at the bottom, below the grid, never overlapping anything
- Context files updated: `changelog.md`
- New risks introduced: none

---

## [2026-07-03] — Home screen 3-column grid + tile reorder

- Files changed in project: `lib/ui/home/home_screen.dart`
- `crossAxisCount` changed from 2 → 3; padding/spacing tightened (12/10px); `_AppTile` icon 48→36, text `titleMedium`→`bodySmall` 11pt bold with `maxLines: 2`
- New tile order: Shopping · Cocktails · Chef | Safety · Checklists · Maintenance | Captain's Log · Fuel & Water · Inventory | Crew & Contacts · Documents · Community | Games
- Context files updated: `changelog.md`
- New risks introduced: none
- Removed/deprecated: none

---

## [2026-07-03] — CF26 cuisine/method filter, CF14 expiry tracking, CF4 allergen badges, CF3 cooking mode

- Files changed in project:
  - `lib/models/recipe.dart`: added `cuisine String?`, `cookingMethod String?`
  - `lib/models/pantry_ingredient.dart`: added `expiryDate DateTime?`
  - `lib/models/models.g.dart`: regenerated (build_runner)
  - `lib/data/seed/seed_recipes.dart`: all 10 food menus seeded with `cuisine` and `cookingMethod` values
  - `lib/ui/menus/menus_screen.dart`:
    - **CF26**: `_MenusTab` converted to `ConsumerStatefulWidget`; two scrollable filter chip rows added (cuisine + cooking method + ≤20/≤45 min time filter); `_RecipeCard` updated with cuisine (teal) + cookingMethod (orange) mini-chips; card aspect ratio adjusted to 0.75 to fit extra content
    - **CF4**: `_RecipeCard` watches `pantryIngredientsProvider` + `recipeIngredientsProvider`; derives allergen union from matching pantry ingredients; shows red warning row (up to 3 allergen names) at bottom of card
    - **CF14**: `PantryIngredient.expiryDate` field; `_ExpiryBadge` widget added (green ≥7d, amber <7d, red = expired); badge shown in `_PantryIngredientTile` subtitle; `_PantryIngredientEditDialogState` gets `_expiryDate DateTime?` field, date picker row (Set date / Clear), and wires into `_save()` for both create and update paths
    - **CF3**: `_CookingModeScreen` added — parses `instructions` by `. ` / newline split into discrete steps; full-screen card-per-step with progress bar, step counter, previous/next navigation; per-step countdown timer (enter minutes → play/stop); "Cook" `FilledButton.icon` added to instructions header in `_RecipeDetailScreen`
    - `_MiniChip` helper widget added for cuisine/method badges
- Context files updated: `changelog.md`, `outstanding.md`
- New risks introduced: none
- Removed/deprecated: CF3 (resolved), CF26 (partially resolved — AddEditRecipeDialog cuisine/method entry remains as low-priority remainder), CF14 (partially resolved — Chef's Corner expiry-sort remains)

---

## [2026-07-03] — Garnish notes, 8 new syrups, 6 new cocktails, shopping bag indicator, market-item left-swipe

- Files changed in project:
  - `lib/models/recipe_ingredient.dart`: added `garnishNotes String?` field
  - `lib/models/models.g.dart`: regenerated (build_runner)
  - `lib/data/seed/seed_recipes.dart`:
    - `addCocktail()` helper: new `garnishNotes` named param wired to `..garnishNotes`
    - All 10 existing cocktails: garnish ingredients updated with descriptive `garnishNotes`; 5 cocktails that lacked garnishes (Zombie, Navy Grog, Suffering Bastard, Fog Cutter, Scorpion Bowl, Beachbum's Own) given appropriate new garnish ingredients with notes
    - 6 new cocktails seeded: Jet Pilot, Jungle Bird, Saturn, Test Pilot, Doctor Funk, Cobra's Fang — each with full ingredient list and garnish notes
    - 8 new house syrups seeded: Honey Syrup, Passion Fruit Syrup, Fresh Coconut Cream, Don's Spices #2, Gardenia Mix, Don's Mix #2, Hibiscus Grenadine, Macadamia Nut Orgeat
    - `seededCocktailIds` and `seededSyrupIds` constants updated to include all new IDs
  - `lib/ui/cocktails/cocktails_screen.dart`:
    - `_IngredientAvailabilityTile`: garnish tile shows `garnishNotes` in grey italic below status text
    - `_IngredientAvailabilityTile` trailing: shopping bag icon — `Icons.shopping_bag` green when item is in shopping list; `Icons.shopping_bag_outlined` grey otherwise (watches `shoppingItemNamesProvider`)
    - `_IngredientAvailabilityTile` endActionPane: always shown — for catalog ingredients toggles `inMyBar`; for market items (not in seed) creates a custom `BarIngredient` with `inMyBar = true` and `isBundled = false` via `addBarIngredient()`
  - `lib/ui/menus/menus_screen.dart`:
    - `_PantryIngredientAvailabilityTile` trailing: same shopping bag indicator (watches `shoppingItemNamesProvider`)
  - `lib/domain/repositories/shopping_repository.dart`: added `watchAllItemNames()` to abstract interface
  - `lib/data/repositories/shopping_repository_impl.dart`: implemented `watchAllItemNames()` returning reactive `Set<String>` of non-hidden item names (lowercased)
  - `lib/core/di.dart`: added `shoppingItemNamesProvider = StreamProvider<Set<String>>`
- Context files updated: `changelog.md`, `data_models.md`
- New risks introduced: none
- Removed/deprecated: none

---

## [2026-07-03] — Bar UI fixes: tab visibility, servings wrapping, substitute display

- Files changed in project:
  - `lib/ui/cocktails/cocktails_screen.dart`:
    - UI2: `TabBar` → `isScrollable: true`, `tabAlignment: TabAlignment.start` — all 4 tab labels now fully visible
    - UI1: `SegmentedButton` servings: labels simplified to plain numbers ("1","2","4","12"), `showSelectedIcon: false` — no more text wrapping
    - UI3: `_IngredientAvailabilityTile` subtitle — when ingredient exists in bar catalog but not stocked, now shows "Sub: X or Y" in orange italic from `BarIngredient.substitute1/2` (previously only `RecipeIngredient.substitute` was checked, which is almost always null)
  - `lib/ui/menus/menus_screen.dart`:
    - UI1: same `SegmentedButton` fix applied to food recipe detail (labels "1","2","4","6","10", `showSelectedIcon: false`)
- Context files updated: `changelog.md`
- New risks introduced: none
- Removed/deprecated: none

---

## [2026-07-03] — CF20 + CF22 + CF6: food recipe swipe actions, pantry camera, serving scaler

- Files changed in project:
  - `lib/models/pantry_ingredient.dart` — added `localPhotoPath String?` field (CF22)
  - `lib/models/models.g.dart` — regenerated by build_runner
  - `lib/ui/menus/menus_screen.dart`:
    - CF20: `_PantryIngredientAvailabilityTile` now wraps non-garnish rows in `Slidable`; right-swipe → add to Shopping (Pantry section), left-swipe → toggle in-pantry
    - CF6: `_RecipeDetailScreenState` gains `int _servings`; `SegmentedButton<int>` (1×/2×/4×/6×/10×) above ingredients; quantities scaled via `servingsMultiplier` on tile
    - CF22: `_PantryIngredientEditDialogState` gains `_localPhotoPath`, `_pickPhoto()`, photo preview + Camera/Gallery buttons; `_save()` writes `localPhotoPath`; `_PantryIngredientTile` leading shows `Image.file` before `imageUrl` fallback
    - Added imports: `dart:io`, `package:image_picker/image_picker.dart`
- Context files updated: `outstanding.md` (BC19, CF20, CF22, CF6 removed), `changelog.md`
- New risks introduced: none
- Removed/deprecated: BC19 (was already implemented in cocktails_screen.dart — confirmed in code review)

---

## [2026-07-03] — Fix cocktails drawer + add delete for custom recipes

- Files changed in project:
  - `lib/ui/cocktails/cocktails_screen.dart`:
    - Wrapped `SafeArea` child `Column` in `Builder` so `Scaffold.of(context)` resolves to the correct inner context — fixes drawer not opening on the Cocktails screen.
    - Added "Delete recipe" outlined button at the bottom of `_RecipeDetailScreen` scroll content, shown only when `!recipe.isBundled`. Includes confirm dialog. Navigates back after deletion.
    - Added `_confirmDelete()` method to `_RecipeDetailScreenState` using `recipeRepositoryProvider.deleteRecipe()`.
- Context files updated: `changelog.md`, `outstanding.md` (RT1/RT2 runtime issues added)
- New risks introduced: none
- Removed/deprecated: none

---

## [2026-07-03] — Dependency upgrade to latest compatible versions

- Files changed in project:
  - `pubspec.yaml`:
    - `flutter pub upgrade` applied — 81 packages updated to latest within constraints
    - `purchases_flutter`/`purchases_ui_flutter` constrained to `>=9.10.0 <9.11.0` (resolves to 9.10.8); 9.11–9.16 fail to compile with Kotlin 2.1.0 due to `MapHelper` reference removed from RevenueCat Android SDK and a type-inference breaking change
    - `bonsoir` intentionally held at 6.x (7.x has a breaking mDNS discovery API change)
    - `google_mobile_ads` held at 5.3.1 (9.x has sweeping API changes affecting `BannerAd`, `InterstitialAd`, `AdRequest` wrappers in `admob_service.dart`)
  - `android/app/build.gradle.kts` — `ndkVersion` bumped `27.0.12077973 → 28.2.13676358` (required by `jni 1.0.0`, a new transitive dep from `mobile_scanner`)
  - `android/settings.gradle.kts` — AGP `8.7.3 → 8.9.1` (already done for BC8/mobile_scanner; retained)
  - `lib/main.dart` — `anonKey:` → `publishableKey:` in `Supabase.initialize()` (deprecated in supabase_flutter 2.15.4)
  - `lib/models/models.g.dart` — regenerated with isar_community_generator 3.3.2
- Key version changes:
  - `flutter_riverpod` 3.0.3 → 3.3.2
  - `isar_community` / `isar_community_flutter_libs` / `isar_community_generator` 3.3.0 → 3.3.2
  - `supabase_flutter` 2.10.3 → 2.15.4
  - `connectivity_plus` 7.0.0 → 7.2.0
  - `build_runner` 2.7.1 → 2.15.0
  - `purchases_flutter` / `purchases_ui_flutter` 9.10.0 → 9.10.8
  - `path_provider` 2.1.5 → 2.1.6
  - `shared_preferences` 2.5.3 → 2.5.5
  - `intl` 0.20.2 → 0.20.3
  - `uuid` 4.5.2 → 4.5.3
- Context files updated: `outstanding.md` (build verification updated), `changelog.md`
- New risks introduced: NDK 28.x is a new requirement; if any other plugin pins NDK <28, a conflict will arise. `purchases_ui_flutter 9.11–9.16` are blocked until RevenueCat ships a Kotlin 2.1-compatible release.
- Removed/deprecated: `build_resolvers`, `build_runner_core`, `code_builder`, `timing` (all discontinued, removed from transitive deps by build_runner 2.15.0)

---

## [2026-07-03] — BC21 bar ingredient camera, BC7 Build a Round, BC8 barcode scanner

- Files changed in project:
  - `pubspec.yaml` — added `image_picker: ^1.1.2` and `mobile_scanner: ^7.0.1`
  - `android/settings.gradle.kts` — bumped AGP `8.7.3 → 8.9.1` (required by mobile_scanner's AndroidX dependencies)
  - `android/app/src/main/AndroidManifest.xml` — added `CAMERA`, `READ_MEDIA_IMAGES` permissions and camera hardware feature (not required)
  - `ios/Runner/Info.plist` — added `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`
  - `lib/models/bar_ingredient.dart` — added `String? localPhotoPath` (priority over `imageUrl` in display)
  - `lib/models/models.g.dart` — regenerated by build_runner
  - `lib/services/barcode_service.dart` (NEW) — offline UPC lookup table for ~35 common bar spirits; `BarcodeService.lookup(barcode)` returns `BarcodeMatch?` with `bottleName`, `suggestedIngredientName`, `category`, `abv`
  - `lib/ui/cocktails/cocktails_screen.dart`:
    - **BC21**: `_IngredientLeading` now shows `localPhotoPath` (via `Image.file`) before `imageUrl` fallback; `_BarIngredientEditDialog` gains a 100×100 photo preview with camera + gallery `_PhotoActionButton`s, a barcode scan `IconButton` beside the name field, and `_localPhotoPath` wired through `_save()`
    - **BC8**: `_BarcodeScannerScreen` — full-screen `MobileScanner` with white overlay frame, pops the scanned barcode string; `_scanBarcode()` calls `BarcodeService.lookup()` and pre-fills ingredient name on match, shows a SnackBar for both match and no-match cases
    - **BC7**: `_BatchScreen` ConsumerStatefulWidget — cocktail picker (`InputDecorator` + `DropdownButton<Recipe>`), +/− count stepper (1–50), scaled ingredient list via `_BatchIngredientRow`; `_formatQty()` reused for scaled amounts; entry point: "Build a Round" `OutlinedButton` in every recipe detail screen
- Context files updated: `outstanding.md` (BC7/BC8/BC21 removed), `changelog.md`
- New risks introduced: AGP upgrade to 8.9.1 — other AGP-sensitive plugins should be retested after this bump. `mobile_scanner` uses the device camera; if camera is unavailable (simulator), `_BarcodeScannerScreen` will fail gracefully (no crash, just no scan).
- Removed/deprecated: none

---

## [2026-07-03] — BC23 sort cocktails by availability

- Files changed in project:
  - `lib/ui/cocktails/cocktails_screen.dart`:
    - `_CocktailsScreenState`: renamed `_almostThereOnly` → `_sortByAvailability`
    - `_CocktailsTab`: renamed params `almostThereOnly/onAlmostThereChanged` → `sortByAvailability/onSortByAvailabilityChanged`; replaced "Almost there" FilterChip with "Sort by availability" chip (`Icons.sort`); when sort active, groups filtered recipes into three flat-list buckets (0 missing = "Can make now", 1 missing = "Almost there", 2+ = "Need ingredients") with `_SectionDivider` labels showing counts; when inactive, renders plain list as before
    - Added `_SectionDivider` top-level `StatelessWidget` — labelled row with inline divider line
- Context files updated: `outstanding.md` (BC23 removed), `changelog.md`
- New risks introduced: none
- Removed/deprecated: "Almost there" filter chip removed — replaced by the richer sort toggle

---

## [2026-07-03] — BC26 overflow fix, BC12 tasting log, BC24 substitute hierarchy

- Files changed in project:
  - `lib/ui/cocktails/cocktails_screen.dart`:
    - BC26: wrapped `SegmentedButton` (1×/2×/4×/Party) in `Expanded()` to fix right-side overflow
    - BC12: added `TastingRecord` embedded list display in recipe detail — tasting log header, average star rating row, records list (newest first), "Add tasting note" button; `_showAddTastingDialog()` method; `_StarRow` top-level StatelessWidget; `_AddTastingDialog` StatefulWidget with rating + location + notes fields
    - BC24: `_IngredientAvailabilityTile` now detects substitute coverage — if any stocked bar ingredient's `substitute1`/`substitute2` matches the recipe ingredient name, shows teal + `Icons.swap_horiz` + "Via: {ingredient name}"; "Try:" hint suppressed when covered via substitute
  - `lib/models/tasting_record.dart` (NEW) — `@embedded` class with `tastedAt DateTime?`, `location String?`, `notes String?`, `rating int = 3`
  - `lib/models/models.dart` — added `part 'tasting_record.dart';`
  - `lib/models/recipe.dart` — added `List<TastingRecord> tastingLog = [];`
  - `lib/models/bar_ingredient.dart` — added `String? substitute1` and `String? substitute2`
  - `lib/models/pantry_ingredient.dart` — added `String? substitute1` and `String? substitute2`
  - `lib/models/models.g.dart` — regenerated (build_runner × 2 runs)
  - `lib/data/repositories/recipe_repository_impl.dart` — `syncMissingIngredientCounts()` now builds expanded stocked sets: each stocked ingredient contributes its own name + sub1 + sub2; syrup recipes use bar stocked set (same as cocktail)
  - `lib/data/seed/seed_bar_ingredients.dart` — added `_barSubstitutes` const map (16 chains) + `_syncBarSubstitutes()` which always runs on startup to safely patch existing installs without touching `inMyBar`; first-install path seeds substitutes inline
- Context files updated: `outstanding.md` (BC26/BC12/BC24 removed), `changelog.md`
- New risks introduced: `_syncBarSubstitutes()` runs on every startup — O(n) over all bar ingredients but negligible at seed scale. Substitutes only affect the `missingIngredientCount` sort heuristic; they do not change what the user can or cannot buy.
- Removed/deprecated: none

---

## [2026-07-02] — BC25 seed accuracy, BC19 ingredient swipe actions, BC22 Syrups & House Mixes tab

- Files changed in project:
  - `lib/data/seed/seed_bar_ingredients.dart` — added Peach Brandy entry (BC25)
  - `lib/data/seed/seed_recipes.dart`:
    - BC25: fixed Zombie (Grapefruit Juice + Cinnamon Syrup + Grenadine + Velvet Falernum replacing Pineapple/Papaya); fixed Three Dots and a Dash (added Aged Blended Rum, Velvet Falernum, Allspice Dram, correct garnishes); fixed Missionary's Downfall (completely rewritten with Peach Brandy, Honey Syrup, Pineapple Juice, Fresh Mint)
    - BC22: added 6 syrup/house-mix Recipes + ingredients: Demerara 2:1, Cinnamon Syrup, House Orgeat, House Velvet Falernum, House Grenadine, Don's Mix #1; stale purge extended to seededSyrupIds
  - `lib/data/seed/bundled_data_seeder.dart` — moved `seedRecipes()` outside the checklist guard so it re-runs on every startup (stale purge inside it makes this idempotent) (BC25)
  - `lib/models/recipe.dart` — added `syrup` to `RecipeType` enum (BC22)
  - `lib/ui/cocktails/cocktails_screen.dart`:
    - BC19: `_IngredientAvailabilityTile` wrapped in `Slidable`; right-swipe → add to shopping via `_addSingleToShopping()`; left-swipe → toggle in-bar via `barIngredientRepositoryProvider.toggleInMyBar()` (only shown when `existsInSeed`); garnishes skip Slidable entirely
    - BC22: TabController length 3→4; 4th "House" tab with `Icons.science`; `_SyrupsTab` widget (list of syrup recipes → reuses `_RecipeDetailScreen`); FAB wired for tab index 3 → `_showAddSyrupDialog()`; `_showEditDialog` and `AddEditRecipeDialog` updated for `RecipeType.syrup`
- Context files updated: `outstanding.md` (BC19/BC22/BC25 removed), `changelog.md`
- New risks introduced: `seedRecipes()` now runs on every startup — if a future change corrupts seeded recipe data, all users will be affected on next launch. Mitigated by the stale-purge-then-reinsert pattern which is idempotent.
- Removed/deprecated: none

---

## [2026-07-02] — BC2 cocktail scaling, BC4 add-missing-to-shopping, BC9 cocktail of the day, BC13 food pairings, BC14 occasion filters

- Files changed in project:
  - `lib/providers/recipe_provider.dart` — added `dailyCocktailProvider` (BC9: day-of-year deterministic pick from cocktail list)
  - `lib/services/mixologist_service.dart` — added `_spiritFoodPairings` map, `foodPairings()` static method, `occasionVibes` const map (BC13, BC14)
  - `lib/ui/cocktails/cocktails_screen.dart`:
    - BC2: `_servings` state + `SegmentedButton<int>` (1×/2×/4×/Party) in cocktail detail; `_formatQty()` top-level helper; `_IngredientAvailabilityTile` gains `servingsMultiplier` param
    - BC4: `_addMissingToShopping()` on `_RecipeDetailScreenState`; `OutlinedButton` shown below ingredient list when `missingIngredientCount > 0`; adds a `ShoppingItem` per missing non-garnish non-optional ingredient
    - BC9: `_FeaturedCocktailBanner` widget tapping into `dailyCocktailProvider`; shown as first child of `_CocktailsTab` column
    - BC13: "Pairs well with" `Chip` row in `_CocktailSuggestionCard` after the rationale block
    - BC14: `_selectedOccasion` state + occasion `FilterChip` row in `_MixologistTab`; occasion vibes merged into `_generate()` call
- Context files updated: `outstanding.md` (BC2/BC4/BC9/BC13/BC14 removed), `changelog.md`
- New risks introduced: none
- Removed/deprecated: none

---

## [2026-07-02] — BC5 favourites, BC6 glassware, BC15 barman's tale, CF2 prep/cook time, F19 dead code removal

- Files changed in project:
  - `lib/models/recipe.dart` — added 5 fields: `isFavourite bool`, `glassware String?`, `prepMinutes int?`, `cookMinutes int?`, `story String?`
  - `lib/models/models.g.dart` — regenerated
  - `lib/data/seed/seed_recipes.dart` — seeded `glassware`, `prepMinutes`, `story` for all 10 cocktails; `prepMinutes` + `cookMinutes` for all 10 menus
  - `lib/ui/cocktails/cocktails_screen.dart`:
    - BC5: heart `IconButton` on `_RecipeTile` toggles `isFavourite` via `updateRecipe`; "Favourites" `FilterChip` added alongside "Almost there"
    - BC6: glassware row (wine_bar icon) shown in cocktail detail above Technique chips
    - BC15: "Barman's Tale" amber-tinted quote block shown in cocktail detail after instructions
  - `lib/ui/menus/menus_screen.dart`:
    - CF2: prep/cook time row on `_RecipeCard` ("25m prep · 20m cook"); Prep/Cook `Chip`s in `_RecipeDetailScreen` after description
  - `lib/services/conflict_resolution_service.dart` — deleted (F19: dead code, never instantiated)
- Context files updated: `changelog.md`, `outstanding.md`
- New risks introduced: none
- Removed/deprecated: `ConflictResolutionService`

---

## [2026-07-02] — BC1 Almost there filter, BC3 substitute hints, BC10 technique cards

- Files changed in project:
  - `lib/ui/cocktails/cocktails_screen.dart` — three changes:
    - BC1: `_CocktailsTab` gains "Almost there" `FilterChip`; filters to recipes where `missingIngredientCount <= 1` when selected
    - BC3: `_IngredientAvailabilityTile` subtitle shows `'Try: {substitute}'` in grey italic when ingredient is not in bar and `RecipeIngredient.substitute` is set
    - BC10: `_RecipeDetailScreen` gains a Technique row with three tappable `ActionChip`s (Shake / Stir / Build); tapping opens a `showModalBottomSheet` with equipment, numbered steps, and tips via top-level `_showTechniqueSheet()`
- Context files updated: `changelog.md`, `outstanding.md`
- New risks introduced: none
- Removed/deprecated: none

---

## [2026-07-02] — Seed normalization, ingredient sync, three-state color, CSV export, Chef rename

- Files changed in project:
  - `lib/data/seed/seed_recipes.dart` — complete rewrite: stale-ingredient purge on each run, all cocktail names normalized to bar-seed canonical names, all menu names normalized to pantry-seed canonical names
  - `lib/data/seed/seed_bar_ingredients.dart` — added `Orange Curaçao`, `Papaya Juice`, `Pineapple Syrup`
  - `lib/data/seed/seed_pantry_ingredients.dart` — added 13 new galley/Asian ingredients: Pineapple, Mango, Cherry Tomatoes, Asparagus, Macadamia Nuts, Thai Basil, Lemongrass, Galangal, Mirin, Dashi Stock, Fresh Tofu, Palm Sugar, Dry White Wine
  - `lib/models/recipe.dart` — added `missingIngredientCount int` field (default 0)
  - `lib/models/models.g.dart` — regenerated after `missingIngredientCount` addition
  - `lib/domain/repositories/recipe_repository.dart` — added `syncMissingIngredientCounts()` to interface
  - `lib/data/repositories/recipe_repository_impl.dart` — implemented `syncMissingIngredientCounts()`: reads all recipes + ingredients + bar/pantry stock, computes missing count per recipe, writes back
  - `lib/data/repositories/bar_ingredient_repository_impl.dart` — `toggleInMyBar()` calls `syncMissingIngredientCounts()` after write; `.trim()` added to name comparison
  - `lib/data/repositories/pantry_ingredient_repository_impl.dart` — `toggleInMyPantry()` calls `syncMissingIngredientCounts()` after write; `.trim()` added to name comparison
  - `lib/core/di.dart` — added `syncIngredientCountsProvider`
  - `lib/ui/components/common_drawer.dart` — `DataManagementSection` gains "Synchronise" tile (calls `syncIngredientCountsProvider`)
  - `lib/ui/cocktails/cocktails_screen.dart` — `_IngredientAvailabilityTile` upgraded to three-state: teal/red/grey + garnish flower icon
  - `lib/ui/menus/menus_screen.dart` — `_PantryIngredientAvailabilityTile` upgraded to three-state; display labels "Menus" → "Chef" (title, tab text, save button, snackbar)
  - `lib/ui/checklists/checklist_items_screen.dart` — Pro-gated "Export to CSV" tile in end drawer; `_handleCsvExport()` handler
  - `lib/ui/home/home_screen.dart` — home tile label "Menus" → "Chef"
  - `lib/ui/onboarding/onboarding_screen.dart` — feature list "Menus" → "Chef"
- Context files updated: `outstanding.md` (BC16–BC18, BC20, CF17–CF19, CF21, F18, FC1 all marked resolved), `changelog.md`
- New risks introduced: none
- Removed/deprecated: none

## [2026-07-02] — Allergen/dietary tags, Chef's Corner tab, expanded pantry seed

- Files changed in project:
  - `lib/models/purchase_record.dart` — NEW `@embedded` class: `price`, `currency`, `place`, `purchaseDate`, `priceUnit`, `notes`
  - `lib/models/bar_ingredient.dart` — NEW fields: `category`, `flavorProfiles`, `alcoholByVolume`, `imageUrl`, `lastKnownPrice`, `priceCurrency`, `lastKnownPriceUnit`, `lastPurchasePlace`, `purchaseHistory`
  - `lib/models/pantry_ingredient.dart` — NEW fields: same as bar plus `cuisineTypes`, `allergenTags`, `dietaryTags`
  - `lib/models/models.dart` — added `part 'purchase_record.dart'`
  - `lib/models/models.g.dart` — regenerated (PurchaseRecordSchema embedded in both BarIngredient and PantryIngredient)
  - `lib/domain/repositories/bar_ingredient_repository.dart` — added `recordPurchase()` method
  - `lib/domain/repositories/pantry_ingredient_repository.dart` — added `recordPurchase()` method
  - `lib/data/repositories/bar_ingredient_repository_impl.dart` — implemented `recordPurchase()`
  - `lib/data/repositories/pantry_ingredient_repository_impl.dart` — implemented `recordPurchase()`
  - `lib/data/seed/seed_bar_ingredients.dart` — rewritten with SC rum taxonomy + tiki ingredients; tuple extended to (name, cat, flavors, abv, price, priceUnit, imageUrl)
  - `lib/data/seed/seed_pantry_ingredients.dart` — rewritten; tuple extended to 11 fields including `allergenTags` and `dietaryTags` for all ~55 ingredients
  - `lib/services/mixologist_service.dart` — NEW service: `MixologistService.suggest()` (cocktails) and `suggestDish()` (food); `suggestDish()` now accepts `allergenRestrictions` and `dietaryRequirements` filter lists; `CocktailSuggestion`, `DishSuggestion`, `SuggestedIngredient` types defined here
  - `lib/ui/cocktails/cocktails_screen.dart` — full rewrite: 3-tab (Cocktails | My Bar | Mixologist), `_BarIngredientTile` shows image/price/flavors, `_BarIngredientEditDialog` with price+imageUrl fields, `_MixologistTab` with vibe chips + `MixologistService.suggest()`, `_CocktailSuggestionCard`, `AddEditRecipeDialog` gains `prefillName`/`prefillInstructions`; all lint issues fixed
  - `lib/ui/menus/menus_screen.dart` — full rewrite: 3-tab (Menus | My Pantry | Chef's Corner), `_PantryIngredientTile` shows image/price/allergens, `_PantryIngredientEditDialog` (ConsumerStatefulWidget) with price+imageUrl+allergen chips+dietary chips, `_ChefTab` with cuisine vibe chips + allergen restriction chips + dietary preference chips + `MixologistService.suggestDish()`, `_DishSuggestionCard`
- Context files updated: `data_models.md` (added PurchaseRecord, expanded BarIngredient/PantryIngredient tables), `INDEX.md` (LLM shelved as future work), `changelog.md`
- New risks: `PurchaseRecord` is `@embedded` — no `Id` field, no schema registration; if model changes require re-gen, run `build_runner`
- Removed/deprecated: none
- Test count: 370 tests, all passing; flutter analyze: zero issues; flutter build apk --debug: success

---

## [2026-07-02] — Bar/Pantry ingredient management + cocktail/menu screen overhaul

- Files changed in project:
  - `lib/models/recipe.dart` — added `recipeType: String` field; added `RecipeType` enum (moved from screen files)
  - `lib/models/bar_ingredient.dart` — NEW: `BarIngredient` Isar collection (name, inMyBar, sortOrder, isBundled)
  - `lib/models/pantry_ingredient.dart` — NEW: `PantryIngredient` Isar collection (name, inMyPantry, quantity, unit, sortOrder, isBundled)
  - `lib/models/models.dart` — added `part 'bar_ingredient.dart'` and `part 'pantry_ingredient.dart'`
  - `lib/models/models.g.dart` — regenerated by build_runner (added BarIngredientSchema, PantryIngredientSchema, RecipeSchema.recipeType)
  - `lib/services/isar_service.dart` — registered `BarIngredientSchema` and `PantryIngredientSchema` in `_schemas`
  - `lib/domain/repositories/bar_ingredient_repository.dart` — NEW domain interface
  - `lib/data/repositories/bar_ingredient_repository_impl.dart` — NEW Isar impl; `recipeNamesForIngredient` scoped to cocktails
  - `lib/domain/repositories/pantry_ingredient_repository.dart` — NEW domain interface
  - `lib/data/repositories/pantry_ingredient_repository_impl.dart` — NEW Isar impl; `recipeNamesForIngredient` scoped to menus
  - `lib/core/di.dart` — added `barIngredientRepositoryProvider`, `pantryIngredientRepositoryProvider`
  - `lib/providers/bar_ingredient_provider.dart` — NEW: `barIngredientsProvider`, `cocktailsForIngredientProvider`
  - `lib/providers/pantry_ingredient_provider.dart` — NEW: `pantryIngredientsProvider`, `menusForIngredientProvider`
  - `lib/providers/recipe_provider.dart` — now typed `List<Recipe>` (was `List<dynamic>`); filter on `recipeType` enabled
  - `lib/data/seed/seed_bar_ingredients.dart` — NEW: ~80 typical bar ingredients (all `inMyBar: false`)
  - `lib/data/seed/seed_pantry_ingredients.dart` — NEW: ~60 pantry staples with quantity/unit
  - `lib/data/seed/seed_recipes.dart` — uncommented `..recipeType` and `..quantity` assignments
  - `lib/data/seed/bundled_data_seeder.dart` — calls `seedBarIngredients` and `seedPantryIngredients` after main txn
  - `lib/ui/cocktails/cocktails_screen.dart` — full rewrite: TabController (Cocktails | My Bar), typed `Recipe`, `_BarIngredientTile` with Slidable (right=toggle inMyBar, left=shopping+delete), `_IngredientAvailabilityTile` uses BarIngredient, removed duplicate `RecipeType` enum, fixed `AddEditRecipeDialog` to use Recipe fields
  - `lib/ui/menus/menus_screen.dart` — full rewrite: TabController (Menus | My Pantry), typed `Recipe`, `_PantryIngredientTile` with Slidable (right=toggle inMyPantry, left=shopping+delete), `_PantryIngredientAvailabilityTile` uses PantryIngredient, removed duplicate `RecipeType` enum, edit dialog includes quantity+unit
  - `lib/ui/paywall/paywall_screen.dart` — fixed bottom overflow: wrapped content `Column` in `SingleChildScrollView`, replaced `Spacer()` with `SizedBox(height: 32)`
- Context files updated: `changelog.md`, `data_models.md`
- New risks introduced: `BarIngredient` and `PantryIngredient` collections registered in `IsarService._schemas`; `seedBarIngredients`/`seedPantryIngredients` have own guards (`count() > 0 return`) so they self-skip on re-init
- Removed/deprecated: `RecipeType` enum removed from both screen files (now canonical in `lib/models/recipe.dart`)

---

## [2026-07-02] — Move gameflow files to game folders + expand test coverage

- Files changed in project:
  - `lib/ui/games/games/backgammon/gameflow.md` — moved from project root `gameflow - Backgammon.md`
  - `lib/ui/games/games/checkers/gameflow.md` — moved from root
  - `lib/ui/games/games/cribbage/gameflow.md` — moved from root
  - `lib/ui/games/games/dudo/gameflow.md` — moved from root
  - `lib/ui/games/games/liars_dice/gameflow.md` — moved from root
  - `lib/ui/games/games/poker/gameflow.md` — moved from root
  - `lib/ui/games/games/solitaire/gameflow.md` — moved from root
  - `lib/ui/games/games/uno/gameflow.md` — moved from root
  - `lib/ui/games/games/yatzy/gameflow.md` — moved from root
  - `test/backgammon_test.dart` — added: passTurn transitions, bearOff guard tests
  - `test/solitaire_test.dart` — added: tapWaste selection, tapFoundation, isWon direct state
  - `test/checkers_test.dart` — added: human move integration (selectCell flow, turn handoff)
  - `test/cribbage_test.dart` — added: playPegCard removes card; playPegCard guard
  - `test/poker_test.dart` — added: playerCheck transitions, newGame reset
  - `test/uno_test.dart` — added: playSelected removes card, playSelected guard
- Context files updated: `.ai_context/INDEX.md` — added 8 new read-next rows for all game gameflow.md paths
- New risks introduced: none
- Removed/deprecated: 9 root-level `gameflow - *.md` files (deleted; content preserved in game folders)
- Test count: 370 tests, all passing; flutter analyze: zero issues

---

## [2026-07-01] — Backgammon/Solitaire bug fixes + AppBar consistency + Liar's Dice state fix

- Files changed in project:
  - `lib/core/di.dart` — added `hintModeProvider` (bool toggle, Notifier-based)
  - `lib/ui/games/games/solitaire/logic.dart` — added `message` field to `SolitaireState`; fixed `tapWaste` (toggle selection, no auto-move); fixed `tapTableau` (preserve waste selection on failed placement, add feedback messages); added `tapFoundation` failure message; added static `computeHint()`; removed unused `_tryMoveToFoundation`
  - `lib/ui/games/games/solitaire/screen.dart` — full rewrite: message/hint bar, scrollable tableau (SingleChildScrollView), AppBar reordered [hint💡, moves, reset↺, rules?]
  - `lib/ui/games/games/backgammon/logic.dart` — added `bearOff()`, `passTurn()` methods; `roll()` now auto-passes if no human moves available after rolling
  - `lib/ui/games/games/backgammon/screen.dart` — fixed triangle direction (`pointsDown: top`); reduced triangle height (0.35→0.27); added ClipRect on piece stacks; Bear Off button (appears when piece selected + bear-off valid); Pass Turn button (appears when no valid moves); score bar uses Expanded for dice row to prevent overflow; message bar limited to maxLines:2; AppBar reordered [reset↺, rules?]
  - `lib/ui/games/games/checkers/screen.dart` — AppBar actions reordered [reset↺, rules?]
  - `lib/ui/games/games/cribbage/screen.dart` — AppBar actions reordered [reset↺, rules?]
  - `lib/ui/games/games/poker/screen.dart` — AppBar actions reordered [reset↺, rules?]
  - `lib/ui/games/games/uno/screen.dart` — AppBar actions reordered [reset↺, rules?]
  - `lib/ui/games/games/yatzy/screen.dart` — AppBar actions reordered [reset↺, rules?]
  - `lib/ui/games/games/liars_dice/screen.dart` — added reset button to AppBar; added `initState` to `_GameplayUIState` to reset stale local providers when widget mounts mid-rollDice phase
  - `lib/ui/games/games/dudo/screen.dart` — added reset button to AppBar
- Context files updated: `changelog.md`
- New risks introduced: none
- Removed/deprecated: `_tryMoveToFoundation` in solitaire/logic.dart

## [2026-07-01] — Help screens wired to all 9 game AppBars

- Files changed in project:
  - `lib/ui/games/components/game_help_screen.dart` — new: `HelpSection`, `GameHelpData`, `GameHelpScreen`, `showGameHelp`
  - `lib/ui/games/components/game_rules_data.dart` — new: rules constants for all 9 games
  - `lib/ui/games/games/backgammon/screen.dart` — added help IconButton to AppBar actions
  - `lib/ui/games/games/checkers/screen.dart` — added help IconButton to AppBar actions
  - `lib/ui/games/games/cribbage/screen.dart` — added help IconButton to AppBar actions
  - `lib/ui/games/games/poker/screen.dart` — added help IconButton to AppBar actions
  - `lib/ui/games/games/solitaire/screen.dart` — added help IconButton to AppBar actions
  - `lib/ui/games/games/uno/screen.dart` — added help IconButton to AppBar actions
  - `lib/ui/games/games/yatzy/screen.dart` — added help IconButton to AppBar actions
  - `lib/ui/games/games/liars_dice/screen.dart` — added actions + help IconButton to AppBar
  - `lib/ui/games/games/dudo/screen.dart` — added actions + help IconButton to AppBar
- Context files updated: `changelog.md`
- New risks: none
- `flutter analyze`: 0 issues; `flutter test`: 350/350 passed; `flutter build apk --debug`: success

---

## [2026-07-01] — Full game unit test suite (all 9 games)

- Files changed in project:
  - `test/dudo_test.dart` — 54 tests: helpers (countBid, isValidRaise, bidToString, faceLabel,
    nextPlayer), data models (DudoPlayer/Bid/GameState), notifier state machine
  - `test/backgammon_test.dart` — board helpers, validHumanMoves, validAiMoves, notifier
  - `test/checkers_test.dart` — getMovesForPiece (simple + jump), getAllMoves, getChainJumps, notifier
  - `test/solitaire_test.dart` — card helpers, initial deal, stock/waste cycling, tableau selection, foundation
  - `test/yatzy_test.dart` — scoreFor (all categories), Scorecard bonus/total, YatzyNotifier flow
  - `test/poker_test.dart` — evaluateHand (all 10 hand ranks), HandResult comparison, PokerNotifier
  - `test/uno_test.dart` — UnoCard.canPlayOn, isWild/isAction, initial deal, selectCard/drawCard/newGame
  - `test/cribbage_test.dart` — scoreHand (fifteens/runs/flush/nobs), scorePegging, faceValue, CribbageNotifier
  - `lib/ui/games/games/dudo/helpers.dart` — added curly braces to if-else in getAIShouldDudo/SpotOn
- Context files updated: `changelog.md`
- Total tests: 350 (all passing)
- New risks: none

---

## [2026-07-01] — Liar's Dice: "Common Hand" rules fixes + ranking card

- Files changed in project:
  - `lib/ui/games/games/liars_dice/logic.dart` — `resolveChallenge`: removed `winnerIndex`;
    challenger now always starts the next round (`currentTurn = state.oppositionPlayer`)
    regardless of whether the challenge succeeded or failed (per "Common Hand" rules)
  - `lib/ui/games/games/liars_dice/screen.dart` — added `_RankingCard` widget and
    `_MiniDie` helper; ranking card appended at the bottom of `_GameplayUI`'s scroll
    view showing all 9 hand ranks with example dice
  - `test/liars_dice_test.dart` — renamed "winner index" test; added new test
    "challenger starts next round even when challenge fails"; total: 111 tests
  - `gameflow - Liars Dice.md` — §6 logic updated (challenger always starts next);
    Challenge Resolution table annotation added; Ranking Card section added
- Context files updated: `changelog.md`
- New risks introduced: none
- Removed/deprecated: `winnerIndex` local variable in `resolveChallenge`

---

## [2026-07-01] — Liar's Dice: one-box variant rules applied

- Files changed in project:
  - `lib/ui/games/games/liars_dice/logic.dart` — `resolveChallenge`: comparator flipped
    from `>= 0` to `<= 0` (overclaiming now penalised, not sandbagging); `advanceFromAcceptReveal`:
    passes shared dice to new declarer (`players[currentTurn].dice` → `players[newDeclarer].dice`)
  - `lib/ui/games/games/liars_dice/screen.dart` — `myDiceProvider` seeded from inherited
    dice on `rollDice` entry; human declarer sees dice before rolling (to enable informed holds)
  - `test/liars_dice_test.dart` — 3 resolveChallenge tests rewritten for one-box rules;
    2 `determineGameOver` helpers updated; 1 new test for shared-dice inheritance (117 total, all pass)
  - `gameflow - Liars Dice.md` — full rewrite: one-box mechanics, correct challenge resolution
    table, `acceptReveal` state added, Implementation Notes corrected (real field names, real paths,
    `dart:io` WebSocket not `web_socket_channel`, Dart enum comparisons not string literals)
- Context files updated: `changelog.md`
- New risks introduced: none
- Removed/deprecated: old PRD sandbagging rule (game now follows standard one-box rules)

---

## [2026-07-01] — Gameflow docs: all 7 games documented

- Files changed in project:
  - `gameflow - Backgammon.md` (new) — 6 states, full encoding conventions, AI priority table
  - `gameflow - Checkers.md` (new) — 5 states, piece encoding, mandatory jump rule, chain jumps, AI priority
  - `gameflow - Cribbage.md` (new) — 5 states, all scoring combinations, pegging go/31, AI discard strategy
  - `gameflow - Poker.md` (new) — 7 states, 5-card draw flow, all PokerPhase values, hand rank table
  - `gameflow - Solitaire.md` (new) — 3 states, 5 sub-states for tap actions, faceDownCounts flip logic
  - `gameflow - Uno.md` (new) — 7 states, 108-card deck composition, 2-player Reverse=Skip rule, AI strategy
  - `gameflow - Yatzy.md` (new) — 6 states, all 13 categories with scoring formulas, AI hold/select strategy
- Context files updated: `changelog.md`
- New risks introduced: none
- Removed/deprecated: none

---

## [2026-07-01] — F1: all 7 stub games implemented

- Files changed in project:
  - `lib/ui/games/games/yatzy/logic.dart` (new) — full Yatzy with scorecard, bonus, AI turn
  - `lib/ui/games/games/yatzy/screen.dart` (new) — scorecard UI, potential scores in green, held dice highlight
  - `lib/ui/games/games/checkers/logic.dart` (new) — 8×8 checkers, mandatory jumps, chain jumps, king promotion, AI heuristic
  - `lib/ui/games/games/checkers/screen.dart` (overwritten) — board via LayoutBuilder, selection/move hints
  - `lib/ui/games/games/solitaire/logic.dart` (new) — Klondike solitaire, stock/waste/foundation/tableau
  - `lib/ui/games/games/solitaire/screen.dart` (new) — card-sized layout, face-down backs, gold selection border
  - `lib/ui/games/games/poker/logic.dart` (new) — 5-card draw poker vs AI, hand evaluation, betting phases
  - `lib/ui/games/games/poker/screen.dart` (new) — AI hand face-down until showdown, discard lift animation
  - `lib/ui/games/games/uno/logic.dart` (new) — full 108-card Uno with action cards, wild, AI opponent
  - `lib/ui/games/games/uno/screen.dart` (new) — color picker overlay, scrollable hand, dimmed non-playable cards
  - `lib/ui/games/games/backgammon/logic.dart` (new) — full backgammon, bar/bearing-off, AI move heuristic
  - `lib/ui/games/games/backgammon/screen.dart` (new) — custom TrianglePainter, 13-col board layout, piece stacks
  - `lib/ui/games/games/cribbage/logic.dart` (new) — 2-player cribbage, pegging (15s/pairs/runs/go/31), hand counting, nobs/nibs, crib
  - `lib/ui/games/games/cribbage/screen.dart` (overwritten) — discard phase, pegging phase, counting phase, game over
- Context files updated: `INDEX.md` (game stub status → fully implemented), `outstanding.md` (F1 resolved, build verification updated), `changelog.md`
- New risks introduced: none
- Removed/deprecated: all 7 "Coming soon" stubs replaced with playable implementations

## [2026-07-01] — Checkers game implemented

- Files changed in project:
  - `lib/ui/games/games/checkers/logic.dart` (new) — full CheckersNotifier + CheckersState + CheckersMove + move generation + mandatory jumps + chain jumps + AI logic
  - `lib/ui/games/games/checkers/screen.dart` (overwritten) — complete game UI: 8×8 board, piece rendering, selection/hint highlighting, game-over overlay, restart button
- Context files updated: `changelog.md`
- New risks introduced: none
- Removed/deprecated: CheckersScreen stub replaced

---

## [2026-06-12] — F9, T1, B7, B8 resolved

- Files changed in project:
  - `lib/ui/onboarding/onboarding_screen.dart` (new) — 4-page PageView onboarding; `hasSeenOnboarding()` / `_markOnboardingSeen()` helpers using SharedPreferences key `onboarding_seen_v1`
  - `lib/ui/startup/startup_screen.dart` — `_goHome()` now checks `hasSeenOnboarding()` and routes to `OnboardingScreen` on first launch
  - `lib/services/revenuecat_service.dart` — `_initFailed` circuit-breaker added; failed init no longer retried on every `isPro()` call
  - `lib/services/sync_service.dart` — `_startQueueMonitor()` moved inside `_init()` after Pro gate; free users never start the 30-second timer
  - `lib/data/repositories/checklist_repository_impl.dart` — `watchItems` and `watchGroups` migrated from `Stream.periodic` to `watchLazy(fireImmediately: true).asyncMap(...)`
  - `lib/data/repositories/shopping_repository_impl.dart` — both `watch*` methods migrated
  - `lib/data/repositories/boat_repository_impl.dart` — `watchBoats` migrated
  - `lib/data/repositories/maintenance_repository_impl.dart` — `watchTasks` migrated
  - `lib/data/repositories/captain_log_repository_impl.dart` — `watchLogs` migrated
  - `lib/data/repositories/recipe_repository_impl.dart` — `watchRecipes` and `watchIngredients` migrated
- Context files updated: `outstanding.md`, `screens.md`, `caching.md`, `changelog.md`
- New risks introduced: none
- Removed/deprecated: `Stream.periodic` polling pattern (fully replaced by `watchLazy`)

---

## [2026-06-12] — Release blockers T2, F13, F3, B5 resolved

- Files changed in project:
  - `lib/main.dart` — removed flutter_dotenv; credentials now via `String.fromEnvironment`
  - `pubspec.yaml` — removed flutter_dotenv dependency; removed `.env` from assets
  - `dart-defines.json` (new, gitignored) — local dev credentials
  - `dart-defines.example.json` (new) — template for new devs
  - `.gitignore` — added `dart-defines.json`
  - `lib/models/community_template.dart` — added `supabaseId` field, `fromJson`, `toJson`
  - `lib/data/repositories/community_repository_impl.dart` — full Supabase implementation; `SyncService` made optional for testability
  - `lib/core/di.dart` — `communityRepositoryProvider` now passes `syncServiceProvider`
  - `lib/ui/community/community_browser_screen.dart` — rewired to real repository; real template list, import, publish dialog, proper paywall for Free users
  - `test/community_repository_test.dart` — updated to construct impl directly; covers all 4 methods' graceful-failure contract
- Context files updated: `outstanding.md`, `data_models.md`
- New risks introduced: Supabase tables `community_templates` and `community_downloads` must be created in the project dashboard before community features are live
- Removed/deprecated: `flutter_dotenv` dependency, `.env` as Flutter asset

---

## [2026-06-09] — Context audit: compare code vs docs, fix all discrepancies

- Files changed in project: none (audit only)
- Context files updated: `caching.md`, `data_models.md`, `access_tiers.md`, `risks.md`, `screens.md`, `INDEX.md`
- Key fixes:
  - `caching.md`: all 15 Isar schemas now listed as registered; removed stale "NOT registered" warnings; fixed theme persistence note; fixed outbox sync wiring note
  - `data_models.md`: `isProProvider` file corrected to `di.dart`; `activeBoatProvider` stub note removed; `SyncOutbox.lastAttemptAt/lastError` caveat removed; `SyncInbox`/`ConflictLog` schema notes updated
  - `access_tiers.md`: entitlement ID `sisu_mate_pro` → `Boat Checks Pro`; product IDs corrected (removed price suffix); API keys noted as real (no longer placeholder); test key in kDebugMode documented; `isPro()` code sample fixed; PaywallScreen restore check fixed
  - `risks.md`: RevenueCat API keys marked resolved; anti-pattern #9 (theme) marked resolved; global state table updated; SyncService upsert JSON issue marked resolved; incoming sync stubs marked resolved; outgoing sync marked resolved
  - `screens.md`: HomeScreen tile count 12→13; Community tile wiring confirmed; SettingsScreen wiring confirmed; nav diagram updated
  - `INDEX.md`: SyncService start location corrected to `startup_screen.dart`; HomeScreen tile count 12→13
- New risks introduced: none
- Removed/deprecated: none

---

## [2026-06-09] — P2 fixes: wire notes/completedAt/photos, showHiddenItems toggle, activeBoatSupabaseId selector

- Files changed in project: `lib/ui/checklists/item_detail_screen.dart`, `lib/ui/checklists/checklist_screen.dart`, `lib/ui/checklists/checklist_items_screen.dart`, `lib/ui/home/home_screen.dart`, `lib/ui/settings/settings_screen.dart`, `lib/ui/boats/boats_screen.dart`
- Context files updated: `outstanding.md` (F10, F11, F12 marked fixed), `changelog.md`
- New risks introduced: none
- Removed/deprecated: `_showHidden` local state in `checklist_items_screen.dart` (replaced with settings-derived value)

---

## [2026-06-09] — P1 fixes: theme persistence, Community tile, Settings nav, activeBoatProvider verified

- Files changed in project: `lib/sisu_mate_theme.dart`, `lib/ui/startup/startup_screen.dart`, `lib/ui/home/home_screen.dart`
- Context files updated: `outstanding.md` (B4, B6, F2, F4 marked resolved), `changelog.md`
- New risks introduced: none
- Self-healing: B6 was stale — `activeBoatProvider` was already correctly implemented

---

## [2026-06-09] — P0 fixes: Isar schemas registered, resetToFactoryDefaults data-loss fix, pre-existing test failures fixed

- Files changed in project: `lib/services/isar_service.dart`, `lib/data/repositories/checklist_repository_impl.dart`, `test/widget_test.dart`, `test/community_repository_test.dart`
- Context files updated: `outstanding.md` (B1, B2 marked stale/resolved; F5, B3 marked fixed), `changelog.md`
- New risks introduced: none
- Removed/deprecated: B1 and B2 were stale — code was already correct when outstanding.md was written
- Self-healing: B1 entry was wrong — `_processOutgoingQueue` already used `jsonDecode`. B2 entry was wrong — all 7 incoming table cases were already implemented.

---

## [2026-06-09] — Remove all scattered TODO comments from source files

- Files changed in project: `lib/ui/checklists/item_detail_screen.dart`, `lib/ui/checklists/checklist_items_screen.dart`, `lib/ui/checklists/checklist_screen.dart`, `lib/ui/home/home_screen.dart`, `lib/ui/settings/settings_screen.dart`, `lib/ui/boats/boats_screen.dart`, `lib/ui/community/community_browser_screen.dart`, `lib/data/repositories/community_repository_impl.dart`, `lib/services/lan/share_lan_service.dart`
- Context files updated: `changelog.md`
- New risks introduced: none
- Removed/deprecated: all `// TODO:` comment lines; deferred work is tracked in `outstanding.md` (F10–F14)

---

## [2026-06-09] — Design gap fixes + gaming text theme

- Files changed in project:
  - `lib/ui/games/games/liars_dice/logic.dart`:
    - **Tie re-roll**: `determineStarter()` now re-rolls only the tied players and recurses until one winner emerges
    - **Disconnect handling**: `_leaveSub` wired in `initHostMode`; `_handleDisconnect(peerId)` removes the player, ends game if < 2 remain, clamps turn indices, broadcasts new state
    - **Dice reveal on accept**: `acceptChallenge(true)` transitions to new `acceptReveal` state instead of jumping straight to `rollDice`; `advanceFromAcceptReveal()` does the cleanup after the 3-second reveal
    - **AI strategy**: `getAIBid()` replaced random pick with hand-aware logic — bids actual evaluated hand first (highest valid face), escalates to better ranks only if honest hand is beaten, falls back to minimum valid bluff; `getAIAccept()` evaluates the AI's dice vs the declared rank and challenges when the declared hand is 3+ rank levels better
    - Added `acceptReveal` to `GameStateEnum`
    - Added `_leaveSub` StreamSubscription field; `exitMultiplayerMode`/`ref.onDispose` cancel it
  - `lib/ui/games/games/liars_dice/screen.dart`:
    - **Gaming text theme**: all containers replaced with `_kOverlay` (black 73% opacity); all text is `Colors.white`; dropdowns use dark background; dice widget uses dark navy background — text is now fully legible against the Viking background
    - Added `_AcceptRevealUI` (ConsumerStatefulWidget, same single-timer pattern) — shows declared vs actual dice side by side for 3 s then advances
    - `_ResolveChallengeUI` upgraded to show Declared / Actual rows (was only showing actual)
    - `getAITieBid()` call updated to `getAIBid()`
    - Scoreboard moved into a named dark card
  - `lib/ui/games/games/liars_dice/gameflow.md` — updated state machine, AI strategy, disconnect section
- Context files updated: `changelog.md`
- New risks introduced: none
- Removed/deprecated: `getAITieBid` (renamed and rewritten as `getAIBid`)

---

## [2026-06-09] — Fix dice randomness + AI timer stacking

- Files changed in project:
  - `lib/ui/games/games/liars_dice/helpers.dart` — `rollDice()` and `rollDiceWithHolds()` now use `dart:math` `Random` (module-level `_rng`); previous implementation used `DateTime.microsecondsSinceEpoch % 6` which produced the same value for all five dice in the same microsecond
  - `lib/ui/games/games/liars_dice/screen.dart` — `_GameplayUI`, `_AcceptChallengeUI`, `_ResolveChallengeUI` converted from `ConsumerWidget` to `ConsumerStatefulWidget`; each state class holds a `_scheduled` (or `_rollScheduled`/`_declareScheduled`) bool that prevents AI auto-action timers from being registered on every rebuild — previously N rebuilds within the 2-second window would fire N duplicate state mutations
- Context files updated: `changelog.md`
- New risks introduced: none
- Removed/deprecated: `DateTime.now().microsecondsSinceEpoch % 6` dice pattern — must never be reused

---

## [2026-06-09] — screen.dart rewrite + gameflow.md + INDEX.md update

- Files changed in project:
  - `lib/ui/games/games/liars_dice/screen.dart` — full rewrite: per-device views (`_isDeclarerMe`/`_isOpponentMe`), `_sendOrApply` action router, fixed `resolveChallenge` bug (was calling `determineGameOver` directly), fixed `finalizeRoll` bug (host commits roll before declaring; client sends roll via `sendMove`), `ref.listen` local state reset between rounds, AI auto-actions gated on `!notifier.isClientMode`, `?` dice shown to non-declarers in multiplayer, waiting messages in multiplayer
  - `lib/ui/games/games/liars_dice/gameflow.md` — NEW: full developer spec (state machine, per-device view rules, action routing, multiplayer setup sequence, auto-advance rules, local state reset, known gaps). Lives alongside the game code (not in .ai_context/) because it is a feature spec, not a codebase navigation aid.
- Context files updated: `INDEX.md` (added gameflow.md pointer to routing table), `changelog.md`
- New risks introduced: none
- Removed/deprecated: broken `player.name == 'You'` heuristic in screen.dart; `determineGameOver` direct call from challenge UI

---

## [2026-06-06] — LAN multiplayer engine + Liar's Dice multiplayer

- Files changed in project:
  - `pubspec.yaml` — added `bonsoir ^6.1.0`
  - `android/app/src/main/AndroidManifest.xml` — added INTERNET, ACCESS_WIFI_STATE, ACCESS_NETWORK_STATE, CHANGE_WIFI_MULTICAST_STATE permissions
  - `ios/Runner/Info.plist` — added NSLocalNetworkUsageDescription + NSBonjourServices (_sisumate._tcp)
  - `lib/services/lan/lan_message.dart` — NEW: wire envelope { channel, type, payload }
  - `lib/services/lan/lan_engine.dart` — NEW: mDNS broadcast/discovery (bonsoir 6.1 API) + WebSocket host/client (dart:io)
  - `lib/services/lan/game_lan_service.dart` — NEW: game protocol: lobby join/leave, state broadcast, client move routing
  - `lib/services/lan/share_lan_service.dart` — NEW: stub for future content sharing
  - `lib/services/lan/lan_providers.dart` — NEW: lanEngineProvider, gameLanServiceProvider, shareLanServiceProvider
  - `lib/ui/games/games/liars_dice/logic.dart` — added toJson/fromJson to GameState/Player/Bid; added initHostMode, initClientMode, isClientMode, _broadcastIfHost, _applyRemoteMove; added localPlayerIdProvider
  - `lib/ui/games/lobby/lobby_screen.dart` — NEW: reusable multiplayer lobby (host/join/scan/wait views)
  - `lib/ui/games/games_screen.dart` — multiplayer toggle now routes through GameLobbyScreen; added isMultiplayerReady badge on tiles
- Context files updated: `INDEX.md` (tech stack, folder structure, nav map, read-next table), `changelog.md`
- New risks introduced:
  - bonsoir uses a sealed-class event API (not enum); always pattern-match on event subtypes, not `.type` strings
  - LanEngine must be disposed when a game session ends — call gameLanService.endSession() in resetGame or on screen pop
  - Android mDNS resolution may fail on some enterprise WiFi networks that block multicast
  - GameState.fromJson / Player.fromJson must be kept in sync with any new fields added to those classes
- Removed/deprecated: none

---

## [2026-06-06] — Migrate Sisu Games into Sisu Mate as Games module

- Files changed in project:
  - **New**: `lib/ui/games/games_screen.dart` (hub screen with 8-game grid + multiplayer toggle)
  - **New**: `lib/ui/games/games/liars_dice/screen.dart` (full game, migrated from original app)
  - **New**: `lib/ui/games/games/liars_dice/logic.dart` (Riverpod 3.x Notifier-based game state)
  - **New**: `lib/ui/games/games/liars_dice/helpers.dart` (pure dice functions)
  - **New**: stub screens for backgammon, checkers, cribbage, poker, solitaire, uno, yatzy
  - **New**: `assets/games/` — all game assets (icons, card images, backgrounds, RuneFont)
  - **Modified**: `pubspec.yaml` — added assets/games/ sections + RuneFont registration
  - **Modified**: `lib/ui/home/home_screen.dart` — added 12th tile "Games" (indigo, Icons.casino)
  - **Removed**: `lib/games/` — original foreign folder fully migrated and deleted
- Context files updated: `INDEX.md`, `screens.md`, `changelog.md`
- New risks introduced:
  - `isMultiplayerProvider` is defined in `games_screen.dart` (not di.dart); game-scoped providers live with their feature files
  - Stub game screens show "Coming soon" — no logic implemented for 7 of 8 games
  - RuneFont (NotoSansRunic) registered but only used if game screens explicitly request it; Sisu Mate theme applies by default
- Removed/deprecated: `lib/games/` (original Sisu Games standalone app folder)

---

## [2026-05-12] — Fix RevenueCat entitlement and product IDs
- Files changed in project: `lib/services/revenuecat_service.dart`
- Context files updated: `risks.md`, `changelog.md`
- New risks introduced: none
- Removed/deprecated: none

---

## [2026-05-12] — Fix sync wiring, activeBoatProvider, and SyncOutbox model
- Files changed in project: `lib/models/sync_outbox.dart`, `lib/models/boat.dart`, `lib/models/checklist_group.dart`, `lib/models/checklist_item.dart`, `lib/models/shopping_category.dart`, `lib/models/shopping_item.dart`, `lib/models/captain_log_entry.dart`, `lib/models/maintenance_task.dart`, `lib/models/models.g.dart`, `lib/services/sync_service.dart`, `lib/data/repositories/checklist_repository_impl.dart`, `lib/data/repositories/boat_repository_impl.dart`, `lib/data/repositories/shopping_repository_impl.dart`, `lib/data/repositories/captain_log_repository_impl.dart`, `lib/data/repositories/maintenance_repository_impl.dart`, `lib/core/di.dart`, `lib/providers/shopping_provider.dart`
- Context files updated: `risks.md`, `changelog.md`
- New risks introduced: none
- Removed/deprecated: none

---

## [2026-05-10] — Replace all missing assets with semantic icons (62 items across 9 seed files)
- Files changed in project: `lib/ui/components/smart_image.dart`, `seed_annual_checks.dart`, `seed_weekly_checks.dart`, `seed_monthly_checks.dart`, `seed_yanmar_4jh45_50/250/500/1000_hours_service.dart`, `seed_day_trip_safety_briefing.dart`, `seed_documents_checks.dart`, `seed_daily_engine_checks.dart`
- Context files updated: `changelog.md`
- `SmartImage._getIconData()` expanded with 30 new icon keys: ac-unit, autopilot, battery, belt, cable/rigging, captain-license, coolant, cylinder, electrical/zincs, engine, engine-valves, exhaust, filter/water-filter, fishing, fuel/injector, hardware/mounting, heat-exchanger, hull, impeller/piston/winch, keel, kitchen/refrigerator, masthead, no-drinks, oil, outboard/turbo, pets, plumbing/seacocks, pool, propane/stove, sail, spreaders, tiller, water-heater, water-pump, watermaker, watermaker-chart, zarpe
- All 62 previously-missing image paths replaced with icon key strings (not NoPicture)
- Day trip: all 16 items now have semantic icons (hand-wave, life-ring, shield-alert, etc.)
- Factory reset required to see changes on existing installs
- `flutter analyze`: 0 issues. Build: success

## [2026-05-10] — Fix missing asset references in 3 seed files
- Files changed in project: `seed_documents_checks.dart`, `seed_daily_engine_checks.dart`, `seed_day_trip_safety_briefing.dart`
- Context files updated: `changelog.md`
- Root cause: seed files referenced image filenames that never existed on disk; images were never missing — they were never there
- `DocumentsChecks/`: 10 of 12 items pointed to non-existent files; remapped to the 6 real assets (BoatRegistration, BoatInsurance, ValidityOfPassports, VisaRequirements, OnlineRequirements, NoPicture)
- `DailyEngineChecks/`: 7 items pointed to wrong names; remapped to actual files (EngineOil, SecondaryWater, Belts, Leaks, DrainSeperator, RawWater, NoPicture)
- `DayTripSafetyBriefing/`: all 16 items referenced a non-existent `DayTrip/` folder; changed to `DayTripSafetyBriefing/NoPicture.jpg`
- Action required: factory reset to reseed with corrected paths
- `flutter analyze`: 0 issues. Build: success

## [2026-05-10] — Add zero-prompt permissions, self-healing context rule
- Files changed in project: `.claude/settings.local.json`, `CLAUDE.md`, `.ai_context/INDEX.md`
- Context files updated: `INDEX.md` (self-healing rule added), `changelog.md`
- Permissions added: `Read`, `Edit`, `Write` for full project tree; `Bash` for flutter, dart, find, grep, sed, mkdir, wc, cat, sort, head, tail, ls, echo, cp, mv, touch, chmod, awk, xargs
- Self-healing rule: any discrepancy found in source vs context during code reading must be fixed immediately, not deferred
- New risks introduced: none
- Removed/deprecated: stale one-off permission entries replaced by broad patterns

## [2026-05-10] — Fix seed images not loading in checklists
- Files changed in project: `lib/ui/checklists/checklist_items_screen.dart`, `lib/ui/checklists/check_page_viewer.dart`, all 14 `lib/data/seed/seed_*.dart` files that had image setters
- Context files updated: `risks.md`, `changelog.md`
- Root cause 1: Every seed's `add()` helper had `..assetName = assetName` commented out — field was never written to Isar. Uncommented in all 11 `assetName`-based seeds + 1 `assetName` safety briefing seed.
- Root cause 2: Three seeds (`seed_daily_engine_checks`, `seed_day_trip_safety_briefing`, `seed_documents_checks`) passed local `lib/assets/...` paths as `photoUrl` parameter (wrong field). Changed to `..assetName = photoUrl`.
- Root cause 3: `_buildItemImage()` in `checklist_items_screen.dart` and `_buildImageSection()` in `check_page_viewer.dart` hardcoded empty strings instead of `item.assetName`, `item.userPhotoUrl`, `item.userPhotoPath`. Fixed to read from model fields.
- Removed hardcoded `customFallback` grey box in both screens — `ImageFallbackService` now provides category-appropriate `NoPicture.jpg` fallbacks.
- **Action required**: Factory reset needed for existing installs (Drawer → Reset to Factory) to reseed items with the correct `assetName` values.
- `flutter analyze`: 0 issues. `flutter build apk --debug`: success.
- New risks introduced: none
- Removed/deprecated: placeholder `assetName: ''` pattern — never use empty string as an image field placeholder

## [2026-05-10] — Fix seeding, all repository reads, startup health check
- Files changed in project: `lib/services/isar_service.dart`, `lib/main.dart`, all 6 `data/repositories/*_impl.dart`, new `lib/ui/startup/startup_screen.dart`, `analysis_options.yaml`
- Context files updated: `INDEX.md`, `risks.md`, `caching.md` (see below), `changelog.md`
- Root cause fixed: `getAll([])` in ALL repository read methods returned empty list always — replaced with `buildQuery().findAll()` (the only valid isar_community 3.x API for fetching all records)
- `MaintenanceTaskSchema` added to `IsarService._schemas` — maintenance screen no longer crashes
- `IsarService.init()` now returns `DbInitResult` enum: `healthy`, `seeded`, `corrupted`
- Added `hardReset()` — deletes `default.isar` on disk, used only for corruption recovery
- Added partial-seed recovery: if boat exists but checklist groups are missing, seed reruns
- `StartupScreen` added as app entry point: shows teal splash + spinner; corruption dialog with Reset button; starts `SyncService` only after Isar is ready
- `main.dart`: removed `IsarService().init()` (moved to StartupScreen); removed `ref.read(syncServiceProvider)` from `SisuMateApp` (moved to StartupScreen)
- `analysis_options.yaml`: suppress `experimental_member_use` warning for `buildQuery` (isar_community package annotation, not a real risk)
- New risks introduced: none
- Removed/deprecated: `getAll([])` pattern — must never be used again

## [2026-05-10] — Consolidate duplicate SisuColors
- Files changed in project: `lib/core/colors.dart`, `lib/sisu_mate_theme.dart`
- Context files updated: `INDEX.md`, `risks.md`, `changelog.md`, `CLAUDE.md`
- Color values: adopted teal/blue-grey palette from `sisu_mate_theme.dart` as PRD-aligned (marine aesthetic); Figma-spec amber/blue values from old `core/colors.dart` retired
- `lib/core/colors.dart` now contains all constants, theme-aware helpers, and `SisuColorExtensions`
- `lib/sisu_mate_theme.dart` imports `core/colors.dart`; no longer defines `SisuColors`
- All UI imports of `core/colors.dart` unchanged; `settings_screen.dart` import of `sisu_mate_theme.dart` unchanged
- `flutter analyze`: 0 issues. `flutter build apk --debug`: success
- New risks introduced: none
- Removed/deprecated: duplicate `SisuColors` in `sisu_mate_theme.dart`; Figma amber/blue status bar colors

## [2026-05-09] — Initial context generation
- Generated full `.ai_context/` folder from project scan
- Files created: INDEX.md, screens.md, data_models.md, access_tiers.md, caching.md, risks.md, changelog.md
- Scan covered: all 90 Dart files in `lib/`, `pubspec.yaml`, `ARCHITECTURE.md`, all model files, all repository impls, all service files, all provider files, all screen files, seed orchestrator
