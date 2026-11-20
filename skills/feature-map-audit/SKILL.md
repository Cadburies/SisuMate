---
name: feature-map-audit
description: 'Use when the Feature Map, fm.sh reach steps, or the public wiki look stale, or after a wave of UI changes: audits every feature against source and one live pass, fixes only proven map or harness drift, and ships one issue of corrections.'
---

# Feature Map audit

The Feature Map is executable: `scripts/fm.sh` drives `reach` steps, `device-evidence` uses them, and `publish_wiki.sh` publishes the ux layer. A stale map silently misroutes reach and coverage. This is the periodic upkeep pass.

**Rule:** cover every feature from source and exercise every feature live. The unit is the feature, not every sentence.

## Outcomes

Pick one and say which:

- **clean** — every feature got source and live coverage; nothing to ship.
- **changed** — one issue or PR of proven map, harness, or wiki corrections.
- **blocked** — coverage could not finish, or a proven fix could not ship safely. Name the blocker.

## Edit scope

Only `.ai_context/feature_map/`, `tool/feature_map.dart`, and the Feature Map harness scripts. Never edit product code during an audit. A behaviour the map describes that the app no longer does is either map drift (fix the map) or a product regression (file an issue with an accurate Touches field, do not document it away).

## Pass

0. **Locate.** Read `.ai_context/feature_map/FORMAT.md`. Count the leaves. Run `dart run tool/feature_map.dart lint` and `dart run tool/feature_map.dart audit`; keep both outputs as the starting evidence.

1. **Index hygiene.** Fix missing, extra, duplicate, or dead entries. No generated inventory.

2. **Source wave.** One read-only scout per area (launch, home modules, games, system/shared) runs concurrently. Each returns: feature summary, source entry points, likely drift with `file:line`, and one live recipe. Children never drive the app and never edit.

3. **Reconcile.** Every feature has a summary. Merge overlapping recipes into as few app states as practical. Spot-check claimed drift; do not re-prove clean claims. Require a concrete source path before calling a feature missing.

4. **Live pass.** Required even when source looks clean. Drive every feature at least once:
   - host: `scripts/fm.sh <id> --reach`
   - device: `scripts/fm.sh <id> --device <serial|udid>` on one Android and one iOS.

   Use `skills/device-evidence/SKILL.md` for captures. `scripts/fm_device_reach.sh` supports label taps and scroll-retry only; a feature that needs `long:` or an iOS `swipe:` is a harness gap, not a pass.

5. **Triage.** Wrong user-POV description → map drift. Working behaviour the harness cannot drive → harness gap. Broken app behaviour → product issue, kept out of this change. Never weaken a reach step to make a feature pass.

6. **Ship.** One issue or PR with the proven corrections. Re-read every changed file. If `tool/` or `scripts/` changed, run the full suite. Preview the public wiki with `scripts/publish_wiki.sh --dry-run`; publish after the push.

## Report

List features covered, features not reachable and why, confirmed drift, harness gaps, and the outcome. Do not commit run notes or scratch files.

Adapted from Lauren Tan's `create-verification-skill` and `maintain-verification-skill` (MIT), rewritten for SisuMate's Feature Map.
