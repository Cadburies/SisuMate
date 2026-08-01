#!/usr/bin/env python3
"""Renders one triage_error_logs.sh JSONL row (from tool/error_log_admin.dart
dump-unprocessed) into a GitHub issue title or body. Not a standalone
entrypoint — called by triage_error_logs.sh.

Usage:
  echo '<json line>' | python3 scripts/_error_log_issue_body.py [--title-only]
"""
import json
import sys


def first_line(text: str) -> str:
    if not text:
        return "(no message)"
    return text.strip().splitlines()[0][:120]


def bare_path(source_file: str) -> str:
    """Strip a trailing `:LINE:COL` for a cleaner, still-identifying title."""
    parts = source_file.rsplit(":", 2)
    if len(parts) == 3 and parts[1].isdigit() and parts[2].isdigit():
        return parts[0]
    return source_file


def main() -> None:
    row = json.loads(sys.stdin.read())
    source_file = row.get("sourceFile") or "unknown source"
    message = row.get("message") or ""
    title = f"{bare_path(source_file)}: {first_line(message)}"

    if "--title-only" in sys.argv:
        print(title)
        return

    stack = row.get("stackTrace") or "(no stack trace captured)"
    route_hint = row.get("routeHint") or "(no route captured)"
    level = row.get("level", "error")
    occurrences = row.get("occurrences", 1)
    first_seen = row.get("firstSeen", "?")
    last_seen = row.get("lastSeen", "?")
    app_version = row.get("appVersion") or "?"
    platform = row.get("platform") or "?"
    is_pro = row.get("isPro", False)
    fingerprint = row["fingerprint"]

    touches = source_file if source_file != "unknown source" else "(no source file captured — inspect the stack trace below to identify it)"

    body = f"""## Found by
`scripts/triage_error_logs.sh` (#121 error-log automation) — auto-filed from a real on-device `{level}`, not written by a human or an agent from a code read. Verify against the stack trace before fixing.

## Level
`{level}` — seen {occurrences}x, first {first_seen}, last {last_seen}. Platform: {platform}. App version: {app_version}. Pro: {is_pro}.

## Message
```
{message}
```

## Stack trace
```
{stack}
```

## Route hint (best-effort, last occurrence)
`{route_hint}`

## Recreate
Best-effort from the captured context — the route above is where the last occurrence fired; the stack trace is the exact call path. If the route hint is empty or unhelpful, the message/stack above is the primary lead (this is common for framework-level errors like a `RenderFlex` overflow, which layout internals report without an app-code stack frame).

## Touches
`{touches}` — auto-predicted from the captured source file. **Verify and refine before claiming** (per CLAUDE.md: every issue needs an accurate Touches field for other agents to check parallel-safety against).

## Acceptance
- [ ] Root cause identified and fixed (or confirmed benign/expected and closed with a note — see #122's verdict table: expected control flow shouldn't have reached the error log in the first place, so if this fires again after the fix, check whether it should have been filtered at the `ErrorLogService` call site instead)
- [ ] Regression test added
- [ ] `./scripts/run_full_suite.sh` green

## Notes
Fingerprint: {fingerprint}
"""
    print(body)


if __name__ == "__main__":
    main()
