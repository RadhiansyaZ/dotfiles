---
title: Configuration packages
source_files:
  - git/.gitconfig
  - zsh/.zshrc
  - tmux/.config/tmux/tmux.conf
  - psmux/.psmux.conf
  - herdr/.config/herdr/config.toml
  - nvim/.config/nvim/init.lua
  - starship/starship.toml
  - wezterm/.config/wezterm/wezterm.lua
  - agents/.agents/.skill-lock.json
last_reviewed: 2026-08-05
---
# Configuration packages

Configuration directories are repository-managed Stow packages. They include shell, Git, terminal, editor, agent, and application configuration such as [zsh](../../zsh/.zshrc), [tmux](../../tmux/.config/tmux/tmux.conf), [psmux](../../psmux/.psmux.conf), [Herdr](../../herdr/.config/herdr/config.toml), [Neovim](../../nvim/.config/nvim/init.lua), and [Starship](../../starship/starship.toml).

## WezTerm Mermaid preview

`zsh/.zshrc` and the native Windows PowerShell profile provide `glowm-wezterm`. It is an experimental wrapper that makes `glowm` select its iTerm2 inline-image path, which WezTerm implements. It must be run directly in WezTerm and needs the provisioned Chrome or Chromium browser; use `glowm --pdf` if inline rendering fails.

## Constraints

The repository is canonical. Application settings that cannot safely use a WSL-backed symlink are governed by [synchronization](synchronization.md), not Stow.

## Guidance

For the detailed cross-platform, difference-first tool inventory, use [machine tooling comparison](machine-tooling.md). Global agent guidance is canonical at [agents/.agents/AGENTS.md](../../agents/.agents/AGENTS.md), installed at `~/.agents/AGENTS.md`, imported by Claude Code, and linked into Pi's agent directory. Agent-skill lockfiles record third-party skill sources but restored third-party directories are not committed.
