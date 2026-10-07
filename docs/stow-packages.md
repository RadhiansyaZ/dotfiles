# Stow packages

On macOS and Linux (including WSL), GNU Stow is the only way repository files are linked into the home directory. Each top-level package directory (for example `zsh/`, `claude/`, `pi/`) mirrors paths relative to `$HOME`. Packages are listed in `stow_packages` in `ansible/group_vars/all.yml`.

The repository stows with `--no-folding` (`stow_common_args`). Stow creates real directories and links individual files, so an application that writes new files into a stowed directory writes them on the host, not into the repository. Do not remove `--no-folding` or create directory-level symlinks.

## Resolve conflicts before stowing

Never stow over an existing target. Dry-run a package from the repository root and inspect conflicts before resolving them:

```sh
stow -nv --no-folding --target="$HOME" --dir="$PWD" --restow <package>
```

For each conflict, inspect the target with `ls -l <target>` and compare it with `diff -u <target> <package>/<path>`. Resolve by case:

| Target state | Action |
| --- | --- |
| Regular file listed in `stow_conflict_files` | Provisioning moves it to `<target>.pre-stow` before stowing, preserving its permissions. If that backup path already exists, provisioning stops before Stow runs and leaves both files intact. Inspect and resolve the collision manually. |
| Other regular file | Merge wanted changes into the repository copy, excluding secrets and machine-local values. Then move the target aside or ask the user. |
| Symlink to somewhere outside this repository | Find what owns it before removing it. The regular-file backup task does not remove symlinks; Stow may report the conflict. |
| Directory where the package has a file, or the reverse | Stop and ask the user. |

Re-run the dry run until it reports no conflicts, then stow. Do not use `stow --adopt`; it overwrites the repository copy with the host file.

Some applications recreate settings as regular files (Pi and Claude Code, for example). Their configured conflict paths are backed up as `<target>.pre-stow`; a later run refuses to overwrite an existing backup, so resolve or rename that backup before provisioning again.

Provisioning uses `stow --stow` rather than `--restow` so already-correct links are not unlinked and recreated on every run. Consequently, it does not automatically remove links for paths later removed from a package. Review those changes with a `--restow` dry run and use a deliberate cleanup when needed.

## Choose the package scope

Because of `--no-folding`, the choice is which files the package tracks: the whole application directory, or specific files inside it.

Track the whole directory only when all of these hold:

- Every file in it is hand-maintained configuration wanted on all machines.
- The application does not write credentials, tokens, sessions, history, caches, logs, or downloaded plugins into it.
- No file holds secrets or machine-specific values.

Examples: `nvim/.config/nvim/`, `tmux/.config/tmux/`.

Track specific files when the directory mixes configuration with application state or machine-local files. List only the shared configuration files in the package and leave everything else on the host.

Examples:

- `claude/.claude/` tracks `settings.json`, `statusline-command.sh`, `CLAUDE.md`, and `agents/`. `settings.local.json`, credentials, sessions, and caches stay machine-local.
- `pi/.pi/agent/` tracks `settings.json`, `mcp.json`, and `AGENTS.md`. `auth.json`, sessions, and package directories stay machine-local.

Before deciding, run the application once and list its directory (`ls -la <app-dir>`) to see what it writes there. When in doubt, track specific files.

## Verify the link survives application writes

Some applications save settings by writing a new file and renaming it over the old one, which replaces the symlink with a regular file. After stowing a settings file, change a setting in the application, then check:

```sh
test -L <target> && echo linked || echo "replaced by a regular file"
```

If the link is replaced, Stow cannot manage that file. Stop and ask the user how to handle it, for example a copy-based sync like the Windows contract in `sync-win.ps1`.
