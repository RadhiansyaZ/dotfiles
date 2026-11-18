---
name: feature-map
description: Build an as-built feature map of one or more codebases – business journeys from the user's (or API consumer's) seat plus technical module docs with call graphs, every claim cited to file:line, published as .md sources and one offline HTML. Read-only scouting with an alignment gate, a fixed git baseline, tiered subagents (Haiku / Sonnet / Opus) and an optional reference doc (PRD, spec) used as a comparison lens.
argument-hint: "<dir> [<dir>...] [--ref <prd-or-spec>] [--parallel N]"
disable-model-invocation: true
---

# Feature map

Produce a map of a product **as it is built today**, read from code, for a reader who needs onboarding
on the product. Two halves:

- **Business** – what a user can do, how it feels, where it hurts. Written from the user's seat when the
  product has a UI, from the API consumer's seat when it does not.
- **Technical** – how each module works: call graphs with data / error / dependency channels, data flows,
  conflicts between repository docs and code.

The job is scouting. Nothing in the target repositories changes.

## Inputs

Parse from the arguments and the user's message. Ask for what is missing at the alignment gate, not
before.

| Input | Default |
|---|---|
| Target dirs (one or more repos, or one monorepo) | required |
| Reference doc (PRD, spec, brief) – path or pasted | none. When given, it is a lens to compare against, never a source of facts about the code |
| `--parallel N` – max subagents running at once | 3 |
| Reader, stack hints, out-of-scope areas | from the user's message; otherwise asked at the gate |

## Ground rules for the whole run

These came out of the first run of this method. Each one prevents a failure seen there.

- **Read-only on targets.** No edits, commits, checkouts, stashes or branch switches. Readers work from
  a `git archive` snapshot, so the user's working tree and branch never matter to them.
- **Truth order: code, then repository docs, then the reference doc.** Conflicts are logged, not fixed.
- **Secrets.** Never read `.env` values; variable names from config code are fine. Never put tokens,
  keys or passwords into any doc.
- **Client data.** Repositories can hold uploaded documents, seed data or fixtures with real client
  content. Record that they exist; do not summarise what they say. Work here can be operationally
  sensitive.
- **Security findings are recorded, never exercised.** Never forge a token, sign an unsigned JWT, or
  bypass auth, even on a local debug build. If a runtime check needs auth, ask the user for a token or
  skip it.
- **Output stays local.** Do not publish to Artifacts, Docs, Confluence or anywhere else unless the user
  asks.
- **Writing.** Plain English. En dashes (–), never em dashes. No metaphors, no filler, no contrast
  framing, no groups of three made up for rhythm. Every factual claim cites a repo-relative
  `path:line`. If something could not be verified, the doc says "unverified".

## Phases

```
1 Recon (main, scripts only) ──► 2 Alignment gate ──► wait for "agreed"
                                                         │
3 Snapshot baseline ◄────────────────────────────────────┘
4 BRIEF.md + SCOPES.md ledger
5 Readers: wave 1 Haiku inventory ─► wave 2 Sonnet / Opus modules   (≤ N at once, queue, resume)
     │ each report → spot-verify load-bearing claims → FINDINGS.md
6 Runtime check (optional, main, in parallel with 5)
7 Synthesis (main): business docs, overview, flows, README
8 Build + QA: collect conflicts → lint → cite check → HTML → render check → fix loop
9 Close: stop what you started, confirm repos clean, final report
```

Keep coordinator state in the scratchpad (`<S>` below): `BRIEF.md`, `SCOPES.md`, `FINDINGS.md`,
`baseline.md`, `snapshot/`. These files survive context compaction. Read them back after a compaction
instead of relying on memory.

### 1 – Recon

Keep this cheap. Reading source in depth belongs to the readers, and doing it here spends main-thread
tokens twice.

```bash
python3 ~/.agents/skills/feature-map/scripts/inventory.py <dir> [<dir>...]
```

This gives the git state (current branch, origin default, dirty paths), manifests, UI detection, lines
of code by folder, the largest files, and the repository docs. Then skim each root `README.md` /
`CLAUDE.md` / `ARCHITECTURE.md` for orientation only. If a reference doc is given, read it fully: it
shapes the key questions.

### 2 – Alignment gate

Present the alignment message using `references/alignment-template.md`. It covers what you understood,
the proposed output tree, the scope plan with a model for each scope, your assumptions, and the open
decisions. The required decisions are baseline branch per repo, output directory, runtime check,
reference doc role, depth and reader.

Stop and wait. Iterate until the user explicitly agrees. Starting phase 3 early wastes the most
expensive part of the run if the scope turns out wrong.

### 3 – Baseline snapshot

```bash
bash ~/.agents/skills/feature-map/scripts/snapshot.sh <repo-dir> <agreed-ref> <S>/snapshot
```

Run once per repo. Record each output line (name, ref, sha, date) in `<S>/baseline.md`. If a target is
not a git repo, copy it with `rsync`, excluding dependency and build folders, and note "no git
baseline". The script also reports whether the working tree differs from the ref in non-markdown files.
That matters only for the runtime check, which runs the working tree. If they differ, tell the user and
ask; never switch branches yourself.

### 4 – Brief and scope ledger

1. Fill `references/brief-template.md` into `<S>/BRIEF.md`: product one-liner, snapshot paths, output
   root, cite prefixes. Keep Formats A / B / C as they are; they are the method.
2. Write `<S>/SCOPES.md` as a table: scope | model | output files | status (queued / running / done /
   stopped) | agent id | notes. This is the queue and the record of who wrote what.

**Splitting scopes**

- One reader per cohesive module. Target about 3–8k lines for a Sonnet reader. Use fewer, larger scopes
  for simple code and smaller ones for dense code.
- Split a frontend in two: the non-visual layer (stores, API clients, streaming, composables – Format A)
  and the visual surfaces (Format B).
- With no UI, one reader owns the consumer surface (Format C) and writes `business/feature-inventory.md`
  from the consumer's view.
- Give every reader explicit "not yours" boundaries ("for X document only the call edge, function +
  file:line"). Without them, readers re-read each other's files.
- A typical service has 4–8 reader scopes. Anything above about 10 means the scopes are too fine.

### 5 – Readers

Prompts come from `references/reader-prompts.md`. Every reader is a `general-purpose` agent, because it
must write files. Pass `model` explicitly on every call.

**Wave 1 – inventory (Haiku).** Mechanical extraction that readers and synthesis lean on: full route
or command table, live vs dead files (import tracing from entry points), config and env var names,
external services named in config. One agent per repo, or one for all repos if they are small. Its
files go under `technical/<repo>/`.

**Wave 2 – module readers (Sonnet or Opus, see tiering).** Launch from `SCOPES.md` in order, so that
no more than N run at once. When a completion notification arrives:

1. Update `SCOPES.md` and launch the next queued scope in the freed slot.
2. Read the report, not the files. Pick the claims that will carry weight in the README or the business
   docs: surprising behaviour, defects, security issues, contradictions with docs or the reference doc.
   Re-read their cited lines yourself (`sed -n` on the snapshot). Record each in `<S>/FINDINGS.md` with
   level `[V]` (you re-read it) or `[R]` (reader only).
3. Give the user a short status: which scope finished, what is running, what is queued, and two to five
   notable findings, with unverified ones marked as such.

**When agents stop.** If an agent stops on a usage limit or is stopped by you or the user, resume it
with `SendMessage` ("continue from where you stopped, same brief, same output files"). Do not start a
new one. Files already written survive, which is why the brief demands early writes. If agents fail on
a usage limit, stop launching new ones and tell the user when the limit resets.

### 6 – Runtime check (only if agreed at the gate)

Run this while readers work. Its purpose is to supplement static reading, not to replace it.

- Start only what the repo's own setup docs describe (compose services, dev server). Run in the
  background and keep a list of everything you start.
- Safe probes: health or readiness endpoints, OpenAPI or route listing, unauthenticated requests that
  confirm 401/403, public endpoints with no side effects.
- Never call the LLM or any paid, ordering, write or notification endpoint. Never forge credentials. For
  authenticated probes, ask the user for a token first.
- Record observations as `[RT]` in `FINDINGS.md`. Note anything that contradicts a reader's claim.

### 7 – Synthesis (main thread)

Write these from the reader docs, `FINDINGS.md` and runtime notes, following
`references/synthesis-templates.md`:

| File | Written by |
|---|---|
| `business/journeys.md` | main |
| `business/feature-inventory.md` | UI-surfaces reader or consumer-surface reader; main reviews |
| `business/reference-alignment.md` | main, only when there is a reference doc |
| `technical/overview.md`, `technical/flows.md` | main |
| `technical/doc-vs-code.md` | preface by main, body generated |
| `README.md` | main, last |

Read reader docs selectively: `grep -n '^#'` first, then the sections you need. Synthesis states facts.
It does not recommend product direction; product decisions belong to the user's organisation.

### 8 – Build and QA

```bash
K=~/.agents/skills/feature-map/scripts
python3 $K/collect_doc_vs_code.py --root <out>
python3 $K/lint_docs.py --root <out>                            # must exit 0
python3 $K/check_cites.py --root <out> --src <repo>=<S>/snapshot/<repo> [...] --report <S>/cites.tsv
python3 $K/build_html.py --root <out> --title "<Product> Feature Map" --subtitle "As built on <ref>" --label "<out relative to targets>/"
python3 $K/render_check.py --html <out>/feature-map.html        # exit 2 = no browser: say so
```

- **Cite check.** Fix every `missing` and `range` entry; these are wrong paths or stale lines. Fix
  `ambiguous` entries by writing the full repo-relative path. If there are many problems in one reader's
  docs, send that reader the list via `SendMessage` rather than fixing them in the main thread.
- **Render check.** A `BAD` page shows the Mermaid parse error. Fix the source `.md` (labels with `;`,
  `:` or parentheses usually need quoting) and rebuild.
- `nav.json` in `<out>` overrides the automatic navigation order, if the default grouping reads badly.

### 9 – Close

Stop every process and container you started. Run `git status --short` in each target and confirm it is
clean. Then send the final report described at the end of `references/synthesis-templates.md`.

## Model tiering

Optimise for cost: give each task the cheapest model that does it reliably. The main thread (the user
runs it at Opus level) owns alignment, synthesis and verification, and does not delegate those.

| Task | Model | Why |
|---|---|---|
| Inventory: route / command tables, live vs dead files, env var names, dependency lists | `haiku` | Extraction with grep and lists. Little judgement needed |
| Fixing a list of wrong cites in an existing doc | `haiku` | Mechanical lookup |
| Module reader for ordinary code: CRUD and API layers, API clients, stores, UI surfaces, integrations, persistence, config, auth plumbing | `sonnet` | Most scopes. Reliable at reading and citing |
| Module reader for dense logic: LLM orchestration or agent graphs, planners, state machines, concurrency or scheduling, any single file above about 2.5k lines, code where control flow is spread across many files | `opus` | Sonnet loses the thread here. Missing a routing condition makes the whole doc wrong |
| Alignment, synthesis, spot verification, final README | main thread | Needs the whole picture and the user's context |

Rules:

- Pick the model per scope at the gate, with a one-line reason in the scope table. The user can
  override.
- When in doubt between Sonnet and Opus, use Sonnet and give the scope tighter key questions. Escalate
  to Opus only if the report comes back thin or contradicts its own cites.
- Prefer a script over any agent for anything mechanical; the bundled scripts cost no tokens.
- Cap each reader's final reply (400–700 words). The reply is what lands in main context; the detail
  belongs in the files.

## Bundled files

| Path | Use |
|---|---|
| `references/alignment-template.md` | Phase 2 message |
| `references/brief-template.md` | Phase 4 shared brief, with Formats A (code), B (UI surface), C (API consumer surface) |
| `references/reader-prompts.md` | Phase 5 prompt templates and key-question banks per module type |
| `references/synthesis-templates.md` | Phase 7 doc templates and phase 9 final report |
| `scripts/inventory.py` | Recon |
| `scripts/snapshot.sh` | Baseline |
| `scripts/collect_doc_vs_code.py`, `lint_docs.py`, `check_cites.py`, `build_html.py`, `render_check.py` | Build and QA |
| `assets/template.html`, `assets/vendor/` | Offline HTML viewer: marked 16.2.1 and mermaid 11.4.1 inlined, sidebar, search, light / dark |
