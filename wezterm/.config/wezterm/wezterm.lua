-- WezTerm configuration.
--
-- Lives at ~/.config/wezterm/wezterm.lua (stow target on Linux/macOS; symlinked
-- into %USERPROFILE%\.config\wezterm on Windows by windows/setup-windows.ps1).
--
-- Goal: a tmux-style keybinding layer using a Ctrl+A leader, so the muscle
-- memory from tmux/.config/tmux/tmux.conf (prefix = C-a) carries over to native
-- WezTerm panes/tabs without running tmux.
--
-- Docs: https://wezterm.org/config/files.html

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- resurrect.wezterm: tmux-resurrect-style save/restore of workspace layout
-- (windows, tabs, panes). Fetched and cached by wezterm on first run.
-- NOTE: upstream repo was archived 2026-05; still functional, unmaintained.
-- Docs: https://github.com/MLFlexer/resurrect.wezterm
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
-- Auto-save the workspace state every 15 min (tmux-continuum feel). Workspaces
-- only: no per-window/per-tab snapshots, matching the workspace-level scope.
-- State is written as plain JSON under wezterm's runtime dir (no encryption).
resurrect.state_manager.periodic_save({
	interval_seconds = 15 * 60,
	save_workspaces = true,
	save_windows = false,
	save_tabs = false,
})
-- Report modified keys (including Shift+Enter) distinctly to terminal apps such as Pi.
config.enable_kitty_keyboard = true
-- Let CTRL alone bypass mouse reporting (tmux.conf sets `mouse on`), so
-- CTRL-click still opens links instead of being swallowed by tmux.
config.bypass_mouse_reporting_modifiers = "CTRL"
-- Single fixed color scheme for every pane/domain (no per-pane switching, so no
-- set_config_overrides repaints and no theme flicker).
config.color_scheme = "Catppuccin Macchiato"
local spawn_domain = "CurrentPaneDomain"

-- Open at bottom-left, sized to at least 1/4 of the screen area (half width,
-- half height of the active screen's resolution). wezterm has no API to query
-- the taskbar's reserved work area, so this assumes the default Windows
-- taskbar height; adjust if yours is a different size.
local TASKBAR_HEIGHT = 48
wezterm.on("gui-startup", function(cmd)
	local screen = wezterm.gui.screens().active
	local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
	local height = screen.height // 2
	window:gui_window():set_position(screen.x, screen.y + screen.height - height - TASKBAR_HEIGHT)
	window:gui_window():set_inner_size(screen.width // 2, height)
end)

-- On Windows, default to a native WSL domain so new tabs/splits inherit the
-- Linux environment and land in the distro's home directory instead of
-- C:\Users\<user>.
if wezterm.target_triple:find("windows") then
	config.default_domain = "WSL:Debian"
	-- spawn_domain stays CurrentPaneDomain: the base pane is already WSL (via
	-- default_domain), so splits/tabs inherit the WSL domain AND the current
	-- working directory. Landing in ~ instead of /mnt/c/Users requires the shell
	-- to report its cwd via OSC 7 (see zsh/.zshrc); without that, WSL splits fall
	-- back to wezterm's Windows launch dir.

	-- Preserve the native Windows font fallback chain and useful shell launcher.
	config.font = wezterm.font_with_fallback({ "JetBrains Mono", "Fira Code", "DengXian" })
	config.font_size = 10
	config.launch_menu = {
		{
			label = "Git Bash",
			args = { "C:\\Program Files\\Git\\bin\\bash.exe", "--login", "-i" },
		},
	}

	-- Ctrl-click links without forwarding the matching mouse-down event.
	config.mouse_bindings = {
		{
			event = { Up = { streak = 1, button = "Left" } },
			mods = "CTRL",
			action = act.OpenLinkAtMouseCursor,
		},
		{
			event = { Down = { streak = 1, button = "Left" } },
			mods = "CTRL",
			action = act.Nop,
		},
	}
end

-- --------------------------------------------------------------------------- leader
-- Ctrl+A, matching tmux `set -g prefix C-a`. A 1s window matches tmux's feel of
-- holding the prefix briefly before the action key.
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

-- Keys mirror the tmux defaults (https://tmuxcheatsheet.com/) with the C-a
-- leader. tmux concepts map onto WezTerm as: tmux "window" -> WezTerm tab,
-- tmux "pane" -> WezTerm pane, tmux "session" -> WezTerm workspace.
config.keys = {
	-- Send a literal Ctrl+A to the terminal (e.g. readline beginning-of-line),
	-- mirroring tmux's `prefix prefix`.
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	-- ------------------------------------------------------------------- panes
	-- tmux splits are named by the divider orientation: % = vertical divider
	-- (side-by-side panes) = WezTerm SplitHorizontal; " = horizontal divider
	-- (stacked panes) = WezTerm SplitVertical.
	{ key = "%", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = spawn_domain }) },
	{ key = '"', mods = "LEADER|SHIFT", action = act.SplitVertical({ domain = spawn_domain }) },
	-- Convenience aliases keyed to the divider you draw: | side-by-side, - stacked.
	{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = spawn_domain }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = spawn_domain }) },

	-- tmux: prefix + arrow keys switch to the adjacent pane.
	{ key = "LeftArrow", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	-- tmux: prefix + o cycles to the next pane; prefix + q shows pane numbers
	-- to jump to; prefix + z toggles zoom; prefix + x kills the pane.
	{ key = "o", mods = "LEADER", action = act.ActivatePaneDirection("Next") },
	{ key = "q", mods = "LEADER", action = act.PaneSelect },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	-- tmux: prefix + { / } swap the pane with the previous / next one.
	{ key = "{", mods = "LEADER|SHIFT", action = act.RotatePanes("CounterClockwise") },
	{ key = "}", mods = "LEADER|SHIFT", action = act.RotatePanes("Clockwise") },
	-- tmux: prefix + Ctrl+arrow resizes the pane (repeatable within leader timeout).
	{ key = "LeftArrow", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "RightArrow", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Right", 5 }) },
	{ key = "UpArrow", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "DownArrow", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Down", 5 }) },

	-- ------------------------------------------------------- windows (= tabs)
	-- tmux: prefix + c new, & kill, n/p next/prev, l last, w list, , rename.
	{ key = "c", mods = "LEADER", action = act.SpawnTab(spawn_domain) },
	{ key = "&", mods = "LEADER|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "l", mods = "LEADER", action = act.ActivateLastTab },
	{ key = "w", mods = "LEADER", action = act.ShowTabNavigator },
	{ key = ",", mods = "LEADER", action = act.PromptInputLine({
		description = "Rename tab",
		action = wezterm.action_callback(function(window, _, line)
			if line then
				window:active_tab():set_title(line)
			end
		end),
	}) },

	-- ------------------------------------------------ sessions (= workspaces)
	-- tmux: prefix + s lists sessions; prefix + $ renames the session.
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ key = "$", mods = "LEADER|SHIFT", action = act.PromptInputLine({
		description = "Rename workspace",
		action = wezterm.action_callback(function(_, _, line)
			if line then
				wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
			end
		end),
	}) },
	-- resurrect: save/restore the workspace, mirroring tmux-resurrect's
	-- prefix+Ctrl-s (save) / prefix+Ctrl-r (restore) under the C-a leader.
	{ key = "s", mods = "LEADER|CTRL", action = wezterm.action_callback(function()
		resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
	end) },
	{ key = "r", mods = "LEADER|CTRL", action = wezterm.action_callback(function(win, pane)
		-- Fuzzy-pick a saved state; only workspace states are restored here.
		resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id)
			local kind = string.match(id, "^([^/]+)")
			id = string.match(id, "([^/]+)$")
			id = string.match(id, "(.+)%..+$")
			if kind == "workspace" then
				local state = resurrect.state_manager.load_state(id, "workspace")
				resurrect.workspace_state.restore_workspace(state, {
					relative = true,
					restore_text = true,
					on_pane_restore = resurrect.tab_state.default_on_pane_restore,
				})
			end
		end)
	end) },

	-- --------------------------------------------------------------- copy/misc
	-- tmux: prefix + [ enters copy mode; prefix + ] pastes; prefix + : opens
	-- the command prompt (WezTerm's command palette is the closest analogue).
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "]", mods = "LEADER", action = act.PasteFrom("Clipboard") },
	{ key = ":", mods = "LEADER|SHIFT", action = act.ActivateCommandPalette },
}

-- tmux: prefix + <number> selects window N (1-indexed). Tabs are 0-indexed here.
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

-- --------------------------------------------------------------------------- ghostty
-- Ghostty's default (Linux/Windows) keybindings layered on top of the tmux
-- leader binds above. These are direct chords (no leader), so they don't
-- collide with the C-a layer. Source: ghostty default keybinds
-- (`ghostty +list-keybinds --default`); Ghostty's ctrl+shift family is used
-- since this config is symlinked to Windows. tmux "window" == WezTerm tab,
-- Ghostty "split" == WezTerm pane.
local ghostty_keys = {
	-- Clipboard.
	{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

	-- Splits (Ghostty: ctrl+shift+o = split right, ctrl+shift+e = split down).
	{ key = "o", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = spawn_domain }) },
	{ key = "e", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = spawn_domain }) },
	-- Navigate splits (Ghostty: ctrl+alt+arrows = goto_split <dir>).
	{ key = "LeftArrow", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Down") },

	-- Tabs (Ghostty: ctrl+shift+t new, ctrl+shift+w close, ctrl+(shift+)tab cycle,
	-- ctrl+pgup/pgdn cycle, ctrl+shift+left/right cycle).
	{ key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab(spawn_domain) },
	{ key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
	{ key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "PageUp", mods = "CTRL", action = act.ActivateTabRelative(-1) },
	{ key = "PageDown", mods = "CTRL", action = act.ActivateTabRelative(1) },
	{ key = "LeftArrow", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(1) },

	-- Windows / app (Ghostty: ctrl+shift+n new window, ctrl+shift+q quit).
	{ key = "n", mods = "CTRL|SHIFT", action = act.SpawnWindow },
	{ key = "q", mods = "CTRL|SHIFT", action = act.QuitApplication },

	-- Font size (Ghostty: ctrl+= / ctrl++ grow, ctrl+- shrink, ctrl+0 reset).
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "+", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },

	-- Scrollback (Ghostty: shift+pgup/pgdn page scroll, ctrl+shift+up/down jump
	-- between shell prompts — the latter needs shell integration / semantic zones).
	{ key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1) },
	{ key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },
	{ key = "UpArrow", mods = "CTRL|SHIFT", action = act.ScrollToPrompt(-1) },
	{ key = "DownArrow", mods = "CTRL|SHIFT", action = act.ScrollToPrompt(1) },

	-- Misc (Ghostty: ctrl+shift+, reload config, ctrl+shift+i inspector,
	-- ctrl+enter toggle fullscreen).
	{ key = ",", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
	{ key = "i", mods = "CTRL|SHIFT", action = act.ShowDebugOverlay },
	{ key = "Enter", mods = "CTRL", action = act.ToggleFullScreen },
}
for _, k in ipairs(ghostty_keys) do
	table.insert(config.keys, k)
end

-- --------------------------------------------------------------------------- rendering
-- WebGpu (DX12 on Windows) is smoother than the default OpenGL front end for
-- the WSL-on-Windows setup; WezTerm auto-falls back to Software rendering under
-- Remote Desktop. If a GPU/driver issue shows up, set front_end = "Software".
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
-- Cap the frame rate so busy WSL output doesn't spin the GPU needlessly.
config.max_fps = 120

-- --------------------------------------------------------------------------- appearance
-- Minimal defaults; tweak freely. Tab bar at the bottom echoes tmux's status line.
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 10000

return config
