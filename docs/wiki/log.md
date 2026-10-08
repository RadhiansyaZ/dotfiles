---
title: Wiki log
source_files:
  - docs/wiki/README.md
  - docs/wiki/maintenance.md
last_reviewed: 2026-10-07
---
# Wiki log

This is an append-only, chronological record of significant wiki maintenance. It records documentation events, not configuration behavior; linked repository sources remain authoritative. Use the consistent heading format below so recent entries are easy to locate with `grep "^## \[" log.md | tail -5`.

## [2026-09-25] maintenance | Added execution tracker artifacts

- Added public-safe planning, decision, audit, and progress artifacts for dotfiles drift remediation.
- Classified tracker files as non-authoritative internal maintenance metadata.

## [2026-07-12] maintenance | Integrated machine tooling inventory

- Moved the cross-platform machine-tooling document into the operational wiki.
- Cataloged it as the difference-first inventory for installed, configured-only, and unprovisioned tools.

## [2026-07-12] maintenance | Added index and log

- Added [index.md](index.md) as the content-oriented catalog for the operational wiki.
- Established this log for significant wiki maintenance and validation events.
- Updated the navigation and maintenance guidance to keep both records current.

## [2026-10-07] maintenance | Reconciled drift-remediation documentation

- Reconciled documentation for current-tree privacy cleanup, one-way canonical Windows settings copies, cross-platform WezTerm configuration delivery, Stow conflict handling, Unix-only Krew, critical-command verification, and removed legacy helper scripts.
- Corrected the WezTerm description: the shared configuration does not declare a `Ctrl-A` leader; tmux and psmux use `Ctrl-A` as their prefix.
- Native Windows PowerShell parsing and explicit-config WezTerm loading passed through WSL interop. Native Unix application loading and live provisioning remain unexecuted.
