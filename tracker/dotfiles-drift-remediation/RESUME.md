# Orchestration checkpoint

## Contract and workspace

Sol scopes, schedules, reviews, and tracks; Luna/Terra implement source and implementation documentation. Branch: `remediation/dotfiles-drift`, in a separate sibling worktree. Original checkout edits are excluded. Verified scoped commits and a final ordinary branch push are authorized. No history rewrite, force push, live provisioning, or PR creation is authorized.

Execution baseline: `6be4fdf323ccc00501a85c9b8b50a49a2a3f7d6d`.
Audit baseline: `48017de`. Goal: `muwu0kr2-j5uvhp`.
Coordination baseline commit: `5d754f4`.

## Approved decisions

DEC-001: current-tree privacy removal only; history remains.
DEC-002: cross-platform WezTerm; remove unused plugins.
DEC-003: idempotent Krew on macOS, Debian/Ubuntu, WSL only; kubectl external; no native Windows Krew.
DEC-004: remove fonts.sh/tpm.sh, retain Ansible equivalents.
DEC-005: preserve and exclude original Pi/zsh edits through worktree isolation.

Follow-ups: narrow ownership repair for docs/package_management/ideas.md and docs/stow-packages.md; narrow portable home-path cleanup in Claude settings/zsh; retain intentional shared Git routing. See DECISIONS.md.

## Current state

Current history is rebased onto main `b35203c` by the maintainer's separate linear-history direction. The prior replay below is superseded for ancestry, not content: before coordination updates, the full tree remained identical to pre-rebase `a05cecf`. Main is an ancestor, the branch range contains no merges and prospective main merge is conflict-free. All 34 tests and syntax/wiki/full-range/whitespace checks passed again. Historical commit IDs in the earlier evidence retain their original meaning; current equivalents are:

| Packet | Historical accepted commit | Rebased commit |
| --- | --- | --- |
| LEGACY | 04692b4 | fcf1857 |
| PRV | 7b6077c | 589eb56 |
| WZT | ed7ef57 | cf5e4d9 |
| CFG | 15508ad | 66e0610 |
| SAFE | 5bff941 | 1e42b2b |
| VERIFY | 8d1e2f6 | 0207142 |
| KREW | 8e30227 | 09bd0da |
| DOC | eb4b8b1 | d6df445 |

The main skill-provisioning commit retained on this branch is `a4b3143`. Safety ref: `backup/remediation-before-linear-rebase-a05cecf`. Push only remediation with explicit lease against `a05cecfd36b01c24021b57dddccf08aeed8f46c8`, then verify final remote equality, main ancestry and clean worktree. No agent work remains pending.

All implementation and DOC packets are accepted. DOC-2 exited 0 in the same verified Terra/xhigh session `drift-doc-1`; the eight-file documentation scope is committed in `eb4b8b1`. No agent is active. FIN-001 through FIN-009 available checks are complete with explicit platform limitations. FIN-010 maintainer acceptance is recorded: “Accept and push”, including all stated platform limitations. Ordinary push succeeded; remote equality was verified at `aa847bc4322fedc2c68303768e0a38cc20655b8d`. This coordination-only receipt is pushed normally and final equality checked before goal completion.

- Goal milestones: inventory, workspace, handoffs, decisions, privacy, legacy, WezTerm, configuration delivery, Stow safety, setup verification, Krew and DOC complete; FIN-010 is accepted and the ordinary branch push succeeded.
- LEGACY committed in 04692b4: fonts.sh/tpm.sh removed, retained Ansible tasks reviewed, narrow proposal/Stow-guide ownership repaired. Four wiki tests, audit, scoped whitespace, execution-baseline range check passed.
- PRV committed in 7b6077c after the ownership gate passed. Sol repeated six privacy tests and the real native Windows sync fixture successfully; Claude JSON and zsh -n passed. Earlier accepted count-only scan and scoped settings review remain recorded in TRACKER.md. Bash is unsuitable for parsing the Zsh pattern syntax; corrected parser passed.
- Full wiki changed-path responsibility check from 48017de to HEAD passes after the PRV documentation commit. The intermediate LEGACY-only range check had correctly required privacy-page updates, now committed.
- WZT-1 exited 0 and was accepted in ed7ef57. Sol repeated platform mocks, native Windows explicit-config WezTerm load, PowerShell parser, twelve Python tests, audit/full range/whitespace successfully. Native Unix WezTerm loads remain unavailable. DOC corrected the pre-existing Ctrl-A leader claim and reconciled review dates.
- CFG-1 exited 0 and was accepted in 15508ad. Sol checked byte-identical Starship relocation, package/source boundaries, temporary-target Stow dry-runs, fifteen Python tests, Ansible syntax, Windows parser and wiki audit/full range/whitespace successfully.
- SAFE-1 was interrupted by Sol, exit 130, for fixture isolation corrections before acceptance. The real WSL facts reached an unrelated SSH-copy task against sensitive-boundary material; temporary test homes cleaned, no boundary contents printed. Partial fixtures failed check-mode/recap assertions; change reporting mistakenly uses stdout although Stow LINK output is stderr.
- SAFE-2 exited 0 and was accepted in 5bff941. Corrected synthetic facts/package source prevent boundary access. Five independent real-Ansible tests, syntax, four wiki tests, audit/full range/whitespace passed. --stow avoids actual link churn but does not prune removed package paths; trade-off documented.
- VERIFY-1 exited 0 in Luna/xhigh session drift-verify-1, but was unaccepted after Sol found `tmux --version` invalid and argument-insensitive mocks.
- VERIFY-2 resumed the same Luna/xhigh session and exited 0. It replaces that unaccepted handoff: `tmux` uses `-V`; other commands retain `--version`; mocks reject incorrect flags; seven controlled real-Ansible tests cover platform/tag rejection, all-present, aggregation, nonzero diagnostics, correct tmux flag, and check-mode probes. Sol repeated all seven tests, Ansible syntax, four wiki tests, staged wiki audit/full range, and whitespace successfully.
- Latest accepted implementation commit: 8e30227 (KREW); latest accepted documentation commit: eb4b8b1 (DOC). No implementation agent may edit tracker files or stage source.
- PRV-1/2, LEGACY-1/3 succeeded; LEGACY-2 exit 130 was superseded by the reconciled same-session follow-up. Never restart these accepted packets.
- KREW-1 accepted in `8e30227`: Sol repeated seven real-task local-archive tests and independently checked executable-symlink installation detection, then syntax, four wiki tests, audit, staged full-range responsibility, whitespace and post-commit full range. No live provisioning ran. CLN-002/006/007 closed with Krew and LEGACY evidence.
- Sol integration so far: 34 Python tests passed; syntax for Ansible/all three Bash scripts/Zsh passed; temporary-target combined Stow dry-runs passed for 16 native packages and 15 WSL packages. Native Windows sync fixture, eight-script parser and explicit-config WezTerm load passed. Count-only privacy scan: 114 non-boundary tracked files, six boundary exclusions, zero unapproved matches; added-content secret-pattern flags zero. After DOC, all 34 tests, syntax, wiki audit/full-range/whitespace and the count-only scans passed again. All 53 initial items have exactly one inventory owner. ShellCheck, native Lua/Unix WezTerm and live provisioning remain unavailable/unexecuted.
- Completion receipt: ordinary push to existing `origin` succeeded and the remote matched local commit `aa847bc4322fedc2c68303768e0a38cc20655b8d`; worktree was clean. This final receipt changes coordination records only. No implementation, agent handoff, decision or maintainer review remains pending. On resume, compare final HEAD to the remote branch and inspect worktree cleanliness; never restart accepted packets.

## Post-completion main replay

The maintainer separately authorized replaying latest main onto remediation and selected only the remediation branch as the push target, with force-with-lease protection. Main `e905769` had three commits not present in remediation; they were replayed onto `41dea2b` as `7da5a8d`, `89b7d40`, and `75cbd23`. Conflicts were limited to wiki references/ownership and preserve both sides. All 34 tests, syntax/wiki/full-range/whitespace, combined temporary-target Stow and removed-value scan pass. Main's committed Pi/Zsh changes are now included by explicit request; original checkout and uncommitted state remain untouched. Local safety ref: `backup/remediation-before-main-replay-41dea2b`. The replay preserves all existing published remediation commits, so its update is a fast-forward with an explicit lease despite authorization to force. Verify final remote HEAD and clean worktree after the lease-protected branch-only push.

## Available verification and limits

Native Windows pwsh.exe 7.6.6 works through WSL interop. Process-only ExecutionPolicy Bypass was needed for the temporary sync fixture; no persistent policy changed. Eight current PowerShell scripts/fixtures parsed without errors. Recheck changed scripts.

Native Windows WezTerm is available through PowerShell, with --config-file/show-keys for read-only explicit config loading. Do not start its GUI or use live user config. nvim supplies isolated embedded Lua for platform mocks; native Lua is absent.

A no-profile native Windows command lookup resolves starship/git/psmux; fzf/zoxide/nvim/eza/bat/glowm do not resolve. Live Windows setup was not run. FIN-010 explicitly accepts these platform-validation limitations; do not label them passes.

## Data handling

Runtime prompts, sessions, event logs, PIDs, exits, and private validation inputs stay under owner-only `drift-agent-runs/` in the Git common directory. Resolve that directory with `git rev-parse --git-common-dir`. Do not publish raw sessions.

PRV reported that a diagnostic emitted autoMode context into its private session and scanned sensitive SSH content. No captured private values are included in tracker artifacts. Treat those sessions as sensitive. Sol's accepted scan excluded every sensitive-boundary path by source-map classification, not just encrypted-file headers. Future scans and fixtures must never read/hash/copy sensitive-boundary contents. SAFE-1's imported WSL SSH-copy task exposed a fixture isolation gap; SAFE-2 must use controlled non-WSL facts and synthetic source packages.

The original Pi/zsh file hashes have remained unchanged during Sol checks. The original hash record is local-only; do not overwrite unrelated changes if a later user/runtime edit changes it.

## Session context limit

The maintainer requests fresh Sol sessions around 40% context usage. Begin handoff/checkpoint preparation around 35%; checkpoint and pause by approximately 40% instead of letting the session grow further. Preserve task evidence and reconcile delegated agents before the pause. This is a session handoff rule, not a whole-goal token budget or a Pi settings change. Resume the existing goal in a fresh session; do not recreate it or copy this transcript into the new context.

## Dispatch and resume

1. Find the worktree for the branch with `git worktree list`; operate only there.
2. Read repository instructions, this checkpoint, WORK-PACKAGES.md, TRACKER.md, and DECISIONS.md. Inspect status/recent commits against packet evidence.
3. Reconcile local runtime .pid/.exit and final events before starting any agent. DOC-1/2 both exited 0 and are accepted; no agent is active. Do not redispatch completed packets. VERIFY-1 is superseded by accepted VERIFY-2, so do not resume it. KREW-1 is accepted. SAFE-2 exit 0 is accepted; SAFE-1 exit 130 was superseded. CFG-1 and WZT-1 exit 0 are accepted. LEGACY-3 exit 0 was accepted; its predecessor LEGACY-2 exit 130 needs no further retry.
4. Verified models are openai-codex/gpt-6-luna and openai-codex/gpt-5.6-terra; effective effort xhigh. Built-in codemode may batch checks. No substitutions without approval.
5. For fresh packets, the local dispatch.sh records PID/exit and rejects duplicate runs. All dispatched packets are reconciled and accepted; retained local prompts are historical. Resume follow-ups with the recorded session, not an unverified new attempt.
6. Agents may not stage, commit, edit tracker files, push, or provision hosts. Sol validates scope/results and explicitly stages only accepted files.
7. Checkpoint before dispatch, after every handoff, at blockers, and before context exhaustion. Final integration and maintainer review are accepted; the ordinary branch push receipt is recorded.

## Blocker rule

Pause the affected packet, record the blocker and exact next action, and ask the maintainer. Continue only independent approved work. Never infer decisions, overwrite backups, bypass failed verification, or claim skipped checks passed.
