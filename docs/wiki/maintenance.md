---
title: Maintenance workflow
source_files:
  - AGENTS.md
  - README.md
  - CHECKPOINT.md
  - docs/idea-artifacts/PLAN.md
  - tracker/README.md
  - .gitattributes
last_reviewed: 2026-10-13
---
# Maintenance workflow

Repository behavior is authoritative; update wiki pages to describe a source change, not the reverse. The maintainer constraints are in [AGENTS.md](../../AGENTS.md), and the wiki implementation plan is [PLAN.md](../idea-artifacts/PLAN.md). Active maintenance work may use public-safe execution artifacts under [tracker](../../tracker/README.md) for scope, decisions, progress, and verification evidence. Trackers are non-authoritative and must be updated alongside the source and wiki changes they record.

## Change workflow

1. Make a change on a branch.
2. Run `python3 scripts/wiki_check.py check --base origin/main --head HEAD`.
3. Update the owned page and `last_reviewed` date when the impact is known. When adding or removing a substantive page, also update the [wiki index](index.md).
4. Otherwise add a public-safe [pending record](pending/README.md).
5. Append a dated entry to the [wiki log](log.md) for significant wiki maintenance, validation, or queue-resolution events; use `## [YYYY-MM-DD] <kind> | <summary>`.
6. Run `python3 scripts/wiki_check.py audit` and `git diff --check`.
7. In review, verify source-backed claims against their linked files.

## BMAD skills

[AGENTS.md](../../AGENTS.md) routes BMAD installation, per-project usage, and
stable-release transition guidance to [BMAD shared skills](../bmad.md). Keep that
guide aligned with the official release and setup instructions when updating skills.

## Constraints

If source and documentation disagree, correct the page or record the ambiguity. Do not change configuration merely to satisfy documentation tooling.
