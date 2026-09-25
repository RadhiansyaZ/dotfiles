# Execution tracker

Last updated: `2026-09-25`

Overall status: `planning`

## Decisions

- [ ] `DEC-001` – choose current-tree removal or Git history rewrite for machine-local Zed metadata
- [ ] `DEC-002` – choose Windows-only or cross-platform WezTerm management
- [ ] `DEC-003` – choose Krew PATH-only support or full provisioning
- [ ] `DEC-004` – remove or retain the legacy font and TPM scripts
- [ ] `DEC-005` – isolate, revert, or separately commit the existing Pi settings change

## Phase 0 – Tracker artifacts

- [x] `TRK-001` Create tracker index
- [x] `TRK-002` Record sanitized audit baseline
- [x] `TRK-003` Record unresolved decisions
- [x] `TRK-004` Define phased implementation and verification gates
- [x] `TRK-005` Add `tracker/**` to wiki source ownership
- [x] `TRK-006` Update maintenance documentation for tracker artifacts
- [x] `TRK-007` Validate and commit Phase 0

## Phase 1 – Privacy and local state

- [ ] `PRV-001` Resolve DEC-001
- [ ] `PRV-002` Resolve DEC-005
- [ ] `PRV-003` Remove machine-local entries from canonical Zed settings
- [ ] `PRV-004` Establish a narrow local-state policy
- [ ] `PRV-005` Verify one-way Windows synchronization with sanitized settings
- [ ] `PRV-006` Apply the approved Git-history treatment
- [ ] `PRV-007` Update privacy and synchronization documentation
- [ ] `PRV-008` Verify and commit Phase 1

## Phase 2 – WezTerm reconciliation

- [ ] `WZT-001` Resolve DEC-002
- [ ] `WZT-002` Remove or restore stale plugin provisioning according to the decision
- [ ] `WZT-003` Remove obsolete WezTerm and Zed backup snapshots
- [ ] `WZT-004` Add narrow backup ignore rules
- [ ] `WZT-005` Align WezTerm comments and platform behavior
- [ ] `WZT-006` Update Windows, configuration-package, and tooling documentation
- [ ] `WZT-007` Run available PowerShell and WezTerm checks
- [ ] `WZT-008` Verify and commit Phase 2

## Phase 3 – Unix configuration delivery

- [ ] `CFG-001` Move Starship configuration into its Stow target layout
- [ ] `CFG-002` Update the Windows Starship source path
- [ ] `CFG-003` Add Starship to Unix Stow deployment
- [ ] `CFG-004` Add Herdr to Unix Stow deployment
- [ ] `CFG-005` Apply the chosen WezTerm deployment model
- [ ] `CFG-006` Confirm psmux remains Windows-only
- [ ] `CFG-007` Run package-specific Stow dry-runs
- [ ] `CFG-008` Verify and commit Phase 3

## Phase 4 – Setup safety and verification

- [ ] `SET-001` Back up plain-file Stow conflicts before replacement
- [ ] `SET-002` Verify conflict handling is idempotent
- [ ] `SET-003` Reject unsupported Linux families in the playbook
- [ ] `SET-004` Aggregate and fail missing critical-command verification
- [ ] `SET-005` Add focused regression tests or fixtures
- [ ] `SET-006` Update setup and verification documentation
- [ ] `SET-007` Verify and commit Phase 4

## Phase 5 – Krew and legacy scripts

- [ ] `CLN-001` Resolve DEC-003
- [ ] `CLN-002` Implement and document the selected Krew scope
- [ ] `CLN-003` Resolve DEC-004
- [ ] `CLN-004` Remove or document `fonts.sh`
- [ ] `CLN-005` Remove or document `tpm.sh`
- [ ] `CLN-006` Update wiki ownership and tooling inventory
- [ ] `CLN-007` Verify and commit Phase 5

## Phase 6 – Integration

- [ ] `FIN-001` Run Ansible syntax validation
- [ ] `FIN-002` Run wiki unit tests
- [ ] `FIN-003` Run wiki audit and changed-path validation
- [ ] `FIN-004` Run Bash syntax and ShellCheck when available
- [ ] `FIN-005` Run PowerShell parser and Windows setup checks when available
- [ ] `FIN-006` Run Stow dry-runs for all Unix packages
- [ ] `FIN-007` Run `git diff --check`
- [ ] `FIN-008` Review tracked content for sensitive or machine-local data
- [ ] `FIN-009` Update the wiki log and tracker evidence
- [ ] `FIN-010` Complete final maintainer review

## Evidence log

| Date | Item | Result | Evidence |
| --- | --- | --- | --- |
| 2026-09-25 | Baseline Ansible syntax | Passed | Playbook parsed successfully. |
| 2026-09-25 | Baseline wiki audit | Passed | Structural audit reported no errors. |
| 2026-09-25 | Baseline wiki tests | Passed | Four tests passed. |
| 2026-09-25 | Latest-commit wiki responsibility check | Failed as expected | Krew PATH change requires a configuration-package documentation update. |
| 2026-09-25 | ShellCheck | Skipped | Tool unavailable. |
| 2026-09-25 | PowerShell parser | Skipped | Tool unavailable. |
