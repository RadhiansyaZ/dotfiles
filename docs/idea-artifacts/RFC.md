# RFC: LLM Wiki Documentation Alignment

- **Status:** Aligned for goal and constraints
- **Scope of this RFC:** Product/documentation intent only. Implementation is explicitly deferred to a later session.

## Context

This repository is the canonical, reproducible source for personal configuration across macOS, Debian/Ubuntu Linux, WSL (Debian), and native Windows. Its current documentation explains initial setup and important platform-specific contracts, particularly the separation between Unix provisioning and native-Windows provisioning.

The LLM Wiki model is a useful direction for expanding that documentation: a persistent, interlinked markdown knowledge base that accumulates synthesized understanding from repository sources. It is not merely a retrieval layer over files. It should retain useful explanations, relationships, and validated conclusions as the repository evolves.

## Goal

Create and maintain public-shareable documentation that covers the entire tracked repository and serves two equally important readers:

1. **The maintainer**, who needs to understand, safely modify, troubleshoot, and maintain the configuration over time.
2. **A new user or future maintainer**, who needs to reproduce a supported setup and understand the repository's operational boundaries.

The documentation should make the repository easier to navigate as a system: explain what each area is responsible for, how supported platforms differ, which files and workflows are authoritative, and how configuration changes affect setup and verification.

## Intended Outcomes

The first release is successful when a reader can:

- orient themselves in the full tracked repository and find the relevant source material for a configuration concern;
- understand the supported-platform model and the boundary between Unix/WSL and native Windows;
- identify the canonical source of configuration and the direction and limits of synchronization;
- complete setup and verification for a supported platform using the documentation; and
- make a meaningful configuration change with enough context to preserve established contracts and verify the result.

## Scope

### In scope

- All tracked repository content that is appropriate to document publicly, including provisioning, configuration packages, setup and synchronization scripts, existing documentation, and their relationships.
- Synthesized explanations that connect source files into an understandable model of the repository.
- Cross-references and durable answers to recurring maintenance and onboarding questions.
- Documentation of important invariants already represented by the repository, such as the repository being canonical and the intentional Windows/WSL separation.

### Out of scope for this alignment

- Implementation choices for generating, storing, navigating, validating, or automating the wiki.
- Selecting an LLM, editor, static-site generator, CI workflow, metadata format, directory structure, or synchronization mechanism.
- Altering the repository's provisioning or synchronization behavior.
- Documenting untracked machine state, credentials, sessions, tokens, private hostnames, or other sensitive data.

## Constraints

### Public-shareable by default

Every wiki artifact must be safe to share publicly. It must not reproduce secrets, credentials, tokens, personal identifiers, private paths, machine-local state, or operational details that should remain private. Public clarity must not weaken the repository's existing security and privacy boundaries.

### Repository source remains authoritative

The tracked repository remains the canonical source for configuration and behavior. The wiki explains and synthesizes it; it must not silently become a competing source of truth or redefine behavior independently of the underlying files.

### Preserve platform and synchronization contracts

Documentation must accurately preserve the established model:

- Unix-like hosts use Ansible and GNU Stow.
- Native Windows uses PowerShell, winget, symlinks, and limited copy-based synchronization where UNC-backed symlinks are unsuitable.
- Repository/WSL-to-Windows is the active synchronization direction.
- Windows-to-WSL synchronization is not a normal workflow and requires an explicit conflict-resolution policy before it can be introduced.

### Freshness is a change contract

The wiki must be updated with every meaningful repository change that affects behavior, supported platforms, usage, safety boundaries, or verification. It is not an occasionally refreshed snapshot. This applies equally to changes made directly by a human through Git or another normal repository workflow; maintaining the wiki must not require an AI agent to author every repository change.

### Human-change bookkeeping and escalation

The documentation system must account for human Git changes that may affect the wiki. It should assess whether a change is relevant and use an escalation model:

- When the change's documentation impact is sufficiently clear, it may update the affected wiki material automatically, subject to later review.
- When relevance, impact, or correctness is uncertain, it must create a visible pending-review record that identifies the change and the documentation question to resolve.

A human-made change must therefore never be silently lost from documentation maintenance merely because no AI agent made the original edit. The bookkeeping record and any automatic update are documentation-maintenance aids; they do not change the repository source's authority.

### Evidence-oriented synthesis

The documentation should distinguish source-backed facts from derived guidance. When multiple repository sources create tension or a change makes previous guidance uncertain, the documentation should surface that uncertainty rather than conceal it. Useful conclusions and answers should be retained as durable documentation rather than disappearing into chat history.

### Usable for both orientation and execution

The documentation must support high-level orientation and concrete reproducibility. It should help readers understand the whole system without forcing them to rediscover relationships across scripts, playbooks, configuration directories, and existing documentation, while still enabling supported setup and verification.

## Principles

- **Persistent and compounding:** each accepted documentation update should add to an evolving, coherent understanding rather than create disconnected summaries.
- **Interlinked:** relationships and dependencies matter as much as individual file descriptions.
- **Maintained, not merely generated:** documentation quality includes keeping cross-references, summaries, and conclusions current as sources change.
- **Conservative:** where source behavior is unclear or potentially unsafe, document the limit and preserve the existing contract instead of inventing certainty.
- **Readable by humans:** the wiki is a browsing and learning aid, not only an agent-facing index.

## Deferred Decisions

The following are intentionally deferred until a separate implementation session:

- wiki information architecture and page taxonomy;
- where generated or maintained documentation will live;
- the mechanism for detecting and recording Git changes;
- the criteria and workflow for confidence, automatic updates, and pending review;
- citation and provenance conventions; and
- publication, rendering, and navigation tooling.
