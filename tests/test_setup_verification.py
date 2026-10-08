import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests/fixtures/setup-verification.yml"
COMMAND_VERSION_FLAGS = {
    "zsh": "--version",
    "stow": "--version",
    "tmux": "-V",
    "nvim": "--version",
    "pyenv": "--version",
}
CRITICAL_COMMANDS = tuple(COMMAND_VERSION_FLAGS)


@unittest.skipUnless(shutil.which("ansible-playbook"), "Ansible is required")
class SetupVerificationTests(unittest.TestCase):
    def create_fixture(self, root, *, missing=(), failing=None):
        home = root / "home"
        home.mkdir()
        package_root = root / "packages"
        package_root.mkdir()
        bin_dir = root / "bin"
        bin_dir.mkdir()
        log = root / "probes.log"

        for command in CRITICAL_COMMANDS:
            if command in missing:
                continue
            version_arg = COMMAND_VERSION_FLAGS[command]
            diagnostic = (
                f"printf '%s\\n' 'fixture probe failure for {command}' >&2\n"
                if command == failing
                else f"printf '%s\\n' 'fixture {command} version'\n"
            )
            exit_code = 23 if command == failing else 0
            script = (
                "#!/bin/sh\n"
                f"if [ \"$#\" -ne 1 ] || [ \"$1\" != \"{version_arg}\" ]; then\n"
                f"  printf '%s\\n' 'unexpected version argument for {command}' >&2\n"
                "  exit 64\n"
                "fi\n"
                f"printf '%s:%s\\n' '{command}' \"$1\" >> \"$SETUP_VERIFY_LOG\"\n"
                f"{diagnostic}"
                f"exit {exit_code}\n"
            )
            executable = bin_dir / command
            executable.write_text(script, encoding="utf-8")
            executable.chmod(0o755)

        return home, package_root, bin_dir, log

    def run_fixture(
        self,
        home,
        package_root,
        bin_dir,
        log,
        *,
        system="Linux",
        family="Debian",
        tags="verify",
        check=False,
    ):
        env = os.environ.copy()
        env.update(
            HOME=str(home),
            ANSIBLE_LOCAL_TEMP=str(home / ".ansible/controller-tmp"),
            SETUP_VERIFY_PATH=str(bin_dir),
            DOTFILES_ROOT=str(package_root),
            SETUP_VERIFY_LOG=str(log),
            SETUP_VERIFY_SYSTEM=system,
            SETUP_VERIFY_FAMILY=family,
        )
        command = [
            shutil.which("ansible-playbook"),
            "-i",
            "localhost,",
            "-c",
            "local",
            str(FIXTURE),
            "--tags",
            tags,
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
        return result

    def test_darwin_and_debian_family_are_supported_and_all_commands_pass(self):
        for system, family in (("Darwin", "Darwin"), ("Linux", "Debian")):
            with tempfile.TemporaryDirectory() as temp_dir:
                with self.subTest(system=system, family=family):
                    home, package_root, bin_dir, log = self.create_fixture(Path(temp_dir))
                    result = self.run_fixture(
                        home, package_root, bin_dir, log, system=system, family=family
                    )
                    output = result.stdout + result.stderr
                    self.assertEqual(result.returncode, 0, output)
                    self.assertIn("changed=0", output)
                    self.assertEqual(
                        log.read_text(encoding="utf-8").splitlines(),
                        [f"{name}:{flag}" for name, flag in COMMAND_VERSION_FLAGS.items()],
                    )
                    self.assertNotIn("Critical command verification failed", output)

    def test_tmux_probe_uses_supported_version_flag(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            home, package_root, bin_dir, log = self.create_fixture(Path(temp_dir))
            result = self.run_fixture(home, package_root, bin_dir, log)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("tmux:-V", log.read_text(encoding="utf-8").splitlines())
            self.assertNotIn("unexpected version argument", output)

    def test_version_probes_run_in_check_mode(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            home, package_root, bin_dir, log = self.create_fixture(Path(temp_dir))
            result = self.run_fixture(home, package_root, bin_dir, log, check=True)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("changed=0", output)
            self.assertEqual(
                log.read_text(encoding="utf-8").splitlines(),
                [f"{name}:{flag}" for name, flag in COMMAND_VERSION_FLAGS.items()],
            )

    def test_unsupported_operating_system_is_rejected_before_probes(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            home, package_root, bin_dir, log = self.create_fixture(Path(temp_dir))
            result = self.run_fixture(
                home, package_root, bin_dir, log, system="FreeBSD", family="FreeBSD"
            )
            output = result.stdout + result.stderr
            self.assertNotEqual(result.returncode, 0, output)
            self.assertIn("Unsupported operating system: FreeBSD", output)
            self.assertNotIn("Probe critical command versions", output)
            self.assertFalse(log.exists())

    def test_non_debian_linux_is_rejected_in_tagged_runs(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            home, package_root, bin_dir, log = self.create_fixture(Path(temp_dir))
            for tags in ("linux", "verify"):
                with self.subTest(tags=tags):
                    result = self.run_fixture(
                        home, package_root, bin_dir, log, family="RedHat", tags=tags
                    )
                    output = result.stdout + result.stderr
                    self.assertNotEqual(result.returncode, 0, output)
                    self.assertIn("Unsupported Linux family: RedHat", output)
                    self.assertNotIn("Probe critical command versions", output)
                    self.assertFalse(log.exists())

    def test_all_missing_commands_are_reported_after_all_probes(self):
        missing = ("zsh", "nvim")
        with tempfile.TemporaryDirectory() as temp_dir:
            home, package_root, bin_dir, log = self.create_fixture(
                Path(temp_dir), missing=missing
            )
            result = self.run_fixture(home, package_root, bin_dir, log)
            output = result.stdout + result.stderr
            self.assertNotEqual(result.returncode, 0, output)
            self.assertIn("Missing critical commands: zsh, nvim", output)
            self.assertIn("zsh (rc=127)", output)
            self.assertIn("nvim (rc=127)", output)
            self.assertEqual(
                log.read_text(encoding="utf-8").splitlines(),
                ["stow:--version", "tmux:-V", "pyenv:--version"],
            )
            self.assertEqual(output.count("FAILED!"), 1, output)

    def test_nonzero_probe_is_reported_with_its_actual_diagnostic(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            home, package_root, bin_dir, log = self.create_fixture(Path(temp_dir), failing="tmux")
            result = self.run_fixture(home, package_root, bin_dir, log)
            output = result.stdout + result.stderr
            self.assertNotEqual(result.returncode, 0, output)
            self.assertIn("Missing critical commands: none", output)
            self.assertIn("tmux (rc=23): fixture probe failure for tmux", output)
            self.assertEqual(
                log.read_text(encoding="utf-8").splitlines(),
                [f"{name}:{flag}" for name, flag in COMMAND_VERSION_FLAGS.items()],
            )
            self.assertEqual(output.count("FAILED!"), 1, output)


if __name__ == "__main__":
    unittest.main()
