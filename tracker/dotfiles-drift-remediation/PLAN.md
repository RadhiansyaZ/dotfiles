# Execution plan

## Success criteria

The remediation is complete when:

- Canonical files contain no known machine-local connection or project metadata.
- Windows setup does not install unused WezTerm dependencies.
- Every documented configuration package has an accurate delivery mechanism.
- Starship uses its expected Unix configuration path.
- Existing user files are preserved before Stow replaces them.
- Unsupported platforms and missing critical commands produce clear setup failures.
- Obsolete backup artifacts and resolved duplicate scripts are removed.
- The source-backed wiki matches implementation behavior.
- Relevant syntax, unit, wiki, and platform checks pass.

## Phase 0 – Establish tracked execution artifacts

Status: `in-progress`

Work:

1. Add this tracker artifact set.
2. Add `tracker/**` to the wiki source map before the artifacts are committed.
3. Update the appropriate maintenance page to explain the tracker’s non-authoritative role.
4. Run wiki audit and changed-path validation.

Verification:

```sh
python3 scripts/wiki_check.py audit
python3 scripts/wiki_check.py check --base origin/main --head HEAD
git diff --check
```

Exit gate: artifacts are reviewable, public-safe, and accepted as the execution baseline.

## Phase 1 – Remove machine-local state

Status: `needs-decision`

Depends on: DEC-001, DEC-005

Work:

1. Remove machine-local connection and project entries from canonical Zed settings.
2. Add the narrowest practical local-state or ignore policy without hiding shared settings.
3. Confirm `sync-win.ps1` continues to copy only the sanitized canonical file.
4. Handle historical copies according to DEC-001.
5. Keep the existing Pi settings change separate according to DEC-005.

Verification:

- Search tracked files for the removed values without printing them.
- Run the Zed configuration parser or application validation where available.
- Run synchronization in a non-destructive test fixture or with mocked destinations.
- Run `git diff --check`.

Exit gate: current tracked content is public-safe and Windows synchronization remains one-way.

## Phase 2 – Reconcile WezTerm provisioning

Status: `needs-decision`

Depends on: DEC-002

Work common to either decision:

1. Remove obsolete tracked WezTerm and Zed backup snapshots.
2. Add narrow ignore rules for equivalent backup artifacts.
3. Remove stale WezTerm plugin provisioning unless plugin usage is restored.
4. Update Windows and machine-tooling documentation.

Windows-only branch:

- Keep the Windows symlink.
- Correct Unix Stow claims and inaccurate source comments.

Cross-platform branch:

- Make the WezTerm domain conditional by platform.
- Add WezTerm to Unix Stow deployment.
- Validate target paths and application startup on each supported platform.

Verification:

- PowerShell parser check.
- WezTerm configuration load check where the binary is available.
- Search for stale plugin references.
- Wiki check and audit.

Exit gate: setup, active config, and documentation describe one consistent WezTerm model.

## Phase 3 – Repair Unix configuration delivery

Status: `ready` after Phase 2’s WezTerm decision

Work:

1. Move Starship configuration to the Stow path for `~/.config/starship.toml`.
2. Update native Windows’s source path for the moved Starship file.
3. Add `starship` and `herdr` to Unix Stow packages.
4. Add WezTerm only if DEC-002 selects cross-platform management.
5. Confirm psmux remains a native-Windows-only link.
6. Run Stow dry-runs before applying links.

Verification:

```sh
stow --no-folding --target="$HOME" --dir="$PWD" -nv --restow starship
stow --no-folding --target="$HOME" --dir="$PWD" -nv --restow herdr
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --syntax-check
```

Also verify the Windows Starship link source with the PowerShell parser or a fixture-based test.

Exit gate: every selected package maps to the documented destination on its supported platforms.

## Phase 4 – Make setup safe and truthful

Status: `ready`

Work:

1. Replace destructive plain-file conflict removal with one-time backup behavior.
2. Preserve idempotency and avoid repeatedly overwriting backups.
3. Reject non-Debian Linux in the playbook before Debian-specific tasks run.
4. Replace suppressed verification failures with aggregated reporting followed by one failure.
5. Add focused tests where logic can be exercised without provisioning a host.

Verification:

- Ansible syntax check.
- Ansible check-mode or fixture validation for conflict backup behavior.
- Confirm a second run reports no backup or link changes.
- Confirm a simulated missing critical command fails after listing all missing commands.
- Confirm a non-Debian fact fixture is rejected.

Exit gate: setup preserves prior files, remains replayable, and cannot report false success.

## Phase 5 – Resolve Krew and legacy-script drift

Status: `needs-decision`

Depends on: DEC-003, DEC-004

Work:

1. Implement the selected Krew scope.
2. Update configuration and machine-tooling documentation.
3. Remove or formally document `fonts.sh` and `tpm.sh`.
4. Update wiki source ownership for removed or retained paths.
5. Repair the documentation obligation missed by baseline commit `48017de`.

Verification:

```sh
python3 scripts/wiki_check.py check --base HEAD~1 --head HEAD
python3 scripts/wiki_check.py audit
```

Run shell syntax and ShellCheck when available for any retained or changed shell scripts.

Exit gate: Krew behavior and legacy entry points are explicit and reproducible.

## Phase 6 – Final integration verification

Status: `pending`

Work:

1. Update README, AGENTS, CHECKPOINT, and responsible wiki pages only where behavior changed.
2. Append a significant maintenance entry to the wiki log.
3. Update every tracker item with final status and evidence.
4. Review the full diff for unrelated or sensitive content.

Required checks:

```sh
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --syntax-check
python3 -m unittest -v tests/test_wiki_check.py
python3 scripts/wiki_check.py audit
python3 scripts/wiki_check.py check --base origin/main --head HEAD
git diff --check
```

Platform checks when available:

```powershell
./setup-windows.ps1 -SkipPackages
Get-Command starship, fzf, zoxide, git, nvim, eza, bat, psmux, glowm
```

```sh
command -v zsh stow tmux nvim pyenv starship
```

Exit gate: all applicable checks pass, skipped platform checks are explicitly recorded, and the final diff contains only approved work.

## Commit strategy

Prefer one reviewable commit per phase:

1. `docs(tracker): add drift remediation artifacts`
2. `fix(privacy): remove machine-local editor state`
3. `fix(windows): reconcile wezterm provisioning`
4. `fix(config): repair unix configuration delivery`
5. `fix(setup): preserve conflicts and enforce verification`
6. `chore: resolve krew and legacy setup drift`
7. `docs: finalize drift remediation records`

Do not combine the pre-existing Pi settings change with these commits unless DEC-005 explicitly approves it.
