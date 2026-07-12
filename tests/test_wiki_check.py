#!/usr/bin/env python3
"""Integration tests for scripts/wiki_check.py using temporary Git repositories."""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
CHECKER = PROJECT / "scripts/wiki_check.py"


class WikiCheckTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "scripts").mkdir()
        (self.root / "docs/wiki/_meta").mkdir(parents=True)
        (self.root / "docs/wiki/pending").mkdir(parents=True)
        shutil.copy2(CHECKER, self.root / "scripts/wiki_check.py")
        (self.root / "config.txt").write_text("initial\n", encoding="utf-8")
        (self.root / "docs/wiki/page.md").write_text(
            "---\ntitle: Page\nsource_files:\n  - config.txt\nlast_reviewed: 2026-07-12\n---\n# Page\n",
            encoding="utf-8",
        )
        (self.root / "docs/wiki/_meta/source-map.yml").write_text(json.dumps({"rules": [
            {"path": "config.txt", "classification": "document", "pages": ["docs/wiki/page.md"], "rationale": "Fixture configuration."},
            {"path": "docs/wiki/**", "classification": "internal-metadata", "pages": [], "rationale": "Fixture wiki metadata."},
            {"path": "scripts/wiki_check.py", "classification": "internal-metadata", "pages": [], "rationale": "Fixture checker."},
        ]}), encoding="utf-8")
        self.git("init", "-q")
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "user.name", "Wiki test")
        self.git("add", ".")
        self.git("commit", "-qm", "initial")
        self.base = self.git("rev-parse", "HEAD").strip()

    def tearDown(self) -> None:
        self.temp.cleanup()

    def git(self, *args: str) -> str:
        return subprocess.run(["git", *args], cwd=self.root, check=True, text=True, capture_output=True).stdout

    def checker(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(["python3", "scripts/wiki_check.py", *args], cwd=self.root, text=True, capture_output=True)

    def test_audit_passes_for_complete_fixture(self) -> None:
        result = self.checker("audit")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_documented_change_passes_and_undocumented_change_fails(self) -> None:
        (self.root / "config.txt").write_text("changed\n", encoding="utf-8")
        self.git("add", "config.txt")
        self.git("commit", "-qm", "configuration change")
        head = self.git("rev-parse", "HEAD").strip()
        result = self.checker("check", "--base", self.base, "--head", head)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires an update", result.stderr)

        (self.root / "docs/wiki/page.md").write_text(
            "---\ntitle: Page\nsource_files:\n  - config.txt\nlast_reviewed: 2026-07-12\n---\n# Page\n\nUpdated.\n",
            encoding="utf-8",
        )
        self.git("add", "docs/wiki/page.md")
        self.git("commit", "-qm", "document configuration")
        head = self.git("rev-parse", "HEAD").strip()
        result = self.checker("check", "--base", self.base, "--head", head)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_unmapped_path_fails_audit(self) -> None:
        (self.root / "new.txt").write_text("new\n", encoding="utf-8")
        self.git("add", "new.txt")
        result = self.checker("audit")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("matches 0 rules", result.stderr)

    def test_broken_link_fails_audit(self) -> None:
        page = self.root / "docs/wiki/page.md"
        page.write_text(page.read_text(encoding="utf-8") + "\n[missing](does-not-exist.md)\n", encoding="utf-8")
        result = self.checker("audit")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("broken local link", result.stderr)


if __name__ == "__main__":
    unittest.main()
