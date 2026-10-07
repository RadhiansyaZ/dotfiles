# Agent work packages

Execution baseline: `6be4fdf`. Audit baseline: `48017de`. Implementation runs in the `remediation/dotfiles-drift` worktree, serially for overlapping file scopes. PRV-2 and LEGACY may overlap because their allowed write scopes are disjoint. Sol owns this directory and task state. This inventory contains the 53 entries unchecked at orchestration start; later completion does not remove them from the inventory.

## Open-item inventory and single ownership

| Owner | IDs and initial open work | Dependencies |
| --- | --- | --- |
| Sol – decisions | DEC-001 history treatment; DEC-002 WezTerm platforms; DEC-003 Krew scope; DEC-004 legacy scripts; DEC-005 existing Pi edit | Maintainer approval, now recorded in DECISIONS.md |
| Sol – privacy gates | PRV-001 resolve DEC-001; PRV-002 resolve DEC-005; PRV-006 approved history treatment; PRV-008 review/verify/commit privacy | PRV packet; PRV-006 records current-tree-only treatment without rewriting history |
| PRV | PRV-003 sanitize Zed; PRV-004 local-state policy; PRV-005 one-way sync verification; PRV-007 privacy/sync docs; WZT-003 delete both obsolete snapshots; WZT-004 narrow backup ignores | DEC-001 and DEC-005 |
| Sol – WezTerm gates | WZT-001 resolve DEC-002; WZT-008 review/verify/commit WezTerm | WZT packet; cross-platform deployment exits after CFG |
| WZT | WZT-002 remove stale plugins; WZT-005 platform-aware config/comments; WZT-006 Windows/config/tooling docs; WZT-007 configuration/parser checks | DEC-002; PRV |
| CFG | CFG-001 Starship layout; CFG-002 Windows source; CFG-003 Starship Stow; CFG-004 Herdr Stow; CFG-005 WezTerm Stow; CFG-006 psmux Windows boundary; CFG-007 package dry-runs | WZT; DEC-002 |
| Sol – delivery gate | CFG-008 review/verify/commit delivery | CFG |
| SAFE | SET-001 preserve conflicts; SET-002 idempotency | CFG |
| VERIFY | SET-003 reject unsupported Linux; SET-004 aggregate critical failures; SET-005 focused safety/verification fixtures; SET-006 setup/verification docs | SAFE; fixtures for SET-001/002 are delivered by SAFE and accepted under this gate |
| Sol – setup gate | SET-007 review/verify/commit setup | SAFE and VERIFY |
| Sol – cleanup decisions/gate | CLN-001 resolve DEC-003; CLN-003 resolve DEC-004; CLN-007 review/verify/commit cleanup | KREW and LEGACY |
| KREW | CLN-002 install/document Krew | DEC-003; VERIFY |
| LEGACY | CLN-004 remove fonts.sh; CLN-005 remove tpm.sh; CLN-006 ownership and tooling documentation | DEC-004; original PRV handoff; tooling edits from KREW contribute later evidence to CLN-006 |
| Sol – integration | FIN-001 Ansible syntax; FIN-002 wiki tests; FIN-003 wiki audit/range check; FIN-004 shell checks; FIN-005 PowerShell/Windows checks; FIN-006 all Unix Stow dry-runs; FIN-007 whitespace; FIN-008 sanitized privacy review; FIN-009 wiki log/tracker evidence; FIN-010 maintainer review | All packets; DOC contributes authored log/docs to FIN-009 |

Phase 0 was committed in `42b888a` and remains complete. PLAN.md's old in-progress status is stale. Later repository changes require rechecking line references and findings; do not implement from old line numbers alone.

## Shared agent contract

- Read AGENTS.md, relevant local source, this packet, DECISIONS.md, and the responsible wiki pages before edits.
- Make the smallest change meeting the packet. No unrelated formatting, refactors, credentials, generated logs, or machine-local settings.
- Only edit the packet's allowed files. If a necessary edit falls outside them, stop and report it to Sol for explicit rescoping. Read access is allowed elsewhere, respecting sensitive boundaries.
- Never modify tracker files or the original checkout. Do not commit, stage, push, switch branches, dispatch other agents, or run live setup/installers.
- Use fixtures with temporary HOME/destination paths; no network or host mutations in regression tests. Do not print removed private values, private hostnames, or project paths in reports.
- Source-related documentation belongs in the same reviewed change. Inspect source-map responsibilities and update relevant frontmatter/links.
- Report changed files, completed acceptance criteria, exact commands and exit results, skipped checks with reason, and remaining risks/blockers. Use public-safe summaries. Raw logs and sessions stay in the Git common directory's local runtime records.
- Model identity and effective thinking effort must be recorded in the session. Verified probes: `openai-codex/gpt-6-luna` and `openai-codex/gpt-5.6-terra` both support effective `xhigh` (highest effort selected here). No model substitution without maintainer approval.

## Serial schedule and current state

| Packet | Model / effort | State | Predecessor |
| --- | --- | --- | --- |
| PRV | Luna / xhigh | accepted; committed 7b6077c | Approved DEC-001/005 |
| WZT | Luna / xhigh | accepted; committed ed7ef57 | LEGACY |
| CFG | Luna / xhigh | accepted; committed 15508ad | WZT |
| SAFE | Luna / xhigh | accepted; committed 5bff941 | CFG |
| VERIFY | Luna / xhigh | unaccepted; VERIFY-2 correction prepared, paused | SAFE |
| KREW | Luna / xhigh | pending | VERIFY; approved Unix-only scope |
| LEGACY | Terra / xhigh | accepted; committed 04692b4 | Original PRV handoff; disjoint PRV-2 may continue |
| DOC | Terra / xhigh | pending | All source packets |

LEGACY is scheduled immediately after PRV to repair the approved baseline wiki ownership gap before remaining source gates. KREW follows VERIFY; CLN-006 accepts KREW tooling evidence later.

Concurrent exception: PRV-2 owns Claude/zsh home-path corrections, privacy tests, and privacy/synchronization/configuration-package wiki pages. LEGACY owns fonts.sh/tpm.sh deletions, source-map ownership, and Unix/tooling/maintenance wiki pages. Their allowed write scopes do not overlap; neither agent may stage or commit. Sol reconciles both handoffs before shared-file work.

Serialize remaining writes: setup-windows.ps1, ansible files, .gitignore, and wiki pages have overlapping packet scopes. Sol reviews/checkpoints each handoff before the next dispatch. Each packet receives its own persistent session and event/exit records, named by packet and attempt. Retries reuse a recorded session or explicitly identify the abandoned attempt.

## PRV – Canonical editor privacy and backup hygiene

Outcome: canonical Zed settings and obsolete snapshots contain no known machine-local connection/project data; synchronization remains repository-to-Windows only.

Allowed files:
- zed/.config/zed/settings.json
- claude/.claude/settings.json and zsh/.zshrc (only matching machine-specific home-path literals, explicitly approved after the scan)
- Delete only zed/.config/zed/settings_backup.json and wezterm/.config/wezterm/wezterm.lua.bak
- .gitignore (narrow backup/local-state patterns only)
- tests/test_zed_privacy.py and tests/test_windows_sync.ps1 (new focused fixtures)
- docs/wiki/privacy-and-sensitive-boundaries.md, docs/wiki/synchronization.md, docs/wiki/configuration-packages.md

Exclusions: no sync script behavior changes unless a fixture exposes a task-related bug and Sol rescopes; no Git history treatment; no broad application-directory ignore; no project-local settings design assuming Zed supports an undocumented user override.

Acceptance:
- Remove machine-local connection/project entries while preserving shared settings and JSON-with-comments formatting.
- Document that connections/project history are local state, excluded from canonical copies. Do not promise automatic preservation of Windows-local edits across the existing overwrite-style sync.
- Delete both named snapshots and add exact/narrow equivalent ignore patterns.
- Capture removed values privately for an in-memory or local-only count-based scan of current tracked files, excluding intentionally encrypted boundary content. Never publish values or fixtures containing them.
- Maintainer-approved follow-up: replace matching machine-specific home-path literals in canonical Claude settings and zsh with supported portable equivalents. Preserve hook/alias behavior, validate configuration and shell syntax, and test path handling in isolated fixtures. Retain the matching shared Git URL-rewrite rule by explicit approval; supported-platform names and that intentional Git routing reference are exemptions from raw-string scan failures. Do not alter Git behavior or print its host.
- Tests verify absence of forbidden machine-local fields and preserve valid shared settings. Use appropriate JSONC validation, not strict JSON without comment/trailing-comma handling.
- PowerShell fixture exercises sync-zed-settings.ps1 with temporary source/destination: forward copy, source unchanged, repeat stability, first backup preservation; exercise the root wrapper with mocked child sync helpers to prove its allowlist/direction where feasible.

Verification: `python3 -m unittest -v tests/test_zed_privacy.py`; `pwsh -NoProfile -File tests/test_windows_sync.ps1` when available; sanitized tracked-value scan; wiki audit; `git diff --check`. If pwsh is unavailable, keep the runnable fixture and report it unexecuted; textual inspection is not a runtime pass.

## WZT – Cross-platform terminal configuration and stale provisioning

Outcome: Unix uses native local domains; Windows retains the existing WSL Debian default. Setup no longer clones unused WezTerm plugins.

Allowed files:
- wezterm/.config/wezterm/wezterm.lua
- setup-windows.ps1 (remove only the obsolete WezTerm plugin section/helpers)
- tests/test_wezterm_config.py, tests/fixtures/wezterm-config.lua (new focused tests if useful)
- docs/wiki/windows-provisioning.md, docs/wiki/configuration-packages.md, docs/wiki/machine-tooling.md

Exclusions: no Starship source move, Unix package list edits, psmux/PPM changes, keybinding redesign, plugin restoration, or installing WezTerm itself.

Acceptance: condition the WSL default on an actual Windows target triple; Unix leaves the native default intact. Correct the root setup-windows.ps1 source comment. Preserve existing unrelated keyboard/font/key/startup settings. Remove plugin escape/clone helpers and clone invocations only when exclusive to unused plugins. Document cross-platform managed configuration and configuration-only installation boundaries. Unix Stow activation is CFG's dependency.

Verification: focused Windows/macOS/Linux mocked configuration evaluation when a Lua interpreter is available, plus source contract checks; WezTerm application load where available; PowerShell parser when available; search for stale resurrect/dev plugin references in active source/docs; wiki audit; whitespace check. Record missing tools separately.

## CFG – Deliver the selected Unix configuration packages

Outcome: Starship, Herdr, and WezTerm use their expected home-relative Stow targets; Windows points at the relocated canonical Starship file.

Allowed files:
- Move starship/starship.toml to starship/.config/starship.toml without changing content
- ansible/group_vars/all.yml (only selected stow_packages additions)
- setup-windows.ps1 (only Starship source path)
- tests/test_config_delivery.py (new focused target-path fixture)
- docs/wiki/configuration-packages.md, docs/wiki/unix-provisioning.md, docs/wiki/machine-tooling.md, docs/wiki/windows-provisioning.md

Exclusions: no psmux Unix deployment; no installer/package expansion; no ad hoc Unix links.

Acceptance: add starship/herdr/wezterm to Unix packages, preserve WSL SSH special handling, fix links/frontmatter referencing the old Starship path, and clearly document native-Windows-only psmux. Dry-run packages into a temporary target rather than the real HOME. Windows-source contract fixture resolves the real relocated file.

Verification: `python3 -m unittest -v tests/test_config_delivery.py`; individual `stow --no-folding --target=<temporary-home> --dir=<worktree> -nv --restow <package>` for starship/herdr/wezterm; Ansible syntax; PowerShell parser when available; wiki audit; whitespace check.

## SAFE – Preserve Stow conflicts

Outcome: approved regular-file conflicts are moved aside once before replacement; existing backups survive and repeat runs are safe.

Allowed files:
- ansible/tasks/common.yml (conflict-handling/Stow idempotent execution and change reporting only)
- ansible/group_vars/all.yml (conflict comments only, not configuration policy changes)
- tests/test_stow_safety.py and tests/fixtures/stow-safety.yml
- docs/stow-packages.md, docs/wiki/unix-provisioning.md, docs/wiki/setup-and-verification.md

Exclusions: no directory-level links, stow --adopt, blanket cleanup, destructive overwrite of backups, or edits to actual HOME.

Acceptance: preserve regular files with a narrow documented backup naming convention; preserve backup permissions; handle an existing backup by failing safely rather than deleting either file or overwriting it. Existing symlinks must not be removed by this regular-file path. Include fixture cases for a second run, collision, symlink exclusion, and check-mode safety. Stow links remain created only by GNU Stow. Second fixture run must not claim repeat backup/link changes.

Verification: real focused Ansible fixture against temporary files, run twice; `python3 -m unittest -v tests/test_stow_safety.py`; Ansible syntax; wiki audit; whitespace check. Avoid simulating implementation with a separate Python copy of its logic.

## VERIFY – Reject unsupported platforms and fail truthful verification

Outcome: direct playbook execution rejects unsupported Linux before Debian tasks, reports every missing critical command, and fails once after aggregation.

Allowed files:
- ansible/playbook.yml
- ansible/tasks/verify.yml (new extraction only if needed for real fixture testing)
- tests/test_setup_verification.py, tests/fixtures/setup-verification.yml
- README.md (verification guidance only), AGENTS.md (verification guidance only; keep its four-section structure), CHECKPOINT.md (changed setup constraints only)
- docs/wiki/setup-and-verification.md, docs/wiki/unix-provisioning.md, docs/wiki/machine-tooling.md, docs/wiki/maintenance.md

Exclusions: no package changes or unrelated suppressed failures (for example TPM installation), no critical-command list expansion unless necessary and explicitly reported.

Acceptance: reject non-Debian Linux early, including relevant tagged runs; retain Darwin and Debian-family support. Preserve the existing critical list zsh/stow/tmux/nvim/pyenv. Evaluate every command with stable non-changing probes, then aggregate failure. All-present case succeeds. Nonzero probes and missing executables must not be treated as successful. Public docs list the actual verified commands and rejection behavior.

Verification: `python3 -m unittest -v tests/test_setup_verification.py`, exercising real Ansible tasks with controlled facts/executables; Ansible syntax; wiki unit tests/audit; whitespace. Adopt SAFE evidence under SET-005/006; do not rewrite its fixtures.

## KREW – Full Unix Krew provisioning

Outcome: macOS, Debian/Ubuntu, and WSL can install Krew replayably. Native Windows and kubectl provisioning are excluded by explicit maintainer follow-up approval.

Allowed files:
- ansible/tasks/krew.yml (new focused task file)
- ansible/tasks/common.yml (one tagged include at the appropriate point)
- ansible/tasks/arch.yml or ansible/group_vars/all.yml only if existing mappings cannot represent official assets
- zsh/.zshrc (Krew comment/PATH only, if necessary; never copy the original-checkout edit)
- tests/test_krew_provisioning.py, tests/fixtures/krew-provisioning.yml
- docs/wiki/unix-provisioning.md, docs/wiki/setup-and-verification.md, docs/wiki/machine-tooling.md, docs/wiki/configuration-packages.md

Upstream reference checked during scoping: https://krew.sigs.k8s.io/docs/user-guide/setup/install/ . Official Unix flow requires git, downloads the matching krew OS/architecture release archive, runs the extracted binary's `install krew`, and exposes `${KREW_ROOT:-$HOME/.krew}/bin`. Upstream requires kubectl v1.12+ for use; kubectl remains external. OS-package-manager installation is not actively supported upstream.

Exclusions: no native Windows support, kubectl installation, plugin inventory, live downloads/install runs for verification, new version-management system, or repository-file symlinks outside Stow. Krew's own local plugin symlinks are upstream application state, not repository configuration.

Acceptance: use the repository's detect-before-install/no-unrequested-upgrade convention; official matching Darwin/Linux assets for supported host architectures; honor KREW_ROOT consistently with the shell. Verify git prerequisite before install, clean up temporary extraction state on success/failure, and avoid changing an already installed Krew. Unsupported architecture must fail clearly before download. Do not claim provisioning kubectl or a full Kubernetes workstation. If installer version/checksum choices require expanding scope, report before changing policy.

Verification: `python3 -m unittest -v tests/test_krew_provisioning.py` exercising actual tasks with local archives/mock installer executables and temporary HOME/KREW_ROOT; test repeat run, asset mapping, prerequisites, unsupported architecture and cleanup/failure paths. Ansible syntax, shell syntax if touched, wiki audit and changed-path validation. No network in tests.

## LEGACY – Remove duplicate standalone scripts

Outcome: fonts.sh and tpm.sh are removed; their retained Ansible equivalents and documentation remain accurate. Repair the separately approved baseline ownership gap for docs/package_management/ideas.md without changing that proposal's content.

Allowed files:
- Delete fonts.sh and tpm.sh only
- docs/wiki/_meta/source-map.yml (remove the two deleted-path rules and add narrow ownership for existing docs/package_management/ideas.md and docs/stow-packages.md, as separately approved)
- docs/wiki/unix-provisioning.md, docs/wiki/machine-tooling.md, docs/wiki/maintenance.md
- README.md or CHECKPOINT.md only if they reference the removed scripts

Exclusions: no Ansible font/TPM behavior changes or broad source-map restructuring.

Verification: inspect retained tasks, search for obsolete source paths/references, `python3 scripts/wiki_check.py audit`, wiki changed-path responsibility validation, and whitespace check. Deleted scripts may be described historically without dead links/frontmatter ownership.

## DOC – Final documentation and maintenance log handoff

Outcome: changed behavior is accurately documented and the wiki log records significant remediation without implementation claims exceeding evidence.

Allowed files: README.md, AGENTS.md, CHECKPOINT.md, docs/stow-packages.md, responsible docs/wiki/*.md pages and the existing wiki log. No source, tests, source-map redesign, or tracker edits.

Acceptance: reconcile only behavior changed by accepted packets; validate file paths and commands; distinguish configuration deployment from binary installation, native Windows from WSL, Krew from external kubectl, current-tree privacy from untouched history, and unavailable live-platform checks from fixture passes. Keep AGENTS.md a short four-section router. Public artifacts contain no machine-specific paths or values.

Verification: wiki tests/audit/range check; referenced-path review; whitespace. Sol subsequently runs the full integration matrix, records evidence, requests FIN-010 acceptance, commits only accepted changes, and pushes the completed branch normally.

## Evidence and completion rules

Sol records commit IDs and packet acceptance in TRACKER.md and checkpoints RESUME.md before each dispatch, after every handoff, and at blockers/context limits. Packet completion requires actual commands/results and diff review; a model's completion statement alone is insufficient. Unavailable PowerShell, WezTerm, native Windows/macOS or ShellCheck checks are outstanding limitations requiring final maintainer acceptance. Never mark a skipped runtime check as passed.
