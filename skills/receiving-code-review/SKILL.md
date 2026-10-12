---
name: receiving-code-review
description: Use when acting on review findings — from a reviewer agent or review tool, a GitHub comment, or the user — especially if a finding seems wrong or unclear. Verify each finding before changing code.
---

# Receiving code review

Adapted from obra/superpowers `receiving-code-review` (MIT).

**Rule:** a finding is a claim to check, not an order. Correctness comes before agreeableness.

## For each finding

1. Restate it as a concrete technical requirement. If you can't, it's unclear.
2. **Check it against the code:** open the file and line, and reproduce it if it's a bug claim.
3. Decide:
   - **Valid** → fix it, run the relevant test, and move to the next finding.
   - **Invalid** → reply with the evidence (code reference, test output, the CLAUDE.md rule) and leave the code alone.
   - **Unclear** → ask before touching *any* of the findings, because they may depend on each other.
4. Fix one finding at a time, testing after each.

## Push back when the finding

- breaks existing behaviour (a test or the Feature Map says otherwise)
- conflicts with a recorded decision: shared tree on main, offline-first AI (#286), Pro gates in `access_tiers.md`, `SisuColors` only
- adds an unused capability. `grep` for callers, and if there are none, propose deleting the code rather than building it out
- is wrong for Flutter, Riverpod or Drift as this repo uses them

On architectural disagreements, ask the user instead of choosing yourself.

## Don't

- Open with "You're right!" or "Great catch". State the fix or the objection.
- Implement every finding to make the reviewer go away. A FIX verdict with an invalid finding gets a reasoned reply, not a code change.
- Change a test to agree with buggy code.
