---
title: Unix provisioning
source_files:
  - setup.sh
  - ansible/playbook.yml
  - ansible/tasks/common.yml
  - ansible/tasks/verify.yml
  - ansible/group_vars/all.yml
  - starship/.config/starship.toml
  - herdr/.config/herdr/config.toml
  - wezterm/.config/wezterm/wezterm.lua
  - Brewfile
  - docs/stow-packages.md
last_reviewed: 2026-10-07
---
# Unix provisioning

[`setup.sh`](../../setup.sh) bootstraps Ansible, then executes [ansible/playbook.yml](../../ansible/playbook.yml). macOS uses a repository-local Python environment when Ansible is absent; Debian/Ubuntu uses `apt`. The playbook dispatches macOS, Linux, and shared tasks. It supports Darwin and Debian-family Linux, rejecting other operating systems and Linux families before provisioning, including tagged runs. After setup it probes `zsh`, `stow`, `nvim`, and `pyenv` with `--version`, and `tmux` with `-V`. The non-mutating probes also run in Ansible check mode; one aggregate failure reports missing commands and probe diagnostics. On Linux and WSL, upstream and release installers first check command availability and leave an installed tool at its current version.

## Constraints

Unix provisioning is for macOS and Debian/Ubuntu Linux. Package names may differ on other Linux families. Repository configuration is linked through GNU Stow rather than copied into the repository. Starship, Herdr, and WezTerm are selected Stow packages, delivering their configurations to `~/.config/starship.toml`, `~/.config/herdr/config.toml`, and `~/.config/wezterm/wezterm.lua`. psmux is native-Windows-only and is not deployed in WSL. Configured regular-file conflicts are moved to `<target>.pre-stow` with permissions preserved; an existing backup stops provisioning without changing either file, and symlink conflicts are left for Stow to report. Provisioning uses `--stow` to avoid relinking correct targets, so removed package paths are not pruned automatically. Follow [Stow package rules](../stow-packages.md) for package scope and conflict resolution.

## Fonts and tmux plugins

The shared Ansible tasks install the configured Nerd Fonts into the macOS or Linux user font directory, then refresh the Linux font cache. They also clone TPM into the user tmux plugin directory and attempt TPM plugin installation after starting tmux. Ansible is the only retained provisioning path for these tasks.

## Mermaid Markdown viewer

Setup installs `glowm` through the shared Go-tool task. macOS installs Google Chrome through Homebrew; Debian/Ubuntu and WSL install Chromium through APT. In WezTerm, use `glowm-wezterm <file.md>` for experimental inline Mermaid rendering.

## Verification

Run `./setup.sh` from a normal user account, then use the verification commands in [setup and verification](setup-and-verification.md).
