---
title: Unix provisioning
source_files:
  - setup.sh
  - ansible/playbook.yml
  - Brewfile
  - fonts.sh
  - tpm.sh
last_reviewed: 2026-07-12
---
# Unix provisioning

[`setup.sh`](../../setup.sh) bootstraps Ansible, then executes [ansible/playbook.yml](../../ansible/playbook.yml). macOS uses a repository-local Python environment when Ansible is absent; Debian/Ubuntu uses `apt`. The playbook dispatches macOS, Linux, and shared tasks and verifies core commands. On Linux and WSL, upstream and release installers first check command availability and leave an installed tool at its current version.

## Constraints

Unix provisioning is for macOS and Debian/Ubuntu Linux. Package names may differ on other Linux families. Repository configuration is linked through GNU Stow rather than copied into the repository.

## Verification

Run `./setup.sh` from a normal user account, then use the verification commands in [setup and verification](setup-and-verification.md).
