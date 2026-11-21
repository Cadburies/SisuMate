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


_CLEAN = None


def bash(cmd: str):
    """Guard decision with a clean throwaway repo as cwd (nothing staged), so
    these tests don't depend on the real tree's index or receipt."""
    global _CLEAN
    _CLEAN = _CLEAN or FakeRepo()
    return f.pretool_decision({"tool_name": "Bash", "tool_input": {"command": cmd},
                               "cwd": _CLEAN.root})


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

    def test_receipt_file_denied(self):
        for rel in (f.RECEIPT, f.SNAPSHOT, f.REVIEW_RECEIPT):
            d = edit(rel)
            self.assertEqual(d[0], "deny", rel)
            self.assertIn("gate scripts write", d[1])

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

    def test_wrapped_commit_denied(self):
        for cmd in (
            "bash -c 'git commit -m x'",
            "sh -c 'git commit -m x'",
            "bash -lc 'git commit -m x'",
            "bash --login -c 'git add lib/x.dart && git commit -m x'",
            "bash -c 'git add lib/x.dart && git commit -m x'",
            "sh -c 'git add lib/x.dart; git commit -m x'",
            "node -e \"require('child_process').execSync('git add lib/x.dart && git commit -m x')\"",
            "$(git commit -m x)",
            "python3 -c \"import subprocess; "
            "subprocess.run(['git','commit','-m','x'])\"",
        ):
            self.assertDenied(cmd, "literal")

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

    def test_governance_bash_write_asks(self):
        for cmd in ("cat > scripts/review_staged.sh",
                    "cp /tmp/x AGENTS.md",
                    "tee scripts/_factory.py",
                    "sed -i s/a/b/ skills/cold-review/SKILL.md"):
            d = bash(cmd)
            self.assertEqual(d[0], "ask", cmd)
            self.assertIn("governance", d[1])
        self.assertIsNone(bash("cat scripts/review_staged.sh"))

    def test_receipt_forgery_common_writers(self):
        for cmd in (
            "node -e \"require('fs').writeFileSync('build/review_receipt.json','x')\"",
            "ruby -e \"File.write('build/review_receipt.json','x')\"",
            "dd of=build/suite_receipt.json",
            "python3 scripts/_factory.py review-receipt && "
            "python3 -c \"open('build/review_receipt.json','w').write('x')\"",
        ):
            self.assertDenied(cmd, "gate scripts write")
        self.assertIsNone(bash("python3 scripts/_factory.py review-receipt"))
        self.assertIsNone(bash("cat build/review_receipt.json"))

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


class SecretsAndReleaseGuards(unittest.TestCase):
    """#434: agents never touch release credentials; a human approves store uploads."""

    def _tool(self, tool, **inp):
        return f.pretool_decision({"tool_name": tool, "tool_input": inp, "cwd": ROOT})

    def test_bash_secret_access_denied(self):
        for cmd in ("cat secrets/google-play-service-account.json",
                    "cp ./secrets/AuthKey_ABC.p8 /tmp/x",
                    "ls secrets/",
                    "base64 android/key.properties",
                    "cat ~/keystores/sisumate/upload.jks",
                    f"head {ROOT}/secrets/appstore-connect.json"):
            d = bash(cmd)
            self.assertIsNotNone(d, cmd)
            self.assertEqual(d[0], "deny", cmd)
            self.assertIn("release credentials", d[1], cmd)

    def test_secrets_readme_allowed(self):
        self.assertIsNone(bash("cat secrets/README.md"))
        self.assertIsNone(self._tool("Read", file_path=os.path.join(ROOT, "secrets/README.md")))

    def test_file_tools_on_secrets_denied(self):
        for tool, inp in (("Read", {"file_path": os.path.join(ROOT, "secrets/appstore-connect.json")}),
                          ("Read", {"file_path": "secrets/x.json"}),
                          ("Grep", {"pattern": "key", "path": os.path.join(ROOT, "secrets")}),
                          ("Glob", {"pattern": "secrets/**"}),
                          ("Edit", {"file_path": os.path.join(ROOT, "android/key.properties")})):
            d = self._tool(tool, **inp)
            self.assertIsNotNone(d, (tool, inp))
            self.assertEqual(d[0], "deny", (tool, inp))
            self.assertIn("release credentials", d[1])

    def test_release_scripts_ask(self):
        for cmd in ("./scripts/play_release.sh --track internal",
                    "bash scripts/appstore_release.sh --track testflight"):
            d = bash(cmd)
            self.assertEqual(d[0], "ask", cmd)
            self.assertIn("store release", d[1].lower())

    def test_mentions_are_not_access(self):
        for cmd in ("grep -rn secrets_manager lib", "git log --oneline",
                    "echo dart-defines.json",
                    'gh issue comment 434 --body "updated the secrets README and guard"'):
            self.assertIsNone(bash(cmd), cmd)


class HookPlumbing(unittest.TestCase):
    def test_other_tools_allowed(self):
        self.assertIsNone(f.pretool_decision({"tool_name": "Read",
                                              "tool_input": {"file_path": "CLAUDE.md"}}))


class FakeRepo:
    """Throwaway git repo shaped like SisuMate (has scripts/_factory.py)."""

    def __init__(self):
        import tempfile
        self.root = tempfile.mkdtemp()
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "t@t")
        self.git("config", "user.name", "t")
        self.write("scripts/_factory.py", "# marker\n")
        self.write("lib/a.dart", "a1\n")
        self.write("test/a_test.dart", "t1\n")
        self.write("README.md", "r\n")
        self.write("test/.test_floor", "10\n")
        self.git("add", "-A")
        self.git("commit", "-qm", "init")

    def git(self, *args):
        import subprocess
        return subprocess.run(["git", "-C", self.root, *args], check=True,
                              capture_output=True, text=True).stdout

    def write(self, rel, text):
        p = os.path.join(self.root, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w") as fh:
            fh.write(text)

    def report(self, passed=12, skipped=1, failed=0):
        evs = [{"type": "testDone", "result": "success", "hidden": True}]  # loading test
        evs += [{"type": "testDone", "result": "success", "hidden": False}] * passed
        evs += [{"type": "testDone", "result": "success", "skipped": True}] * skipped
        evs += [{"type": "testDone", "result": "failure"}] * failed
        self.write("build/r.json", "\n".join(json.dumps(e) for e in evs) + "\n")
        return "build/r.json"

    def suite(self, flags="", during=None, **kw):
        f.write_snapshot(self.root)
        if during:
            during()  # an edit while the suite is running
        return f.write_receipt(self.root, flags, self.report(**kw), None)

    def review(self, status="PASS", findings=None, diff_hash=None):
        self.write(f.REVIEW_RECEIPT, json.dumps({
            "status": status,
            "diff_hash": diff_hash if diff_hash is not None else f.review_diff_hash(self.root),
            "reviewer_family": "fake",
            "round": 1,
            "findings": findings or [],
        }))

    def commit_decision(self, msg="msg"):
        return f.commit_check(self.root, msg)


import json  # noqa: E402


class ReceiptAndCommitGate(unittest.TestCase):
    def setUp(self):
        self.r = FakeRepo()

    def test_report_counts_ignore_hidden_and_skipped(self):
        r = self.r.suite(passed=12, skipped=2)
        self.assertEqual((r["host_tests"], r["skipped"]), (12, 2))

    def test_failed_report_writes_no_receipt(self):
        with self.assertRaises(SystemExit):
            self.r.suite(failed=1)
        self.assertIsNone(f.load_receipt(self.r.root))

    def test_floor_ratchets_up_only_on_full_run(self):
        self.r.suite(passed=12)
        self.assertEqual(open(os.path.join(self.r.root, f.FLOOR)).read().strip(), "12")
        self.r.suite(passed=11)  # fewer: never lowered
        self.assertEqual(open(os.path.join(self.r.root, f.FLOOR)).read().strip(), "12")
        self.r.suite(flags="--skip-live", passed=20)  # skip flags: no raise
        self.assertEqual(open(os.path.join(self.r.root, f.FLOOR)).read().strip(), "12")

    def test_commit_without_receipt_denied(self):
        self.r.write("lib/a.dart", "a2\n")
        self.r.git("add", "lib/a.dart")
        d = self.r.commit_decision()
        self.assertEqual(d[0], "deny")
        self.assertIn("No suite receipt", d[1])

    def test_commit_matching_receipt_allowed(self):
        self.r.write("lib/a.dart", "a2\n")
        self.r.suite()
        self.r.git("add", "lib/a.dart")
        self.r.review()
        self.assertIsNone(self.r.commit_decision())

    def test_edit_after_suite_denied(self):
        self.r.write("lib/a.dart", "a2\n")
        self.r.suite()
        self.r.write("lib/a.dart", "a3\n")
        self.r.git("add", "lib/a.dart")
        d = self.r.commit_decision()
        self.assertEqual(d[0], "deny")
        self.assertIn("differs from what the suite verified", d[1])

    def test_edit_during_suite_run_is_not_verified(self):
        self.r.write("lib/a.dart", "a2\n")
        self.r.suite(during=lambda: self.r.write("lib/a.dart", "a3\n"))
        self.r.git("add", "lib/a.dart")
        self.assertIn("differs from what the suite verified", self.r.commit_decision()[1])

    def test_new_file_during_suite_run_is_not_verified(self):
        self.r.suite(during=lambda: self.r.write("lib/new.dart", "n\n"))
        self.r.git("add", "lib/new.dart")
        self.assertEqual(self.r.commit_decision()[0], "deny")

    def test_receipt_needs_start_snapshot(self):
        # Fresh repo: no snapshot was ever taken.
        with self.assertRaises(SystemExit):
            f.write_receipt(self.r.root, "", self.r.report(), None)

    def test_other_agents_dirty_file_ignored(self):
        self.r.write("lib/a.dart", "a2\n")
        self.r.suite()
        self.r.write("lib/other_agent.dart", "x\n")  # appears after the suite, not staged
        self.r.git("add", "lib/a.dart")
        self.r.review()
        self.assertIsNone(self.r.commit_decision())

    def test_skip_flags_need_reason(self):
        self.r.write("lib/a.dart", "a2\n")
        self.r.suite(flags="--skip-live")
        self.r.git("add", "lib/a.dart")
        self.assertIn("suite-skip", self.r.commit_decision()[1])
        self.r.review()
        self.assertIsNone(self.r.commit_decision("x\n\nsuite-skip: offline on a plane"))

    def test_test_count_below_head_floor_denied(self):
        self.r.write("lib/a.dart", "a2\n")
        self.r.suite(flags="--skip-live", passed=9)  # floor in HEAD is 10
        self.r.git("add", "lib/a.dart")
        d = self.r.commit_decision("suite-skip: x")
        self.assertIn("below the floor", d[1])

    def test_lowering_floor_denied(self):
        self.r.write("test/.test_floor", "5\n")
        self.r.git("add", "test/.test_floor")
        self.r.write("lib/a.dart", "a1\n")
        d = self.r.commit_decision()
        self.assertEqual(d[0], "deny")

    def test_docs_only_commit_needs_no_receipt(self):
        self.r.write("README.md", "r2\n")
        self.r.git("add", "README.md")
        self.assertIsNone(self.r.commit_decision())

    def test_governance_change_asks_even_with_receipt(self):
        self.r.write("scripts/_factory.py", "# changed by shell\n")
        self.r.suite()
        self.r.git("add", "scripts/_factory.py")
        self.r.review()
        d = self.r.commit_decision()
        self.assertEqual(d[0], "ask")
        self.assertIn("governance", d[1])

    def test_check_crash_fails_closed(self):
        d = f.guarded_commit_check("/nonexistent/repo", "m")
        self.assertEqual(d[0], "deny")
        self.assertIn("crashed", d[1])

    def test_bash_commit_routes_through_gate(self):
        self.r.write("lib/a.dart", "a2\n")
        self.r.git("add", "lib/a.dart")
        d = f.check_bash(f"git -C {self.r.root} commit -m x", "/tmp")
        self.assertIn("No suite receipt", d[1])

    def test_stage_and_commit_in_one_command_denied(self):
        d = f.check_bash(f"git -C {self.r.root} add lib/a.dart && git -C {self.r.root} commit -m x", "/tmp")
        self.assertIn("separate commands", d[1])

    def test_commit_with_paths_denied(self):
        for cmd in ("git commit -m x lib/a.dart", "git commit -m x -- lib/a.dart",
                    "git commit -i -m x", "git commit --only -m x"):
            d = f.check_bash(cmd, self.r.root)
            self.assertIn("without paths", d[1], cmd)

    def test_commit_message_parsing(self):
        self.assertEqual(f.commit_message(["-m", "a", "-m", "b"], "/"), "a\nb")
        self.assertEqual(f.commit_message(["--message=z"], "/"), "z")


class StopHook(unittest.TestCase):
    def test_edited_paths_from_transcript(self):
        lines = [json.dumps({"message": {"content": [
            {"type": "tool_use", "name": "Edit", "input": {"file_path": "/r/lib/a.dart"}},
            {"type": "tool_use", "name": "Read", "input": {"file_path": "/r/lib/b.dart"}}]}}),
            "not json"]
        self.assertEqual(f.edited_paths(lines), {"/r/lib/a.dart"})

    def test_stale_only_for_unverified_session_edits(self):
        r = FakeRepo()
        r.write("lib/a.dart", "a2\n")
        p = {os.path.join(r.root, "lib/a.dart")}
        self.assertEqual(f.stale_session_edits(r.root, p), ["lib/a.dart"])
        r.suite()
        self.assertEqual(f.stale_session_edits(r.root, p), [])

    def test_stale_covers_code_trees_not_docs(self):
        r = FakeRepo()
        r.write("integration_test/a_test.dart", "x\n")
        r.write("scripts/fm.sh", "x\n")
        r.write("tool/x.dart", "x\n")
        r.write("README.md", "changed\n")
        paths = {os.path.join(r.root, p) for p in (
            "integration_test/a_test.dart", "scripts/fm.sh", "tool/x.dart", "README.md")}
        self.assertEqual(f.stale_session_edits(r.root, paths), [
            "integration_test/a_test.dart", "scripts/fm.sh", "tool/x.dart"])

    def test_stop_block_sends_the_agent_back(self):
        d = f.stop_decision(["lib/a.dart"], "keep going")
        self.assertEqual(d["decision"], "block")
        self.assertIn("lib/a.dart", d["reason"])
        self.assertIn("run_full_suite.sh", d["reason"])
        self.assertIn("Do not commit", d["reason"])
        self.assertIsNone(f.stop_decision([], "keep going"))

    def test_hold_off_allows_stop(self):
        self.assertIsNone(f.stop_decision(["lib/a.dart"], "hold off"))
        self.assertIsNone(f.stop_decision(["lib/a.dart"], "please stop now"))
        self.assertIsNotNone(f.stop_decision(["lib/a.dart"], "stop guessing"))
        self.assertFalse(f.is_hold_off(
            "Please implement hold off handling in the hook and keep going"))

    def test_last_user_text_ignores_assistant(self):
        lines = [
            json.dumps({"type": "user", "message": {"role": "user", "content": [
                {"type": "text", "text": "fix the loop"}]}}),
            json.dumps({"type": "assistant", "message": {"role": "assistant", "content": [
                {"type": "text", "text": "hold off"}]}}),
        ]
        self.assertEqual(f.last_user_text(lines), "fix the loop")
        lines.append(json.dumps({"type": "user", "message": {"role": "user",
                                                             "content": "stop now"}}))
        self.assertTrue(f.is_hold_off(f.last_user_text(lines)))


class ReceiptForge(unittest.TestCase):
    def test_agent_cannot_write_the_receipt(self):
        for cmd in ("python3 scripts/_factory.py receipt-write --flags ''",
                    "python3 scripts/_factory.py snapshot",
                    "echo {} > build/suite_receipt.json",
                    "python3 -c \"open('build/suite_snapshot.json','w').write('{}')\""):
            d = bash(cmd)
            self.assertEqual(d[0], "deny", cmd)
            self.assertIn("gate scripts write", d[1], cmd)

    def test_receipt_summary_and_mentions_allowed(self):
        self.assertIsNone(bash("python3 scripts/_factory.py receipt"))
        self.assertIsNone(bash("grep suite_receipt.json scripts"))


class ReviewFacts(unittest.TestCase):
    def setUp(self):
        self.r = FakeRepo()

    def stage(self, path, text):
        self.r.write(path, text)
        self.r.git("add", path)

    def rules(self):
        return {x["rule"] for x in f.review_facts(self.r.root)["findings"]}

    def test_ui_drift_import(self):
        self.stage("lib/ui/x.dart",
                   "import 'package:sisu_mate/data/drift/app_database.dart';\n")
        self.assertIn("ui_drift_import", self.rules())

    def test_colour_literal_and_token(self):
        self.stage("lib/ui/x.dart", "final a = Color(0xFF000000);\n")
        self.assertIn("colour_literal", self.rules())
        self.r.git("reset", "HEAD", "lib/ui/x.dart")
        self.stage("lib/ui/x.dart", "final a = SisuColors.primary;\n")
        self.assertNotIn("colour_literal", self.rules())

    def test_colour_literal_on_sisu_colors_line_still_flags(self):
        self.stage("lib/ui/x.dart",
                   "final a = [SisuColors.primary, Color(0xFFFFFFFF)];\n")
        self.assertIn("colour_literal", self.rules())

    def test_colour_literal_moved_from_head_is_ignored(self):
        self.r.write("lib/ui/x.dart", "// header\nfinal a = Colors.red;\n")
        self.r.git("add", "lib/ui/x.dart")
        self.r.git("commit", "-qm", "legacy literal")
        self.stage("lib/ui/x.dart", "final a = Colors.red;\n// header\n")
        self.assertNotIn("colour_literal", self.rules())

    def test_colour_literal_new_line_still_flags(self):
        self.r.write("lib/ui/x.dart", "// header\nfinal a = Colors.red;\n")
        self.r.git("add", "lib/ui/x.dart")
        self.r.git("commit", "-qm", "legacy literal")
        self.stage("lib/ui/x.dart",
                   "// header\nfinal a = Colors.red;\nfinal b = Colors.blue;\n")
        self.assertIn("colour_literal", self.rules())

    def test_schema_without_migration(self):
        self.stage("lib/data/drift/app_database.dart", "int get schemaVersion => 2;\n")
        self.assertIn("schema_without_migration", self.rules())

    def test_schema_with_migration_allowed(self):
        self.stage("lib/data/drift/app_database.dart", "int get schemaVersion => 2;\n")
        self.stage("supabase/migrations/20260101000000_x.sql", "select 1;\n")
        self.assertNotIn("schema_without_migration", self.rules())

    def test_schema_with_deleted_migration_is_not_a_migration(self):
        self.r.write("supabase/migrations/20260101000000_x.sql", "select 1;\n")
        self.r.git("add", "supabase/migrations/20260101000000_x.sql")
        self.r.git("commit", "-qm", "migration")
        self.r.git("rm", "-q", "supabase/migrations/20260101000000_x.sql")
        self.stage("lib/data/drift/app_database.dart", "int get schemaVersion => 2;\n")
        self.assertIn("schema_without_migration", self.rules())

    def test_llm_only_and_local_fallback(self):
        self.stage("lib/ui/x.dart", "final r = await LlmClientService().ask('x');\n")
        self.assertIn("llm_only", self.rules())
        self.r.git("reset", "HEAD", "lib/ui/x.dart")
        self.stage("lib/ui/x.dart",
                   "// local fallback first\nfinal r = await LlmClientService().ask('x');\n")
        self.assertNotIn("llm_only", self.rules())

    def test_llm_only_localization_is_not_a_fallback(self):
        self.stage("lib/ui/x.dart",
                   "import 'app_localizations.dart';\n"
                   "final r = await LlmClientService().ask('x');\n")
        self.assertIn("llm_only", self.rules())


    def test_unlogged_catch_and_logged_catch(self):
        self.stage("lib/services/x.dart", "void f() { try { x(); } catch (e) {} }\n")
        self.assertIn("unlogged_catch", self.rules())
        self.r.git("reset", "HEAD", "lib/services/x.dart")
        self.stage("lib/services/x.dart",
                   "void f() { try { x(); } catch (e, st) { "
                   "ErrorLogService().logException(e, st); } }\n")
        self.assertNotIn("unlogged_catch", self.rules())

    def test_test_tamper_removed_expect(self):
        self.r.write("test/a_test.dart", "test('a', () { expect(1, 1); });\n")
        self.r.git("add", "test/a_test.dart")
        self.r.git("commit", "-qm", "test")
        self.stage("test/a_test.dart", "test('a', () { });\n")
        self.assertIn("test_tamper", self.rules())

    def test_test_tamper_skip(self):
        self.stage("test/x_test.dart", "test('x', () {}, skip: 'later');\n")
        self.assertIn("test_tamper", self.rules())


    def test_test_tamper_deleted_file(self):
        self.r.write("test/gone_test.dart", "test('a', () { expect(1, 1); });\n")
        self.r.git("add", "test/gone_test.dart")
        self.r.git("commit", "-qm", "test")
        self.r.git("rm", "-q", "test/gone_test.dart")
        self.assertIn("test_tamper", self.rules())

    def test_callers_of_changed_symbol(self):
        self.stage("lib/a.dart", "void newHelper() {}\n")
        self.stage("test/a_test.dart", "void t() { newHelper(); }\n")
        callers = f.review_facts(self.r.root)["facts"]["callers"]
        self.assertIn("newHelper", callers)

    def test_regression_proof_not_run_by_default(self):
        self.stage("test/a_test.dart", "test('a', () {});\n")
        proof = f.review_facts(self.r.root)["facts"]["regression_proof"]
        self.assertEqual(proof, [{"test": "test/a_test.dart", "result": "not_run"}])

    def test_regression_proof_removes_added_lib(self):
        from unittest import mock

        bin_dir = os.path.join(self.r.root, "bin")
        os.makedirs(bin_dir)
        fake = os.path.join(bin_dir, "flutter")
        with open(fake, "w", encoding="utf-8") as fh:
            fh.write("#!/usr/bin/env bash\n"
                     "grep -q FIX lib/new_fix.dart && exit 0\n"
                     "exit 1\n")
        os.chmod(fake, 0o755)
        self.stage("lib/new_fix.dart", "// FIX\n")
        self.stage("test/a_test.dart", "test('a', () {});\n")
        path = bin_dir + os.pathsep + os.environ.get("PATH", "")
        with mock.patch.dict(os.environ, {"PATH": path}):
            proof = f.regression_proof(self.r.root, ["test/a_test.dart"], True)
        self.assertEqual(proof, [{"test": "test/a_test.dart", "result": "fail"}])

    def test_clean_diff_has_no_findings(self):
        self.stage("lib/services/x.dart", "void f() {}\n")
        self.assertEqual(f.review_facts(self.r.root)["findings"], [])


class ReviewGate(unittest.TestCase):
    def setUp(self):
        self.r = FakeRepo()

    def stage_code(self):
        self.r.write("lib/a.dart", "a2\n")
        self.r.suite()
        self.r.git("add", "lib/a.dart")

    def test_missing_review_receipt_denied(self):
        self.stage_code()
        d = self.r.commit_decision()
        self.assertEqual(d[0], "deny")
        self.assertIn("No review receipt", d[1])

    def test_review_pass_allowed(self):
        self.stage_code()
        self.r.review()
        self.assertIsNone(self.r.commit_decision())

    def test_stale_review_hash_denied(self):
        self.stage_code()
        self.r.review(diff_hash="0" * 64)
        d = self.r.commit_decision()
        self.assertEqual(d[0], "deny")
        self.assertIn("stale", d[1])

    def test_review_fail_denied_with_findings(self):
        self.stage_code()
        self.r.review(status="FAIL", findings=[
            {"rule": "ui_drift_import", "file": "lib/a.dart", "line": 1,
             "scenario": "UI imports Drift"}])
        d = self.r.commit_decision()
        self.assertEqual(d[0], "deny")
        self.assertIn("Cold review FAIL", d[1])
        self.assertIn("ui_drift_import", d[1])

    def test_review_needs_human_denied(self):
        self.stage_code()
        self.r.review(status="NEEDS_HUMAN")
        self.assertIn("NEEDS_HUMAN", self.r.commit_decision()[1])

    def test_review_receipt_forgery_denied(self):
        for cmd in ("echo {} > build/review_receipt.json",
                    "python3 -c \"open('build/review_receipt.json','w').write('{}')\""):
            d = bash(cmd)
            self.assertEqual(d[0], "deny", cmd)
            self.assertIn("gate scripts write", d[1], cmd)
        self.assertIsNone(bash("python3 scripts/_factory.py review-receipt"))

    def test_review_receipt_edit_denied(self):
        d = edit(f.REVIEW_RECEIPT)
        self.assertEqual(d[0], "deny")
        self.assertIn("gate scripts write", d[1])

    def test_prompt_edits_ask(self):
        for name in f.REVIEW_PROMPTS:
            d = edit(f"{f.REVIEW_PROMPT_DIR}/{name}")
            self.assertEqual(d[0], "ask", name)
            self.assertIn("governance", d[1])


if __name__ == "__main__":
    unittest.main()
