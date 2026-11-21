#!/usr/bin/env python3
"""Agent-factory guards for SisuMate (stdlib only).

Harness-agnostic logic; harnesses wire it in thin adapters (Claude Code:
`.claude/settings.json` → `scripts/hook_*.sh`). Hooks only govern agent tool
calls; a human at a terminal is never blocked.

Subcommands:
    hook-pretool    PreToolUse: deny/ask on unsafe git, generated + governance
                    files, and `git commit` without a matching suite receipt
    hook-stop       Stop: block while this session's code or test edits lack a fresh receipt
    snapshot        (run_full_suite.sh, at start) hash dirty files
    receipt-write   (run_full_suite.sh, on green) write build/suite_receipt.json
                    for files unchanged since the snapshot; ratchet test/.test_floor
    receipt         print the one-line receipt summary for issue comments

Rationale for each guard lives next to it. Tests: `python3 scripts/_factory_test.py`.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
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
    "scripts/review_staged.sh",
    "scripts/review_staged_test.py",
    "skills/cold-review/SKILL.md",
    "test/.test_floor",
    "AGENTS.md",
    "CLAUDE.md",
    "skills/cold-review/prompts/correctness.md",
    "skills/cold-review/prompts/contract.md",
    "skills/cold-review/prompts/acceptance.md",
    "skills/cold-review/prompts/verify.md",
)

_GOV_ALT = "|".join(re.escape(p) for p in GOVERNANCE_PATHS)
GOVERNANCE_WRITE_RE = re.compile(
    r"(?:>>?|\btee\b(?:\s+-a)?|\bcp\b|\bmv\b|\bsed\s+-i\b|\bperl\s+-i\b)"
    r"[^\n;|&]*\b(" + _GOV_ALT + r")\b")

RECEIPT = "build/suite_receipt.json"
SNAPSHOT = "build/suite_snapshot.json"
FLOOR = "test/.test_floor"
RECEIPT_FORGE_REASON = (
    "The gate scripts write the receipts. Agents do not write "
    "build/suite_receipt.json, build/review_receipt.json, the snapshot, or call receipt-write.")

# Commits touching only these need no suite receipt (no code, nothing the suite checks).
DOCS_ONLY_RE = re.compile(r"^(\.ai_context/|\.github/|plans/|skills/|marketing/)|^[^/]+\.md$")

# Commands that kill every agent's `flutter run`, not just the caller's.
SHARED_KILL_RE = re.compile(r"stop_flutter\.sh|\b(pkill|killall)\b[^\n]*\bflutter\b")
# #434: release credentials. The release scripts read them as subprocesses;
# an agent never needs the bytes, so a hijacked one can't exfiltrate them.
SECRET_RE = re.compile(
    r"(?:^|[\s'\"=/])(?:\./)?secrets/(?!README\.md\b)"
    r"|\bkey\.properties\b|\.(?:p8|jks|keystore)\b"
    r"|google-play-service-account|appstore-connect\.json")
RELEASE_RE = re.compile(r"\b(?:play_release|appstore_release)\.sh\b")
SECRET_REASON = ("That path holds release credentials (secrets/, signing keys). Agents never "
                 "read, copy or list them; the release scripts use them directly.")
FILE_TOOLS = ("Read", "Grep", "Glob")

SEGMENT_SPLIT_RE = re.compile(r"&&|\|\||;|\||\n")
ENV_ASSIGN_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
WRAPPER_TOKENS = {
    "bash", "sh", "zsh", "dash", "node", "python", "python3", "ruby",
    "perl", "php", "xargs", "env",
}

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
    if rel in (RECEIPT, SNAPSHOT, REVIEW_RECEIPT):
        return ("deny", RECEIPT_FORGE_REASON)
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


def _git_sub(toks: list[str]) -> tuple[str, list[str], str | None] | None:
    """('add', args, -C dir) for a git invocation, else None."""
    if os.path.basename(toks[0]) != "git":
        return None
    i, cdir = 1, None
    while i < len(toks) and toks[i].startswith("-"):
        if toks[i] in GIT_GLOBAL_WITH_VALUE:
            if toks[i] == "-C" and i + 1 < len(toks):
                cdir = toks[i + 1]
            i += 2
        else:
            i += 1
    if i >= len(toks):
        return None
    return toks[i], toks[i + 1:], cdir


def _short_flags(args: list[str]) -> set[str]:
    """Letters of single-dash flag clusters (`-am` → {'a','m'})."""
    flags: set[str] = set()
    for a in args:
        if a == "--":
            break
        if a.startswith("-") and not a.startswith("--") and len(a) > 1:
            flags.update(a[1:])
    return flags


COMMIT_TAKES_VALUE = {"-m", "-F", "-C", "-c", "-t", "--author", "--date", "--message",
                      "--file", "--template", "--fixup", "--squash", "--reuse-message",
                      "--reedit-message", "--trailer", "--cleanup"}


def _commit_flags(args: list[str]) -> tuple[set[str], set[str]]:
    """Short/long flags of `git commit`, skipping message/file values."""
    short: set[str] = set()
    long: set[str] = set()
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--":
            break
        if a.startswith("--"):
            long.add(a.split("=", 1)[0])
            if a in COMMIT_TAKES_VALUE:
                i += 1
        elif a.startswith("-") and len(a) > 1:
            short.update(a[1:])
            # A value-taking letter at the end of a cluster consumes the next token.
            if a[-1] in "mFCct":
                i += 1
        i += 1
    return short, long


def _pathspecs_after_values(args: list[str]) -> list[str]:
    """Positional (path) args of `git commit`, skipping option values."""
    if "--" in args:
        return args[args.index("--") + 1:]
    paths, i = [], 0
    while i < len(args):
        a = args[i]
        if a in COMMIT_TAKES_VALUE or (a.startswith("-") and not a.startswith("--")
                                       and len(a) > 1 and a[-1] in "mFCct"):
            i += 2
            continue
        if not a.startswith("-"):
            paths.append(a)
        i += 1
    return paths


def commit_message(args: list[str], cwd: str) -> str:
    """Concatenated -m/--message values and -F/--file contents (best effort)."""
    parts: list[str] = []
    i = 0
    while i < len(args):
        a = args[i]
        nxt = args[i + 1] if i + 1 < len(args) else ""
        if a in ("-m", "--message") or (a.startswith("-") and not a.startswith("--") and a.endswith("m")):
            parts.append(nxt)
            i += 2
            continue
        if a in ("-F", "--file") or (a.startswith("-") and not a.startswith("--") and a.endswith("F")):
            try:
                with open(os.path.join(cwd, nxt), encoding="utf-8") as fh:
                    parts.append(fh.read())
            except OSError:
                pass
            i += 2
            continue
        if a.startswith("--message="):
            parts.append(a.split("=", 1)[1])
        i += 1
    return "\n".join(parts)


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


def touches_secret(text: str) -> bool:
    """`text` is one argument or tool path: the folder itself or a path in it.
    Prose that merely mentions "secrets" (an issue comment) is not access."""
    t = text.replace("\\", "/").rstrip("/")
    return t in ("secrets", "./secrets") or t.endswith("/secrets") or bool(SECRET_RE.search(" " + t))


def forges_receipt(command: str) -> bool:
    """True when an agent command writes the receipt instead of the gate script."""
    if re.search(r"receipt-write|_factory\.py\s+snapshot\b", command):
        return True
    write = re.compile(
        r"(>>?|\btee\b|\bcp\b|\bmv\b|\binstall\b|\bopen\b|\bsed\s+-i\b|"
        r"\bnode\b|\bruby\b|\bperl\b|\bdd\b|\btruncate\b|\bwriteFileSync\b|"
        r"\bpython3?\s+(?:-c\b|[^\n;|&]*\.py\b))")
    if re.search(r"review_receipt\.json", command):
        return bool(write.search(command))
    if not re.search(r"suite_receipt\.json|suite_snapshot\.json", command):
        return False
    return bool(write.search(command))


def check_bash(command: str, cwd: str | None = None) -> tuple[str, str] | None:
    if forges_receipt(command):
        return ("deny", RECEIPT_FORGE_REASON)
    gov = GOVERNANCE_WRITE_RE.search(command)
    if gov:
        return ("ask", f"{gov.group(1)} is a factory governance file (guards, suite gate, "
                       "test floor, contract). A human must approve this edit.")
    if re.search(r"\b(?:bash|sh|zsh|dash)\s+-c\b", command) and re.search(r"\bgit\b", command):
        return ("deny", "Do not run git inside a shell wrapper (`bash -c`, `sh -c`); "
                        "stage and commit as literal commands so the suite and review "
                        "gates see exactly what is committed.")
    for toks in _segments(command):
        g = _git_sub(toks)
        if g and g[0] == "commit":
            continue  # a commit message may name secrets/ without reading it
        if any(touches_secret(t) for t in toks):
            return ("deny", SECRET_REASON)
    if RELEASE_RE.search(command):
        return ("ask", "This runs a store release (signed build + upload). "
                       "A human approves every run.")
    if SHARED_KILL_RE.search(command):
        return ("ask", "This kills every agent's `flutter run`, not just yours. "
                       "Prefer `kill <pid>` with the pid android_run.sh/ios_run.sh printed.")
    cwd = cwd or os.getcwd()
    staging_earlier = False
    saw_commit = False
    for toks in _segments(command):
        if toks and toks[0] in WRAPPER_TOKENS and any("git" in t for t in toks[1:]):
            return ("deny", "Do not run git inside a shell/interpreter wrapper; "
                            "stage and commit as literal commands so the suite and "
                            "review gates see exactly what is committed.")
        g = _git_sub(toks)
        if not g:
            continue
        sub, args, cdir = g
        verdict = check_git(sub, args)
        if verdict:
            return verdict
        if sub in ("add", "rm", "mv"):
            staging_earlier = True
        if sub == "commit":
            saw_commit = True
            # The gate inspects the index before the command runs, so staging in
            # the same command, or committing paths (`--only`/`-i` semantics take
            # working-tree content), would slip past it.
            if staging_earlier:
                return ("deny", "Stage and commit in separate commands, so the commit "
                                "gate sees what is staged.")
            if _pathspecs_after_values(args) or {"-i", "--include", "-o", "--only"} & set(args):
                return ("deny", "Commit what is staged, without paths: `git add <files>`, "
                                "then a bare `git commit -m ...`.")
            gcwd = os.path.join(cwd, cdir) if cdir else cwd
            root = _repo_root(gcwd)
            if root and os.path.exists(os.path.join(root, "scripts", "_factory.py")):
                verdict = guarded_commit_check(root, commit_message(args, gcwd))
                if verdict:
                    return verdict
    if not saw_commit and re.search(
            r"\bgit\s+commit\b|['\"]git['\"]\s*,\s*['\"]commit['\"]", command):
        return ("deny", "Run `git commit` as a literal command, not inside a shell "
                        "or interpreter wrapper; the suite and review gates cannot "
                        "inspect the wrapped commit.")
    return None


# --- git plumbing -----------------------------------------------------------------

def _git(root: str, *args: str) -> str:
    return subprocess.run(["git", "-C", root, *args], check=True,
                          capture_output=True, text=True).stdout


def _git_ok(root: str, *args: str) -> str | None:
    r = subprocess.run(["git", "-C", root, *args], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else None


def staged_entries(root: str) -> dict[str, str | None]:
    """{path: staged blob sha | None for a deletion}."""
    out: dict[str, str | None] = {}
    raw = _git(root, "diff", "--cached", "--name-status", "-z", "--no-renames")
    toks = [t for t in raw.split("\0") if t]
    for status, path in zip(toks[0::2], toks[1::2]):
        if status.startswith("D"):
            out[path] = None
        else:
            line = _git(root, "ls-files", "-s", "--", path).split()
            out[path] = line[1] if len(line) > 1 else None
    return out


def dirty_hashes(root: str) -> dict[str, str | None]:
    """{path: working-tree blob sha | None if deleted} for every modified/untracked file."""
    raw = _git(root, "status", "--porcelain", "-z", "--untracked-files=all", "--no-renames")
    out: dict[str, str | None] = {}
    for entry in (e for e in raw.split("\0") if e):
        path = entry[3:]
        full = os.path.join(root, path)
        if os.path.isfile(full):
            out[path] = _git(root, "hash-object", "--", path).strip()
        elif not os.path.exists(full):
            out[path] = None
    return out


def read_floor(text: str | None) -> int:
    try:
        return int((text or "0").strip() or 0)
    except ValueError:
        return 0


# --- cold review (#422) -------------------------------------------------------------

REVIEW_RECEIPT = "build/review_receipt.json"
REVIEW_PROMPT_DIR = "skills/cold-review/prompts"
REVIEW_PROMPTS = ("correctness.md", "contract.md", "acceptance.md", "verify.md")

HUNK_RE = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@")
_DIFF_GIT_RE = re.compile(r"^diff --git a/(.*) b/(.*)$")
_LLM_FALLBACK_RE = re.compile(
    r"(?i)(?<![A-Za-z])(?:local(?:ly)?|fallback|offline|heuristic)(?![A-Za-z])")
SYMBOL_RE = re.compile(
    r"^\s*(?:class|mixin|enum|typedef)\s+([A-Z]\w*)"
    r"|^\s*(?:Future(?:<[^>]+>)?|void|String|int|double|bool|List(?:<[^>]+>)?|"
    r"Map(?:<[^>]+>)?|Widget|Stream(?:<[^>]+>)?|Timer)\s+([a-z_]\w*)\s*\("
)
CALLER_SKIP = {
    "build", "main", "run", "dispose", "initState", "toString", "fromJson",
    "toJson", "copyWith", "setState",
}


def review_diff(root: str) -> str:
    return _git(root, "diff", "--cached", "--no-color", "--no-ext-diff", "--unified=0")


def review_diff_hash(root: str) -> str:
    raw = subprocess.run(
        ["git", "-C", root, "diff", "--cached", "--binary", "--no-color"],
        capture_output=True,
    ).stdout
    return hashlib.sha256(raw).hexdigest()


def review_entries(root: str) -> list[tuple[str, str, int, str]]:
    """(path, add|del, new-line, text) for every staged hunk line."""
    out: list[tuple[str, str, int, str]] = []
    path = None
    line_no = 0
    for line in review_diff(root).splitlines():
        git_files = _DIFF_GIT_RE.match(line)
        if git_files:
            path = git_files.group(1) if git_files.group(2) in ("/dev/null", "dev/null") else git_files.group(2)
            continue
        if line.startswith("+++ b/"):
            path = line[6:]
            continue
        if line.startswith("+++ /dev/null"):
            continue
        if line.startswith("@@"):
            match = HUNK_RE.match(line)
            line_no = int(match.group(1)) if match else 0
            continue
        if path is None or line.startswith(("diff --git", "index ", "--- ", "+++ ")):
            continue
        if line.startswith("+") and not line.startswith("+++"):
            out.append((path, "add", line_no, line[1:]))
            line_no += 1
        elif line.startswith("-") and not line.startswith("---"):
            out.append((path, "del", line_no, line[1:]))
        elif line.startswith(" "):
            line_no += 1
    return out


def _finding(rule: str, path: str, line: int, scenario: str, severity: str = "high") -> dict:
    return {"rule": rule, "file": path, "line": line, "scenario": scenario,
            "severity": severity}


def lint_ui_drift(entries) -> list[dict]:
    out = []
    for path, kind, line, text in entries:
        if kind == "add" and path.startswith("lib/ui/") and re.search(
                r"import\s+['\"][^'\"]*(?:data/drift|app_database)", text):
            out.append(_finding("ui_drift_import", path, line,
                                "UI imports Drift directly; use a repository/provider."))
    return out


def lint_colour_literals(entries, root: str) -> list[dict]:
    out = []
    head_cache: dict[str, set[str]] = {}
    for path, kind, line, text in entries:
        if kind != "add" or not path.startswith("lib/ui/"):
            continue
        if not re.search(r"\bColor\s*\(\s*0x|\bColor\.from(?:ARGB|RGBO)\s*\(|\bColors\.[A-Za-z]", text):
            continue
        # A moved/reformatted line that already exists in HEAD is legacy, not
        # a new literal this change introduced.
        if path not in head_cache:
            head_cache[path] = {ln.strip() for ln in _head_text(root, path).splitlines()}
        if text.strip() in head_cache[path]:
            continue
        out.append(_finding("colour_literal", path, line,
                            "Colour literal outside SisuColors; use a theme token.", "medium"))
    return out


def lint_schema_without_migration(entries, staged_paths) -> list[dict]:
    bumped = [e for e in entries
              if e[0] == "lib/data/drift/app_database.dart" and e[1] == "add"
              and re.search(r"schemaVersion\s*(?:=>|=)\s*\d+", e[3])]
    if not bumped:
        return []
    if any(p.startswith("supabase/migrations/") and p.endswith(".sql") for p in staged_paths):
        return []
    return [_finding("schema_without_migration", bumped[0][0], bumped[0][2],
                     "schemaVersion changed with no staged supabase migration.")]


def _git_text(root: str, rev_path: str) -> str:
    proc = subprocess.run(["git", "-C", root, "show", rev_path],
                          capture_output=True, text=True)
    return proc.stdout if proc.returncode == 0 else ""


def _head_text(root: str, path: str) -> str:
    return _git_text(root, f"HEAD:{path}")


def _staged_text(root: str, path: str) -> str:
    text = _git_text(root, f":{path}")
    return text if text else _worktree_text(root, path)


def _worktree_text(root: str, path: str) -> str:
    try:
        with open(os.path.join(root, path), encoding="utf-8") as fh:
            return fh.read()
    except OSError:
        return ""


def lint_llm_only(entries, root: str) -> list[dict]:
    out = []
    for path, kind, line, text in entries:
        if kind != "add" or not path.startswith(("lib/ui/", "lib/services/")):
            continue
        if path == "lib/services/llm_client_service.dart":
            continue
        if not re.search(r"\bLlmClientService\b|\bllmClient\b", text):
            continue
        if "_local_" in path or _LLM_FALLBACK_RE.search(_staged_text(root, path)):
            continue
        out.append(_finding("llm_only", path, line,
                            "LLM call with no local/offline fallback (#286)."))
    return out


def lint_unlogged_catch(entries, root: str) -> list[dict]:
    out = []
    for path, kind, line, text in entries:
        if kind != "add" or not path.startswith("lib/") or not re.search(r"\bcatch\s*\(", text):
            continue
        lines = _staged_text(root, path).splitlines()
        window = "\n".join(lines[max(0, line - 1):line + 15])
        if re.search(r"ErrorLogService|logException|logWarning|rethrow|\bthrow\b|// no log|// expected", window):
            continue
        out.append(_finding("unlogged_catch", path, line,
                            "catch neither logs nor rethrows; log it or add a no-log comment.",
                            "medium"))
    return out


def lint_test_tamper(entries) -> list[dict]:
    by_file: dict[str, dict[str, list[tuple[int, str]]]] = {}
    for path, kind, line, text in entries:
        if path.startswith(("test/", "integration_test/")):
            by_file.setdefault(path, {"add": [], "del": []})[kind].append((line, text))
    out = []
    for path, sides in by_file.items():
        deleted_expects = [x for x in sides["del"] if "expect(" in x[1]]
        added_expects = [x for x in sides["add"] if "expect(" in x[1]]
        if len(deleted_expects) > len(added_expects):
            out.append(_finding("test_tamper", path, deleted_expects[0][0],
                                "expect() assertion removed without replacement."))
        for line, text in sides["add"]:
            if re.search(r"\bskip\s*:|@Skip\b|testOn\s*:", text):
                out.append(_finding("test_tamper", path, line, "test skipped or narrowed."))
        deleted_tests = [x for x in sides["del"] if re.search(r"\b(?:test|testWidgets)\s*\(", x[1])]
        added_tests = [x for x in sides["add"] if re.search(r"\b(?:test|testWidgets)\s*\(", x[1])]
        if len(deleted_tests) > len(added_tests):
            out.append(_finding("test_tamper", path, deleted_tests[0][0],
                                "test removed without replacement."))
    return out


def changed_symbol_callers(entries, root: str) -> dict[str, list[str]]:
    symbols: dict[str, str] = {}
    for path, kind, line, text in entries:
        if kind != "add" or not path.startswith("lib/"):
            continue
        match = SYMBOL_RE.match(text)
        if not match:
            continue
        symbol = match.group(1) or match.group(2)
        if symbol and symbol not in CALLER_SKIP and len(symbol) > 2:
            symbols.setdefault(symbol, path)
    out: dict[str, list[str]] = {}
    for symbol, defining in symbols.items():
        result = subprocess.run(
            ["git", "-C", root, "grep", "-n", "-w", symbol, "--", "lib", "test",
             "integration_test"],
            capture_output=True, text=True,
        )
        hits = [line for line in result.stdout.splitlines()
                if not line.startswith(defining + ":")]
        if hits:
            out[symbol] = hits[:8]
    return out


def regression_proof(root: str, tests: list[str], run: bool) -> list[dict]:
    """Staged tests must fail with HEAD's lib/ in a scratch worktree."""
    if not tests:
        return []
    if not run:
        return [{"test": t, "result": "not_run"} for t in tests]
    scratch = tempfile.mkdtemp(prefix="sisu-review-")
    results: list[dict] = []
    try:
        _git(root, "worktree", "add", "--detach", scratch, "HEAD")
        patch = subprocess.run(["git", "-C", root, "diff", "--cached", "--binary"],
                               capture_output=True, check=True).stdout
        subprocess.run(["git", "-C", scratch, "apply", "--index"], input=patch, check=True)
        # New lib/ files are in the scratch index after `git apply --index`;
        # reset them to untracked, restore HEAD, then delete them. Checkout
        # alone cannot remove an index-tracked addition and clean skips it.
        _git(scratch, "reset", "HEAD", "--", "lib")
        _git(scratch, "checkout", "HEAD", "--", "lib")
        _git(scratch, "clean", "-fd", "--", "lib")
        dot = os.path.join(root, ".dart_tool")
        if os.path.isdir(dot) and not os.path.exists(os.path.join(scratch, ".dart_tool")):
            os.symlink(dot, os.path.join(scratch, ".dart_tool"))
        for test in tests:
            if not os.path.exists(os.path.join(scratch, test)):
                results.append({"test": test, "result": "missing"})
                continue
            try:
                proc = subprocess.run(["flutter", "test", test], cwd=scratch,
                                      capture_output=True, text=True, timeout=900)
                output = proc.stdout + proc.stderr
                if proc.returncode and re.search(
                        r"package_config|pub get|Could not resolve|No pubspec",
                        output, re.I):
                    result = "unknown"
                else:
                    result = "fail" if proc.returncode else "pass"
                results.append({"test": test, "result": result})
            except (OSError, subprocess.TimeoutExpired):
                results.append({"test": test, "result": "unknown"})
    except Exception:
        return [{"test": t, "result": "unknown"} for t in tests]
    finally:
        subprocess.run(["git", "-C", root, "worktree", "remove", "--force", scratch],
                       capture_output=True)
        shutil.rmtree(scratch, ignore_errors=True)
    return results


def review_facts(root: str, regression: bool = False) -> dict:
    entries = review_entries(root)
    entries_map = staged_entries(root)
    staged = sorted(entries_map)
    staged_present = sorted(p for p, blob in entries_map.items() if blob is not None)
    tests = [p for p in staged if p.startswith(("test/", "integration_test/"))]
    findings = (
        lint_ui_drift(entries)
        + lint_colour_literals(entries, root)
        + lint_schema_without_migration(entries, staged_present)
        + lint_llm_only(entries, root)
        + lint_unlogged_catch(entries, root)
        + lint_test_tamper(entries)
    )
    return {
        "head": _git(root, "rev-parse", "HEAD").strip(),
        "diff_hash": review_diff_hash(root),
        "changed": staged,
        "changed_lib": [p for p in staged if p.startswith("lib/")],
        "changed_tests": tests,
        "facts": {
            "regression_proof": regression_proof(root, tests, regression),
            "callers": changed_symbol_callers(entries, root),
        },
        "findings": findings,
    }


def load_review_receipt(root: str) -> dict | None:
    try:
        with open(os.path.join(root, REVIEW_RECEIPT), encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return None


def review_receipt_summary(receipt: dict | None) -> str:
    if not receipt:
        return "no review receipt (stage files, then run scripts/review_staged.sh <issue>)"
    return (f"Review {receipt.get('status', '?')} ({receipt.get('reviewer_family', '?')}): "
            f"{len(receipt.get('findings') or [])} finding(s), round "
            f"{receipt.get('round', '?')}, diff {str(receipt.get('diff_hash', ''))[:12]}")


def review_gate(root: str, code_paths: list[str]) -> tuple[str, str] | None:
    if not code_paths:
        return None
    receipt = load_review_receipt(root)
    if not receipt:
        return ("deny", "No review receipt. Stage your files, then run "
                        "`scripts/review_staged.sh <issue>` and fix confirmed findings.")
    if receipt.get("diff_hash") != review_diff_hash(root):
        return ("deny", "Review receipt is stale: the staged diff changed after the review. "
                        "Re-run scripts/review_staged.sh.")
    if receipt.get("status") != "PASS":
        findings = receipt.get("findings") or []
        shown = "; ".join(f"{f.get('file')}:{f.get('line')} {f.get('rule', 'finding')}"
                          for f in findings[:5])
        return ("deny", f"Cold review {receipt.get('status')}: "
                        f"{shown or 'see ' + REVIEW_RECEIPT}")
    return None


def extract_json(text: str):
    text = text.strip()
    try:
        return json.loads(text)
    except ValueError:
        pass
    for match in re.finditer(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.S):
        try:
            return json.loads(match.group(1))
        except ValueError:
            continue
    start = text.find("{")
    if start >= 0:
        for end in range(len(text), start, -1):
            try:
                return json.loads(text[start:end])
            except ValueError:
                continue
    raise ValueError("no JSON object in reviewer output")


# --- suite receipt (#420) ---------------------------------------------------------

def count_flutter_report(lines) -> dict[str, int]:
    """Counts from a `flutter test --file-reporter json:` file (one event per line)."""
    passed = skipped = failed = 0
    for line in lines:
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if not isinstance(ev, dict) or ev.get("type") != "testDone" or ev.get("hidden"):
            continue
        if ev.get("skipped"):
            skipped += 1
        elif ev.get("result") == "success":
            passed += 1
        else:
            failed += 1
    return {"passed": passed, "skipped": skipped, "failed": failed}


def write_snapshot(root: str) -> None:
    """Hashes of dirty files when the suite starts (see write_receipt)."""
    os.makedirs(os.path.join(root, "build"), exist_ok=True)
    with open(os.path.join(root, SNAPSHOT), "w") as fh:
        json.dump(dirty_hashes(root), fh)


def write_receipt(root: str, flags: str, report_path: str, started: float | None) -> dict:
    with open(os.path.join(root, report_path), encoding="utf-8") as fh:
        counts = count_flutter_report(fh)
    if counts["failed"]:
        raise SystemExit(f"receipt-write: {counts['failed']} failed tests in {report_path}; no receipt")
    flags = flags.strip()
    floor_path = os.path.join(root, FLOOR)
    old_floor = 0
    if os.path.exists(floor_path):
        with open(floor_path) as fh:
            old_floor = read_floor(fh.read())
    # Ratchet only on a full run; it only ever goes up (lowering it is a governance edit).
    if not flags and counts["passed"] > old_floor:
        with open(floor_path, "w") as fh:
            fh.write(f"{counts['passed']}\n")
    receipt = {
        "head": _git(root, "rev-parse", "HEAD").strip(),
        "flags": flags,
        "host_tests": counts["passed"],
        "skipped": counts["skipped"],
        "floor": max(old_floor, counts["passed"]) if not flags else old_floor,
        "finished_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "duration_s": int(time.time() - started) if started else None,
        "files": verified_files(root),
    }
    os.makedirs(os.path.join(root, "build"), exist_ok=True)
    with open(os.path.join(root, RECEIPT), "w") as fh:
        json.dump(receipt, fh, indent=1, sort_keys=True)
    return receipt


def verified_files(root: str) -> dict[str, str | None]:
    """Dirty files whose content was the same at suite start and end.

    A file edited while the suite ran was not what the tests saw, so it is left
    out and counts as unverified at commit time. The floor file is the one
    expected mid-run change (the suite itself raises it).
    """
    try:
        with open(os.path.join(root, SNAPSHOT), encoding="utf-8") as fh:
            start = json.load(fh)
    except (OSError, ValueError):
        raise SystemExit("receipt-write: no start snapshot; run via ./scripts/run_full_suite.sh")
    end = dirty_hashes(root)
    head = "<clean at start>"
    return {p: h for p, h in end.items()
            if p == FLOOR or start.get(p, head) == h}


def load_receipt(root: str) -> dict | None:
    try:
        with open(os.path.join(root, RECEIPT), encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return None


def receipt_summary(r: dict | None) -> str:
    if not r:
        return "no suite receipt (run ./scripts/run_full_suite.sh)"
    flags = r.get("flags") or "no skip flags"
    return (f"Suite green ({flags}): {r['host_tests']} host tests, {r['skipped']} skipped, "
            f"floor {r['floor']}, at {r['head'][:7]} + {len(r['files'])} dirty files, "
            f"{r['finished_utc']}")


def commit_check(root: str, message: str) -> tuple[str, str] | None:
    """Deny/ask for a commit whose staged content the suite didn't verify."""
    staged = staged_entries(root)
    if not staged:
        return None
    gov = sorted(p for p in staged if p in GOVERNANCE_PATHS)
    code = [p for p in staged if not DOCS_ONLY_RE.match(p)]
    if code:
        r = load_receipt(root)
        if not r:
            return ("deny", "No suite receipt. Run ./scripts/run_full_suite.sh after your "
                            "last edit; it writes build/suite_receipt.json on green.")
        files = r.get("files", {})
        stale = []
        for path, blob in staged.items():
            if path in files:
                ok = files[path] == blob
            else:
                # Clean at suite time: the staged content must equal that commit's version.
                at_suite = _git_ok(root, "rev-parse", f"{r['head']}:{path}")
                ok = (at_suite or "").strip() == (blob or "") if blob else at_suite is None
            if not ok:
                stale.append(path)
        if stale:
            return ("deny", "Staged content differs from what the suite verified: "
                    + ", ".join(sorted(stale)[:8])
                    + ". Re-run ./scripts/run_full_suite.sh after your last edit.")
        if r.get("flags") and "suite-skip:" not in message:
            return ("deny", f"Receipt was produced with `{r['flags']}`. Add a "
                            "`suite-skip: <reason>` line to the commit message.")
        head_floor = read_floor(_git_ok(root, "show", f"HEAD:{FLOOR}"))
        if r.get("host_tests", 0) < head_floor:
            return ("deny", f"Host test count {r.get('host_tests')} is below the floor "
                            f"{head_floor} in HEAD. Tests were removed or skipped.")
        review = review_gate(root, code)
        if review:
            return review
    if FLOOR in staged:
        new = read_floor(_git_ok(root, "show", f":{FLOOR}"))
        if new < read_floor(_git_ok(root, "show", f"HEAD:{FLOOR}")):
            return ("deny", "test/.test_floor may only go up.")
    if gov:
        # Catches governance files changed by any means (incl. shell writes the
        # edit guard can't see).
        return ("ask", "This commit changes factory governance files: " + ", ".join(gov)
                + ". A human must approve.")
    return None


def guarded_commit_check(root: str, message: str) -> tuple[str, str] | None:
    try:
        return commit_check(root, message)
    except Exception as e:  # fail closed: a broken gate must not wave commits through
        return ("deny", f"Commit check crashed ({type(e).__name__}: {e}). Fix scripts/_factory.py.")


# --- stop hook ----------------------------------------------------------------------

EDIT_TOOLS = ("Edit", "Write", "MultiEdit", "NotebookEdit")


def edited_paths(transcript_lines) -> set[str]:
    """File paths passed to edit tools anywhere in a session transcript (JSONL)."""
    found: set[str] = set()

    def walk(o):
        if isinstance(o, dict):
            if o.get("type") == "tool_use" and o.get("name") in EDIT_TOOLS:
                inp = o.get("input") or {}
                p = inp.get("file_path") or inp.get("notebook_path")
                if p:
                    found.add(p)
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)

    for line in transcript_lines:
        try:
            walk(json.loads(line))
        except ValueError:
            continue
    return found


LOOP_PREFIXES = ("lib/", "test/", "integration_test/", "scripts/", "tool/")


def stale_session_edits(root: str, paths: set[str]) -> list[str]:
    """This session's code or test edits that are dirty but not in a fresh receipt."""
    rels = {repo_relative(os.path.abspath(p), root) for p in paths}
    rels = {p for p in rels if p.startswith(LOOP_PREFIXES)}
    if not rels:
        return []
    dirty = dirty_hashes(root)
    files = (load_receipt(root) or {}).get("files", {})
    return sorted(p for p in rels if p in dirty and files.get(p, "missing") != dirty[p])


# --- hook plumbing --------------------------------------------------------------

def pretool_decision(payload: dict) -> tuple[str, str] | None:
    tool = payload.get("tool_name", "")
    inp = payload.get("tool_input") or {}
    cwd = payload.get("cwd") or os.getcwd()
    if tool in FILE_TOOLS + EDIT_TOOLS:
        for key in ("file_path", "notebook_path", "path", "pattern" if tool == "Glob" else ""):
            val = inp.get(key) if key else None
            if isinstance(val, str) and touches_secret(val):
                return ("deny", SECRET_REASON)
    if tool in EDIT_TOOLS:
        path = inp.get("file_path") or inp.get("notebook_path") or ""
        if not path:
            return None
        path = os.path.join(cwd, path)  # no-op for absolute paths
        # Root from the file itself: the session cwd may be a scratchpad.
        root = _repo_root(os.path.dirname(path))
        return check_edit(os.path.normpath(path), root) if root else None
    if tool == "Bash":
        return check_bash(inp.get("command", ""), cwd)
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


def _arg(argv: list[str], name: str, default: str | None = None) -> str | None:
    return argv[argv.index(name) + 1] if name in argv and argv.index(name) + 1 < len(argv) else default


HOLD_OFF_RE = re.compile(
    r"(?i)(?:please\s+)?(?:hold off|stop now|do not continue|don't continue|you can stop)\b")


def is_hold_off(text: str) -> bool:
    """Last user line is a session-end, not a debugging instruction like 'stop guessing'."""
    raw = (text or "").replace("\u2019", "'").strip().splitlines()
    line = raw[0].strip() if raw else ""
    return bool(line) and len(line) <= 80 and bool(HOLD_OFF_RE.match(line))


def _flatten_text(content) -> str:
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, str):
                parts.append(item)
            elif isinstance(item, dict) and item.get("type") in (None, "text"):
                parts.append(str(item.get("text") or ""))
        return "\n".join(p for p in parts if p).strip()
    if isinstance(content, dict):
        return str(content.get("text") or "").strip()
    return ""


def _user_text(obj) -> str:
    if not isinstance(obj, dict):
        return ""
    role = obj.get("type") or obj.get("role") or ""
    msg = obj.get("message")
    if isinstance(msg, dict):
        role = role or msg.get("role") or ""
        content = msg.get("content")
    else:
        content = obj.get("content")
    if role not in ("user", "human"):
        return ""
    return _flatten_text(content)


def last_user_text(transcript_lines) -> str:
    last = ""
    for line in transcript_lines:
        try:
            text = _user_text(json.loads(line))
        except ValueError:
            continue
        if text:
            last = text
    return last


def stop_block(stale: list[str]) -> dict:
    shown = ", ".join(stale[:6])
    extra = f" (+{len(stale) - 6} more)" if len(stale) > 6 else ""
    return {
        "decision": "block",
        "reason": (
            "[factory] Not done. These edits have no fresh green suite receipt: "
            f"{shown}{extra}. "
            "Run ./scripts/run_full_suite.sh after the last edit. If it is red, fix the "
            "cause and re-run. Do not claim done, commit, or push. Do not weaken, skip, "
            "delete, or narrow a test to get green. If the same failure has been fixed "
            "three times with no new evidence, or a human must decide, revert these edits "
            "and then stop. A human hold-off (hold off, stop now, do not continue, you can "
            "stop) is the only other way to end with these edits still dirty. A harness cap "
            "that forces this session to end is not green. Do not commit."
        ),
    }


def stop_decision(stale: list[str], user_text: str) -> dict | None:
    if not stale or is_hold_off(user_text):
        return None
    return stop_block(stale)

def main(argv: list[str]) -> int:
    cmd = argv[1] if len(argv) > 1 else ""
    root = _repo_root(os.getcwd()) or os.getcwd()
    if cmd == "hook-pretool":
        try:
            payload = json.load(sys.stdin)
        except ValueError:
            return 0
        emit_pretool(pretool_decision(payload))
        return 0

    if cmd == "hook-stop":
        try:
            payload = json.load(sys.stdin)
            with open(payload.get("transcript_path", ""), encoding="utf-8") as fh:
                lines = fh.readlines()
            stop_root = _repo_root(payload.get("cwd") or root) or root
            stale = stale_session_edits(stop_root, edited_paths(lines))
            user = last_user_text(lines)
        except (ValueError, OSError):
            return 0
        decision = stop_decision(stale, user)
        if decision:
            print(json.dumps(decision))
        return 0
    if cmd == "receipt-write":
        started = _arg(argv, "--started")
        r = write_receipt(root, _arg(argv, "--flags", "") or "",
                          _arg(argv, "--report", "build/flutter_test_report.json"),
                          float(started) if started else None)
        print(receipt_summary(r))
        return 0
    if cmd == "snapshot":
        write_snapshot(root)
        return 0
    if cmd == "receipt":
        print(receipt_summary(load_receipt(root)))
        return 0
    if cmd == "review-facts":
        print(json.dumps(review_facts(root, "--regression" in argv), indent=1, sort_keys=True))
        return 0
    if cmd == "review-hash":
        print(review_diff_hash(root))
        return 0
    if cmd == "review-parse":
        try:
            data = extract_json(sys.stdin.read())
        except ValueError as exc:
            print(f"review-parse: {exc}", file=sys.stderr)
            return 1
        print(json.dumps(data, indent=1, sort_keys=True))
        return 0
    if cmd == "review-receipt":
        print(review_receipt_summary(load_review_receipt(root)))
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
