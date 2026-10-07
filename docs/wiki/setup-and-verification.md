---
title: Setup and verification
source_files:
  - README.md
  - setup.sh
  - setup-windows.ps1
  - ansible/playbook.yml
  - ansible/tasks/common.yml
  - ansible/group_vars/all.yml
  - docs/wiki/machine-tooling.md
last_reviewed: 2026-08-05
---
# Setup and verification

Run [`./setup.sh`](../../setup.sh) as a normal user on macOS, Debian/Ubuntu, or inside WSL. It invokes the [Ansible playbook](../../ansible/playbook.yml). For native Windows, run the PowerShell entry point described in [README.md](../../README.md).

## Verification

The Unix playbook probes `zsh`, `stow`, `tmux`, and `nvim`; manually run `command -v zsh stow tmux nvim glowm chromium chromium-browser` when needed. Native Windows setup reports shell-tool availability; manually use `Get-Command starship, fzf, psmux, glowm` from PowerShell. In WezTerm, run `glowm-wezterm <file.md>` against a file containing Mermaid and use `glowm --pdf <file.md>` as the fallback. The cross-platform, difference-first tooling inventory is [machine tooling comparison](machine-tooling.md).

## Stow conflict handling

For configured regular-file conflicts, Ansible preserves the file at `<target>.pre-stow` with its permissions before Stow runs. If that backup already exists, setup stops without changing either file. Symlink conflicts are not removed by this backup path. Stow uses `--stow` to leave existing correct links in place; package paths removed later are not automatically pruned.

## Constraints

Do not run `./setup.sh` with `sudo`. On Linux and WSL, setup detects commands before invoking upstream or release installers, so existing tools are not upgraded. Use the relevant setup path or targeted Ansible tags after provisioning changes. Third-party agent skills are restored from the tracked lockfile; add a local skill only after explicitly allowlisting it in `agents/.agents/skills/.gitignore`.
