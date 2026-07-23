-- WezTerm configuration.
--
-- Lives at ~/.config/wezterm/wezterm.lua (stow target on Linux/macOS; symlinked
-- into %USERPROFILE%\.config\wezterm on Windows by windows/setup-windows.ps1).
--
-- Docs: https://wezterm.org/config/files.html

local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font_with_fallback({ "JetBrains Mono", "Fira Code", "DengXian" })
config.font_size = 11
config.default_domain = "WSL:Debian"

wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

return config
