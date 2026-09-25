# Dotfiles drift remediation

Status: `planning`

Baseline commit: `48017de`

Created: `2026-09-25`

## Objective

Resolve confirmed configuration, provisioning, privacy, documentation, and repository-hygiene drift while preserving the repository’s platform boundaries:

- Unix-like hosts use Ansible and GNU Stow.
- Native Windows uses PowerShell, Winget, links, and allowlisted one-way copies.
- Repository files remain canonical.
- Credentials and machine-local state remain outside the repository.

## Artifacts

- [AUDIT.md](AUDIT.md) – sanitized evidence baseline and scope
- [DECISIONS.md](DECISIONS.md) – choices requiring maintainer approval
- [PLAN.md](PLAN.md) – phased implementation and verification plan
- [TRACKER.md](TRACKER.md) – executable work-item checklist

## Execution rule

Do not begin a phase marked `needs-decision`. Keep unrelated local changes, including runtime-written settings changes, outside remediation commits unless explicitly approved.
