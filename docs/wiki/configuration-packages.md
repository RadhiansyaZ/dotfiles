---
title: Configuration packages
source_files:
  - git/.gitconfig
  - zsh/.zshrc
  - tmux/.config/tmux/tmux.conf
  - nvim/.config/nvim/init.lua
  - starship/starship.toml
  - wezterm/.config/wezterm/wezterm.lua
  - agents/.agents/.skill-lock.json
last_reviewed: 2026-07-12
---
# Configuration packages

Configuration directories are repository-managed Stow packages. They include shell, Git, terminal, editor, agent, and application configuration such as [zsh](../../zsh/.zshrc), [tmux](../../tmux/.config/tmux/tmux.conf), [Neovim](../../nvim/.config/nvim/init.lua), and [Starship](../../starship/starship.toml).

## Constraints

The repository is canonical. Application settings that cannot safely use a WSL-backed symlink are governed by [synchronization](synchronization.md), not Stow.

## Guidance

For the detailed cross-platform, difference-first tool inventory, use [machine tooling comparison](machine-tooling.md). Agent-skill lockfiles record third-party skill sources but restored third-party directories are not committed.
