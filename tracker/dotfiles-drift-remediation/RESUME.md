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

Execution resumed through the active goal continuation. LEGACY-3 resumed the recorded Terra/xhigh session drift-legacy-1, exited 0, and its narrow ownership follow-up was accepted. Source changes are committed; no push has been made.

- Goal milestones: inventory, workspace, handoffs, decisions, privacy, legacy, WezTerm, configuration delivery complete; Stow safety in progress.
- LEGACY committed in 04692b4: fonts.sh/tpm.sh removed, retained Ansible tasks reviewed, narrow proposal/Stow-guide ownership repaired. Four wiki tests, audit, scoped whitespace, execution-baseline range check passed.
- PRV committed in 7b6077c after the ownership gate passed. Sol repeated six privacy tests and the real native Windows sync fixture successfully; Claude JSON and zsh -n passed. Earlier accepted count-only scan and scoped settings review remain recorded in TRACKER.md. Bash is unsuitable for parsing the Zsh pattern syntax; corrected parser passed.
- Full wiki changed-path responsibility check from 48017de to HEAD passes after the PRV documentation commit. The intermediate LEGACY-only range check had correctly required privacy-page updates, now committed.
- WZT-1 exited 0 and was accepted in ed7ef57. Sol repeated platform mocks, native Windows explicit-config WezTerm load, PowerShell parser, twelve Python tests, audit/full range/whitespace successfully. Native Unix WezTerm loads remain unavailable. DOC must correct the pre-existing Ctrl-A leader claim and refresh review dates.
- CFG-1 exited 0 and was accepted in 15508ad. Sol checked byte-identical Starship relocation, package/source boundaries, temporary-target Stow dry-runs, fifteen Python tests, Ansible syntax, Windows parser and wiki audit/full range/whitespace successfully.
- SAFE-1 is next/active: Luna/xhigh session drift-safe-1, exclusive SAFE allowed files. Reconcile PID/exit/final events before retry or acceptance.
- PRV-1/2, LEGACY-1/3 succeeded; LEGACY-2 exit 130 was superseded by the reconciled same-session follow-up. Never restart these accepted packets.
- Next: review SAFE-1 handoff and run actual Ansible temporary-home conflict fixtures, including repeat run, collision, symlink and check-mode cases; verify preservation/idempotency before committing. Then VERIFY, KREW, DOC with shared scopes serialized. CLN-006/007 await Krew's inventory and cleanup phase gate.

## Available verification and limits

Native Windows pwsh.exe 7.6.6 works through WSL interop. Process-only ExecutionPolicy Bypass was needed for the temporary sync fixture; no persistent policy changed. Eight current PowerShell scripts/fixtures parsed without errors. Recheck changed scripts.

Native Windows WezTerm is available through PowerShell, with --config-file/show-keys for read-only explicit config loading. Do not start its GUI or use live user config. nvim supplies isolated embedded Lua for platform mocks; native Lua is absent.

A no-profile native Windows command lookup resolves starship/git/psmux; fzf/zoxide/nvim/eza/bat/glowm do not resolve. Live Windows setup was not run. Final maintainer review must accept outstanding platform-validation limitations; do not label them passes.

## Data handling

Runtime prompts, sessions, event logs, PIDs, exits, and private validation inputs stay under owner-only `drift-agent-runs/` in the Git common directory. Resolve that directory with `git rev-parse --git-common-dir`. Do not publish raw sessions.

PRV reported that a diagnostic emitted autoMode context into its private session and scanned sensitive SSH content. No captured private values are included in tracker artifacts. Treat those sessions as sensitive. Sol's accepted scan excluded every sensitive-boundary path by source-map classification, not just encrypted-file headers. Future scans must never read/hash sensitive-boundary contents.

The original Pi/zsh file hashes have remained unchanged during Sol checks. The original hash record is local-only; do not overwrite unrelated changes if a later user/runtime edit changes it.

## Session context limit

The maintainer requests fresh Sol sessions around 40% context usage. Begin handoff/checkpoint preparation around 35%; checkpoint and pause by approximately 40% instead of letting the session grow further. Preserve task evidence and reconcile delegated agents before the pause. This is a session handoff rule, not a whole-goal token budget or a Pi settings change. Resume the existing goal in a fresh session; do not recreate it or copy this transcript into the new context.

## Dispatch and resume

1. Find the worktree for the branch with `git worktree list`; operate only there.
2. Read repository instructions, this checkpoint, WORK-PACKAGES.md, TRACKER.md, and DECISIONS.md. Inspect status/recent commits against packet evidence.
3. Reconcile local runtime .pid/.exit and final events before starting any agent. Current packet is SAFE-1, session drift-safe-1. CFG-1 and WZT-1 exit 0 are accepted. LEGACY-3 exit 0 was accepted; its predecessor LEGACY-2 exit 130 needs no further retry.
4. Verified models are openai-codex/gpt-6-luna and openai-codex/gpt-5.6-terra; effective effort xhigh. Built-in codemode may batch checks. No substitutions without approval.
5. For fresh packets, the local dispatch.sh records PID/exit and rejects duplicate runs. Existing packet prompts are prepared. Resume follow-ups with the recorded session, not an unverified new attempt.
6. Agents may not stage, commit, edit tracker files, push, or provision hosts. Sol validates scope/results and explicitly stages only accepted files.
7. Checkpoint before dispatch, after every handoff, at blockers, and before context exhaustion. Final integration, maintainer review, and ordinary branch push remain pending.

## Blocker rule

Pause the affected packet, record the blocker and exact next action, and ask the maintainer. Continue only independent approved work. Never infer decisions, overwrite backups, bypass failed verification, or claim skipped checks passed.
