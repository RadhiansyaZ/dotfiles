---
title: Maintenance workflow
source_files:
  - AGENTS.md
  - README.md
  - CHECKPOINT.md
  - docs/idea-artifacts/PLAN.md
  - .gitattributes
last_reviewed: 2026-07-12
---
# Maintenance workflow

Repository behavior is authoritative; update wiki pages to describe a source change, not the reverse. The maintainer constraints are in [AGENTS.md](../../AGENTS.md), and the current implementation plan is [PLAN.md](../idea-artifacts/PLAN.md).

## Change workflow

1. Make a change on a branch.
2. Run `python3 scripts/wiki_check.py check --base origin/main --head HEAD`.
3. Update the owned page and `last_reviewed` date when the impact is known.
4. Otherwise add a public-safe [pending record](pending/README.md).
5. Run `python3 scripts/wiki_check.py audit` and `git diff --check`.
6. In review, verify source-backed claims against their linked files.

## Constraints

If source and documentation disagree, correct the page or record the ambiguity. Do not change configuration merely to satisfy documentation tooling.
