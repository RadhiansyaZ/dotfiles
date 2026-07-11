# Agent Guide

## 1. Goal and motivations

This repository makes personal dotfiles reproducible across macOS, Debian/Ubuntu Linux, WSL (Debian), and native Windows. Unix-like hosts are provisioned with Ansible and GNU Stow; native Windows uses PowerShell, winget, symlinks, and copy-based sync for application settings that cannot safely be symlinked from WSL.

Preserve that separation: repository files are canonical; Pi and Zed settings are copied to Windows through `sync-win.ps1`; do not introduce Windows-to-WSL copying without an explicit conflict-resolution policy. Do not commit credentials or machine-local state.

## 2. Setup and verification

- **macOS / Debian / Ubuntu:** from a normal user account, run `./setup.sh`. It bootstraps Ansible (a repository-local virtual environment on macOS; `apt` on Debian/Ubuntu) and runs `ansible/playbook.yml`. Do not run it with `sudo`.
- **WSL:** from elevated Windows PowerShell, run `Set-ExecutionPolicy -Scope Process Bypass -Force; ./setup.ps1` to ensure WSL2 and Debian exist, then clone/open this repository inside the distro and run `./setup.sh` there. Use `./setup-wsl.ps1` when only the WSL stage is required.
- **Native Windows:** from elevated PowerShell, run `Set-ExecutionPolicy -Scope Process Bypass -Force; ./setup.ps1`; it runs the WSL and Windows stages. For only native provisioning, run `./setup-windows.ps1`; use `-SkipPackages` only when winget installation is intentionally skipped. Open a new PowerShell session afterward.
- **Verification:** the Unix playbook dry-runs Stow and probes `zsh`, `stow`, `tmux`, and `nvim`; rerun it after changes. On Windows, `setup-windows.ps1` reports whether `starship`, `fzf`, `zoxide`, `git`, `nvim`, `eza`, and `bat` resolve. Manually check with `Get-Command starship, fzf` or `command -v zsh stow tmux nvim` as applicable. Before committing, run the relevant setup path or targeted Ansible tags and `git diff --check`.

## 3. Documentation index

- `README.md` — user-facing bootstrap, Windows sync, skills, and layout reference.
- `CHECKPOINT.md` — current setup-refactor checkpoint and follow-up constraints.
- `ansible/playbook.yml` and `ansible/tasks/` — provisioner behavior and tags.
- `setup.sh`, `setup.ps1`, `setup-wsl.ps1`, `setup-windows.ps1`, and `sync-win.ps1` — executable setup and synchronization contracts.
- `docs/` — detailed documentation, including `docs/machine-tooling.md` for cross-platform package and tooling inventory.

## 4. AI-agent documentation housekeeping

Keep this file a short routing guide with only these four sections. Put new or expanded documentation in `docs/`, use descriptive kebab-case names, and add each document to the index above. When setup behavior, supported platforms, sync direction, or verification changes, update the relevant user-facing documentation in the same change and validate all referenced paths and commands. Do not record secrets, private hostnames, user-specific paths, generated output, or transient investigation notes in tracked documentation.
