#!/usr/bin/env python3
"""Renders one triage_error_logs.sh JSONL row (from tool/error_log_admin.dart
dump-unprocessed) into a GitHub issue title or body. Not a standalone
entrypoint — called by triage_error_logs.sh, which `cd`s to the repo root
first (so relative lib/... and test/... paths below resolve correctly).

Usage:
  echo '<json line>' | python3 scripts/_error_log_issue_body.py [--title-only]
"""
import json
import re
import sys

CONTEXT_LINES = 6
# Nearest enclosing class/mixin, scanned backward from the reported line —
# gives an agent "which screen/class" without opening the file, and feeds a
# more descriptive issue title than the bare file path.
_CLASS_RE = re.compile(r"^\s*(?:abstract\s+)?(?:class|mixin)\s+(\w+)")

# `logFlutterError` now renders via `details.toString()` (needed to reach the
# file:line location — see error_log_service.dart), which is Flutter's full
# boxed console format: a `══╡ EXCEPTION CAUGHT BY X ╞══...` border line,
# then a "The following ... was thrown[...]:" lead-in, THEN the actual
# one-line summary ("A RenderFlex overflowed by 1.1 pixels on the bottom.").
# Naively taking the literal first line put that border/boilerplate in every
# title instead of the summary. Skip both to find the real summary line.
_BORDER_RE = re.compile(r"^[\s═╡╞◢◤]+$")
_LEAD_IN_RE = re.compile(r"^The following .* was thrown.*:$")


def first_line(text: str) -> str:
    if not text:
        return "(no message)"
    lines = text.strip().splitlines()
    for raw in lines:
        line = raw.strip()
        if not line or _BORDER_RE.match(line) or "EXCEPTION CAUGHT BY" in line:
            continue
        if _LEAD_IN_RE.match(line):
            continue
        return line[:120]
    return lines[0][:120]


def parse_source_file(source_file: str):
    """`package:sisu_mate/ui/x.dart:112:14` -> ('lib/ui/x.dart', 112, 14).
    `test/foo_test.dart:20:5` -> ('test/foo_test.dart', 20, 5). Returns None
    if source_file doesn't match this shape (e.g. "unknown source")."""
    m = re.match(r"^(?:package:sisu_mate/|test/)(.+):(\d+):(\d+)$", source_file)
    if not m:
        return None
    rel = m.group(1)
    path = f"lib/{rel}" if source_file.startswith("package:sisu_mate/") else source_file.rsplit(":", 2)[0]
    return path, int(m.group(2)), int(m.group(3))


def enclosing_class(lines: list[str], line_no: int) -> str | None:
    """Nearest `class Foo`/`mixin Foo` above line_no (1-based)."""
    for i in range(min(line_no, len(lines)) - 1, -1, -1):
        m = _CLASS_RE.match(lines[i])
        if m:
            return m.group(1)
    return None


def code_snippet(path: str, line_no: int, col: int):
    """Returns (snippet_text, enclosing_class_or_None), or (None, None) if
    the file can't be read (different machine, moved/renamed since capture,
    etc.) — triage must degrade gracefully, never crash on a stale path."""
    try:
        with open(path, encoding="utf-8") as f:
            lines = f.read().splitlines()
    except OSError:
        return None, None

    cls = enclosing_class(lines, line_no)
    start = max(1, line_no - CONTEXT_LINES)
    end = min(len(lines), line_no + CONTEXT_LINES)
    width = len(str(end))
    out = []
    for n in range(start, end + 1):
        marker = ">>" if n == line_no else "  "
        text = lines[n - 1] if n - 1 < len(lines) else ""
        out.append(f"{marker} {str(n).rjust(width)}| {text}")
    return "\n".join(out), cls


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

    parsed = parse_source_file(source_file) if source_file != "unknown source" else None
    snippet, cls = (None, None)
    if parsed:
        snippet, cls = code_snippet(*parsed)

    title_prefix = f"{cls} ({bare_path(source_file)})" if cls else bare_path(source_file)
    title = f"{title_prefix}: {first_line(message)}"

    if "--title-only" in sys.argv:
        print(title)
        return

    stack = row.get("stackTrace") or "(no stack trace captured)"
    route_hint = row.get("routeHint") or "(no route captured)"
    debug_breadcrumbs = row.get("debugBreadcrumbs")
    level = row.get("level", "error")
    occurrences = row.get("occurrences", 1)
    first_seen = row.get("firstSeen", "?")
    last_seen = row.get("lastSeen", "?")
    app_version = row.get("appVersion") or "?"
    platform = row.get("platform") or "?"
    is_pro = row.get("isPro", False)
    fingerprint = row["fingerprint"]

    touches = source_file if source_file != "unknown source" else "(no source file captured — inspect the stack trace below to identify it)"
    touches_suffix = f" (inside `{cls}`)" if cls else ""

    breadcrumbs_section = ""
    if debug_breadcrumbs:
        breadcrumbs_section = f"""
## Recent provider activity (best-effort, up to 20 events before capture)
Riverpod provider lifecycle events immediately preceding this — helps pin down timing-dependent
races (e.g. a StreamProvider emission landing mid-build) that the stack trace alone can't show,
since Riverpod's own scheduler frames don't name which provider triggered them.
```
{debug_breadcrumbs}
```
"""

    code_section = ""
    if parsed:
        path, line_no, col = parsed
        if snippet:
            code_section = f"""
## Code at the reported location
`{path}:{line_no}:{col}`{f" — inside `{cls}`" if cls else ""}
```dart
{snippet}
```
"""
        else:
            code_section = f"""
## Code at the reported location
`{path}:{line_no}:{col}` — file not found in this checkout at triage time (moved/renamed since capture, or triaged from a different machine). Open it directly at that line.
"""

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
{code_section}
## Route hint (best-effort, last occurrence)
`{route_hint}`
{breadcrumbs_section}
## Recreate
Best-effort from the captured context — the route above is where the last occurrence fired; the stack trace is the exact call path. If the route hint is empty or unhelpful, the message/stack above is the primary lead (this is common for framework-level errors like a `RenderFlex` overflow, which layout internals report without an app-code stack frame).

## Touches
`{touches}`{touches_suffix} — auto-predicted from the captured source file. **Verify and refine before claiming** (per CLAUDE.md: every issue needs an accurate Touches field for other agents to check parallel-safety against).

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
