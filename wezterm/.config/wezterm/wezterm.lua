-- WezTerm configuration.
--
-- Lives at ~/.config/wezterm/wezterm.lua (stow target on Linux/macOS; symlinked
-- into %USERPROFILE%\.config\wezterm on Windows by windows/setup-windows.ps1).
--
-- Docs: https://wezterm.org/config/files.html

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font_with_fallback({ "JetBrains Mono", "Fira Code", "DengXian" })
config.font_size = 11
config.default_domain = "WSL:Debian"

-- The installed Windows WezTerm build misreports shifted printable keys through
-- Kitty keyboard mode in WSL multiplexers. Use standard terminal input instead.
config.enable_kitty_keyboard = false

config.keys = {
	{
		key = "c",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			if window:get_selection_text_for_pane(pane) ~= "" then
				window:perform_action(act.CopyTo("Clipboard"), pane)
			else
				window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
			end
		end),
	},
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
}

wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

return config
