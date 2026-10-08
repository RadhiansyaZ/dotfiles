import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "wezterm/.config/wezterm/wezterm.lua"
SETUP = ROOT / "setup-windows.ps1"

LUA_HARNESS = r'''
local wezterm = {
    target_triple = vim.env.WEZTERM_TARGET_TRIPLE,
    action = {},
}

local function action(name)
    return function(value) return { name = name, value = value } end
end

wezterm.action.CopyTo = action("CopyTo")
wezterm.action.PasteFrom = action("PasteFrom")
wezterm.action.SendKey = action("SendKey")
wezterm.config_builder = function() return {} end
wezterm.font_with_fallback = function(fonts) return fonts end
wezterm.action_callback = function(callback) return callback end
local events = {}
wezterm.on = function(name, callback) events[name] = callback end
package.preload.wezterm = function() return wezterm end

local config = dofile(vim.env.WEZTERM_CONFIG)
local expected = vim.env.WEZTERM_EXPECTED_DOMAIN
assert(config.default_domain == (expected ~= "" and expected or nil), "wrong default domain")
assert(config.color_scheme == "Catppuccin Mocha")
assert(config.font_size == 11)
assert(
    config.font[1] == "JetBrains Mono" and config.font[2] == "Fira Code" and config.font[3] == "DengXian"
)
assert(config.enable_kitty_keyboard == false)
assert(#config.keys == 2)
assert(config.keys[1].key == "c" and config.keys[1].mods == "CTRL")
assert(config.keys[2].key == "v" and config.keys[2].mods == "CTRL")
assert(type(events["gui-startup"]) == "function")
'''


class WezTermConfigTests(unittest.TestCase):
    def test_windows_setup_keeps_wezterm_link_and_psmux_ppm(self):
        setup = SETUP.read_text(encoding="utf-8")
        self.assertIn('Write-Step "Installing psmux Plugin Manager"', setup)
        self.assertIn("https://github.com/psmux/psmux-plugins.git", setup)
        self.assertIn('Source "$RepoRoot\\wezterm\\.config\\wezterm\\wezterm.lua"', setup)
        self.assertNotIn("Installing WezTerm plugins", setup)
        self.assertNotIn("Get-WeztermPluginDir", setup)
        self.assertNotIn("Install-WeztermPlugin", setup)

    @unittest.skipUnless(shutil.which("nvim"), "nvim with embedded Lua is unavailable")
    def test_domain_and_existing_settings_for_platform_target_triples(self):
        cases = (
            ("x86_64-pc-windows-msvc", "WSL:Debian"),
            ("aarch64-apple-darwin", ""),
            ("x86_64-unknown-linux-gnu", ""),
        )
        with tempfile.TemporaryDirectory() as temp_dir:
            harness = Path(temp_dir) / "wezterm-test.lua"
            harness.write_text(LUA_HARNESS, encoding="utf-8")
            for target, expected_domain in cases:
                with self.subTest(target=target):
                    env = os.environ.copy()
                    env.update(
                        WEZTERM_CONFIG=str(CONFIG),
                        WEZTERM_TARGET_TRIPLE=target,
                        WEZTERM_EXPECTED_DOMAIN=expected_domain,
                    )
                    result = subprocess.run(
                        [
                            shutil.which("nvim"),
                            "--headless",
                            "-u",
                            "NONE",
                            "-i",
                            "NONE",
                            "-l",
                            str(harness),
                        ],
                        cwd=ROOT,
                        env=env,
                        capture_output=True,
                        text=True,
                        timeout=15,
                        check=False,
                    )
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
