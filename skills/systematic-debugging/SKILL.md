---
name: systematic-debugging
description: Use for any bug, failing or flaky test, crash, error-log/triage issue (ui-overflow, ips crash), or unexpected behaviour — before proposing a fix. Root cause first; stops guess-and-patch loops.
---

# Systematic debugging

Adapted from obra/superpowers `systematic-debugging` (MIT).

**Rule:** no fix until the root cause is found and written down. A fix for the symptom is not a fix.

## Phase 1: Investigate

- Read the whole error, stack trace and `context:` string. Triage issues from `triage_error_logs*.sh` already carry the file and a snippet, so start there.
- **Reproduce** reliably: a host test, `scripts/fm.sh <id>`, or a device run. If you can't reproduce it, gather more data. Don't guess.
- Check what changed: `git log -p --since=... -- <path>`, recent migrations, `schemaVersion`, dependency bumps.
- Multi-layer bugs (UI → provider → repo → Drift → sync → Supabase): log or assert at each boundary once, find the layer where good data turns bad, and fix it there.

## Phase 2: Compare

Find a working sibling in the codebase, such as another module's repo or screen, or another game's timer handling. Read it fully and list every difference.

## Phase 3: One hypothesis at a time

Write "X causes this because Y", then test it with the smallest change. Change one variable per run. If it's wrong, form a new hypothesis. Don't stack patches.

## Phase 4: Fix

1. Write a failing regression test first (`test-driven-development`).
2. Make one fix at the root cause, with no drive-by cleanups.
3. Verify it (`verification-before-completion`).

**Three failed fixes means stop.** If each fix moves the symptom, the design is wrong, not the hypothesis. Tell the user what you tried and ask before trying a fourth. If you are told "stop guessing" or "is that actually happening?", go back to Phase 1.

## Flaky and timing tests

See [condition-based-waiting.md](condition-based-waiting.md). Most "flaky under load" failures are real waits on wall-clock time.

## Truly external causes

If the cause really is the environment or the network, write down what you ruled out, handle it (timeout, retry, user message), and log it per the CLAUDE.md error-logging table (`logWarning` for degraded but survivable). Most "no root cause" conclusions are investigations that stopped too early.
