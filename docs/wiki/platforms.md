---
title: Supported platforms
source_files:
  - README.md
  - setup.sh
  - setup.ps1
  - setup-wsl.ps1
last_reviewed: 2026-07-12
---
# Supported platforms

The repository supports macOS, Debian/Ubuntu Linux, WSL with Debian, and native Windows. [setup.sh](../../setup.sh) provisions Unix-like hosts; [setup.ps1](../../setup.ps1) coordinates WSL availability and native Windows setup.

## Constraints

WSL configuration is performed inside the cloned repository with `./setup.sh`. Native Windows does not provide tmux or Ghostty; use WSL for those tools.

## Guidance

Follow [setup and verification](setup-and-verification.md) for supported entry points rather than inferring a platform workflow from individual configuration files.
