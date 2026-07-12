---
title: Windows synchronization
source_files:
  - sync-win.ps1
  - windows/sync-pi-settings.ps1
  - windows/sync-zed-settings.ps1
  - copy-ssh-from-windows.sh
  - pi/.pi/agent/settings.json
  - zed/.config/zed/settings.json
last_reviewed: 2026-07-12
---
# Windows synchronization

[`sync-win.ps1`](../../sync-win.ps1) copies canonical Pi and Zed settings to Windows-local application locations through the helpers in [windows/](../../windows/). It is intended to be invoked from PowerShell through the repository's WSL UNC path when WSL is canonical.

## Safety boundary

Synchronization is one-way: repository files are canonical and are copied to Windows. Do not add Windows-to-WSL copying without an explicit conflict-resolution policy. Pi and Zed are copied rather than symlinked because the applications write their settings and UNC-backed symlinks are unsuitable.

## Guidance

Use `-SkipPi` or `-SkipZed` to synchronize one application. [`copy-ssh-from-windows.sh`](../../copy-ssh-from-windows.sh) is a separate one-way SSH import helper; it does not replace the Stow-managed SSH configuration.
