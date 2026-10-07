import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GROUP_VARS = ROOT / "ansible/group_vars/all.yml"
COMMON_TASKS = ROOT / "ansible/tasks/common.yml"
WINDOWS_SETUP = ROOT / "setup-windows.ps1"
STOW_TARGETS = {
    "starship": ".config/starship.toml",
    "herdr": ".config/herdr/config.toml",
    "wezterm": ".config/wezterm/wezterm.lua",
}


class ConfigDeliveryTests(unittest.TestCase):
    def test_selected_unix_packages_and_wsl_ssh_handling(self):
        group_vars = GROUP_VARS.read_text(encoding="utf-8")
        match = re.search(r"(?ms)^stow_packages:\n((?:  - [^\n]+\n)+)", group_vars)
        self.assertIsNotNone(match, "stow_packages list not found")
        packages = {line.removeprefix("  - ") for line in match.group(1).splitlines()}
        self.assertTrue(set(STOW_TARGETS).issubset(packages))
        self.assertIn("ssh", packages)
        self.assertNotIn("psmux", packages)

        common_tasks = COMMON_TASKS.read_text(encoding="utf-8")
        self.assertIn("stow_packages | difference(['ssh']) if is_wsl else stow_packages", common_tasks)
        self.assertIn("Deploy ssh config natively on WSL", common_tasks)

    @unittest.skipUnless(shutil.which("stow"), "GNU Stow is unavailable")
    def test_stow_dry_runs_use_expected_temporary_home_targets(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            home = Path(temp_dir) / "home"
            home.mkdir()
            for package, target in STOW_TARGETS.items():
                with self.subTest(package=package):
                    result = subprocess.run(
                        [
                            shutil.which("stow"),
                            "--no-folding",
                            f"--target={home}",
                            f"--dir={ROOT}",
                            "-nv",
                            "--restow",
                            package,
                        ],
                        cwd=ROOT,
                        capture_output=True,
                        text=True,
                        check=False,
                    )
                    output = result.stdout + result.stderr
                    self.assertEqual(result.returncode, 0, output)
                    self.assertIn(f"LINK: {target} => ", output)
                    self.assertEqual(list(home.iterdir()), [])

    def test_windows_starship_source_resolves_to_relocated_file(self):
        source = ROOT / "starship/.config/starship.toml"
        self.assertTrue(source.is_file())
        self.assertFalse((ROOT / "starship/starship.toml").exists())
        setup = WINDOWS_SETUP.read_text(encoding="utf-8")
        self.assertIn('-Source "$RepoRoot\\starship\\.config\\starship.toml"', setup)


if __name__ == "__main__":
    unittest.main()
