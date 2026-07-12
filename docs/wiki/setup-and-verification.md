---
title: Setup and verification
source_files:
  - README.md
  - setup.sh
  - setup-windows.ps1
  - ansible/playbook.yml
  - docs/machine-tooling.md
last_reviewed: 2026-07-12
---
# Setup and verification

Run [`./setup.sh`](../../setup.sh) as a normal user on macOS, Debian/Ubuntu, or inside WSL. It invokes the [Ansible playbook](../../ansible/playbook.yml). For native Windows, run the PowerShell entry point described in [README.md](../../README.md).

## Verification

The Unix playbook probes `zsh`, `stow`, `tmux`, and `nvim`; manually run `command -v zsh stow tmux nvim` when needed. Native Windows setup reports shell-tool availability; manually use `Get-Command starship, fzf` from PowerShell. The cross-platform tooling inventory is [machine-tooling.md](../machine-tooling.md).

## Constraints

Do not run `./setup.sh` with `sudo`. Use the relevant setup path or targeted Ansible tags after provisioning changes.
