# dotfiles

Collection of my personal dotfiles for any GDT-related work.

Supported environments: **macOS**, **Debian/Ubuntu Linux**, **WSL (Debian)**, and
**native Windows**. See [PLAN.md](./PLAN.md) for the cross-platform architecture and
[TODO.md](./TODO.md) for delivery status.

## Bootstrap

### macOS / Linux / WSL
```sh
./setup.sh
```
Installs Ansible (Homebrew-free, via venv on macOS / apt on Debian) and runs the playbook:
packages, GNU Stow symlinks, Nerd Fonts, tmux/TPM, Go tooling.

### Native Windows
Run from an **elevated** PowerShell (Run as Administrator):
```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
./setup.ps1
```
`setup.ps1` is a thin bootstrap. It prepares the machine (Developer Mode, WSL2 + Debian,
OpenSSH Server, SSH key auth, firewall, host-address detection) and then hands provisioning
to **Ansible running inside WSL**, which configures both the Linux side and the native
Windows side (winget packages, config symlinks, PowerShell profile, fonts).

> Native Windows uses **winget** for packages and a native **PowerShell profile**
> (`windows/powershell/Microsoft.PowerShell_profile.ps1`) mirroring `zsh/.zshrc`.
> tmux and Ghostty have no native Windows support — use Windows Terminal + WSL for those.

### Windows symlinks (standalone, no Ansible)

After WSL and dotfiles are set up, run this from a normal PowerShell with Developer Mode
enabled (or from an elevated shell) to wire up Windows config files:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\windows\setup-windows.ps1
```

This installs winget packages and creates symlinks from `%USERPROFILE%` into the WSL
dotfiles repo via `\\wsl$\<distro>`. Pass `-SkipPackages` to skip winget on re-runs.
Pass `-Distro Ubuntu` if your distro isn't Debian.

### SSH key import (WSL)

To bring SSH keys from the Windows user profile into WSL:

```sh
./copy-ssh-from-windows.sh
```

Auto-detects your Windows username, copies `id_*`, `*.pub`, and `known_hosts` (skips
`config` — that comes from the stow package), and sets correct permissions. Safe to re-run.

## Layout

| Path | Purpose |
|---|---|
| `setup.sh` | macOS/Linux/WSL bootstrap → Ansible |
| `setup.ps1` | Native Windows bootstrap → WSL → Ansible |
| `windows/setup-windows.ps1` | Standalone Windows symlinks + winget (no Ansible) |
| `copy-ssh-from-windows.sh` | WSL utility: import SSH keys from Windows profile |
| `ansible/` | Provisioning playbook (macOS, Linux, and — added — Windows plays) |
| `windows/powershell/` | Native PowerShell profile |
| `windows/packages/` | winget package manifest (`winget import`) |
| `starship/` | Shared starship prompt config (all platforms) |
| `zsh/ git/ nvim/ tmux/ …` | GNU Stow packages (Unix side) |
