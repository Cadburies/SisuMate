#!/usr/bin/env python3
"""Integration tests for scripts/review_staged.sh with fake reviewer CLIs.

Run: python3 scripts/review_staged_test.py

Proves the receipt shape is the same for two different CLIs, that a refuted
finding does not block, and that the receipt hash matches the staged diff.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PROMPTS = ("correctness.md", "contract.md", "acceptance.md", "verify.md")


class ReviewScript(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "scripts").mkdir()
        (self.root / "skills/cold-review/prompts").mkdir(parents=True)
        shutil.copy2(REPO / "scripts/review_staged.sh",
                     self.root / "scripts/review_staged.sh")
        shutil.copy2(REPO / "scripts/_factory.py",
                     self.root / "scripts/_factory.py")
        for name in PROMPTS:
            shutil.copy2(REPO / "skills/cold-review/prompts" / name,
                         self.root / "skills/cold-review/prompts" / name)
        (self.root / "lib").mkdir()
        (self.root / "lib/a.dart").write_text("a1\n", encoding="utf-8")
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "t@t")
        self.git("config", "user.name", "t")
        self.git("add", "-A")
        self.git("commit", "-qm", "init")
        (self.root / "lib/a.dart").write_text("a2\n", encoding="utf-8")
        self.git("add", "lib/a.dart")

    def tearDown(self):
        self.tmp.cleanup()

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.root), *args], check=True,
                              capture_output=True, text=True).stdout

    def fake(self, name: str, body: str) -> Path:
        path = self.root / name
        path.write_text("#!/usr/bin/env bash\nset -euo pipefail\n" + body,
                        encoding="utf-8")
        path.chmod(0o755)
        return path

    def review(self, fake: Path, extra_env: dict | None = None,
               args: list[str] | None = None):
        env = dict(
            os.environ,
            SISU_REVIEW_CMD=f"bash {fake}",
            SISU_REVIEW_FAMILY="claude",
            SISU_BUILDER_FAMILY="deepseek",
            SISU_REVIEW_NO_REGRESSION="1",
        )
        if extra_env:
            env.update({key: str(value) for key, value in extra_env.items()})
        result = subprocess.run(
            ["bash", "scripts/review_staged.sh", *(args or [])], cwd=self.root,
            env=env, capture_output=True, text=True,
        )
        receipt_path = self.root / "build/review_receipt.json"
        if not receipt_path.exists():
            self.fail(f"no receipt\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}")
        receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
        return result, receipt

    def test_two_clis_share_receipt_shape(self):
        clean = self.fake("clean.sh",
                          "cat >/dev/null\nprintf '{\"findings\":[]}\\n'\n")
        finding = self.fake(
            "finding.sh",
            "input=\"$(cat)\"\n"
            "if grep -q '# Correctness pass' <<<\"$input\"; then\n"
            "  printf '{\"findings\":[{\"severity\":\"low\",\"file\":\"lib/a.dart\","
            "\"line\":1,\"scenario\":\"fake\",\"claim\":\"fake\"}]}\\n'\n"
            "elif grep -q '# Verify pass' <<<\"$input\"; then\n"
            "  printf '{\"confirmed\":false,\"reason\":\"refuted\"}\\n'\n"
            "else\n"
            "  printf '{\"findings\":[]}\\n'\n"
            "fi\n",
        )

        first, receipt_a = self.review(clean)
        self.assertEqual(first.returncode, 0, first.stderr)
        second, receipt_b = self.review(finding)
        self.assertEqual(second.returncode, 0, second.stderr)

        self.assertEqual(receipt_a["status"], "PASS")
        self.assertEqual(receipt_b["status"], "PASS")
        self.assertEqual(set(receipt_a), set(receipt_b))
        self.assertEqual(receipt_a["diff_hash"], receipt_b["diff_hash"])
        self.assertEqual(receipt_b["confirmed"], [])
        self.assertEqual(len(receipt_b["findings"]), 1)
        self.assertFalse(receipt_b["findings"][0]["confirmed"])

    def confirmed_fake(self) -> Path:
        return self.fake(
            "confirmed.sh",
            "input=\"$(cat)\"\n"
            "if grep -q '# Correctness pass' <<<\"$input\"; then\n"
            "  printf '{\"findings\":[{\"severity\":\"high\",\"file\":\"lib/a.dart\","
            "\"line\":1,\"scenario\":\"fake failure\",\"claim\":\"fake\"}]}\\n'\n"
            "elif grep -q '# Verify pass' <<<\"$input\"; then\n"
            "  printf '{\"confirmed\":true,\"reason\":\"reproduced\"}\\n'\n"
            "else\n"
            "  printf '{\"findings\":[]}\\n'\n"
            "fi\n",
        )

    def test_confirmed_finding_fails(self):
        result, receipt = self.review(self.confirmed_fake())
        self.assertEqual(result.returncode, 1)
        self.assertEqual(receipt["status"], "FAIL")
        self.assertEqual(len(receipt["confirmed"]), 1)
        self.assertIn("lib/a.dart", result.stdout + result.stderr)

    def test_round_advances_to_needs_human(self):
        fake = self.confirmed_fake()
        first, receipt_one = self.review(fake)
        self.assertEqual(first.returncode, 1)
        self.assertEqual(receipt_one["round"], 1)
        self.assertEqual(receipt_one["status"], "FAIL")
        second, receipt_two = self.review(fake)
        self.assertEqual(second.returncode, 1)
        self.assertEqual(receipt_two["round"], 2)
        self.assertEqual(receipt_two["status"], "NEEDS_HUMAN")

    def test_needs_human_stays_capped(self):
        fake = self.confirmed_fake()
        self.review(fake)
        _, receipt_two = self.review(fake)
        self.assertEqual(receipt_two["status"], "NEEDS_HUMAN")
        third, receipt_three = self.review(fake)
        self.assertEqual(third.returncode, 1)
        self.assertEqual(receipt_three["round"], 2)
        self.assertEqual(receipt_three["status"], "NEEDS_HUMAN")

    def test_verify_failure_is_needs_human(self):
        fake = self.fake(
            "verify_fail.sh",
            "input=\"$(cat)\"\n"
            "if grep -q '# Correctness pass' <<<\"$input\"; then\n"
            "  printf '{\"findings\":[{\"severity\":\"high\",\"file\":\"lib/a.dart\","
            "\"line\":1,\"scenario\":\"fake\",\"claim\":\"fake\"}]}\\n'\n"
            "elif grep -q '# Verify pass' <<<\"$input\"; then\n"
            "  echo 'reviewer down' >&2\n"
            "  exit 1\n"
            "else\n"
            "  printf '{\"findings\":[]}\\n'\n"
            "fi\n",
        )
        result, receipt = self.review(fake)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(receipt["status"], "NEEDS_HUMAN")
        self.assertTrue(receipt["verify_errors"])
        self.assertEqual(receipt["confirmed"], [])

    def test_verifier_string_false_is_not_confirmed(self):
        fake = self.fake(
            "string_false.sh",
            "input=\"$(cat)\"\n"
            "if grep -q '# Correctness pass' <<<\"$input\"; then\n"
            "  printf '{\"findings\":[{\"severity\":\"low\",\"file\":\"lib/a.dart\","
            "\"line\":1,\"scenario\":\"fake\",\"claim\":\"fake\"}]}\\n'\n"
            "elif grep -q '# Verify pass' <<<\"$input\"; then\n"
            "  printf '{\"confirmed\":\"false\",\"reason\":\"refuted\"}\\n'\n"
            "else\n"
            "  printf '{\"findings\":[]}\\n'\n"
            "fi\n",
        )
        result, receipt = self.review(fake)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(receipt["status"], "PASS")
        self.assertEqual(receipt["confirmed"], [])

    def test_capped_finding_needs_human(self):
        fake = self.fake(
            "many.sh",
            "input=\"$(cat)\"\n"
            "if grep -q '# Correctness pass' <<<\"$input\"; then\n"
            "  python3 -c 'import json; print(json.dumps({\"findings\":"
            "[{\"severity\":\"low\",\"file\":\"lib/a.dart\",\"line\":i,\"scenario\":\"f\","
            "\"claim\":\"c\"} for i in range(1,5)]}))'\n"
            "elif grep -q '# Verify pass' <<<\"$input\"; then\n"
            "  printf '{\"confirmed\":false,\"reason\":\"refuted\"}\\n'\n"
            "else\n"
            "  printf '{\"findings\":[]}\\n'\n"
            "fi\n",
        )
        result, receipt = self.review(fake, {"SISU_REVIEW_MAX_FINDINGS": "3"})
        self.assertEqual(result.returncode, 1)
        self.assertEqual(receipt["status"], "NEEDS_HUMAN")
        self.assertEqual(len(receipt["dropped_findings"]), 1)

    def test_pass_without_findings_list_needs_human(self):
        fake = self.fake(
            "bad_pass.sh",
            "input=\"$(cat)\"\n"
            "if grep -q '# Correctness pass' <<<\"$input\"; then\n"
            "  printf '{\"error\":\"rate limited\"}\\n'\n"
            "else\n"
            "  printf '{\"findings\":[]}\\n'\n"
            "fi\n",
        )
        result, receipt = self.review(fake)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(receipt["status"], "NEEDS_HUMAN")
        self.assertTrue(receipt["pass_errors"])
        self.assertFalse(receipt["spec_available"])

    def test_issue_fetch_failure_needs_human(self):
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        gh = bin_dir / "gh"
        gh.write_text("#!/usr/bin/env bash\nexit 1\n", encoding="utf-8")
        gh.chmod(0o755)
        clean = self.fake("clean.sh",
                          "cat >/dev/null\nprintf '{\"findings\":[]}\\n'\n")
        result, receipt = self.review(
            clean, {"PATH": str(bin_dir) + os.pathsep + os.environ.get("PATH", "")},
            args=["999"],
        )
        self.assertEqual(result.returncode, 1)
        self.assertEqual(receipt["status"], "NEEDS_HUMAN")
        self.assertEqual(receipt["issue"], 999)
        self.assertFalse(receipt["spec_available"])

    def test_prompts_load_from_head_and_acceptance_skips_without_issue(self):
        prompt_dir = self.root / "captured"
        fake = self.fake(
            "capture.sh",
            "input=\"$(cat)\"\n"
            "case \"$input\" in\n"
            "  *'# Correctness pass'*) name=correctness ;;\n"
            "  *'# Contract pass'*) name=contract ;;\n"
            "  *'# Acceptance pass'*) name=acceptance ;;\n"
            "  *'# Verify pass'*) name=verify ;;\n"
            "  *) name=unknown ;;\n"
            "esac\n"
            "mkdir -p \"$SISU_TEST_PROMPT_DIR\"\n"
            "printf '%s' \"$input\" > \"$SISU_TEST_PROMPT_DIR/$name.txt\"\n"
            "printf '{\"findings\":[]}\\n'\n",
        )
        prompt = self.root / "skills/cold-review/prompts/correctness.md"
        prompt.write_text(prompt.read_text(encoding="utf-8") + "\nSTAGED WEAKNESS\n",
                          encoding="utf-8")
        self.git("add", str(prompt.relative_to(self.root)))
        result, receipt = self.review(fake, {"SISU_TEST_PROMPT_DIR": prompt_dir})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(receipt["status"], "PASS")
        captured = (prompt_dir / "correctness.txt").read_text(encoding="utf-8")
        self.assertIn("# Correctness pass", captured)
        instructions, _, staged_diff = captured.partition("--- STAGED DIFF ---")
        self.assertNotIn("STAGED WEAKNESS", instructions)
        self.assertIn("STAGED WEAKNESS", staged_diff)
        self.assertFalse((prompt_dir / "acceptance.txt").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
