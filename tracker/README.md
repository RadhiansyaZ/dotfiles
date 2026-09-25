# Dotfiles work tracker

This directory contains execution artifacts for repository maintenance work. It records scope, decisions, sequencing, acceptance criteria, and verification without replacing the source-backed wiki.

## Active work

- [Dotfiles drift remediation](dotfiles-drift-remediation/README.md)

## Status vocabulary

- `pending` – not started
- `needs-decision` – requires explicit maintainer direction
- `ready` – requirements and dependencies are settled
- `in-progress` – implementation is underway
- `blocked` – cannot proceed until the recorded blocker is resolved
- `verified` – acceptance criteria and checks passed
- `deferred` – intentionally excluded from the current execution

## Maintenance rule

Update the work tracker in the same change as each implementation phase. Repository behavior and the source-backed wiki remain authoritative. Do not place credentials, private hostnames, usernames, absolute user paths, or other machine-local details in tracker artifacts.
