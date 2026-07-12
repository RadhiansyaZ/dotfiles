# Checkpoint

## Windows / WSL setup

- `setup.ps1` is the elevated wrapper: it ensures WSL, then invokes `setup-windows.ps1`.
- `setup-windows.ps1` exclusively provisions native Windows. The retired Ansible Windows play,
  Windows host variables, and Windows-only Ansible collections were removed.
- `sync-win.ps1` is the only copy-sync entry point. It is called by `setup-windows.ps1` and by
  the PowerShell-profile `Sync-WindowsSettings`, `Sync-ZedSettings`, and `Sync-PiSettings`
  helpers.
- The repository is canonical. The active direction is repository/WSL → local Windows.

## Copy-managed configuration

Only application settings that cannot safely use a UNC-backed symlink are copied:

- `zed/.config/zed/settings.json` → `%APPDATA%\Zed\settings.json`
- `pi/.pi/agent/settings.json` → `%USERPROFILE%\.pi\agent\settings.json`
- `pi/.pi/agent/mcp.json` → `%USERPROFILE%\.pi\agent\mcp.json`

The scripts use content hashes to avoid redundant writes, back up an existing Windows file once,
and replace old symlinks with real files. Pi credentials, sessions, runtime/package directories,
and binaries remain machine-local and must never be synchronized into the repository.

## Reverse-sync policy (not implemented)

Do not run a Windows → WSL copy from setup or normal sync commands. If an explicit manual pull is
added, limit it to the three allowlisted files above and keep it out of `setup.ps1`,
`setup-windows.ps1`, and `sync-win.ps1`.

Use a persistent last-synced hash per file for three-way conflict detection:

1. If Windows matches the baseline, do nothing.
2. If the repository matches the baseline and Windows changed, copy the Windows file into the
   repository working tree for `git diff` review; never auto-commit.
3. If both sides changed from the baseline, stop without writing and require manual resolution.

Validate JSON before any import. Treat each file as atomic initially; do not silently merge JSON
objects or arrays.

## Verification

- `ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --syntax-check`
- `git diff --check`
