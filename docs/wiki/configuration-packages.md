---
title: Configuration packages
source_files:
  - git/.gitconfig
  - zsh/.zshrc
  - tmux/.config/tmux/tmux.conf
  - psmux/.psmux.conf
  - herdr/.config/herdr/config.toml
  - nvim/.config/nvim/init.lua
  - starship/.config/starship.toml
  - wezterm/.config/wezterm/wezterm.lua
  - agents/.agents/.skill-lock.json
  - claude/.claude/settings.json
  - agents/.agents/skills/.gitignore
  - agents/.agents/skills/artifact-driven-development/SKILL.md
  - docs/package_management/ideas.md
  - docs/stow-packages.md
last_reviewed: 2026-10-07
---
# Configuration packages

Selected configuration directories are repository-managed Stow packages on macOS and Linux, including WSL. They include shell, Git, terminal, editor, agent, and application configuration such as [zsh](../../zsh/.zshrc), [tmux](../../tmux/.config/tmux/tmux.conf), [psmux](../../psmux/.psmux.conf), [Herdr](../../herdr/.config/herdr/config.toml), [Neovim](../../nvim/.config/nvim/init.lua), [Starship](../../starship/.config/starship.toml), [WezTerm](../../wezterm/.config/wezterm/wezterm.lua), [Zed](../../zed/.config/zed/settings.json), and [Claude Code](../../claude/.claude/settings.json).

Unix Stow delivers Starship to `~/.config/starship.toml`, Herdr to `~/.config/herdr/config.toml`, and WezTerm to `~/.config/wezterm/wezterm.lua`. psmux is native-Windows-only: its configuration is linked by Windows setup and is not deployed in WSL.

The tracked Zed settings hold shared preferences only. Connection definitions and project history are application-local state and are excluded from canonical settings; see [synchronization](synchronization.md). Claude hook commands and the Zsh `obsidian` alias use quoted `$HOME`-relative paths. These references do not install the local hooks or application binary.

WezTerm uses one shared configuration across platforms. Unix hosts deploy it through GNU Stow, while Windows setup links it into the user configuration directory. The WSL:Debian default applies only to Windows target triples; macOS and Linux retain their native default domain. These are configuration delivery paths only – none installs the WezTerm application.

## WezTerm Mermaid preview

`zsh/.zshrc` and the native Windows PowerShell profile provide `glowm-wezterm`. It is an experimental wrapper that makes `glowm` select its iTerm2 inline-image path, which WezTerm implements. It must be run directly in WezTerm and needs the provisioned Chrome or Chromium browser; use `glowm --pdf` if inline rendering fails.

## Constraints

The repository is canonical. On macOS and Linux, Stow is the only mechanism for linking repository files into the home directory; add a package directory instead of using `ln -s` or Ansible `state: link`. Application settings that cannot safely use a WSL-backed symlink are governed by [synchronization](synchronization.md), not Stow.

## Guidance

For the detailed cross-platform, difference-first tool inventory, use [machine tooling comparison](machine-tooling.md). Global agent guidance is canonical at [agents/.agents/AGENTS.md](../../agents/.agents/AGENTS.md), installed at `~/.agents/AGENTS.md`, imported by Claude Code, and linked into Pi's agent directory. Agent-skill lockfiles record third-party skill sources but restored third-party directories are not committed.

The allowlisted local [artifact-driven-development skill](../../agents/.agents/skills/artifact-driven-development/SKILL.md) provides alignment, design, and implementation prompt templates, explicit approval gates, manual model-routing guidance, and cache-aware handoffs. It has no API runner or automatic model switching. It is installed through the existing `agents` Stow package; Pi discovers `~/.agents/skills/` and can reload updated skills with `/reload`.
