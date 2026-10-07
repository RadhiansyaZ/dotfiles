import os
import re
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests/fixtures/stow-safety.yml"
PACKAGE_FILES = (".zshrc", ".gdt.zshrc", ".homebrew.zshrc")


@unittest.skipUnless(
    shutil.which("ansible-playbook") and shutil.which("stow"),
    "Ansible and GNU Stow are required",
)
class StowSafetyTests(unittest.TestCase):
    def create_fixture_paths(self, root):
        home = root / "home"
        home.mkdir()
        package_root = root / "packages"
        package_dir = package_root / "zsh"
        package_dir.mkdir(parents=True)
        for name in PACKAGE_FILES:
            (package_dir / name).write_text("synthetic stow fixture\n", encoding="utf-8")
        return home, package_root

    def run_fixture(self, home, package_root, *, check=False):
        env = os.environ.copy()
        env.update(HOME=str(home), DOTFILES_ROOT=str(package_root))
        command = [
            shutil.which("ansible-playbook"),
            "-i",
            "localhost,",
            "-c",
            "local",
            str(FIXTURE),
            "--tags",
            "stow",
            "--skip-tags",
            "ssh",
        ]
        if check:
            command.append("--check")
        result = subprocess.run(
            command,
            cwd=ROOT,
            env=env,
            capture_output=True,
            text=True,
            check=False,
            timeout=30,
        )
        self.assertNotIn("Check repo ssh config exists", result.stdout + result.stderr)
        return result

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_empty_home_reports_first_stow_link_creation_as_changed(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            home, package_root = self.create_fixture_paths(Path(temp_dir))

            result = self.run_fixture(home, package_root)
            self.assert_success(result)
            output = result.stdout + result.stderr
            self.assertRegex(
                output,
                r"TASK \[Stow dotfile packages\][\s\S]*?changed: \[localhost\]",
            )
            self.assertRegex(output, r"localhost\s+:\s+ok=\d+\s+changed=1")
            self.assertTrue(all((home / name).is_symlink() for name in PACKAGE_FILES))
            self.assertFalse((home / ".zshrc.pre-stow").exists())

    def test_regular_conflict_backup_and_second_run_are_preserved_and_idempotent(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            home, package_root = self.create_fixture_paths(Path(temp_dir))
            target = home / ".zshrc"
            backup = home / ".zshrc.pre-stow"
            original = b"local zsh configuration\n"
            target.write_bytes(original)
            target.chmod(0o640)

            first = self.run_fixture(home, package_root)
            self.assert_success(first)
            self.assertEqual(backup.read_bytes(), original)
            self.assertEqual(stat.S_IMODE(backup.stat().st_mode), 0o640)
            self.assertTrue(target.is_symlink())
            self.assertEqual(target.resolve(), package_root / "zsh/.zshrc")
            links = [home / name for name in PACKAGE_FILES]
            self.assertTrue(all(link.is_symlink() for link in links))
            first_output = first.stdout + first.stderr
            self.assertRegex(
                first_output,
                r"TASK \[Stow dotfile packages\][\s\S]*?changed: \[localhost\]",
            )

            backup_before = backup.stat()
            links_before = [(link.lstat().st_ino, link.lstat().st_mtime_ns) for link in links]
            second = self.run_fixture(home, package_root)
            self.assert_success(second)
            self.assertRegex(
                second.stdout + second.stderr,
                r"localhost\s+:\s+ok=\d+\s+changed=0",
            )
            self.assertEqual(backup.stat().st_ino, backup_before.st_ino)
            self.assertEqual(backup.stat().st_mtime_ns, backup_before.st_mtime_ns)
            self.assertEqual(
                [(link.lstat().st_ino, link.lstat().st_mtime_ns) for link in links],
                links_before,
            )

    def test_existing_backup_stops_without_changing_either_file(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            home, package_root = self.create_fixture_paths(Path(temp_dir))
            target = home / ".zshrc"
            backup = home / ".zshrc.pre-stow"
            target.write_text("original target\n", encoding="utf-8")
            backup.write_text("existing backup\n", encoding="utf-8")
            target.chmod(0o600)
            backup.chmod(0o640)

            result = self.run_fixture(home, package_root)
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("already exists", result.stdout + result.stderr)
            self.assertEqual(target.read_text(encoding="utf-8"), "original target\n")
            self.assertEqual(backup.read_text(encoding="utf-8"), "existing backup\n")
            self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)
            self.assertEqual(stat.S_IMODE(backup.stat().st_mode), 0o640)
            self.assertFalse((home / ".gdt.zshrc").exists())

    def test_symlink_backup_collision_and_symlink_conflict_are_left_untouched(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            home, package_root = self.create_fixture_paths(root)
            target = home / ".zshrc"
            backup = home / ".zshrc.pre-stow"
            sentinel = root / "sentinel"
            sentinel.write_text("external fixture target\n", encoding="utf-8")
            target.write_text("original target\n", encoding="utf-8")
            backup.symlink_to(sentinel)

            result = self.run_fixture(home, package_root)
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("already exists", result.stdout + result.stderr)
            self.assertTrue(target.is_file())
            self.assertEqual(target.read_text(encoding="utf-8"), "original target\n")
            self.assertTrue(backup.is_symlink())
            self.assertEqual(backup.resolve(), sentinel)
            self.assertEqual(sentinel.read_text(encoding="utf-8"), "external fixture target\n")

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            home, package_root = self.create_fixture_paths(root)
            sentinel = root / "sentinel"
            sentinel.write_text("external fixture target\n", encoding="utf-8")
            target = home / ".zshrc"
            target.symlink_to(sentinel)

            result = self.run_fixture(home, package_root)
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("conflicts", (result.stdout + result.stderr).lower())
            self.assertTrue(target.is_symlink())
            self.assertEqual(target.resolve(), sentinel)
            self.assertFalse((home / ".zshrc.pre-stow").exists())

    def test_check_mode_leaves_conflicts_and_targets_untouched(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            home, package_root = self.create_fixture_paths(Path(temp_dir))
            target = home / ".zshrc"
            original = b"check-mode target\n"
            target.write_bytes(original)
            target.chmod(0o604)

            result = self.run_fixture(home, package_root, check=True)
            self.assert_success(result)
            self.assertTrue(target.is_file())
            self.assertFalse(target.is_symlink())
            self.assertEqual(target.read_bytes(), original)
            self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o604)
            self.assertFalse((home / ".zshrc.pre-stow").exists())
            self.assertFalse((home / ".gdt.zshrc").exists())
            self.assertFalse((home / ".homebrew.zshrc").exists())
            self.assertRegex(
                result.stdout + result.stderr,
                r"localhost\s+:\s+ok=\d+\s+changed=0",
            )


if __name__ == "__main__":
    unittest.main()
