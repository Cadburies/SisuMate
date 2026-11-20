#!/usr/bin/env python3
"""Validate skills/*/SKILL.md against the repo's Agent Skills contract.

Run:
    python3 scripts/validate_skills.py
    python3 scripts/validate_skills.py --skills-dir /tmp/fixture/skills

Checks (errors):
  - YAML frontmatter at line 1, only `name` and `description`
  - `name` matches the folder and is lowercase kebab-case
  - `description` is one line, <= 1024 chars, starts with "Use "
  - no slash commands (`/correct`, `/triage`) in the description or body
  - no machine-specific absolute paths (`/Users/...`, `~/...`, `C:\\...`)
  - every referenced `scripts/`, `tool/`, `skills/`, `.ai_context/`, `lib/`,
    `test/`, `supabase/`, `android/`, `ios/` path exists
  - every relative Markdown link resolves

Warnings: SKILL.md longer than 120 lines. `cyber-check` may name `.claude/`
and `CLAUDE.md` on purpose: those are audit targets, not vendor instructions.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

FRONTMATTER_KEYS = {"name", "description"}
NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
MAX_DESCRIPTION = 1024
MAX_LINES = 120
REF_PREFIXES = (
    "scripts/",
    "tool/",
    "skills/",
    ".ai_context/",
    "lib/",
    "test/",
    "integration_test/",
    "supabase/",
    "android/",
    "ios/",
)
# Machine-specific paths only. `/tmp/evidence/...` is a legitimate artifact path.
ABS_PATH_RE = re.compile(r"(^|[\s`(])/(?:Users|home|root)/|(^|[\s`(])~/|[A-Za-z]:\\\\")
SLASH_TOKEN_RE = re.compile(r"^/[A-Za-z][A-Za-z0-9_-]*$")
# Filesystem roots that can appear as `/tmp/...` in an allowed artifact path.
FS_ROOTS = {"tmp", "usr", "opt", "var", "etc", "dev", "bin", "sbin", "Applications", "Library", "System"}
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
TICK_RE = re.compile(r"`([^`]+)`")


def unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1].replace("''", "'")
    if len(value) >= 2 and value[0] == value[-1] == '"':
        try:
            return json.loads(value)
        except ValueError:
            return value[1:-1]
    return value


def parse_frontmatter(text: str) -> tuple[dict[str, str], int]:
    """Return (key -> scalar, index of the closing --- line)."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        raise ValueError("no frontmatter block at line 1")
    end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end = i
            break
    if end is None:
        raise ValueError("frontmatter opened with --- but never closed")

    data: dict[str, str] = {}
    i = 1
    while i < end:
        line = lines[i]
        if not line.strip() or line.lstrip().startswith("#"):
            i += 1
            continue
        if line[0].isspace():
            raise ValueError(f"line {i + 1}: unexpected indentation outside a block scalar")
        match = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if not match:
            raise ValueError(f"line {i + 1}: expected `key: value`")
        key, value = match.group(1), match.group(2)
        if key in data:
            raise ValueError(f"line {i + 1}: duplicate key `{key}`")
        if value.strip() in ("|", ">", "|-", ">-", "|+", ">+"):
            style = value.strip()[0]
            block: list[str] = []
            i += 1
            while i < end and (not lines[i].strip() or lines[i][0].isspace()):
                block.append(lines[i].strip())
                i += 1
            data[key] = ("\n" if style == "|" else " ").join(x for x in block if x)
            continue
        data[key] = unquote(value)
        i += 1
    return data, end


def slash_commands(line: str) -> list[str]:
    """Return command names written as a whole backtick span (`/correct`) or a
    bullet/line starting with a slash. `Process.run`/FFI is not a command."""
    found: list[str] = []
    for match in TICK_RE.finditer(line):
        content = match.group(1).strip()
        if SLASH_TOKEN_RE.match(content):
            name = content[1:]
            if name not in FS_ROOTS:
                found.append(name)
    stripped = line.strip()
    if stripped.startswith("- "):
        stripped = stripped[2:].strip()
    if stripped.startswith("/"):
        token = re.split(r"[\s.,;:)]", stripped, 1)[0]
        name = token[1:]
        if re.match(r"^[A-Za-z][A-Za-z0-9_-]*$", name) and name not in FS_ROOTS:
            found.append(name)
    return found


def check_references(
    path: Path, lines: list[str], body_start: int, root: Path
) -> list[str]:
    errors: list[str] = []
    for lineno in range(body_start, len(lines) + 1):
        line = lines[lineno - 1]
        if "http://" in line or "https://" in line:
            continue

        for command in slash_commands(line):
            errors.append(
                f"line {lineno}: slash command `/{command}` — describe the trigger, "
                "not a vendor command"
            )

        if ABS_PATH_RE.search(line):
            errors.append(
                f"line {lineno}: machine-specific absolute path — use a repo-relative path"
            )

        for match in TICK_RE.finditer(line):
            token = match.group(1).strip().split()[0].rstrip(".,;:")
            if not token.startswith(REF_PREFIXES):
                continue
            if any(ch in token for ch in "<>*{}$"):
                continue
            if not (root / token).exists():
                errors.append(f"line {lineno}: referenced path does not exist: {token}")

        for match in LINK_RE.finditer(line):
            target = match.group(1).split("#", 1)[0].strip()
            if not target or target.startswith(("http://", "https://", "mailto:", "tel:")):
                continue
            if target.startswith("/"):
                continue
            if not (path.parent / target).resolve().exists():
                errors.append(f"line {lineno}: relative link does not resolve: {target}")
    return errors


def validate_skill(
    path: Path, expected_name: str, root: Path
) -> tuple[list[str], list[str]]:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        return [f"cannot read: {exc}"], []

    errors: list[str] = []
    warnings: list[str] = []
    if text.startswith("\ufeff"):
        warnings.append("file starts with a UTF-8 BOM")

    try:
        frontmatter, closing = parse_frontmatter(text)
    except ValueError as exc:
        return [str(exc)], warnings

    for key in sorted(set(frontmatter) - FRONTMATTER_KEYS):
        errors.append(
            f"unknown frontmatter key `{key}` — only `name` and `description` are allowed"
        )

    name = frontmatter.get("name", "").strip()
    if not name:
        errors.append("missing `name`")
    elif not NAME_RE.match(name):
        errors.append(f"`name` must be lowercase kebab-case: {name!r}")
    elif name != expected_name:
        errors.append(f"`name` {name!r} does not match folder {expected_name!r}")

    description = frontmatter.get("description", "").strip()
    if not description:
        errors.append("missing `description`")
    else:
        if "\n" in description:
            errors.append("`description` must be one line")
        if len(description) > MAX_DESCRIPTION:
            errors.append(
                f"`description` is {len(description)} chars; limit is {MAX_DESCRIPTION}"
            )
        if not description.startswith("Use "):
            errors.append('`description` must start with "Use " (the trigger)')
        for command in slash_commands(description):
            errors.append(
                f"`description` contains slash command `/{command}` — describe the trigger"
            )

    lines = text.splitlines()
    body_start = closing + 2
    if not any(line.strip() for line in lines[body_start - 1 :]):
        errors.append("empty body after frontmatter")

    errors.extend(check_references(path, lines, body_start, root))

    if len(lines) > MAX_LINES:
        warnings.append(f"{len(lines)} lines; keep skills under {MAX_LINES}")

    return errors, warnings


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--skills-dir",
        help="defaults to <repo>/skills; references resolve against its parent",
    )
    parser.add_argument("--quiet", action="store_true", help="only print problems")
    args = parser.parse_args(argv)

    default_root = Path(__file__).resolve().parent.parent
    skills_dir = (
        Path(args.skills_dir).resolve() if args.skills_dir else default_root / "skills"
    )
    root = skills_dir.parent

    if not skills_dir.is_dir():
        print(f"validate-skills: no skills directory at {skills_dir}", file=sys.stderr)
        return 2

    skill_dirs = sorted(p for p in skills_dir.iterdir() if p.is_dir())
    if not skill_dirs:
        print(f"validate-skills: no skill folders in {skills_dir}", file=sys.stderr)
        return 2

    total_errors = 0
    total_warnings = 0
    for folder in skill_dirs:
        path = folder / "SKILL.md"
        if not path.exists():
            errors, warnings = ["missing SKILL.md"], []
        else:
            errors, warnings = validate_skill(path, folder.name, root)

        total_errors += len(errors)
        total_warnings += len(warnings)
        if errors:
            print(f"  ✗  {folder.name}")
            for message in errors:
                print(f"       ERROR: {message}")
        elif not args.quiet:
            print(f"  ✓  {folder.name}")
        for message in warnings:
            print(f"       WARN:  {message}")

    status = (
        "FAILED" if total_errors else "PASSED WITH WARNINGS" if total_warnings else "PASSED"
    )
    print(
        f"\n{len(skill_dirs)} skills checked — {total_errors} error(s), "
        f"{total_warnings} warning(s) — {status}"
    )
    return 1 if total_errors else 0


if __name__ == "__main__":
    sys.exit(main())
