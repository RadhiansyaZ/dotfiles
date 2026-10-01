# Stow packages

On macOS and Linux (including WSL), GNU Stow is the only way repository files are linked into the home directory. Each top-level package directory (for example `zsh/`, `claude/`, `pi/`) mirrors paths relative to `$HOME`. Packages are listed in `stow_packages` in `ansible/group_vars/all.yml`.

The repository stows with `--no-folding` (`stow_common_args`). Stow creates real directories and links individual files, so an application that writes new files into a stowed directory writes them on the host, not into the repository. Do not remove `--no-folding` or create directory-level symlinks.

## Resolve conflicts before stowing

Never stow over an existing target. Resolve every conflict first:

1. Dry-run the package from the repository root:

   ```sh
   stow -nv --no-folding --target="$HOME" --dir="$PWD" --restow <package>
   ```

2. For each reported conflict, inspect the target with `ls -l <target>` and compare it with `diff -u <target> <package>/<path>`. Then resolve by case:

   | Target state | Action |
   | --- | --- |
   | Regular file, identical to the repository copy | Remove the target. |
   | Regular file, different from the repository copy | Merge any wanted changes into the repository copy, excluding secrets and machine-local values. Then remove the target. If unsure, move it aside (`mv <target> <target>.pre-stow`) and ask the user. |
   | Symlink to somewhere outside this repository | Find what owns it (another tool or an old dotfiles setup) before removing it. |
   | Directory where the package has a file, or the reverse | Stop and ask the user. |

3. Re-run the dry run until it reports no conflicts, then stow.

Do not use `stow --adopt`. It overwrites the repository copy with the host file.

Some applications recreate their settings file as a regular file on first run (Pi and Claude Code do this). For those, add the target path to `stow_conflict_files` in `ansible/group_vars/all.yml` so provisioning removes it before stowing. That task deletes the file without a backup, so add a path only after the repository copy is authoritative and the host copy holds nothing worth keeping.

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
