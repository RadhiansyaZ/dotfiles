-- WezTerm configuration.
--
-- Lives at ~/.config/wezterm/wezterm.lua (stowed on Linux/macOS; linked into
-- %USERPROFILE%\.config\wezterm by setup-windows.ps1 on Windows).
--
-- Docs: https://wezterm.org/config/files.html

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font_with_fallback({ "JetBrains Mono", "Fira Code", "DengXian" })
config.font_size = 11
if wezterm.target_triple:find("windows", 1, true) then
	config.default_domain = "WSL:Debian"
end

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
