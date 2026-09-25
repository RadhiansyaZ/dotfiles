# Audit baseline

## Repository state

- Branch: `main`
- Baseline commit: `48017de`
- Existing unrelated working-tree change: `pi/.pi/agent/settings.json`
- The unrelated change must not be modified, reverted, staged, or included without explicit approval.

## Confirmed findings

| ID | Priority | Area | Finding | Evidence | Proposed outcome |
| --- | --- | --- | --- | --- | --- |
| DRIFT-001 | High | Privacy | Shared Zed settings contain machine-local connection and project metadata. | `zed/.config/zed/settings.json:10-33` | Remove machine-local entries from the canonical file and establish a local-state policy. |
| DRIFT-002 | High | Windows | Windows setup clones WezTerm plugins that the active configuration no longer loads. | `setup-windows.ps1:253-300`; `wezterm/.config/wezterm/wezterm.lua` | Remove stale provisioning and its documentation, unless plugin restoration is explicitly chosen. |
| DRIFT-003 | High | Unix configuration | Starship configuration is not delivered to its normal Unix location. | `starship/starship.toml`; `ansible/group_vars/all.yml:8-21`; `zsh/.zshrc:154` | Move the file into the Stow package layout and add the package to Unix deployment. |
| DRIFT-004 | High | Cross-platform configuration | Herdr and WezTerm are documented as repository-managed configuration but are absent from Unix Stow deployment. The active WezTerm config also assumes a WSL domain. | `ansible/group_vars/all.yml:8-21`; `docs/wiki/configuration-packages.md:17`; `wezterm/.config/wezterm/wezterm.lua` | Align deployment and documentation after deciding WezTerm’s supported platforms. |
| DRIFT-005 | High | Data safety | Unix setup deletes plain-file Stow conflicts without preserving them. | `ansible/tasks/common.yml:42-58` | Create one-time backups before replacement and preserve idempotency. |
| DRIFT-006 | Medium | Documentation | The latest Krew PATH change lacks its required wiki update and does not provision Krew. | `zsh/.zshrc:128-129`; `docs/wiki/_meta/source-map.yml:36` | Choose PATH-only support or full provisioning, then update implementation and docs. |
| DRIFT-007 | Medium | Verification | Unix command verification suppresses all failures. | `ansible/playbook.yml` verification task | Report every missing command and fail setup once when critical tools are absent. |
| DRIFT-008 | Medium | Platform boundary | Direct playbook execution warns on unsupported Linux families but proceeds into Debian-oriented tasks. | `ansible/playbook.yml` pre-tasks | Reject unsupported Linux families consistently with `setup.sh`. |
| DRIFT-009 | Cleanup | Repository hygiene | Obsolete backup snapshots are tracked. | `wezterm/.config/wezterm/wezterm.lua.bak`; `zed/.config/zed/settings_backup.json` | Delete obsolete snapshots and add narrow ignore rules. |
| DRIFT-010 | Cleanup | Legacy setup | Standalone font and TPM scripts duplicate Ansible behavior and have no documented invocation. | `fonts.sh`; `tpm.sh`; `ansible/tasks/common.yml` | Remove them and update wiki ownership, or explicitly document their recovery role. |
| DRIFT-011 | Maintenance | Wiki enforcement | Checking `origin/main..HEAD` cannot detect documentation omitted by the already-pushed latest commit. A direct previous-commit check fails as designed. | `python3 scripts/wiki_check.py check --base HEAD~1 --head HEAD` | Repair the missing documentation and retain range-based checks for future changes. |

## Validation baseline

| Check | Result |
| --- | --- |
| `ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --syntax-check` | Passed |
| `python3 scripts/wiki_check.py audit` | Passed |
| `python3 -m unittest -v tests/test_wiki_check.py` | Four tests passed |
| Bash syntax checks for tracked shell entry points | Passed |
| `git diff --check` | Passed |
| Tracked symlink target inspection | Passed |
| ShellCheck | Not available |
| PowerShell parser | Not available |
| GitHub Actions run inspection | Not available because GitHub CLI authentication is absent |

## Audit constraints

- This artifact intentionally omits private values found during the audit.
- JSON-with-comments files used by Zed are not required to pass a strict JSON parser.
- No implementation file was changed while producing this baseline.
