---
name: verification-before-completion
description: Use before saying work is done, fixed, passing or green; before closing an issue, committing or pushing; and before trusting another agent's success report. Requires fresh command output as evidence for every claim.
---

# Verification before completion

Adapted from obra/superpowers `verification-before-completion` (MIT).

**Rule:** no completion claim without evidence produced *after your last edit*. A run from earlier, a run before your last edit, or "it should pass" is not evidence.

## Gate (run it every time)

1. **Name** the command that proves the claim (table below).
2. **Run** it fresh and in full, not a filtered subset.
3. **Read** the output: the exit code, the failure count, and any skips.
4. **State** the result with the evidence. If it failed, say so and quote the failure. Don't soften it.

## Claim → evidence (SisuMate)

| Claim | Evidence required | Not enough |
| --- | --- | --- |
| Task done / suite green | `./scripts/run_full_suite.sh` ends `==> full suite green`, run **after** your last edit; skip flags named | `flutter test` on one file; a green run from before an edit |
| Analyzer clean | `flutter analyze` → `No issues found!` | "only touched one file" |
| Builds | `flutter build apk --debug --dart-define-from-file=dart-defines.json` exits 0 | analyze passing |
| Bug fixed | The regression test that reproduced it failed before the fix and passes after (see `test-driven-development`) | Code changed; the test was only ever seen passing |
| Schema landed | `./scripts/verify_supabase_schema.sh --require` green after MCP `apply_migration` | `--skip-live` suite |
| Works on device | Screenshot/log from **both** iOS and Android (see `device-evidence`) | One platform; a screenshot without a log for state-dependent bugs |
| Another agent finished | `git diff`/`git log` shows the change, and you ran the check yourself | Its summary |
| Acceptance met | Each Acceptance box checked against the diff, one by one | Tests passing |

## Red flags (stop and run the gate)

"should", "probably", "looks fixed", "I'm confident", "just this once", satisfaction before output, about to `git commit` or `gh issue close`.

## Reporting

Issue close comments quote the result line, flags and test count: "Suite green, no skip flags, 2517 host tests + integration_test". Never write "tests pass" without that line.
