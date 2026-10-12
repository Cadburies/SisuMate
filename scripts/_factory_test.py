#!/usr/bin/env python3
"""Unit tests for scripts/_factory.py — run with:

    python3 scripts/_factory_test.py

Every guard test asserts *which* guard fired (by reason text), not just that
something denied, so deleting any one guard turns its test red.
"""
from __future__ import annotations

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _factory as f  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def bash(cmd: str):
    return f.pretool_decision({"tool_name": "Bash", "tool_input": {"command": cmd}, "cwd": ROOT})


def edit(rel: str, tool: str = "Edit"):
    return f.pretool_decision({"tool_name": tool,
                               "tool_input": {"file_path": os.path.join(ROOT, rel)},
                               "cwd": "/tmp"})


class EditGuards(unittest.TestCase):
    def test_generated_drift_file_denied(self):
        d = edit("lib/data/drift/app_database.g.dart")
        self.assertEqual(d[0], "deny")
        self.assertIn("build_runner", d[1])

    def test_freezed_denied_for_write(self):
        self.assertEqual(edit("lib/models/x.freezed.dart", "Write")[0], "deny")

    def test_governance_paths_ask(self):
        for rel in f.GOVERNANCE_PATHS:
            d = edit(rel)
            self.assertEqual(d[0], "ask", rel)
            self.assertIn("governance", d[1])

    def test_ordinary_source_allowed(self):
        self.assertIsNone(edit("lib/data/drift/app_database.dart"))
        self.assertIsNone(edit("scripts/fm.sh"))
        self.assertIsNone(edit(".ai_context/INDEX.md"))

    def test_relative_path_resolved_against_cwd(self):
        d = f.pretool_decision({"tool_name": "Edit",
                                "tool_input": {"file_path": "CLAUDE.md"}, "cwd": ROOT})
        self.assertEqual(d[0], "ask")

    def test_file_outside_repo_allowed(self):
        self.assertIsNone(f.pretool_decision({"tool_name": "Write",
                                              "tool_input": {"file_path": "/tmp/x/CLAUDE.md"},
                                              "cwd": ROOT}))


class GitGuards(unittest.TestCase):
    def assertDenied(self, cmd, needle):
        d = bash(cmd)
        self.assertIsNotNone(d, cmd)
        self.assertEqual(d[0], "deny", cmd)
        self.assertIn(needle, d[1], cmd)

    def test_add_sweeps_denied(self):
        for cmd in ("git add -A", "git add --all", "git add .", "git add -u",
                    "git add -Av", "git add -- .", "git -C /x add -A", "git add :/"):
            self.assertDenied(cmd, "git add")

    def test_add_named_files_allowed(self):
        self.assertIsNone(bash("git add lib/a.dart test/a_test.dart"))
        self.assertIsNone(bash("git add ./lib/a.dart"))

    def test_commit_all_denied(self):
        for cmd in ("git commit -a -m x", "git commit -am 'msg'", "git commit --all -m x"):
            self.assertDenied(cmd, "commit -a")

    def test_commit_message_containing_dash_a_allowed(self):
        self.assertIsNone(bash("git commit -m '-a is not a flag here'"))
        self.assertIsNone(bash('git commit -m "Fix (#1)" -m "body --all words"'))

    def test_force_push_denied(self):
        for cmd in ("git push -f", "git push --force origin main",
                    "git push --force-with-lease", "git push origin +main"):
            self.assertDenied(cmd, "force-push")

    def test_plain_push_allowed(self):
        self.assertIsNone(bash("git push origin main"))

    def test_reset_hard_denied(self):
        self.assertDenied("git reset --hard HEAD", "reset --hard")
        self.assertIsNone(bash("git reset HEAD lib/a.dart"))

    def test_checkout_restore_whole_tree_denied(self):
        self.assertDenied("git checkout -- .", "git checkout")
        self.assertDenied("git checkout -f main", "git checkout")
        self.assertDenied("git restore .", "git restore")
        self.assertIsNone(bash("git checkout -- lib/a.dart"))
        self.assertIsNone(bash("git restore --staged lib/a.dart"))

    def test_clean_force_denied(self):
        self.assertDenied("git clean -fd", "git clean")
        self.assertIsNone(bash("git clean -n"))

    def test_bare_stash_denied(self):
        for cmd in ("git stash", "git stash push", "git stash save wip", "git stash -u"):
            self.assertDenied(cmd, "git stash")
        self.assertIsNone(bash("git stash push -- lib/a.dart"))
        self.assertIsNone(bash("git stash list"))

    def test_chained_command_checked_per_segment(self):
        self.assertDenied("git status && git add -A && git commit -m x", "git add")
        self.assertDenied("FOO=1 git reset --hard", "reset --hard")

    def test_read_only_git_allowed(self):
        for cmd in ("git status", "git diff --cached", "git log --oneline -5",
                    "echo 'git add -A'"):
            self.assertIsNone(bash(cmd), cmd)


class SharedKillGuard(unittest.TestCase):
    def test_stop_flutter_asks(self):
        for cmd in ("bash scripts/stop_flutter.sh", "./scripts/stop_flutter.sh",
                    "pkill -f flutter", "killall flutter"):
            d = bash(cmd)
            self.assertEqual(d[0], "ask", cmd)
            self.assertIn("every agent", d[1])

    def test_kill_own_pid_allowed(self):
        self.assertIsNone(bash("kill 12345"))


class HookPlumbing(unittest.TestCase):
    def test_other_tools_allowed(self):
        self.assertIsNone(f.pretool_decision({"tool_name": "Read",
                                              "tool_input": {"file_path": "CLAUDE.md"}}))


if __name__ == "__main__":
    unittest.main()
