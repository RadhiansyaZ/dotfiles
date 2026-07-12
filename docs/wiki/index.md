---
title: Wiki index
source_files:
  - docs/wiki/README.md
  - docs/wiki/_meta/source-map.yml
last_reviewed: 2026-07-12
---
# Wiki index

This content-oriented catalog is the starting point for navigating the operational wiki. Repository files remain authoritative; entries summarize the role of each maintained page rather than replacing its source-backed claims.

## Core model

- [Architecture](architecture.md) — authority boundaries, deterministic validation, and the role of the wiki artifacts.
- [Platforms](platforms.md) — supported operating systems and the division between Unix-like hosts, WSL, and native Windows.
- [Setup and verification](setup-and-verification.md) — supported bootstrap paths and validation commands.

## Provisioning and configuration

- [Unix provisioning](unix-provisioning.md) — Ansible, Stow, packages, fonts, and Unix setup.
- [Windows provisioning](windows-provisioning.md) — PowerShell, winget, links, and native Windows setup.
- [Synchronization](synchronization.md) — the canonical WSL/repository-to-Windows copy contract.
- [Configuration packages](configuration-packages.md) — tracked Stow packages and their configuration responsibilities.
- [Machine tooling comparison](machine-tooling.md) — difference-first inventory of installed, configured-only, and unprovisioned tooling by platform.

## Governance and safety

- [Maintenance](maintenance.md) — safe-change, review, and wiki-maintenance workflow.
- [Privacy and sensitive boundaries](privacy-and-sensitive-boundaries.md) — material that must be excluded from public operational prose.
- [Pending-review queue](pending/README.md) — public-safe questions awaiting a documentation decision.

## Wiki records

- [Wiki log](log.md) — append-only record of significant wiki maintenance and validation events.
- [Wiki landing page](README.md) — concise navigation and the relationship between this catalog and the log.
