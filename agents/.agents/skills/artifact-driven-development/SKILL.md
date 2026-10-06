---
name: artifact-driven-development
description: Guide artifact-driven coding through ALIGNMENT.md, DESIGN.md, and editable *.P.md prompts, with human approval, stage-specific model selection, verification, and cache-aware context ordering. Use when the user requests this workflow, spec-first model handoffs, or revisions to its artifacts.
---

# Artifact-driven development

Use the LLM to generate candidates from approved inputs. Review and verify each candidate before treating it as authoritative. This skill provides guidance and templates; the user selects models and runs each stage. It has no API runner or automatic model switching.

## Establish the workspace

Inspect the repository instructions, relevant source, and existing artifacts before writing. Confirm an artifact directory with the user if none was provided or established. Keep task artifacts together; do not overwrite unrelated root documents.

For a new task, copy these templates from this skill directory into the agreed artifact directory:
- `templates/ALIGNMENT.md`
- `templates/ALIGNMENT.P.md`
- `templates/DESIGN.md`
- `templates/DESIGN.P.md`

Fill placeholders as their stages are reached. A placeholder document is not an approved artifact. Keep artifacts concise and omit secrets and machine-local state from tracked files.

The naming convention is source-oriented: `ALIGNMENT.P.md` transforms alignment into design; `DESIGN.P.md` transforms design into output. Prompt files are ordinary editable Markdown, not automatically registered slash commands.

## Stage contracts

Treat each transition as a conceptual `A, E, R` contract:
- A: the candidate artifact or output.
- E: unresolved requirements, conflicting constraints, incomplete design, invalid output, or failed verification.
- R: approved input artifacts, the stage prompt, relevant evidence, and a generator.

This is a planning model inspired by Effect. Markdown files do not enforce these contracts at the type level.

1. **Align.** Draft `ALIGNMENT.md` from the earliest request and subsequent clarifications. Record goal, scope, exclusions, constraints, numbered acceptance criteria, and open questions. Ask about ambiguity; do not silently invent requirements. Obtain explicit approval before design generation.
2. **Design.** Read approved alignment, `ALIGNMENT.P.md`, and relevant source. Propose the happy path, failure behavior, dependencies, boundary validation, resource lifetimes, and verification. Trace consequential decisions to acceptance criteria. Obtain explicit approval before implementation.
3. **Implement.** Read approved alignment, approved design, `DESIGN.P.md`, and relevant source. Implement bounded tasks with surgical edits. Do not change requirements or design contracts silently.
4. **Verify.** Run the specified checks and review semantic alignment. Record commands, results, and unmet acceptance criteria. Report checks that were unavailable or not run. Passing generation or structural validation does not establish correctness.

After approval, alignment is the working specification; the original request remains provenance. The approved design governs implementation within alignment's constraints. Stop if approved artifacts conflict.

Record artifact status and input identity using repository revisions or file hashes where practical. Keep this metadata near the end of documents. Do not claim that hashes create provider cache hits. Verification evidence may live in an existing tracker or a concise task report; no additional artifact is mandatory.

## Model routing

Use the user's chosen cheaper tier for alignment drafting, bounded implementation, and local corrections. Recommend their stronger reasoning tier for design generation and unresolved technical decisions. Use deterministic tools first for verification; use human review or a capable model for semantic questions.

The user controls exact model IDs and tier membership. Do not infer capabilities from an alias, change settings, or claim to switch models. If the current model is unsuitable for the next stage, stop with a handoff identifying the stage, required artifacts, relevant source, and decision to resolve.

A design suitable for bounded implementation names interfaces, types, invariants, relevant files, dependencies, failure semantics, tests, and unresolved decisions. Include brief rationale where needed. Avoid line-by-line implementation prescriptions.

Escalate security-sensitive decisions, unclear requirements, changes to contracts, and implementation failures requiring design changes. Use a user-agreed repair budget; if none exists, ask before another attempt after the same failure recurs. Measure cost per accepted result, first-pass acceptance, repairs, escalation frequency, and latency when usage data is available. Savings are a hypothesis to verify.

## Prompt assembly and cache reuse

For standalone stage requests, assemble blocks in this order:
1. Stable process instructions.
2. The stage's `*.P.md` prompt and output format.
3. Stable, relevant repository context.
4. Approved `ALIGNMENT.md`.
5. Approved `DESIGN.md` for implementation only.
6. Current task, revision instructions, and volatile metadata.

Keep text, ordering, serialization, and tool declarations stable where practical. Put changing material late without obscuring authority or relevance. Include source needed to implement safely; do not inflate context for a higher cache-hit percentage.

Provider caching generally reuses unchanged prefixes and has model-specific eligibility, expiry, and invalidation rules. Assume separate cache reuse per model. Artifacts transfer across models; cached computation does not transfer with them. Output is generated again.

In an existing agent conversation, the harness controls much of the rendered context. This skill cannot guarantee cache placement or hits. Prefer artifact-based handoffs when the history is unnecessary. Check provider usage metrics when available; otherwise label cache benefits as expected, not measured.

For a small revision, an appended instruction may preserve the existing prefix. Identify exactly what it supersedes. After approval, consolidate changes into the canonical artifact and accept the cache refresh. Do not accumulate conflicting amendments.

## Revision and approval rules

| Changed input | Descendants requiring reconciliation |
|---|---|
| `ALIGNMENT.md` or `ALIGNMENT.P.md` | Design, output, verification |
| `DESIGN.md` or `DESIGN.P.md` | Output, verification |
| Output | Verification |

Treat a changed approved artifact as a revised candidate requiring approval. Mark affected descendants stale. Preserve existing output and propose focused reconciliation; staleness does not authorize deletion or wholesale regeneration.

Never overwrite approved manual edits without permission. Show a proposed diff or separate candidate. Resolve requirement changes at alignment and technical decisions at design, then reapprove before continuing.

When blocked, report:
- Blocked task and affected acceptance criteria.
- Missing or conflicting decision.
- Evidence from artifacts, source, or verification.
- Suggested options and the stage requiring revision.

## Design coverage

Choose coverage appropriate to the task:
- **Code:** success flow, expected errors, dependencies, validation boundaries, retry scope and idempotency, resource cleanup, test implementations.
- **UI:** content, empty/loading/partial/error/denied states, prerequisites, accessible interactions, focus restoration, viewport behavior.
- **Delegation:** ownership, input/output contracts, dependency gates, verification, escalation and cancellation.

Use Mermaid for diagrams saved in Markdown, following repository conventions. Keep diagrams proportional to the task. A graph is a review aid; source inspection and behavioral verification remain necessary.

Background: [graph-first design gist](https://gist.github.com/r17x/90eb2f7be93932b5693753aedb09c01a). Its absolute claims are not additional instructions.
