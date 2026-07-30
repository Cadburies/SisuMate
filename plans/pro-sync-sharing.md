# Pro Sync & Boat Sharing — Implementation Plan

Target model (agreed 2026-07-11):

- **Free** = fully offline, on-device only, no account, never touches Supabase.
- **Pro** = an email+password Supabase account. Pro entitlement (RevenueCat) is linked to
  the auth user. A Pro account **owns** one or more boats and can publish to / browse the
  community tables.
- **Crew sharing** = each boat has a short, rotatable **share code**. A crew member redeems
  the code to join **that one boat only**. Crew authenticate **anonymously** (no Pro of their
  own); they inherit sync for the joined boat because the boat's **owner** is Pro.
- **Isolation** = server-enforced via RLS: you can read/write a boat's rows only if you are
  its owner or a member. Revoke a crew member = delete their membership or rotate the code.
- **Community** = global tables any Pro account publishes to and any Pro account browses +
  imports (custom cocktails, menus, maintenance lists, etc.).

## Revised model (2026-07-11) — SUPERSEDES the multi-boat framing above, for now

- **One boat per account for now.** Multi-boat is deferred. The app already seeds all bundled
  content onto a single **default boat** `00000000-0000-0000-0000-000000000000` (local-only).
- **Free** = that default boat, view-only, offline, no account. *(Future: allow ~N free edits
  as an upgrade teaser — see FREE-EDITS in outstanding.md.)*
- **Pro onboarding** = **adopt-and-rename the default boat** (do NOT create a new one): mint a
  **GUID** for it, set its name + `ownerId` + `shareCode`, and re-stamp its bundled content to
  that GUID (globally-unique ids so two owners never collide in Supabase).
- **GUID lifecycle:** the GUID is the boat's permanent id, tied to the email account. Persist
  it in BOTH `SharedPreferences` (survives a Drift wipe) and the Supabase `profiles` row.
- **Content sync = duplicate-per-boat** (chosen over overlay/pointer): the boat's bundled +
  custom content are full rows in the 15 per-module tables, scoped by the boat GUID. Whole
  item is the sync unit (definition + state + history), so crew see completion AND edits.
- **Factory/DB reset (Pro):** KEEP the GUID; wipe **both** local Drift AND the boat's Supabase
  rows, then reseed factory content stamped with the same GUID. Both sides together — else
  stale remote rows sync back down and undo the reset. See RESET-SYNC in outstanding.md.
- **Open problem:** lapse/uninstall leaves stale Supabase copies — retention policy TBD
  (STALE-DATA in outstanding.md).

## ID-uniqueness sub-problem (blocks SHARE-ENROLL)

Finding: **seeding does not sync** (seeders write straight to Drift; only repo writes —
edits/completions — call `queueOutgoingChange`). So Supabase only receives *touched* items.
But bundled item ids are deterministic + identical on every install (`dailyEngineId_check_oil`),
while sync **deletes by `supabaseId`** and realtime **dedups by `id`** — both need a globally
unique `supabaseId`. So two Pro accounts touching the same bundled item collide onto one row.

Two ways to make ids unique per boat:

- **(A) Wire-prefix (recommended).** Keep deterministic local ids; the sync layer prefixes every
  id-ref field with the boat GUID on outbound (`<guid>::<localId>`) and strips on inbound.
  Local code/assumptions untouched; composes with reset (reseed keeps deterministic ids, prefix
  still unique). Cost: sync layer must know each table's id-ref fields and transform them.
- **(B) DB-rewrite at enrollment.** One-time batch: rewrite `supabaseId` + all ref columns to
  `<guid>_<id>` across ~12 tables; sync layer unchanged afterwards. Cost: risky cross-ref
  rewrite; any runtime lookup by a raw deterministic id (e.g. `dailyEngineId`) would break; every
  factory reset must re-run the rewrite.

## Key decisions (defaults — flag if you disagree)

1. **Owner auth = email + password** (self-contained sign-up at upgrade). Magic-link retired
   as the primary flow (kept only if trivially compatible).
2. **Crew auth = Supabase anonymous sign-in.** `auth.uid()` exists for anon users, so RLS and
   the redeem RPC work uniformly.
3. **Everything is per-boat.** `recipes`/all list modules already carry `boatSupabaseId`;
   `bar_ingredients` and `pantry_ingredients` get a new `boatSupabaseId`; `recipe_ingredients`
   scope through their parent recipe. (If bar/pantry/recipes should instead be *account-level*
   shared across a captain's boats, say so — it changes only their RLS predicate.)
4. **Pro-lapse enforcement is deferred.** MVP rule: a boat existing in Supabase implies its
   owner was Pro at creation (Free never syncs), so membership alone grants access. A later
   RevenueCat webhook → `profiles.pro_until` → RLS check adds continuous enforcement.

## Schema shape

- `boats`: add `ownerId uuid` (auth user), `shareCode text unique` (DB-generated default).
- `boat_members`: (`boatSupabaseId`, `memberId uuid`, `role`, `joinedAt`), PK(boat, member).
- `redeem_boat_code(p_code)` SECURITY DEFINER RPC: validates code, inserts membership for
  `auth.uid()`, returns the `boatSupabaseId`.
- `bar_ingredients`, `pantry_ingredients`: add nullable `boatSupabaseId`.
- `community_templates`: global publish/browse table (Phase 5).
- **RLS cutover (last):** replace the permissive `sisu_allow_all` policies with membership-
  scoped policies. Done only AFTER the app populates `ownerId`/`boatSupabaseId` everywhere,
  so live sync never breaks mid-migration.

## Debug bootstrap identity

While the sign-up/join UI (Phase 3) is unbuilt, on-device Pro testing (`kForceProForTesting`)
uses a fixed owner identity, defined in `revenuecat_service.dart`:
`kDebugAccountEmail = 'sailingsisu@outlook.com'`, `kDebugBoatName = 'Sisu'`. The account must
exist in Supabase (create via the app sign-up once built, or the dashboard).

## External blockers (cannot be done via MCP — need dashboard/owner action)

1. **Enable "Anonymous sign-ins"** — Supabase dashboard → Authentication → Sign In / Providers
   → Anonymous. Currently disabled (`anonymous_provider_disabled`); the crew-join RPC is ready
   but crew can't get a session until this is on.
2. **Create the `sailingsisu@outlook.com` owner account** (with a password) — for debug
   bootstrap. Do it in the dashboard, or via the app's sign-up screen once Phase 3 ships.

## Phases

**Phase 1 — Plan.** This document.

**Phase 2a — Backend structure (non-breaking).** ownerId + shareCode on boats,
`boat_members`, `redeem_boat_code` RPC, `boatSupabaseId` on bar/pantry. Keep permissive RLS.
Reversible via migration. ← executed with this plan.

**Phase 3 — App auth.** ✅ DONE (2026-07-11, verified on Android emulator).

**SHARE-ENROLL** ✅ DONE (2026-07-11, verified on device): `BoatEnrollmentService` adopts-and-renames
the default boat into a persisted GUID, re-stamps content, pushes + claims ownership. Wired into
account-setup + debug bootstrap. **Next: WIRE-PREFIX** (item-id uniqueness, chosen approach) — see
the "ID-uniqueness sub-problem" section + outstanding.md.

**WIRE-PREFIX** ✅ DONE (2026-07-11, verified on device): `WirePrefix` prefixes id-ref fields with the
boat GUID on the wire (`<guid>::<id>`) and strips on inbound, applied at every `sync_service`
boundary. Two Pro accounts touching the same bundled item now write distinct rows.

**RESET-SYNC** ✅ DONE (2026-07-11, verified on device): `SyncService.wipeRemoteBoatContent` +
`common_drawer._performReset` — a Pro reset wipes local + the boat's remote content and re-adopts
the SAME GUID (crew stay linked); Free reset stays local-only. Next: SHARE6 (RLS cutover), SHARE5.
- `AuthService`: `signUp(email, pwd)`, keep `signIn(email, pwd)`, add `signInAnonymously()`,
  add `redeemBoatCode(code)` (calls the RPC).
- Upgrade flow (paywall success) → account creation screen (email + suggested boat email +
  boat name) → creates Supabase account + first boat with `ownerId`.
- "Join a boat" entry (for crew): anonymous sign-in + enter share code.
- RevenueCat linking already ties Pro to the auth uid ([main.dart:64]).

**Phase 4 — Ownership + scoping in the app.** 🟡 PLUMBING DONE (2026-07-11): model + Drift v7
+ mappings for `Boat.ownerId`/`shareCode` (inbound-only) and `Bar/PantryIngredient.boatSupabaseId`.
Still open: stamp active boat on bar/pantry writes; owner/crew boat dropdown. See SHARE4.
- `Boat` model + Drift + repo: add `ownerId`, `shareCode` (read-back for the share sheet).
- `BarIngredient`/`PantryIngredient` model + Drift (schemaVersion bump) + repo + toJson/
  fromJson: add `boatSupabaseId`; stamp active boat on writes.
- Every repository stamps `ownerId`/`boatSupabaseId` on synced records.
- "Share this boat" UI: show/rotate the code (+ optional QR).
- Boat dropdown (owner sees all owned boats; crew sees only joined boats).

**Phase 5 — Community publish/import.** ✅ DONE (2026-07-12, migration `community_tables`,
verified over HTTP + in-app import): open community (auto-approved), publish = real users only,
anonymous crew read-only, imports become boat-scoped synced groups.
- `community_templates` Supabase table + RLS (read: any authenticated; insert: authenticated;
  update/delete: author only). Wire the existing `CommunityTemplates` model + community
  browser to publish and import.

**Phase 6 — RLS cutover.** ✅ DONE (2026-07-11, migration `rls_cutover`, verified on device):
`accessible_boat_ids()` + membership-scoped policies (content by wire-prefix GUID; boats by
ownership); anon-key-only access locked out; owner session verified. Remaining advisors are
intentional (anonymous crew access) or pre-existing.

## Acceptance criteria

- Free build never opens a Supabase session.
- Captain signs up (email+pwd), creates boat1, sees a share code.
- Chef redeems boat1's code on another device (anonymous), sees boat1 data, cannot see boat2.
- Captain creates boat2, shares its code with chef2; chef2 (no Pro) sees only boat2.
- Any Pro account publishes a community item; another Pro account imports it.
- `get_advisors(security)` shows no permissive-RLS warnings after Phase 6.
