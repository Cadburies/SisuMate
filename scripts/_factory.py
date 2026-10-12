#!/usr/bin/env python3
"""Agent-factory guards for SisuMate (stdlib only).

Called by Claude Code hooks (`.claude/settings.json` → `scripts/hook_*.sh`) and
by factory scripts. Hooks only govern agent tool calls; a human at a terminal
is never blocked.

Subcommands:
    hook-pretool   PreToolUse: deny/ask on unsafe git, generated + governance files

Rationale for each guard lives next to it. Tests: `python3 scripts/_factory_test.py`.
"""
from __future__ import annotations

import json
import os
import re
import shlex
import sys
from pathlib import PurePosixPath

# --- policy -----------------------------------------------------------------

GENERATED_SUFFIXES = (".g.dart", ".freezed.dart")

# Editing these changes the rules agents are judged by, so a human approves
# every edit (an agent must not be able to quietly switch a guard off).
GOVERNANCE_PATHS = (
    ".claude/settings.json",
    "scripts/_factory.py",
    "scripts/_factory_test.py",
    "scripts/hook_pretool.sh",
    "scripts/hook_stop.sh",
    "scripts/run_full_suite.sh",
    "test/.test_floor",
    "AGENTS.md",
    "CLAUDE.md",
)

# Commands that kill every agent's `flutter run`, not just the caller's.
SHARED_KILL_RE = re.compile(r"stop_flutter\.sh|\b(pkill|killall)\b[^\n]*\bflutter\b")

SEGMENT_SPLIT_RE = re.compile(r"&&|\|\||;|\||\n")
ENV_ASSIGN_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")

# git global options that take a separate value token.
GIT_GLOBAL_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace"}


# --- path rules ---------------------------------------------------------------

def repo_relative(path: str, root: str) -> str:
    """Repo-relative POSIX path; absolute paths outside root come back as-is."""
    p = str(PurePosixPath(path.replace("\\", "/")))
    root = root.rstrip("/") + "/"
    return p[len(root):] if p.startswith(root) else p


def check_edit(path: str, root: str) -> tuple[str, str] | None:
    """(decision, reason) for an Edit/Write on `path`, or None to allow."""
    rel = repo_relative(path, root)
    if rel.endswith(GENERATED_SUFFIXES):
        return ("deny", f"{rel} is generated. Change the source and run "
                        "`dart run build_runner build --delete-conflicting-outputs`.")
    if rel in GOVERNANCE_PATHS:
        return ("ask", f"{rel} is a factory governance file (guards, suite gate, "
                       "test floor, contract). A human must approve this edit.")
    return None


# --- bash rules -----------------------------------------------------------------

def _segments(command: str) -> list[list[str]]:
    out = []
    for seg in SEGMENT_SPLIT_RE.split(command):
        seg = seg.strip()
        if not seg:
            continue
        try:
            toks = shlex.split(seg)
        except ValueError:
            toks = seg.split()
        while toks and (ENV_ASSIGN_RE.match(toks[0]) or toks[0] in ("sudo", "command", "exec")):
            toks = toks[1:]
        if toks:
            out.append(toks)
    return out


def _git_sub(toks: list[str]) -> tuple[str, list[str]] | None:
    """('add', args) for a git invocation, else None."""
    if os.path.basename(toks[0]) != "git":
        return None
    i = 1
    while i < len(toks) and toks[i].startswith("-"):
        if toks[i] in GIT_GLOBAL_WITH_VALUE:
            i += 2
        else:
            i += 1
    if i >= len(toks):
        return None
    return toks[i], toks[i + 1:]


def _short_flags(args: list[str]) -> set[str]:
    """Letters of single-dash flag clusters (`-am` → {'a','m'})."""
    flags: set[str] = set()
    for a in args:
        if a == "--":
            break
        if a.startswith("-") and not a.startswith("--") and len(a) > 1:
            flags.update(a[1:])
    return flags


def _commit_flags(args: list[str]) -> tuple[set[str], set[str]]:
    """Short/long flags of `git commit`, skipping message/file values."""
    takes_value = {"-m", "-F", "-C", "-c", "-t", "--author", "--date", "--message",
                   "--file", "--template", "--fixup", "--squash", "--reuse-message",
                   "--reedit-message", "--trailer", "--cleanup"}
    short: set[str] = set()
    long: set[str] = set()
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--":
            break
        if a.startswith("--"):
            long.add(a.split("=", 1)[0])
            if a in takes_value:
                i += 1
        elif a.startswith("-") and len(a) > 1:
            short.update(a[1:])
            # A value-taking letter at the end of a cluster consumes the next token.
            if a[-1] in "mFCct":
                i += 1
        i += 1
    return short, long


def _pathspecs(args: list[str]) -> list[str]:
    if "--" in args:
        return args[args.index("--") + 1:]
    return [a for a in args if not a.startswith("-")]


SWEEP_SPECS = {".", ":/", ":", "*", "./"}


def check_git(sub: str, args: list[str]) -> tuple[str, str] | None:
    """Shared-tree-unsafe git: sweeps up or destroys other agents' work."""
    shared = " In the shared tree this would sweep up or destroy other agents' uncommitted work."
    if sub == "add":
        if {"A", "u"} & _short_flags(args) or {"--all", "--update"} & set(args) \
                or SWEEP_SPECS & set(_pathspecs(args)):
            return ("deny", "`git add` must name your own files (no -A/-u/--all/`.`)." + shared)
    elif sub == "commit":
        short, long = _commit_flags(args)
        if "a" in short or "--all" in long:
            return ("deny", "`git commit -a` stages every modified file." + shared
                    + " Stage your files by name, then commit.")
    elif sub == "push":
        if "f" in _short_flags(args) or any(a.startswith(("--force", "+")) for a in args):
            return ("deny", "Never force-push. On rejection: `git fetch` + rebase/merge, then push.")
    elif sub == "reset":
        if "--hard" in args:
            return ("deny", "`git reset --hard` discards the whole tree." + shared)
    elif sub in ("checkout", "restore"):
        if SWEEP_SPECS & set(_pathspecs(args)) or (sub == "checkout" and "f" in _short_flags(args)):
            return ("deny", f"`git {sub}` on the whole tree discards changes." + shared
                    + " Name the specific files.")
    elif sub == "clean":
        if "f" in _short_flags(args) or "--force" in args:
            return ("deny", "`git clean -f` deletes untracked files." + shared)
    elif sub == "stash":
        action = args[0] if args and not args[0].startswith("-") else "push"
        if action in ("push", "save") and "--" not in args:
            return ("deny", "A bare `git stash` stashes every agent's changes." + shared
                    + " Use `git stash push -- <your files>`.")
    return None


def check_bash(command: str) -> tuple[str, str] | None:
    if SHARED_KILL_RE.search(command):
        return ("ask", "This kills every agent's `flutter run`, not just yours. "
                       "Prefer `kill <pid>` with the pid android_run.sh/ios_run.sh printed.")
    for toks in _segments(command):
        g = _git_sub(toks)
        if g:
            verdict = check_git(*g)
            if verdict:
                return verdict
    return None


# --- hook plumbing --------------------------------------------------------------

def pretool_decision(payload: dict) -> tuple[str, str] | None:
    tool = payload.get("tool_name", "")
    inp = payload.get("tool_input") or {}
    cwd = payload.get("cwd") or os.getcwd()
    if tool in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
        path = inp.get("file_path") or inp.get("notebook_path") or ""
        if not path:
            return None
        path = os.path.join(cwd, path)  # no-op for absolute paths
        # Root from the file itself: the session cwd may be a scratchpad.
        root = _repo_root(os.path.dirname(path))
        return check_edit(os.path.normpath(path), root) if root else None
    if tool == "Bash":
        return check_bash(inp.get("command", ""))
    return None


def _repo_root(start: str) -> str | None:
    p = os.path.abspath(start)
    while p != "/":
        if os.path.exists(os.path.join(p, ".git")):
            return p
        p = os.path.dirname(p)
    return os.environ.get("CLAUDE_PROJECT_DIR")


def emit_pretool(decision: tuple[str, str] | None) -> None:
    if not decision:
        return
    kind, reason = decision
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": kind,
        "permissionDecisionReason": f"[factory] {reason}",
    }}))


def main(argv: list[str]) -> int:
    cmd = argv[1] if len(argv) > 1 else ""
    if cmd == "hook-pretool":
        try:
            payload = json.load(sys.stdin)
        except ValueError:
            return 0
        emit_pretool(pretool_decision(payload))
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
