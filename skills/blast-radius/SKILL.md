---
name: blast-radius
description: 'Use before shipping a change that crosses layers (Drift, model, Supabase, sync, DI, router, units, Pro gates, LAN) or when a small diff looks riskier than its size: finds what it breaks beyond the diff and proves the one safety fact by running real code.'
---

# Blast radius

Find what a change breaks somewhere else, before it ships. Listing callers is the easy part; the breakage grep will not show you is the job.

**Rule:** a writeup that sounds right is worthless. Find the one or two facts the change is safe because of, and prove them by running real code.

## 1. Read the change

Read the diff, the symbols it adds, changes, and deletes, and what it now does differently, including the part the diff does not spell out. For a branch, include the commit list.

## 2. Name the safety fact

Most risky changes are safe because of a single fact: "this call only drops already-dead outbox rows", "the RLS policy still scopes by boat", "the wire prefix is idempotent". Find it. If it holds, most scary cases clear at once. Spend your time here, not on a list of maybes.

## 3. Look where grep stops

- The pinned library source in `pubspec.lock`, not your memory of it.
- Riverpod lifecycle and provider disposal, Drift generated SQL, Supabase RLS, the wire format, the outbox drain, and the Pro gate.
- What a symbol search misses: a JSON field, a DB column, another language reading the same bytes, a feature flag, code three hops downstream.

## 4. Rate each risk

Name how it breaks, the `file:line`, how likely and how bad, and the cheapest check. Keep confirmed risks; list cleared ones separately. A search that finds nothing is still an answer. Never invent a caller or an API.

## 5. Prove the fact

Write the smallest test or throwaway script that calls the real code and fails loud if the fact is false. Run it and paste the result. Keep it as a regression test when it covers a real edge; delete it otherwise.

For a wide or contested change, do a second pass from the opposite assumption before shipping.

## SisuMate triggers

| Change | Prove |
| --- | --- |
| Drift table or column, model field | `schema-change` cascade; repo round-trip test |
| Supabase migration or RLS | live TEST8 with a non-member account |
| `WirePrefix` or sync outbox | encode/decode idempotence; offline drain |
| `di.dart`, router, `models.dart`, `units.dart` | every caller compiles and the gate still fires |
| Pro gate or free-edit counter | free and Pro paths, plus the server-side check |
| LAN protocol, seat, roster | two-device round; host authority |

## Hand back

- What changed, including the non-obvious part.
- The safety fact, the level you proved it to, and the proof.
- Risks with `file:line`, likelihood, cost, and check.
- Cleared checks.
- The cheapest regression test.

Write it through `unslop`, cite real code, and strip anything private before it goes public.

Adapted from Lauren Tan's `blast-radius` (MIT), rewritten for SisuMate.
