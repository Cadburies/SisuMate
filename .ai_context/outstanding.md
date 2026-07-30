# Outstanding Issues

> Open work only. Risks/guardrails → `risks.md`.
>
> Severity: **critical** | **high** | **medium** | **low**
>
> ### Maintenance
>
> **Rule 1 — Resolved leaves entirely.** Delete the row; short note in hot `changelog.md`. Never strikethrough history here. Never leave “_(done / closed / none)_” archive blurbs in this file.
>
> **Rule 2 — No build-count snapshots.** Analyze/test/build counts belong only in the task's changelog entry (they go stale instantly).
>
> **Rule 3 — Live-test failures log immediately** in the failure table: test / what failed / fix hint (symptom → file → cause). Resolved → Rule 1.

---

## Testing bypasses (debug-only)

Release ignores these even if `true`. Grep `ForTesting`.

| # | Severity | Area | Description | Key files |
| --- | --- | --- | --- | --- |
| RM1 | low | Pro | `kForceProForTesting` → `isPro()` true only in `kDebugMode` | `revenuecat_service.dart` |
| RM2 | low | Onboarding | `kBypassOnboardingForTesting` only in `kDebugMode` | `onboarding_screen.dart` |

---

## Testing gaps

| # | Severity | Area | Description | Key files |
| --- | --- | --- | --- | --- |
| TEST3 | low | Services | `auth_service.dart`, `profile_heartbeat.dart`, `email_service.dart`, `recipe_share_service.dart` have no tests — each needs a new DI/platform-mock seam (static `SupabaseClientWrapper`, `BuildContext`/`url_launcher`, or `Printing.layoutPdf`) that doesn't exist yet. | `services/auth_service.dart`, `services/profile_heartbeat.dart`, `services/email_service.dart`, `services/recipe_share_service.dart` |
| TEST4 | low | Ads | AdMob: only the day-count/limit logic (`canShowInterstitialAd`/`recordInterstitialAdShown`) is unit-tested; ad creation/load/show still needs a real device (hits the live Mobile Ads SDK). | `admob_service.dart` |
| TEST5 | medium | UI | Most AddEdit dialogs have no widget test — only crew/fuel/inventory got coverage in the 2026-07-30 pass (plus documents/recipe, pre-existing). Meal plan, checklist, maintenance, guest profile, collection, captain's log, etc. still untested. | `lib/ui/**/*_screen.dart` |
| TEST6 | medium | UI | All widget tests (existing + new) pump a dialog in isolation — no test wires a real screen to a live provider tree + DB. | `test/*_screen_test.dart` |
| TEST7 | medium | Games | LAN multiplayer tests cover only 1 host + 1 client transport/handshake (`fake_lan_engine.dart`) — no automated coverage of 3+ seat games, AI-seat interaction, or the game-notifier logic layered on top (`GameStateNotifier`/`DudoGameNotifier`). | `test/game_multiplayer_lan_test.dart`, `test/test_helpers/fake_lan_engine.dart` |
| TEST8 | medium | Sync | Every sync test runs against `FakeSupabaseRemote` — nothing exercises real Supabase (RLS policies, realtime latency, actual conflict timing under real network jitter). | `sync_service.dart`, `test/sync_conflict_2device_test.dart` |
| TEST9 | low | Infra | No `integration_test/` suite — nothing boots the real app end-to-end on a simulator/emulator; still only the manual adb/idb scripts in `scripts/`. | `scripts/*.sh` |
| TEST10 | low | Infra | Performance, accessibility, and platform-channel-specific behavior (iOS vs Android quirks) aren't tested at all. | — |

---

## Suggestions

| # | Severity | Area | Suggestion |
| --- | --- | --- | --- |
| SUG3 | low | Weather | Named locations, marine depth, imperial fuel units |

---

## Local AI — Games (no model calls)

Heuristic bots already exist (`isAI` lobby seats; per-game `_aiMove` / `_aiTurn` / `computeAIBid`). Deepen pure-Dart play; keep bots offline and deterministic. Prefer shared helpers under `lib/services/game_ai/` only if multiple games share logic.

| # | Severity | Area | Suggestion | Key files |
| --- | --- | --- | --- | --- |
| GAI1 | medium | Games | Difficulty levels (Easy / Normal / Hard): Easy more random, Hard deeper eval. Optional Pro gate for Hard+ is a product choice. | per-game `logic.dart`, lobby |
| GAI2 | medium | Games | Minimax / alpha-beta for Checkers (and other perfect-info board games where fan-out is small). | `checkers/logic.dart` |
| GAI3 | medium | Games | Expectimax / Monte Carlo for Backgammon and other dice-heavy games (current BG AI is shallow score: hit / bear-off / home). | `backgammon/logic.dart` |
| GAI4 | medium | Games | Bayesian / probability bluffing for Dudo & Liar's Dice (bid history, remaining dice, existing probability tables). | `dudo/logic.dart`, `liars_dice/logic.dart` |
| GAI5 | low | Games | Persona bots for multiplayer seat-fill: aggressive / tight / chaos (names + biased thresholds). | lobby + per-game AI |
| GAI6 | low | Games | Hints / coach mode: show *why* a move is good without taking the turn (solo practice). | per-game screen + logic |
| GAI7 | low | Games | Practice mode: after each human turn, optionally surface best-move suggestion from the same eval used by Hard AI. | per-game screen + logic |
| GAI8 | low | Games | Do **not** drive game moves via cloud LLM — slow, non-deterministic, expensive, worse than math at sea. | — |

---

## Local AI — Boat life (rule engines)

Extend the S4 pattern: pure functions over Drift data → Riverpod → banner/sheet. No network required. Pattern: `Repository → lib/services/* → provider → UI`.

| # | Severity | Area | Suggestion | Key files |
| --- | --- | --- | --- | --- |
| BAI1 | medium | Suggestions | Passage readiness score: safety checks + maintenance overdue + weather cache + fuel → “Ready / fix N things first”. | `suggestion_engine.dart`, home, safety/fuel/weather |
| BAI2 | medium | Shopping | Smart shopping rank: pantry + meal plan + seasonal + last prices → prioritized “buy before passage” list. | `provision_calculator.dart`, shopping, seasonal |
| BAI3 | medium | Checklists | Checklist autopilot: trip type / weather / days → suggest which checklists to run. | checklists UI + `suggestion_engine.dart` |
| BAI4 | medium | Fuel | Fuel/water burn estimator from logs + hours + distance → ETA empty tanks. | fuel module, `suggestion_engine.dart` |
| BAI5 | low | Sync | Conflict UX helpers: field-level “prefer mine / theirs” suggestions from merge shape (not OT/CRDT). | `conflict_resolution_service.dart` |
| BAI6 | low | Import | Offline import assist: fuzzy name match, unit normalize, “did you mean X?” without LLM. | `import_service.dart` |
| BAI7 | low | Suggestions | Richer home `SuggestionEngine` rules (more maintenance/weather/log cues) before any LLM layer. | `suggestion_engine.dart`, `home_screen.dart` |

---

## Local AI — Cocktails / Chef (Mixologist depth)

Deterministic flavor graphs + inventory already in `mixologist_service.dart`. No LLM required for these.

| # | Severity | Area | Suggestion | Key files |
| --- | --- | --- | --- | --- |
| MIX1 | medium | Cocktails | “What can I make tonight?” ranked by missing-ingredient count against bar/pantry. | `mixologist_service.dart`, cocktails/menus UI |
| MIX2 | medium | Cocktails | Substitute graph (lime↔lemon, orgeat↔almond syrup, etc.) with confidence notes. | `mixologist_service.dart` |
| MIX3 | low | Cocktails | ABV / strength slider, glassware constraints, crew-size scaling on suggestions. | `mixologist_service.dart`, Mixologist tab |
| MIX4 | low | Bar | “Bar is low on X” from purchase / stock history signals. | bar ingredients, purchase records |
| MIX5 | low | Chef | Leftovers / pantry ranking improvements on top of existing `suggestDish()`. | `mixologist_service.dart`, menus UI |

---

## Local AI — On-device ML (no cloud model)

Still no cloud LLM bill; APK size / battery tradeoffs. Prefer rules first.

| # | Severity | Area | Suggestion | Key files |
| --- | --- | --- | --- | --- |
| ML1 | low | OCR | ML Kit text recognition: labels / logbook pages / checklist drafts → structured fields (user confirms). | scanner UI, import paths |
| ML2 | low | Barcode | Expand offline barcode catalog beyond common bar spirits. | `barcode_service.dart` |
| ML3 | low | ML | Optional small TFLite classifiers only where tables fail (e.g. receipt-vs-not); avoid full on-device LLM (size/battery/quality). | new service if needed |

---

## Online AI / LLM (optional, paid path)

No durable free unlimited cloud LLM for a consumer app. Free provider tiers are for dev/tiny traffic only. Never embed API keys in the APK.

| # | Severity | Area | Suggestion | Key files |
| --- | --- | --- | --- | --- |
| LLM1 | medium | Infra | Production shape: App (auth + Pro/quota) → Supabase Edge Function (holds API key) → xAI/OpenAI/etc. → JSON/stream back. Offline always falls back to rule engines. | Supabase functions (new), app client service |
| LLM2 | medium | Pro | Quota + billing: Free N tips/day (or ads-funded soft cap); Pro higher cap; hard monthly $ kill-switch. | Edge Function, `isProProvider`, settings |
| LLM3 | medium | Privacy | Send summaries only (task titles, weather snippet, pantry names) — not full boat dumps / crew docs unless explicit opt-in. | Edge Function + client payload builders |
| LLM4 | low | Cost | Short prompts, small models for tips, cache identical queries, structured JSON out. | Edge Function |
| LLM5 | low | Product | Good LLM-only uses: NL captain-log → structured fields; “explain this maintenance alert”; creative cocktail novelty; messy PDF/CSV → import JSON; passage briefing narrative. Always pair each with offline fallback. | relevant modules + LLM client |
| LLM6 | low | Product | BYO API key in settings (user pays) is possible for power users — bad default UX; prefer server key + Pro. | settings UI |
| LLM7 | low | Product | S4 “LLM-assisted tips” remains optional later; Tier 0 rules + game AI first. | `suggestion_engine.dart`, `outstanding` Priority |

---

## Priority

1. **Tier 0 (free forever):** GAI* game AI + BAI* boat rules + MIX* Mixologist depth — most offline “wow”  
2. TEST5–TEST6 widget coverage when next touching those screens  
3. **Tier 1 (optional):** ML1–ML3 on-device OCR/classifiers where rules fail  
4. **Tier 2 (optional Pro/online):** LLM1–LLM5 Edge Function path only if narrative AI still missing after Tier 0  
5. S6 deeper collab (OT/CRDT) only if product needs it  
6. SUG3 weather polish when next in Weather  
