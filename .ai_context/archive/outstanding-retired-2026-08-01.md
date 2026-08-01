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

## Security / infra

Found during the 2026-07-30 git-init security pass.

| # | Severity | Area | Description | Key files |
| --- | --- | --- | --- | --- |
| SEC2 | low | Secrets | `.mcp.json` (committed to the now-private GitHub repo) embeds the Supabase project ref in a URL — not a credential by itself, but reveals project identity. Fine while the repo stays private; revisit if visibility ever changes. | `.mcp.json` |

---

## Testing gaps

### How to run the full suite (post every task)

```bash
./scripts/run_full_suite.sh
```

| Step | Command (inside script) | Skip flag |
| --- | --- | --- |
| SEC3 secrets | `scripts/scan_release_secrets.sh` | — |
| Analyze | `flutter analyze` | — |
| Host tests | `flutter test` | — |
| TEST8 live RLS | `scripts/test_supabase_rls.sh` | `--skip-live` |
| TEST9 integration | `flutter test integration_test` (`-d flutter-tester` default) | `--skip-integration` / `--device <id>` |

```bash
./scripts/run_full_suite.sh --skip-live                    # no network / no dart-defines
./scripts/run_full_suite.sh --skip-live --skip-integration # host-only fast loop
./scripts/run_full_suite.sh --device <id>                  # real sim/device for TEST9
```

Docs: `CLAUDE.md` §5 · `README.md` → Testing · `scripts/run_full_suite.sh` header · multi-agent: `parallel_ai.md` rule 5.

**Add tests for every new/changed behavior** before claiming done. Zero analyze issues; suite green or hand-off documents which skip flags were used and why.

**Shipped test gates (do not re-open):** SEC3, TEST3/4/6/8–17, TEST25 WirePrefix, TEST26 weather, TEST27 units, TEST28 AI determinism, TEST29 factory reset.  
Pointers: TEST16 `conflict_resolution_e2e_test.dart` (automated dual-device) · TEST25 `wire_prefix_test.dart` · TEST26 weather · TEST29 `factory_reset_test.dart` + `lib/core/factory_reset.dart`.  
Still open P1: **TEST18** (LAN RC).

### Pre-launch — P1 (high confidence before real sailors)

| # | Severity | Area | Description | Key files |
| --- | --- | --- | --- | --- |
| TEST18 | medium | Games | LAN multiplayer release-candidate smoke: host + 1–2 clients, Liar’s Dice or Dudo full round; reconnect mid-game if claimed. Use existing harness scripts. | `scripts/liars_dice_4sim_setup.sh`, LAN services, game logic |

### Pre-launch — P2 (device / store reality)

| # | Severity | Area | Description | Key files |
| --- | --- | --- | --- | --- |
| TEST19 | medium | Device | Real iOS + Android hardware: camera/barcode permission deny → no crash; photo/document missing path graceful; location denied vs allowed for weather/passage; kill after ~30 min cold resume (session/sync OK). | barcode, image, weather, startup |
| TEST20 | medium | Ads | Free on device with Google **test** ad units: banner doesn’t permanently cover FABs; interstitial daily cap observed once; Pro never shows banner (layout collapse). | `admob_service.dart`, banner/native widgets |
| TEST21 | low | Perf | Full seed cold open stopwatch on mid phone; long shopping list scroll; optional large-Drift stress (N items, stream still emits). | seeders, list screens |
| TEST22 | low | A11y | Expand TEST10 guidelines beyond home/shopping to Safety, Checklists, Settings (paywall CTA labeled). | those screens, `test/accessibility_test.dart` |
| TEST23 | low | Auth | Magic-link / deep link cold start once per OS: `io.supabase.sisu://login-callback/` if email OTP ships. | `auth_service.dart`, platform URL config |

### Pre-launch — P3 (polish; lower launch risk)

| # | Severity | Area | Description | Key files |
| --- | --- | --- | --- | --- |
| TEST24 | low | UI | Optional golden/screenshot smoke for **home only** (theme disasters) — keep few, not layout-only sprawl. | `home_screen.dart` |

---

## Suggestions

| # | Severity | Area | Suggestion |
| --- | --- | --- | --- |
| SUG5 | low | Units | Wind speed and boat/SOG speed share one `SpeedUnitPref` (`units.dart`) — most chartplotters do this too, but some marine apps let them differ (e.g. wind in knots, boat speed in km/h). Splitting into separate `windSpeed`/`boatSpeed` prefs is a small, contained follow-up if a user asks for it. |

---

## Local AI — Games (no model calls)

Heuristic bots already exist (`isAI` lobby seats; GAI1 skill + GAI5 persona on wire; per-game `_aiMove` / `_aiTurn` / `computeAIBid`). Deepen pure-Dart play; keep bots offline and deterministic. Shared helpers: `lib/services/game_ai/` (`GameAiDifficulty`, `GameAiPersona`, `GameAiRng`). **TEST28** shipped (`test/game_ai_determinism_test.dart`).

| # | Severity | Area | Suggestion | Key files |
| --- | --- | --- | --- | --- |
| GAI8 | low | Games | Do **not** drive game moves via cloud LLM — slow, non-deterministic, expensive, worse than math at sea. | — |

---

## Local AI — Boat life (rule engines)

Extend the S4 pattern: pure functions over Drift data → Riverpod → banner/sheet. No network required. Pattern: `Repository → lib/services/* → provider → UI`. **BAI7** (richer home rules) shipped — see `suggestion_engine.dart`.

---

## Local AI — On-device ML (no cloud model)

Still no cloud LLM bill; APK size / battery tradeoffs. Prefer rules first.

| # | Severity | Area | Suggestion | Key files |
| --- | --- | --- | --- | --- |
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

1. **Pre-launch P1 pack:** TEST18 LAN RC (TEST13–17 shipped)  
2. **Tier 0 (free forever):** further GAI* depth (BAI7 shipped) — most offline “wow”  
3. Optional: more TEST6 screen+Drift (maintenance/logbook) when next touching modules; keep `./scripts/run_full_suite.sh` green after every task  
4. **P2 pre-launch** as needed: TEST19–TEST23 (real device, ads, a11y, deep link)  
5. **Tier 1 (optional):** ML3 small on-device classifiers only where tables fail  
6. **Tier 2 (optional Pro/online):** LLM1–LLM5 Edge Function path only if narrative AI still missing after Tier 0  
7. S6 deeper collab (OT/CRDT) only if product needs it  
8. **P3 polish:** TEST24–TEST29 (golden home, WirePrefix fuzz, weather offline, units edges, AI determinism, factory reset)  

