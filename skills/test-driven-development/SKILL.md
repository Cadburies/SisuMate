---
name: test-driven-development
description: Use when implementing a feature, bugfix or behaviour change in lib/ — before writing the production code. Regression test first, watched failing for the right reason, then the minimal fix.
---

# Test-driven development (regression-first)

Adapted from obra/superpowers `test-driven-development` (MIT).

**Rule:** every behaviour change ships with a test that was **seen failing** before the change. A test you only ever saw pass proves nothing; it may test nothing.

## Cycle

1. **Red.** Write one test for one behaviour, named after the behaviour. Run *that file* (`flutter test test/x_test.dart`). It must **fail**, and fail because the behaviour is missing, not because of a typo or compile error. If it passes, it's testing something that already works, so fix the test.
2. **Green.** Write the least code that makes it pass. Don't add features beyond the test. If it still fails, fix the code, not the test.
3. **Refactor** only while green.
4. **Full suite** before claiming done (`verification-before-completion`).

## Which test layer (SisuMate)

| Change | Test |
| --- | --- |
| Pure logic: services, units, game rules, local AI | Unit test `test/<thing>_test.dart` |
| Module screen behaviour | TEST6-style screen + Riverpod + in-memory Drift `test/*_integration_test.dart` |
| Pro / Free gate | Extend `test/pro_free_gate_matrix_test.dart` |
| A Feature Map feature | Its host test `test/feature_map/<area>_test.dart` (`scripts/fm.sh <id>`) |
| Sync / import / offline | The matching TEST13/14/15 file (CLAUDE.md suite map) |
| Layout-only change | No test (CLAUDE.md rule) |

## Rules

- Mock only at boundaries you don't own (Supabase, RevenueCat, platform channels). Use a real in-memory Drift, not a mocked repository.
- Assert the specific value, widget or row, not "something exists". A check like "a list renders" passes on an empty list.
- **Never weaken a test to get to green.** Deleting an `expect`, loosening a matcher, adding `skip:`, or widening a tolerance needs a reason in the issue comment. The reviewer and the test floor (#420) check for this.
- Timers and async: see `systematic-debugging/condition-based-waiting.md`.
- Exceptions (ask first): throwaway spikes, generated code, config-only changes.

## Code written before its test?

Comment it out, write the test, and watch it fail against the old behaviour, then restore the code. If the test passes against the old behaviour, it isn't testing your change.
