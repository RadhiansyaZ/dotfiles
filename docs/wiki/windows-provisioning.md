---
title: Windows provisioning
source_files:
  - setup.ps1
  - setup-wsl.ps1
  - setup-windows.ps1
  - windows/packages/packages.winget.json
  - windows/powershell/Microsoft.PowerShell_profile.ps1
last_reviewed: 2026-08-05
---
# Windows provisioning

[`setup.ps1`](../../setup.ps1) is the elevated Windows entry point. It ensures the WSL stage and runs [`setup-windows.ps1`](../../setup-windows.ps1) for native packages, configuration links, copy-based settings synchronization, and command checks. The Windows package manifest is [packages.winget.json](../../windows/packages/packages.winget.json). Setup installs psmux, links its [configuration](../../psmux/.psmux.conf) to `%USERPROFILE%\.psmux.conf`, and bootstraps PPM (the psmux plugin manager). Start `psmux`, then press `C-a` followed by `I` to install the configured plugins.

The manifest installs Google Chrome and setup installs `glowm` through the provisioned Go toolchain. In WezTerm, use `glowm-wezterm <file.md>` for the experimental inline-Mermaid path; the PowerShell wrapper scopes its iTerm2 terminal-detection override to that command.

## Guidance

Use `setup-wsl.ps1` only for the WSL stage and `setup-windows.ps1` only for native provisioning. Use `-SkipPackages` only when deliberately skipping winget installation on a repeat run.

## Verification

Open a new PowerShell session after setup, then follow [setup and verification](setup-and-verification.md).
