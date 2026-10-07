---
title: Privacy and sensitive boundaries
source_files:
  - postgresql/.pgpass
  - postgresql/.pg_service.conf
  - .git-crypt/.gitattributes
  - gnupg/.gnupg/gpg-agent.conf
  - ssh/.ssh/config
  - zed/.config/zed/settings.json
  - windows/sync-zed-settings.ps1
last_reviewed: 2026-10-06
---
# Privacy and sensitive boundaries

Some tracked paths are boundary-only material, including PostgreSQL connection files, Git-crypt metadata, GnuPG configuration, and SSH configuration. Their contents are not wiki source material.

## Safety boundary

The checker may use only the repository-relative path for a sensitive-boundary file. It must not read, copy, summarize, hash, or print its contents. Wiki pages and pending records must not include credentials, private keys, hostnames, usernames, absolute paths, or raw diffs.

## Zed application-local state

Zed connection definitions and project history can contain machine-local host, distro, account, and project-path metadata. Keep that information in Zed's local state; canonical settings contain shared preferences and exclude connection and project history. Cleanup applies to the current tree only, so historical commits remain unchanged.

## Guidance

When a sensitive-boundary path changes, update this page if the documented boundary changes. If impact is uncertain, create a public-safe [pending record](pending/README.md).
