# Orchestration checkpoint

## Contract

Sol coordinates, scopes, reviews, and tracks. Luna/Terra implement source changes and implementation documentation. Work is on branch `remediation/dotfiles-drift` in a separate sibling worktree. The original checkout is excluded from all edits and staging. Verified local commits and a final ordinary push of the completed branch are authorized. No history rewrite, force push, or live provisioning is authorized.

Execution baseline: `6be4fdf323ccc00501a85c9b8b50a49a2a3f7d6d`.
Original audit baseline: `48017de`.
Goal ID: `muwu0kr2-j5uvhp`.

## Maintainer decisions

- DEC-001: current-tree removal only. Historical metadata remains; no rewrite.
- DEC-002: cross-platform WezTerm management; remove unused plugin provisioning.
- DEC-003: full, idempotent Krew provisioning on macOS, Debian/Ubuntu, and WSL only. Native Windows is excluded; kubectl remains external.
- DEC-004: remove `fonts.sh` and `tpm.sh`; retain Ansible provisioning.
- DEC-005: leave the pre-existing Pi edit outside remediation using worktree isolation. Also exclude the pre-existing zsh edit. Never copy, revert, or stage either original-checkout edit.

## Current state

- Separate worktree and branch created from the execution baseline.
- Luna and Terra are available through the authenticated `openai-codex` provider.
- Model/effort probes passed: openai-codex/gpt-6-luna and openai-codex/gpt-5.6-terra both record effective xhigh in persisted sessions.
- All 53 original open entries are mapped in WORK-PACKAGES.md. Maintainer decisions are approved.
- Implementation has not started.
- Next: verify/commit coordination records, then dispatch PRV with Luna/xhigh.
- Active dispatch: none; both probes exited successfully.

## Local runtime records

Sessions, raw event logs, prompts, private validation inputs, and PID/exit records belong under `drift-agent-runs/` in the Git common directory, never in tracked files. Resolve that directory with `git rev-parse --git-common-dir`. Those records may contain sensitive context. Do not publish them.

## Resume procedure

1. Find the worktree for `remediation/dotfiles-drift` with `git worktree list`. Work only there.
2. Read this file, `WORK-PACKAGES.md`, `TRACKER.md`, `DECISIONS.md`, and repository instructions.
3. Inspect `git status --short` and recent commits. Compare evidence against actual source; do not duplicate accepted work.
4. Inspect local runtime PID/exit records and last events before starting an agent. A running process must be reconciled before a replacement dispatch.
5. Resume the next approved packet with its recorded Luna/Terra identity and effective thinking effort. Agents may not edit tracker records, commit, push, or provision the live host.
6. Review the complete diff and rerun the packet checks. Sol updates coordination records and creates scoped commits only after acceptance.
7. Record unavailable platform checks explicitly. Final maintainer review is required before goal completion and the authorized branch push.

## Blocker rule

Pause the affected packet, record the blocker and exact next action, and ask the maintainer. Continue only independent approved work. Model/effort substitutions, new dependency choices, destructive treatment, and historical rewrites must not be inferred.
