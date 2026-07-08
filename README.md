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

### Windows setup (standalone, no Ansible)

Once WSL and the dotfiles repo are in place, run this to install all winget packages and
wire up the Windows config files. Run it from **any** PowerShell — it self-elevates via UAC:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\windows\setup-windows.ps1
```

Approve the UAC prompt. An elevated window opens and stays open so you can read the output.
The script:

1. **Installs winget packages** from `windows/packages/packages.winget.json`. Elevation is
   required because some packages are machine-scoped MSIs (e.g. `Starship.Starship`).
2. **Refreshes the session PATH** from the registry, so tools installed this run — both MSI
   (`C:\Program Files\…`, Machine PATH) and portable (`…\WinGet\Links`, User PATH) — are
   immediately resolvable without opening a new shell.
3. **Symlinks Windows config** from `%USERPROFILE%` into the WSL dotfiles repo via
   `\\wsl$\<distro>` — including the PowerShell 7 profile (`Documents\PowerShell\`), which is
   what loads starship, zoxide, and the aliases. Without it, the prompt stays bare.
4. **Verifies** that the key shell tools (`starship`, `fzf`, `zoxide`, `git`, `nvim`, `eza`,
   `bat`) resolve, and warns about any that don't.

Then open a **new** PowerShell 7 window — starship renders with the host/OS prompt and fzf
key bindings (Ctrl+T / Ctrl+R) are active.

**Flags:** `-SkipPackages` skips the winget step on re-runs (symlinks + verify still run).
`-Distro Ubuntu` if your distro isn't Debian.

**Verify manually:**
```powershell
Get-Command starship, fzf
```

### SSH key import (WSL)

To bring SSH keys from the Windows user profile into WSL:

```sh
./copy-ssh-from-windows.sh
```

Auto-detects your Windows username, copies `id_*`, `*.pub`, and `known_hosts` (skips
`config` — that comes from the stow package), and sets correct permissions. Safe to re-run.

## Claude Code skills

Skills live in the `agents` stow package under `agents/.agents/skills/`. Only
**local/hand-written** skills are committed (the `gitnexus-*` set). Third-party
skills pulled from GitHub are **not** tracked — `agents/.agents/skills/.gitignore`
ignores every skill folder and re-includes only `gitnexus-*/`.

The GitHub-sourced skills are restored on demand by the skills CLI from the
repo-tracked lockfile `agents/.agents/.skill-lock.json`, which records each
skill's `sourceUrl` and folder hash. The lockfile is symlinked to
`~/.local/state/skills/.skill-lock.json` (via stow) so one lock stays in sync
across machines. To restore third-party skills on a new machine, run the skills
CLI install/sync against that lockfile.

Adding a new local skill: name it so it is tracked (e.g. drop it under a tracked
prefix, or extend the `!` allowlist in `agents/.agents/skills/.gitignore`).

> Caveat: a GitHub-only skill is unrecoverable if its upstream repo is deleted or
> moved. Vendor (commit) the folder if the source is fragile.

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
