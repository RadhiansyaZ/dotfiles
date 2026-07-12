---
title: Wiki architecture
source_files:
  - docs/idea-artifacts/DESIGN.md
  - docs/idea-artifacts/RFC.md
last_reviewed: 2026-07-12
---
# Wiki architecture

Repository files remain authoritative. This wiki is hand-maintained Markdown that links to source files; it never overrides source behavior. The design in [DESIGN.md](../idea-artifacts/DESIGN.md) defines deterministic diff checks and a tracked pending-review queue.

The [wiki index](index.md) is the content-oriented catalog of maintained pages. The [wiki log](log.md) is an append-only timeline of significant wiki maintenance and validation events. Both are navigational records, not sources of configuration behavior.

## Safety boundary

The checker uses Git path metadata and public wiki content. It does not use an LLM, an external documentation service, or automation that changes configuration behavior.

## Guidance

Use [maintenance.md](maintenance.md) for the change workflow and the [pending queue](pending/README.md) when a source change cannot be documented confidently.
