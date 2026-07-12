# Design: Git-Native Repository Wiki

- **Status:** Proposed
- **Implements:** [`RFC.md`](RFC.md)
- **Decision:** Store a hand-maintained Markdown wiki in the repository and enforce its freshness with deterministic Git-diff checks and tracked pending-review records. Do not use an LLM or an external documentation service in the first implementation.

## 1. Summary

The wiki will live at `docs/wiki/` and be published as ordinary repository Markdown (and therefore be readable on GitHub without a site generator). Repository files remain authoritative: wiki pages describe them, link to them, and record clearly marked derived operational guidance.

A small, dependency-free Python checker will compare a proposed Git change to its merge base, map changed tracked files to their documentation responsibilities, and require one of two outcomes:

1. the affected wiki page is updated in the same change; or
2. a tracked pending-review record explains why the documentation impact needs human resolution.

The checker will run locally on demand and in required pull-request CI. This provides a durable audit trail for human and agent changes without granting an automation permission to silently redefine configuration behavior.

## 2. Goals and non-goals

### Goals

- Give a reader a navigable explanation of every public-documentable area of the tracked repository.
- Preserve the repository/WSL-to-Windows direction and all existing platform contracts.
- Make documentation freshness enforceable for normal Git changes.
- Make uncertain documentation work visible, reviewable, and resolvable in Git.
- Keep implementation portable across macOS, Debian/Ubuntu/WSL, Windows, and GitHub Actions.
- Avoid publishing or copying sensitive values while still documenting sensitive-file boundaries.

### Non-goals

- Generate prose from repository contents.
- Introduce an LLM, API credentials, embeddings, a database, a static-site generator, or a hosted wiki.
- Change setup, Stow, Ansible, Windows provisioning, or synchronization behavior.
- Automatically edit source configuration or automatically commit documentation.
- Document the contents of encrypted, credential-bearing, or machine-local files.

## 3. Chosen architecture

### 3.1 Repository layout

```text
docs/
  machine-tooling.md
  idea-artifacts/
    RFC.md                           # documentation intent and constraints
    DESIGN.md                        # selected wiki architecture
    PLAN.md                          # implementation plan and verification gates
  wiki/
    README.md                         # concise landing page and navigation
    index.md                          # content-oriented catalog of maintained pages
    log.md                            # append-only wiki-maintenance timeline
    architecture.md                   # system model and source-of-truth rules
    platforms.md                      # macOS, Debian/Ubuntu, WSL, Windows model
    setup-and-verification.md         # supported setup and checks
    unix-provisioning.md              # setup.sh, playbook, tasks, Stow
    windows-provisioning.md           # PowerShell and winget setup
    synchronization.md                # sync-win contract and limits
    configuration-packages.md         # Stow package map and configuration areas
    maintenance.md                    # safe-change and review workflow
    privacy-and-sensitive-boundaries.md
    _meta/
      source-map.yml                  # tracked-path classification and page ownership
      page-schema.md                  # documented front-matter and writing rules
    pending/
      README.md                       # queue semantics; no pending item is a success state
      <change-id>.md                  # one unresolved documentation question
scripts/
  wiki_check.py                       # deterministic validator and impact checker
.github/
  workflows/
    wiki.yml                          # PR and default-branch audit workflow
```

`docs/wiki/` is authored content, not disposable generated output. All pages and queue records are tracked. `scripts/wiki_check.py` uses only Python's standard library and supports Python 3.10+; Python is already part of the supported Windows tooling and is readily available to Unix provisioning and CI. No package manager, virtual environment, or network access is required to check the wiki.

### 3.2 Page contract

Each substantive page begins with small YAML front matter:

```yaml
---
title: Synchronization
source_files:
  - sync-win.ps1
  - setup-windows.ps1
  - windows/sync-pi-settings.ps1
  - windows/sync-zed-settings.ps1
last_reviewed: 2026-07-12
---
```

The body uses these conventions:

- **Source-backed facts** link to repository paths and state behavior without extrapolation.
- **Operational guidance** is labelled as guidance and links to the facts on which it relies.
- **Constraints** and **Safety boundaries** state prohibitions explicitly.
- **Verification** gives commands that are already supported by the repository.
- **Uncertainty** links to a pending-review item rather than claiming a conclusion.

The tool validates the front matter, that `source_files` are tracked paths, that local Markdown links resolve, and that each page has a title. It does not attempt to judge prose correctness.

### 3.3 Source map: coverage without leaking content

`docs/wiki/_meta/source-map.yml` is the coverage manifest. Every path returned by `git ls-files` must match exactly one rule. A rule contains:

- a path or glob;
- a classification: `document`, `sensitive-boundary`, `generated-or-vendored`, or `internal-metadata`;
- the responsible wiki page(s), when documentation is required; and
- a short public-safe rationale for exclusions or boundary-only treatment.

The map is deliberately path-based, never content-derived. For example, `postgresql/.pgpass` and `.git-crypt/**` are classified as `sensitive-boundary`: the wiki may state that credentials/encrypted material are excluded, but must not read, copy, summarize, hash, or print their contents. Configuration such as `ansible/**`, `setup*.ps1`, `sync-win.ps1`, and Stow packages is classified as `document`.

This manifest makes “entire tracked repository” testable while respecting the RFC's public-shareability constraint. A new tracked path that matches no rule fails the checker until its author classifies it.

## 4. Change-detection and enforcement

### 4.1 Inputs and change range

The normal command is:

```sh
python3 scripts/wiki_check.py check --base <merge-base> --head HEAD
```

For a pull request, CI fetches the target branch and supplies `git merge-base HEAD origin/<target>`. For a local feature branch, maintainers may use `origin/main`; the script reports a clear error rather than guessing if the base revision is unavailable. The checker evaluates only tracked changes in `base...head`, so untracked machine state is never inspected.

A full audit is also available:

```sh
python3 scripts/wiki_check.py audit
```

It validates the source map against `git ls-files`, the page schema, links, and queue consistency independently of a diff.

### 4.2 Deterministic impact algorithm

For every changed tracked file, `check` performs the following steps:

1. Find its single matching source-map rule. An unmatched or ambiguously matched path is an error.
2. Ignore changes to the wiki checker and CI only when their source-map rules explicitly classify them as `internal-metadata`.
3. For a `document` rule, identify its owned wiki pages.
4. Succeed only if at least one owned page is changed in the proposed range **or** an open pending-review record covers the same source path and proposed change identity.
5. For a `sensitive-boundary` rule, require either the responsible privacy/boundary page to be updated or a pending item. The checker never exposes the file contents in output; it reports only the repository-relative path.
6. For a `generated-or-vendored` rule, require no prose update unless the rule's documented rationale or owner mapping changes.

Changing a page alone is allowed, but `audit` still ensures its declared source paths and links are valid. Changing a source-map rule requires updating the relevant page or adding a pending item, preventing the manifest from becoming an undocumented escape hatch.

The checker is intentionally conservative: it cannot determine whether a line-level source change affects an explanation. The page-or-pending requirement makes that judgement explicit and reviewable rather than attempting unreliable automatic inference.

### 4.3 Pending-review records

When the documentation impact is unclear, the author adds `docs/wiki/pending/<change-id>.md`. `change-id` is the short head SHA at creation; the front matter retains the full base and head SHA so a reviewer can locate the original change even after history advances.

```yaml
---
status: open
base: <40-character SHA>
head: <40-character SHA>
paths:
  - ansible/tasks/linux.yml
question: Does this package-installation change alter the supported tooling inventory?
owner: unassigned
created: 2026-07-12
---
```

The body provides a public-safe description of the question, links to source paths, names the page likely to be affected, and records the resolution. It must never include a raw diff, credentials, machine-local paths, or sensitive configuration values.

An open record is an acceptable result for an uncertain source change, but it is not invisible debt:

- `check` verifies that it names a changed, mapped path and a valid revision pair.
- `audit` reports all open records and fails if one is older than 30 days. The threshold is configurable in the script but defaults to 30 calendar days.
- A resolver updates the affected page, changes the record to `resolved`, adds a `resolved_by` commit SHA and date, and may then remove the record in a later cleanup commit.
- A record that no longer covers any live source path, has invalid metadata, or is marked resolved while the required page is unchanged fails validation.

This is the required escalation mechanism for both human and agent changes. It records uncertainty without treating a pending item as authoritative documentation.

### 4.4 CI and normal Git workflow

Add `.github/workflows/wiki.yml` with two jobs:

1. **Pull requests:** checkout full history, compute the merge base, run `wiki_check.py check`, and run `wiki_check.py audit`.
2. **Pushes to the default branch:** run `audit` and a `check` against the previous pushed revision. A failure is visible immediately and creates no automatic repository mutation.

The pull-request check is configured as a required status check on the default branch. That is the enforcement point that prevents a normal human-authored change from merging without either an appropriate wiki update or a visible pending item. Direct pushes to the protected default branch are disabled except for explicitly authorized emergency administration; the post-push audit makes any such exception visible.

A lightweight optional pre-commit hook may run the local check, but it is advisory. CI and branch protection, not developer-machine hooks, are the correctness boundary.

## 5. Initial wiki information architecture

The first content pass creates the pages in the layout above. Their responsibilities are:

| Page | Primary questions answered | Principal sources |
|---|---|---|
| `README.md` | Where do I start and how is the wiki organized? | all wiki pages |
| `index.md` | What maintained operational page is relevant to my task? | wiki navigation and source map |
| `log.md` | What significant wiki maintenance, validation, or queue work happened recently? | wiki maintenance workflow |
| `architecture.md` | What is canonical? What are the system boundaries? | `README.md`, `AGENTS.md`, `docs/idea-artifacts/RFC.md` |
| `platforms.md` | Which platforms are supported and how do their roles differ? | `README.md`, setup scripts, playbook |
| `setup-and-verification.md` | How do I install and validate each supported path? | `README.md`, `setup.sh`, `setup*.ps1`, playbook |
| `unix-provisioning.md` | How do Ansible, Stow, packages, and Unix tasks interact? | `ansible/**`, `Brewfile`, Stow packages |
| `windows-provisioning.md` | How is native Windows provisioned? | `setup*.ps1`, `windows/**` |
| `synchronization.md` | What is copied, in which direction, and what is prohibited? | `sync-win.ps1`, `windows/sync-*.ps1`, `CHECKPOINT.md` |
| `configuration-packages.md` | What does each configuration package own? | Stow package directories, `ansible/group_vars/all.yml` |
| `maintenance.md` | How do I make a safe change and keep documentation current? | `AGENTS.md`, `docs/idea-artifacts/DESIGN.md`, checker contract |
| `privacy-and-sensitive-boundaries.md` | What must not be documented or synchronized? | `.git-crypt/**`, credential paths, sync scripts, `AGENTS.md` |

The initial content must cite paths rather than duplicate long scripts or configuration blocks. Existing `README.md` remains the concise entry point; it gains a link to the wiki but is not replaced by it. `docs/machine-tooling.md` remains its detailed inventory and is linked from the relevant wiki pages.

## 6. Writing and review workflow

1. Make a repository change on a branch.
2. Run `python3 scripts/wiki_check.py check --base origin/main --head HEAD`.
3. Update the owned wiki page if the effect is known. Update its `last_reviewed` date and source links; update `index.md` when the page set changes.
4. If the effect is uncertain, add a pending-review record instead of guessing.
5. Append a dated `log.md` entry for significant wiki maintenance, validation, or queue resolution.
6. Run `python3 scripts/wiki_check.py audit` and `git diff --check`.
7. In code review, reviewers verify source-backed claims against the linked files and either accept the page change or resolve/retain the queued question.

Documentation pages never override source behavior. If documentation and source disagree, the reviewer fixes the page or explicitly records the source ambiguity; they do not change configuration merely to satisfy documentation tooling.

## 7. Security and privacy controls

- The checker reads Git path metadata, page metadata, and public wiki files; it does not read sensitive-boundary file contents.
- CI logs only relative paths and validation categories. It never prints file contents or diffs as part of a failure report.
- The source map makes exclusions explicit. An excluded path cannot be silently omitted.
- No external service receives repository source or documentation in the first implementation.
- No workflow has write permissions. The `GITHUB_TOKEN` is read-only and no bot opens PRs, commits, or issues.
- Public wiki prose must use repository-relative paths and generic environment-variable notation; it must not include usernames, hostnames, absolute personal paths, tokens, credentials, session data, or local command output.

## 8. Rollout plan

### Phase 1: Establish the corpus

1. Add the directory layout, initial pages, source map, and page schema.
2. Classify every currently tracked path with no unmatched paths.
3. Write initial source-backed pages, especially the setup, platform, synchronization, and privacy boundaries.
4. Review the corpus manually for sensitive information and contract accuracy.

### Phase 2: Add deterministic tooling

1. Implement `scripts/wiki_check.py` with `audit` first, then diff-based `check`.
2. Add fixture repositories or temporary Git repositories for path coverage, ambiguous rules, stale pending records, broken links, and sensitive-boundary reporting.
3. Document command usage in `README.md` and `AGENTS.md` as part of the implementation change.

### Phase 3: Enforce in CI

1. Add the read-only GitHub Actions workflow.
2. Enable the PR job as a required status check and protect the default branch.
3. Run the first full audit; resolve or intentionally queue every finding before enforcement is enabled.

## 9. Acceptance criteria

The implementation is complete when:

- `audit` verifies one and only one source-map classification for every tracked file.
- The first wiki corpus covers all `document` and `sensitive-boundary` rules with valid source links.
- A change to `sync-win.ps1`, an Ansible task, a setup script, or a Stow package fails PR validation unless its responsible page changes or it has a valid tracked pending item.
- A new tracked path fails until it is classified.
- Broken page links, missing source files, invalid front matter, stale open records, and sensitive-content references fail validation with public-safe diagnostics.
- The workflow has no write token or external API dependency.
- The documented setup and verification commands remain consistent with the existing supported-platform contract.

## 10. Deferred decisions

The design intentionally leaves these for later, after the deterministic baseline has proven useful:

- whether a static site renderer should be added while preserving Markdown as the source;
- whether an LLM may produce non-authoritative draft updates in a separate, opt-in workflow;
- richer source provenance (for example, line ranges or commit-derived citations);
- a GitHub issue integration for pending records; and
- automated detection of semantic impact beyond the conservative path-to-page mapping.
