# dotfiles

Personal dotfiles for macOS, Debian/Ubuntu Linux, WSL (Debian), and native Windows.
Unix-like systems use Ansible and GNU Stow; native Windows uses PowerShell, winget, and
symlinks.

## Quick start

### macOS, Debian/Ubuntu, or WSL

Clone the repository on the target system and run this as your normal user:

```sh
./setup.sh
```

The script installs Ansible when necessary (a local virtual environment on macOS, `apt` on
Debian/Ubuntu) and applies `ansible/playbook.yml`: packages, Stow links, fonts, tmux/TPM,
and Go tooling. On Linux and WSL, a tool already available on `PATH` is left in place without
an installer or version upgrade. Do not run it with `sudo`.

### Native Windows

From an elevated PowerShell in the repository:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
./setup.ps1
```

This ensures WSL2 and Debian are available, then provisions native Windows. It installs the
winget manifest, creates configuration links (including psmux), copies Pi and Zed settings,
and checks the shell tools. Open a new PowerShell session when it completes.

Use `./setup-wsl.ps1` for only the WSL stage, or `./setup-windows.ps1` for only native
Windows. `setup-windows.ps1 -SkipPackages` skips winget on a repeat run but still links,
synchronizes, and verifies configuration.

> To configure the WSL distribution after `setup.ps1`, clone this repository inside WSL and
> run `./setup.sh` there. Native Windows does not support tmux or Ghostty; psmux provides the
> native PowerShell terminal-multiplexer setup.

## Verify and synchronize

- Unix setup dry-runs Stow and probes `zsh`, `stow`, `tmux`, `nvim`, and `pyenv`. To check manually:
  ```sh
  command -v zsh stow tmux nvim pyenv
  ```
- Windows setup reports missing tools. To check manually:
  ```powershell
  Get-Command starship, fzf, psmux
  ```
- After setup, run `psmux`, then press `C-a` followed by `I` to install its configured plugins.
- `sync-win.ps1` refreshes the Windows-local copies of Pi and Zed settings. When the WSL
  repository is canonical, invoke it from PowerShell through its `\\wsl$` path:
  ```powershell
  & "\\wsl$\Debian\home\<user>\dotfiles\sync-win.ps1"
  ```
  Use `-SkipPi` or `-SkipZed` to synchronize only one application.
- To import SSH keys from the Windows profile into WSL, run `./copy-ssh-from-windows.sh`.
  It copies keys and `known_hosts`, leaves `config` to Stow, and is safe to rerun.

## Wiki validation

The source-backed [repository wiki](docs/wiki/README.md) documents operational behavior. After a source change, run:

```sh
python3 scripts/wiki_check.py check --base origin/main --head HEAD
python3 scripts/wiki_check.py audit
git diff --check
```

Update the responsible wiki page when the impact is known. If it needs human resolution, add a public-safe record under `docs/wiki/pending/` instead of guessing.

## Agent skills

The `agents` Stow package installs global agent guidance at `~/.agents/AGENTS.md`, skills
under `~/.agents/skills`, and keeps the skills CLI lockfile at
`~/.local/state/skills/.skill-lock.json`. These are Stow links to the tracked package, so
shared guidance and the dependency list stay consistent across machines. Claude Code imports
the global guidance from `~/.claude/CLAUDE.md`; Pi receives a linked copy at
`~/.pi/agent/AGENTS.md`.

- **Local skills:** add hand-written skills under `agents/.agents/skills/` and allowlist them
  in `agents/.agents/skills/.gitignore` before committing.
- **Third-party skills:** ignored after installation. Their Git source, path, and folder hash
  are recorded in `.skill-lock.json`; restore them on a new machine with the skills CLI using
  that lockfile.
- **Syncing third-party skills:** run `npx skills update --global --yes`, then review and
  commit the resulting lockfile change. Do not commit the restored skill directories.
- **Durability:** vendor a third-party skill when its upstream source might disappear; a
  lockfile cannot restore a deleted or moved repository.

## Repository map

| Path | Purpose |
|---|---|
| `AGENTS.md` | Maintainer and AI-agent guidance |
| `ansible/` | Unix provisioning playbook and tasks |
| `setup.sh` | macOS/Linux/WSL bootstrap |
| `setup.ps1` | Windows wrapper: WSL stage then native Windows stage |
| `setup-wsl.ps1`, `setup-windows.ps1` | Individual Windows setup stages |
| `sync-win.ps1` | Copies canonical Pi and Zed settings to Windows |
| `windows/` | PowerShell profile, package manifest, and Windows sync scripts |
| `agents/` | Global agent guidance, agent-skill Stow package, and tracked lockfile |
| `CHECKPOINT.md` | Current setup-refactor notes and constraints |
| `docs/wiki/` | Source-backed repository wiki and pending-review queue |
| `scripts/wiki_check.py` | Wiki audit and changed-path validator |
