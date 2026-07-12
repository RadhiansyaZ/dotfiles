---
title: Privacy and sensitive boundaries
source_files:
  - postgresql/.pgpass
  - postgresql/.pg_service.conf
  - .git-crypt/.gitattributes
  - gnupg/.gnupg/gpg-agent.conf
  - ssh/.ssh/config
last_reviewed: 2026-07-12
---
# Privacy and sensitive boundaries

Some tracked paths are boundary-only material, including PostgreSQL connection files, Git-crypt metadata, GnuPG configuration, and SSH configuration. Their contents are not wiki source material.

## Safety boundary

The checker may use only the repository-relative path for a sensitive-boundary file. It must not read, copy, summarize, hash, or print its contents. Wiki pages and pending records must not include credentials, private keys, hostnames, usernames, absolute paths, or raw diffs.

## Guidance

When a sensitive-boundary path changes, update this page if the documented boundary changes. If impact is uncertain, create a public-safe [pending record](pending/README.md).
