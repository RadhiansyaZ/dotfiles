import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SETTINGS = ROOT / "zed/.config/zed/settings.json"
CLAUDE_SETTINGS = ROOT / "claude/.claude/settings.json"
ZSHRC = ROOT / "zsh/.zshrc"
ABSOLUTE_HOME = re.compile(r"/(?:home|Users)/[^/\s]+")


def hook_commands(settings):
    return [
        hook["command"]
        for entries in settings["hooks"].values()
        for entry in entries
        for hook in entry["hooks"]
    ]


def strip_jsonc(text):
    output = []
    index = 0
    in_string = False
    while index < len(text):
        char = text[index]
        if in_string:
            output.append(char)
            if char == "\\" and index + 1 < len(text):
                index += 1
                output.append(text[index])
            elif char == '"':
                in_string = False
        elif text.startswith("//", index):
            end = text.find("\n", index + 2)
            if end < 0:
                break
            output.append("\n")
            index = end
        elif text.startswith("/*", index):
            end = text.find("*/", index + 2)
            if end < 0:
                raise ValueError("unterminated JSONC comment")
            output.extend("\n" for item in text[index : end + 2] if item == "\n")
            index = end + 1
        else:
            if char == '"':
                in_string = True
            output.append(char)
        index += 1

    without_comments = "".join(output)
    output = []
    index = 0
    in_string = False
    while index < len(without_comments):
        char = without_comments[index]
        if in_string:
            output.append(char)
            if char == "\\" and index + 1 < len(without_comments):
                index += 1
                output.append(without_comments[index])
            elif char == '"':
                in_string = False
        elif char == '"':
            in_string = True
            output.append(char)
        elif char == ",":
            lookahead = index + 1
            while lookahead < len(without_comments) and without_comments[lookahead].isspace():
                lookahead += 1
            if lookahead == len(without_comments) or without_comments[lookahead] not in "}]":
                output.append(char)
        else:
            output.append(char)
        index += 1
    return "".join(output)


def parse_jsonc(text):
    return json.loads(strip_jsonc(text))


def contains_key(value, forbidden):
    if isinstance(value, dict):
        return any(key in forbidden or contains_key(child, forbidden) for key, child in value.items())
    if isinstance(value, list):
        return any(contains_key(child, forbidden) for child in value)
    return False


class ZedPrivacyTests(unittest.TestCase):
    def test_jsonc_settings_exclude_machine_local_connections_and_projects(self):
        text = SETTINGS.read_text(encoding="utf-8")
        settings = parse_jsonc(text)
        self.assertFalse(contains_key(settings, {"ssh_connections", "wsl_connections", "projects"}))
        self.assertIn("cli_default_open_behavior", settings)
        self.assertIn("theme", settings)
        self.assertIn("agent_servers", settings)
        self.assertIn("SQL", settings["languages"])
        self.assertIn("terminal", settings)

    def test_jsonc_comments_and_trailing_commas_are_accepted(self):
        parsed = parse_jsonc('{"shared": {"enabled": true,}, // shared comment\n"items": [1, 2,],}')
        self.assertTrue(parsed["shared"]["enabled"])
        self.assertEqual(parsed["items"], [1, 2])

    def test_claude_settings_use_portable_hook_and_context_paths(self):
        settings = json.loads(CLAUDE_SETTINGS.read_text(encoding="utf-8"))
        commands = hook_commands(settings)
        self.assertEqual(len(commands), 5)
        for command in commands:
            self.assertTrue(re.search(r'"\$HOME/[^"]+"', command), "hook path is not quoted and home-relative")
            self.assertFalse(ABSOLUTE_HOME.search(command), "machine-specific home path remains in a hook")

        environment = settings["autoMode"]["environment"]
        self.assertIsInstance(environment, list)
        self.assertGreater(len(environment), 21)
        self.assertIsInstance(environment[21], str)
        self.assertIn("current repository root", environment[21])
        self.assertFalse(ABSOLUTE_HOME.search(environment[21]), "machine-specific path remains in autoMode context")

    def test_claude_hook_paths_resolve_with_home_spaces_using_mocks(self):
        settings = json.loads(CLAUDE_SETTINGS.read_text(encoding="utf-8"))
        commands = hook_commands(settings)

        with tempfile.TemporaryDirectory(prefix="prv fixture ") as temporary:
            root = Path(temporary)
            home = root / "home with spaces"
            mock_bin = root / "mock bin"
            home.mkdir()
            mock_bin.mkdir()
            log = root / "hook log"
            env = os.environ.copy()
            env.update(HOME=str(home), PATH=f"{mock_bin}{os.pathsep}{os.defpath}", PRV_HOOK_LOG=str(log))

            recorder = '''#!/bin/sh
printf '%s\\n' "$@" > "$PRV_HOOK_LOG"
'''
            for executable in ("bash", "python3"):
                path = mock_bin / executable
                path.write_text(recorder, encoding="utf-8")
                path.chmod(0o755)
            direct_recorder = '''#!/bin/sh
printf '%s\\n' "$0" "$@" > "$PRV_HOOK_LOG"
'''

            for command in commands:
                match = re.search(r'"\$HOME(/[^"]+)"', command)
                self.assertIsNotNone(match, "hook has no quoted portable path")
                target = home / match.group(1).lstrip("/")
                target.parent.mkdir(parents=True, exist_ok=True)
                if command.startswith(("bash ", "python3 ")):
                    target.touch()
                else:
                    target.write_text(direct_recorder, encoding="utf-8")
                    target.chmod(0o755)

                result = subprocess.run(["/bin/bash", "-c", command], env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, "mocked hook command failed")
                recorded = log.read_text(encoding="utf-8").splitlines()
                expected = [str(target)] + (["session"] if command.endswith(" session") else [])
                self.assertTrue(recorded == expected, "hook path or argument changed under the controlled HOME")

    def test_obsidian_alias_resolves_with_home_spaces_using_mock(self):
        zsh = shutil.which("zsh")
        if zsh is None:
            self.skipTest("zsh is unavailable")
        aliases = [line.strip() for line in ZSHRC.read_text(encoding="utf-8").splitlines() if line.strip().startswith("alias obsidian=")]
        self.assertEqual(len(aliases), 1)
        alias = aliases[0]
        self.assertTrue(alias == 'alias obsidian=\'"$HOME/.local/bin/obsidian.AppImage"\'', "alias path is not quoted and home-relative")
        self.assertFalse(ABSOLUTE_HOME.search(alias), "machine-specific home path remains in the alias")

        with tempfile.TemporaryDirectory(prefix="prv fixture ") as temporary:
            root = Path(temporary)
            home = root / "home with spaces"
            executable = home / ".local/bin/obsidian.AppImage"
            executable.parent.mkdir(parents=True)
            log = root / "alias log"
            executable.write_text('''#!/bin/sh
printf '%s\\n' "$0" "$@" > "$PRV_ALIAS_LOG"
''', encoding="utf-8")
            executable.chmod(0o755)
            env = os.environ.copy()
            env.update(HOME=str(home), PRV_ALIAS_LOG=str(log))
            script = f'''setopt aliases
{alias}
eval 'obsidian "argument with spaces"'
'''
            result = subprocess.run([zsh, "-f", "-c", script], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, "mocked alias invocation failed")
            recorded = log.read_text(encoding="utf-8").splitlines()
            self.assertTrue(recorded == [str(executable), "argument with spaces"], "alias did not resolve as one quoted executable path")

    def test_obsolete_snapshots_are_absent_and_narrowly_ignored(self):
        snapshots = (
            "zed/.config/zed/settings_backup.json",
            "wezterm/.config/wezterm/wezterm.lua.bak",
        )
        ignored = set((ROOT / ".gitignore").read_text(encoding="utf-8").splitlines())
        for path in snapshots:
            self.assertFalse((ROOT / path).exists())
            self.assertIn(f"/{path}", ignored)


if __name__ == "__main__":
    unittest.main()
