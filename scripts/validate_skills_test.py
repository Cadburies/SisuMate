#!/usr/bin/env python3
"""Unit tests for scripts/validate_skills.py — run with:

    python3 scripts/validate_skills_test.py
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
VALIDATOR = HERE / "validate_skills.py"


def write_skill(
    root: Path,
    name: str,
    *,
    description: str = "Use when testing the validator.",
    body: str = "# Test\n",
    extra_frontmatter: str = "",
) -> Path:
    folder = root / "skills" / name
    folder.mkdir(parents=True)
    (folder / "SKILL.md").write_text(
        "---\n"
        f"name: {name}\n"
        f"description: {description}\n"
        f"{extra_frontmatter}"
        "---\n\n"
        f"{body}",
        encoding="utf-8",
    )
    return folder


def run(skills_dir: Path) -> tuple[int, str]:
    result = subprocess.run(
        [sys.executable, str(VALIDATOR), "--skills-dir", str(skills_dir)],
        capture_output=True,
        text=True,
        cwd=str(REPO),
    )
    return result.returncode, result.stdout + result.stderr


class ValidatorTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        (self.root / "skills").mkdir()

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def assertFails(self, needle: str) -> None:
        code, output = run(self.root / "skills")
        self.assertEqual(code, 1, output)
        self.assertIn(needle, output)

    def test_valid_skill(self) -> None:
        (self.root / "scripts").mkdir()
        (self.root / "scripts" / "foo.sh").write_text("#!/bin/sh\n", encoding="utf-8")
        write_skill(
            self.root,
            "good-skill",
            body="# Good\n\nRun `scripts/foo.sh` and read [this](SKILL.md).\n",
        )
        code, output = run(self.root / "skills")
        self.assertEqual(code, 0, output)
        self.assertIn("PASSED", output)

    def test_missing_frontmatter(self) -> None:
        folder = self.root / "skills" / "no-frontmatter"
        folder.mkdir(parents=True)
        (folder / "SKILL.md").write_text("# No frontmatter\n", encoding="utf-8")
        self.assertFails("no frontmatter block")

    def test_name_must_match_folder(self) -> None:
        write_skill(self.root, "real-name")
        text = (self.root / "skills" / "real-name" / "SKILL.md").read_text()
        (self.root / "skills" / "real-name" / "SKILL.md").write_text(
            text.replace("name: real-name", "name: other-name")
        )
        self.assertFails("does not match folder")

    def test_unknown_frontmatter_key(self) -> None:
        write_skill(self.root, "vendor-key", extra_frontmatter="disable-model-invocation: true\n")
        self.assertFails("unknown frontmatter key")

    def test_description_must_be_one_line(self) -> None:
        folder = self.root / "skills" / "block-description"
        folder.mkdir(parents=True)
        (folder / "SKILL.md").write_text(
            "---\nname: block-description\ndescription: |\n  Use when one\n  Use when two\n---\n\n# Body\n",
            encoding="utf-8",
        )
        self.assertFails("must be one line")

    def test_missing_description(self) -> None:
        folder = self.root / "skills" / "no-description"
        folder.mkdir(parents=True)
        (folder / "SKILL.md").write_text(
            "---\nname: no-description\n---\n\n# Body\n", encoding="utf-8"
        )
        self.assertFails("missing `description`")

    def test_description_must_start_with_use(self) -> None:
        write_skill(self.root, "bad-description", description="Handles reviews.")
        self.assertFails('must start with "Use "')

    def test_long_description(self) -> None:
        write_skill(self.root, "long-description", description="Use " + ("x" * 1030))
        self.assertFails("limit is 1024")

    def test_slash_command_in_body(self) -> None:
        write_skill(self.root, "slash-command", body="# Body\n\nRun `/correct`.\n")
        self.assertFails("slash command")

    def test_machine_absolute_path(self) -> None:
        write_skill(self.root, "absolute-path", body="# Body\n\nOpen /Users/me/project.\n")
        self.assertFails("machine-specific absolute path")

    def test_missing_referenced_script(self) -> None:
        write_skill(self.root, "missing-ref", body="# Body\n\nRun `scripts/nope.sh`.\n")
        self.assertFails("referenced path does not exist: scripts/nope.sh")

    def test_broken_relative_link(self) -> None:
        write_skill(self.root, "broken-link", body="# Body\n\nRead [missing](missing.md).\n")
        self.assertFails("relative link does not resolve: missing.md")

    def test_placeholder_reference_is_ignored(self) -> None:
        write_skill(
            self.root,
            "placeholder",
            body="# Body\n\nRun `scripts/<area>.sh --reach`.\n",
        )
        code, output = run(self.root / "skills")
        self.assertEqual(code, 0, output)

    def test_long_file_warns_but_passes(self) -> None:
        write_skill(self.root, "long-file", body="# Body\n" + ("line\n" * 130))
        code, output = run(self.root / "skills")
        self.assertEqual(code, 0, output)
        self.assertIn("WARN", output)

    def test_real_repo_skills_pass(self) -> None:
        result = subprocess.run(
            [sys.executable, str(VALIDATOR)],
            capture_output=True,
            text=True,
            cwd=str(REPO),
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
