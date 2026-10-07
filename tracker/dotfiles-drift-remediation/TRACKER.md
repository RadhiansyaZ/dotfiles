# Execution tracker

Last updated: `2026-10-07`

Overall status: `running`

Execution baseline: `6be4fdf`; branch: `remediation/dotfiles-drift`.

The original 53-item inventory, single-owner mapping, and agent contracts are in [WORK-PACKAGES.md](WORK-PACKAGES.md). Resume from [RESUME.md](RESUME.md). Implementation is delegated; Sol owns this tracker.

## Decisions

- [x] `DEC-001` – choose current-tree removal or Git history rewrite for machine-local Zed metadata
- [x] `DEC-002` – choose Windows-only or cross-platform WezTerm management
- [x] `DEC-003` – choose Krew PATH-only support or full provisioning
- [x] `DEC-004` – remove or retain the legacy font and TPM scripts
- [x] `DEC-005` – isolate, revert, or separately commit the existing Pi settings change

## Phase 0 – Tracker artifacts

- [x] `TRK-001` Create tracker index
- [x] `TRK-002` Record sanitized audit baseline
- [x] `TRK-003` Record unresolved decisions
- [x] `TRK-004` Define phased implementation and verification gates
- [x] `TRK-005` Add `tracker/**` to wiki source ownership
- [x] `TRK-006` Update maintenance documentation for tracker artifacts
- [x] `TRK-007` Validate and commit Phase 0

## Phase 1 – Privacy and local state

- [x] `PRV-001` Resolve DEC-001
- [x] `PRV-002` Resolve DEC-005
- [x] `PRV-003` Remove machine-local entries from canonical Zed settings
- [x] `PRV-004` Establish a narrow local-state policy
- [x] `PRV-005` Verify one-way Windows synchronization with sanitized settings
- [x] `PRV-006` Apply the approved Git-history treatment
- [x] `PRV-007` Update privacy and synchronization documentation
- [x] `PRV-008` Verify and commit Phase 1

## Phase 2 – WezTerm reconciliation

- [x] `WZT-001` Resolve DEC-002
- [ ] `WZT-002` Remove or restore stale plugin provisioning according to the decision
- [x] `WZT-003` Remove obsolete WezTerm and Zed backup snapshots
- [x] `WZT-004` Add narrow backup ignore rules
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

- [x] `CLN-001` Resolve DEC-003
- [ ] `CLN-002` Implement and document the selected Krew scope
- [x] `CLN-003` Resolve DEC-004
- [x] `CLN-004` Remove or document `fonts.sh`
- [x] `CLN-005` Remove or document `tpm.sh`
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
| 2026-10-06 | Orchestration workspace | Passed | Separate branch/worktree from 6be4fdf; original Pi/zsh edits excluded. |
| 2026-10-06 | Decisions | Approved | DEC-001 through DEC-005 recorded. Krew is Unix-only; kubectl stays external. |
| 2026-10-06 | Delegate capability | Passed | Luna gpt-6-luna and Terra gpt-5.6-terra probes returned READY; persistent sessions record effective xhigh effort. |
| 2026-10-06 | Current-baseline wiki audit | Failed | Existing docs/package_management/ideas.md lacks ownership. Maintainer approved narrow repair in LEGACY; no implementation bypass. |
| 2026-10-07 | PRV handoff review | Passed | Luna PRV-1/2: six Python tests, Windows sync fixture, JSON/shell syntax, scoped field/line review, and whitespace passed. Shared Zed settings preserved. Commit awaits wiki ownership gate. |
| 2026-10-07 | Privacy count-only scan | Passed | Zero private project/home matches; zero endpoint matches outside approved Git routing among non-sensitive tracked/new files. All sensitive-boundary paths excluded by classification. History unchanged. |
| 2026-10-07 | PowerShell parser | Passed | Eight current scripts/fixtures parsed with zero errors via native Windows PowerShell. Recheck after source changes. |
| 2026-10-07 | Native Windows command probe | Partial | No-profile lookup resolves starship, git, psmux; fzf, zoxide, nvim, eza, bat, glowm do not resolve. No live setup was run; platform limitations require final maintainer review. |
| 2026-10-07 | Remaining baseline ownership | Approved repair | Full scan found docs/stow-packages.md unmapped. Maintainer approved narrow ownership repair; deleted legacy script entries will disappear after staging. |
| 2026-10-07 | Maintainer pause | Paused at prior checkpoint | LEGACY-2 stopped with SIGINT, exit 130; uncommitted work preserved. |
| 2026-10-07 | Resumed ownership follow-up | Accepted | LEGACY-3 reuses Terra/xhigh session drift-legacy-1, exited 0; exact two-file follow-up reviewed. Commit 04692b4 removes legacy scripts and repairs narrow ownership; retained Ansible font/TPM tasks inspected. Wiki audit, four wiki tests, scoped whitespace and execution-baseline range check passed. |
| 2026-10-07 | Privacy commit | Passed | Commit 7b6077c contains only accepted PRV scope. Six Python privacy tests, native Windows sync fixture, Claude JSON and zsh -n pass. Bash parser was unsuitable for Zsh syntax; corrected to zsh -n. Wiki audit and full range check 48017de..HEAD pass after privacy documentation commit. CLN-006/007 remain open for Krew's inventory/phase gate. |
| 2026-10-07 | WZT-1 dispatch | Running | Luna/xhigh owns only WZT allowed files; preceding source packets committed and shared writes serialized. |
