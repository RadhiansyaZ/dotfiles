import io
import os
import shutil
import subprocess
import tarfile
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests/fixtures/krew-provisioning.yml"


class KrewArchiveHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.server.requests.append(self.path)
        asset_archive = Path(self.path).name
        if not asset_archive.endswith(".tar.gz"):
            self.send_error(404)
            return

        asset = asset_archive.removesuffix(".tar.gz")
        installer = (
            "#!/bin/sh\n"
            "set -eu\n"
            "if [ \"$#\" -ne 2 ] || [ \"$1\" != install ] || [ \"$2\" != krew ]; then\n"
            "  exit 64\n"
            "fi\n"
            "printf '%s|%s\\n' \"$0\" \"$KREW_ROOT\" >> \"$KREW_TEST_LOG\"\n"
            "if [ \"${KREW_TEST_FAIL:-0}\" = 1 ]; then exit 23; fi\n"
            "mkdir -p \"$KREW_ROOT/bin\"\n"
            f"printf '%s\\n' 'installed {asset}' > \"$KREW_ROOT/bin/kubectl-krew\"\n"
            "chmod 755 \"$KREW_ROOT/bin/kubectl-krew\"\n"
        ).encode("utf-8")
        archive = io.BytesIO()
        with tarfile.open(fileobj=archive, mode="w:gz") as bundle:
            entry = tarfile.TarInfo(asset)
            entry.mode = 0o755
            entry.size = len(installer)
            bundle.addfile(entry, io.BytesIO(installer))

        payload = archive.getvalue()
        self.send_response(200)
        self.send_header("Content-Type", "application/gzip")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format_string, *args):
        pass


class KrewProvisioningTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not shutil.which("ansible-playbook"):
            raise unittest.SkipTest("Ansible is required")

    def create_fixture(
        self, root, *, system="Linux", arch="x86_64", git=True, krew_root=None, fail=False
    ):
        home = root / "home"
        home.mkdir()
        krew_root = krew_root or home / ".krew"
        bin_dir = root / "bin"
        bin_dir.mkdir()
        temp_parent = root / "temporary"
        temp_parent.mkdir()
        log = root / "installer.log"

        if git:
            git_path = bin_dir / "git"
            git_path.write_text("#!/bin/sh\nprintf 'git fixture\\n'\n", encoding="utf-8")
            git_path.chmod(0o755)

        return {
            "home": home,
            "krew_root": krew_root,
            "bin_dir": bin_dir,
            "temp_parent": temp_parent,
            "log": log,
            "system": system,
            "arch": arch,
            "fail": fail,
        }

    @staticmethod
    def local_archive_server():
        server = ThreadingHTTPServer(("127.0.0.1", 0), KrewArchiveHandler)
        server.requests = []
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        return server, thread

    def run_fixture(self, fixture, server):
        env = os.environ.copy()
        env.update(
            HOME=str(fixture["home"]),
            ANSIBLE_LOCAL_TEMP=str(fixture["home"] / ".ansible/controller-tmp"),
            ANSIBLE_NOCOLOR="1",
            KREW_ROOT="" if fixture["krew_root"] == fixture["home"] / ".krew" else str(fixture["krew_root"]),
            KREW_TEST_SYSTEM=fixture["system"],
            KREW_TEST_ARCH=fixture["arch"],
            KREW_TEST_PATH=str(fixture["bin_dir"]),
            KREW_TEST_TEMP_PARENT=str(fixture["temp_parent"]),
            KREW_TEST_LOG=str(fixture["log"]),
            KREW_TEST_FAIL="1" if fixture["fail"] else "0",
            KREW_TEST_RELEASE_BASE_URL=f"http://127.0.0.1:{server.server_port}",
            NO_PROXY="127.0.0.1,localhost",
            no_proxy="127.0.0.1,localhost",
        )
        result = subprocess.run(
            [
                shutil.which("ansible-playbook"),
                "-i",
                "localhost,",
                "-c",
                "local",
                str(FIXTURE),
                "--tags",
                "krew",
            ],
            cwd=ROOT,
            env=env,
            capture_output=True,
            text=True,
            check=False,
            timeout=30,
        )
        return result

    def run_with_server(self, fixture, assertions):
        server, thread = self.local_archive_server()
        try:
            result = self.run_fixture(fixture, server)
            assertions(result, server)
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=5)

    def test_existing_install_is_untouched_and_needs_no_git(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            fixture = self.create_fixture(Path(temp_dir), git=False)
            installed = fixture["krew_root"] / "bin/kubectl-krew"
            installed.parent.mkdir(parents=True)
            installed.write_text("existing installation\n", encoding="utf-8")
            installed.chmod(0o755)
            before = (installed.read_bytes(), installed.stat().st_mode)

            def assert_unchanged(result, server):
                output = result.stdout + result.stderr
                self.assertEqual(result.returncode, 0, output)
                self.assertIn("changed=0", output)
                self.assertEqual(server.requests, [])
                self.assertFalse(fixture["log"].exists())
                self.assertEqual(list(fixture["temp_parent"].iterdir()), [])
                self.assertEqual((installed.read_bytes(), installed.stat().st_mode), before)

            self.run_with_server(fixture, assert_unchanged)

    def test_release_assets_match_supported_os_and_architectures(self):
        cases = (
            ("Darwin", "x86_64", "krew-darwin_amd64.tar.gz"),
            ("Darwin", "arm64", "krew-darwin_arm64.tar.gz"),
            ("Linux", "x86_64", "krew-linux_amd64.tar.gz"),
            ("Linux", "aarch64", "krew-linux_arm64.tar.gz"),
        )
        for system, arch, expected_asset in cases:
            with self.subTest(system=system, arch=arch), tempfile.TemporaryDirectory() as temp_dir:
                fixture = self.create_fixture(Path(temp_dir), system=system, arch=arch)

                def assert_asset(result, server):
                    output = result.stdout + result.stderr
                    self.assertEqual(result.returncode, 0, output)
                    self.assertEqual(server.requests, [f"/{expected_asset}"])
                    installed = fixture["krew_root"] / "bin/kubectl-krew"
                    self.assertEqual(installed.read_text(encoding="utf-8"), f"installed {expected_asset[:-7]}\n")
                    self.assertEqual(list(fixture["temp_parent"].iterdir()), [])
                    self.assertEqual(fixture["log"].read_text(encoding="utf-8").split("|", 1)[1].strip(), str(fixture["krew_root"]))

                self.run_with_server(fixture, assert_asset)

    def test_custom_krew_root_and_repeat_run_do_not_upgrade(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            custom_root = root / "custom-krew"
            fixture = self.create_fixture(root, krew_root=custom_root)

            def assert_repeat(result, server):
                output = result.stdout + result.stderr
                self.assertEqual(result.returncode, 0, output)
                self.assertRegex(output, r"changed=[1-9]")
                self.assertEqual(server.requests, ["/krew-linux_amd64.tar.gz"])
                installed = custom_root / "bin/kubectl-krew"
                self.assertTrue(installed.is_file())
                self.assertFalse((fixture["home"] / ".krew").exists())
                log_lines = fixture["log"].read_text(encoding="utf-8").splitlines()
                self.assertEqual(len(log_lines), 1)
                installer_path, installed_root = log_lines[0].split("|", 1)
                self.assertEqual(Path(installer_path).name, "krew-linux_amd64")
                self.assertEqual(installed_root, str(custom_root))
                self.assertEqual(list(fixture["temp_parent"].iterdir()), [])

                second = self.run_fixture(fixture, server)
                second_output = second.stdout + second.stderr
                self.assertEqual(second.returncode, 0, second_output)
                self.assertIn("changed=0", second_output)
                self.assertEqual(server.requests, ["/krew-linux_amd64.tar.gz"])
                self.assertEqual(len(fixture["log"].read_text(encoding="utf-8").splitlines()), 1)

            self.run_with_server(fixture, assert_repeat)

    def test_unsupported_architecture_fails_before_download(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            fixture = self.create_fixture(Path(temp_dir), arch="riscv64")

            def assert_rejected(result, server):
                output = result.stdout + result.stderr
                self.assertNotEqual(result.returncode, 0, output)
                self.assertIn("Unsupported Krew architecture: riscv64", output)
                self.assertEqual(server.requests, [])
                self.assertFalse(fixture["log"].exists())
                self.assertEqual(list(fixture["temp_parent"].iterdir()), [])

            self.run_with_server(fixture, assert_rejected)

    def test_missing_git_fails_before_download_or_temporary_directory(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            fixture = self.create_fixture(Path(temp_dir), git=False)

            def assert_git_required(result, server):
                output = result.stdout + result.stderr
                self.assertNotEqual(result.returncode, 0, output)
                self.assertIn("Git is required to install Krew", output)
                self.assertEqual(server.requests, [])
                self.assertFalse(fixture["log"].exists())
                self.assertEqual(list(fixture["temp_parent"].iterdir()), [])

            self.run_with_server(fixture, assert_git_required)

    def test_temporary_files_are_removed_when_installer_fails(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            fixture = self.create_fixture(Path(temp_dir), fail=True)

            def assert_cleanup(result, server):
                output = result.stdout + result.stderr
                self.assertNotEqual(result.returncode, 0, output)
                self.assertIn("non-zero return code", output)
                self.assertEqual(server.requests, ["/krew-linux_amd64.tar.gz"])
                self.assertEqual(len(fixture["log"].read_text(encoding="utf-8").splitlines()), 1)
                self.assertEqual(list(fixture["temp_parent"].iterdir()), [])

            self.run_with_server(fixture, assert_cleanup)

    def test_shell_path_uses_the_same_krew_root_default(self):
        shell_config = (ROOT / "zsh/.zshrc").read_text(encoding="utf-8")
        self.assertIn('export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"', shell_config)


if __name__ == "__main__":
    unittest.main()
