# Implementation Plan: Git-Native Repository Wiki

This plan implements the proposed design in [`DESIGN.md`](DESIGN.md). Each step has an explicit verification gate.

## Implementation status

- [x] Wiki structure, contracts, source-backed corpus, and complete source map
- [x] Standard-library audit and diff-based checker
- [x] Checker integration tests and developer workflow documentation
- [x] Read-only GitHub Actions workflow
- [x] Baseline audit and completion checks

## 1. Establish the wiki structure

Create:

- `docs/idea-artifacts/{RFC,DESIGN,PLAN}.md`
- `docs/wiki/{README,index,log}.md`
- `docs/wiki/{architecture,platforms,setup-and-verification,unix-provisioning,windows-provisioning,synchronization,configuration-packages,maintenance,privacy-and-sensitive-boundaries}.md`
- `docs/wiki/_meta/{source-map.yml,page-schema.md}`
- `docs/wiki/pending/README.md`
- `scripts/wiki_check.py`
- `.github/workflows/wiki.yml`

**Verification:** Every path exists, `docs/wiki/README.md` links to the content-oriented index and chronological log, and `index.md` catalogs every substantive operational page.

## 2. Define page and queue contracts

Document required YAML front matter for substantive wiki pages:

```yaml
---
title: <page title>
source_files:
  - <tracked repository-relative path>
last_reviewed: YYYY-MM-DD
---
```

Document the writing rules:

- Source-backed claims link to repository paths.
- Operational guidance is labelled as guidance.
- Uncertainty links to a pending-review item.
- `index.md` is updated when substantive pages are added or removed.
- `log.md` is append-only and records significant wiki maintenance, validation, and queue-resolution events with dated headings.
- Wiki content must not contain secrets, machine-local paths, hostnames, raw diffs, or sensitive values.

Define pending records as `docs/wiki/pending/<short-head-sha>.md` with:

```yaml
---
status: open
base: <40-character SHA>
head: <40-character SHA>
paths:
  - <repository-relative path>
question: <public-safe question>
owner: unassigned
created: YYYY-MM-DD
---
```

**Verification:** The contracts state failure conditions for missing or malformed page and pending-record metadata.

## 3. Create the initial source-backed corpus

Write the initial pages from current repository behavior, prioritizing:

1. Architecture and source-of-truth boundaries.
2. Supported platforms and setup/verification commands.
3. Unix Ansible/Stow provisioning.
4. Native Windows PowerShell/winget provisioning.
5. WSL bootstrap.
6. One-way Windows synchronization through `sync-win.ps1`.
7. Configuration-package layout.
8. Privacy and sensitive-file boundaries.
9. Safe-change and review workflow.

Keep `README.md` as the concise bootstrap entry point and add a link to the wiki. Link relevant pages to `docs/machine-tooling.md` rather than duplicating its inventory.

**Verification:** Manually review every source-backed claim against its linked file and confirm no page contains sensitive or machine-local material.

## 4. Build a complete source map

Implement `docs/wiki/_meta/source-map.yml` so every path from `git ls-files` matches exactly one rule. Each rule contains:

- a path or glob;
- a classification: `document`, `sensitive-boundary`, `generated-or-vendored`, or `internal-metadata`;
- responsible wiki page(s), where documentation is required;
- a public-safe rationale for exclusions or boundary treatment.

Classify configuration and provisioning paths as `document`; credential or encrypted paths as `sensitive-boundary`; and wiki tooling/CI explicitly as `internal-metadata`.

**Verification:** A coverage report has zero unmatched paths and zero paths with multiple matching rules.

## 5. Implement `wiki_check.py audit`

Use Python 3.10+ and only the standard library. Implement:

```sh
python3 scripts/wiki_check.py audit
```

It must validate:

- every tracked file has exactly one source-map rule;
- page front matter, titles, and `source_files`;
- referenced source files are tracked;
- local Markdown links resolve;
- pending-record metadata and status consistency;
- open pending records are no more than 30 days old by default;
- wiki content does not contain prohibited sensitive references;
- diagnostics expose only categories and repository-relative paths.

**Verification:** `audit` succeeds against the initial corpus and fails for each deliberately introduced invalid case.

## 6. Implement diff-based `check`

Implement:

```sh
python3 scripts/wiki_check.py check --base <merge-base> --head HEAD
```

Evaluate only tracked changes in `base...head`, and fail clearly if the base revision is unavailable.

For every changed tracked file:

- fail on unmatched or ambiguous source-map classification;
- for `document`, require an owned page change or valid open pending record;
- for `sensitive-boundary`, require the privacy/boundary page change or a pending record, without reading or printing sensitive contents;
- for `generated-or-vendored`, require no prose update unless its rationale or ownership changes;
- allow `internal-metadata` changes only when explicitly classified as such;
- require source-map changes to have an associated page update or pending item.

**Verification:** Use temporary Git repositories or fixtures to test:

- source change without documentation fails;
- source change plus owned page update passes;
- source change plus valid pending item passes;
- a new unmapped path fails;
- ambiguous rules fail;
- stale or invalid pending items fail;
- a sensitive-boundary change reports only its repository-relative path.

## 7. Document the developer workflow

Add the normal workflow to `README.md` and `AGENTS.md`:

1. Make the source change.
2. Run:
   ```sh
   python3 scripts/wiki_check.py check --base origin/main --head HEAD
   ```
3. Update the owned page and its `last_reviewed` date, or add a pending record when the impact is unclear.
4. Run:
   ```sh
   python3 scripts/wiki_check.py audit
   git diff --check
   ```

**Verification:** Every documented path and command exists, and the commands succeed on a valid branch.

## 8. Add read-only CI enforcement

Create `.github/workflows/wiki.yml`:

- **Pull requests:** use a full-history checkout, compute the target-branch merge base, then run `check` and `audit`.
- **Default-branch pushes:** run `audit` and `check` against the prior pushed revision.
- Use no write token and no external API or documentation service.

Configure the pull-request job as a required status check and protect the default branch.

**Verification:** Inspect workflow permissions to confirm it has no write scope. Test a pull request with an undocumented change and confirm CI blocks it.

## 9. Enable after a clean baseline

Run the first complete audit. Resolve every finding with documentation or a valid pending record before making CI required.

## Completion checklist

- `audit` reports exactly one classification per tracked file.
- All `document` and `sensitive-boundary` rules have valid source-linked coverage.
- Changes to setup scripts, Ansible, Stow packages, and `sync-win.ps1` require documentation or a pending record.
- Broken links, stale queue items, invalid metadata, and unsafe wiki references fail validation.
- CI is read-only and dependency-free.
- Wiki verification guidance remains consistent with the supported-platform contract.
