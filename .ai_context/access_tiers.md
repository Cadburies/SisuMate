# Access Tiers — Free vs Pro

> Capability matrix + gate inventory. **No pasted source snippets** (they go stale). Open the listed file for current code.

## Matrix

| Capability | Free | Pro |
| --- | --- | --- |
| View modules (lists, recipes, log, etc.) | yes | yes |
| Mark complete / notes (list affordance) | no (hard gate) | yes |
| Detail complete/notes | 5 free via `FreeEditGate` then gate | unlimited |
| Custom groups/items FAB | paywall | yes |
| Multiple / manage boats | no (1 boat) | yes |
| Realtime Supabase sync | no* | yes |
| Crew join + sync as anonymous | n/a | ride owner Pro |
| Community browse/import | no | yes |
| Ads (banner / native / interstitial) | shown | hidden |

\*Sync eligibility is **not** identical to feature-Pro — see below.

## Runtime Pro

- **Authoritative:** RevenueCat `entitlements.active` contains `Boat Checks Pro` (`RevenueCatService.isPro()`).
- **UI gate:** watch `isProProvider` (`StreamProvider` in `di.dart`) — re-emits on purchase/restore/login.
- **Not authoritative:** `UserSettings.isPro` / `proExpiresAt` (legacy/local only).
- **Debug:** `kForceProForTesting` only when `kDebugMode` (RM1) — release ignores it. See GitHub issue #1.

## Sync ≠ Pro (decision 2026-07-11)

Feature gates (ads, complete, multi-boat) use `isProProvider`.

**Sync** uses `SyncService._syncAllowed()` = `isPro() || (anonymous Supabase session)`. Crew redeem a share code, get anonymous auth, sync the owner's boat without being Pro themselves. Design: `plans/pro-sync-sharing.md`.

## RevenueCat config

| Item | Value |
| --- | --- |
| Entitlement | `Boat Checks Pro` |
| Products | `sisu_mate_pro_yearly`, `sisu_mate_pro_monthly` |
| Keys | Apple/Google/test fields in `revenuecat_service.dart` (not duplicated here) |
| App user id | Prefer Supabase UUID; else device `user_<ts>`; `linkSupabaseUserId` on auth changes (PRO3) |

## Paywall gates (exhaustive inventory)

| # | Feature | Where | Free behavior |
| --- | --- | --- | --- |
| 1 | List-level mark complete | `checklist_items_screen.dart` | Interstitial (cap 3/day) + snackbar + upgrade |
| 2 | Detail complete / notes | `CheckPageViewer` + `FreeEditGate` | 5 free then dialog |
| 3 | Boat management | `home_screen.dart` drawer | Lock tile if ≤1 boat |
| 4 | Sync start / outbox | `sync_service.dart` | No-op unless Pro or anon crew |
| 5 | Custom group FAB | `checklist_screen.dart` | Paywall |
| 6 | Custom item dialog | `AddChecklistItemDialog` pattern | Internal Pro check (PRO1) |
| 7 | Banner ad | `banner_ad_widget.dart` | Shown; Pro → shrink |
| 8 | Native ad every 8 items | checklist list + `NativeAdWidget` | Widget should suppress for Pro — verify in widget |
| 9 | Upgrade tile | `common_drawer.dart` `ProUpgradeSection` | Enabled when not Pro |

**New gated feature:** add a row here + implement with `isProProvider` / same patterns. Never bypass.

## IAP / restore

1. Upgrade entry → `showPaywall` → `PaywallScreen` loads offerings.
2. Purchase package → refresh customer info → `isProProvider` re-emits.
3. Restore: Paywall "Restore Previous Purchase" + `restorePurchases()`.

No trial / grace period coded. Offline: SDK cached `CustomerInfo`; if never initialized, `isPro()` may return false until online (Pro user briefly treated Free).

## Partial Free limits

- Interstitial: max 3/day (`interstitial_ad_count` + date keys).
- FREE-EDITS: 5 total free detail completions/notes (`freeEditsUsed`), not per-day.
