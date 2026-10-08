---
title: Setup and verification
source_files:
  - README.md
  - setup.sh
  - setup-windows.ps1
  - ansible/playbook.yml
  - ansible/tasks/common.yml
  - ansible/tasks/verify.yml
  - ansible/group_vars/all.yml
  - docs/wiki/machine-tooling.md
last_reviewed: 2026-10-07
---
# Setup and verification

Run [`./setup.sh`](../../setup.sh) as a normal user on macOS, Debian/Ubuntu, or inside WSL. It invokes the [Ansible playbook](../../ansible/playbook.yml). For native Windows, run the PowerShell entry point described in [README.md](../../README.md).

## Verification

The Unix playbook supports Darwin and Debian-family Linux. It rejects other operating systems and non-Debian Linux before provisioning, including tagged runs. Setup dry-runs Stow, then probes `zsh`, `stow`, `nvim`, and `pyenv` with `--version`, and `tmux` with `-V`. These non-mutating probes also run in Ansible check mode; one final failure reports every missing command and each failed probe's diagnostic. Manually check with `command -v zsh stow tmux nvim pyenv`. Native Windows setup reports shell-tool availability; manually use `Get-Command starship, fzf, zoxide, git, nvim, eza, bat, psmux, glowm` from PowerShell. In WezTerm, run `glowm-wezterm <file.md>` against a file containing Mermaid and use `glowm --pdf <file.md>` as the fallback. The cross-platform, difference-first tooling inventory is [machine tooling comparison](machine-tooling.md).

## Stow conflict handling

For configured regular-file conflicts, Ansible preserves the file at `<target>.pre-stow` with its permissions before Stow runs. If that backup already exists, setup stops without changing either file. Symlink conflicts are not removed by this backup path. Stow uses `--stow` to leave existing correct links in place; package paths removed later are not automatically pruned.

## Constraints

Do not run `./setup.sh` with `sudo`. On macOS, Debian/Ubuntu, and WSL, shared tasks provision Krew from its matching latest-release archive after checking for Git and an existing executable installation. The task removes temporary extraction files even when installation fails. Krew requires externally installed `kubectl` v1.12+ for use; setup does not install kubectl or Krew on native Windows. Krew is not part of the final critical-command probes. On Linux and WSL, setup detects commands before invoking upstream or release installers, so existing tools are not upgraded. Use the relevant setup path or targeted Ansible tags after provisioning changes. Third-party agent skills are restored from the tracked lockfile; add a local skill only after explicitly allowlisting it in `agents/.agents/skills/.gitignore`.
