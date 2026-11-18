# Synthesis templates (phases 7 and 9)

The main thread writes these docs. Sections are a default. Drop a section that has nothing true to say,
and add one when the product needs it. Structure should follow what was found, not fill a template.

Every coordinator doc opens with the baseline line and the evidence legend:

```
Baseline: `<ref>` – <repo> `<sha>`, <repo> `<sha>`. Evidence: **[V]** cited lines re-read by the
coordinator, **[R]** reported by a reader agent with a cite, **[RT]** observed on the locally running app.
```

Put the mark after the claim it qualifies. The HTML viewer renders `[V]`, `[R]` and `[RT]` as badges.

---

## business/journeys.md

Written from the seat of the user (UI) or the caller (no UI). Each journey is a job the person comes to
do, in their words, not a feature name.

```
# User journeys – <Product> as built          (no UI: "Consumer journeys – …")

<baseline + legend>

## The screen the user gets                   (no UI: "The surface the consumer gets")
<ASCII wireframe from the UI reader, or a table of entry points: API base, auth, SDK, CLI>
<2–4 sentences: primary surface, how results come back>

## Journey overview
<Mermaid flowchart: entry → "what do I need?" → each journey → the control or call it lands on>

## J1 – <job, in the user's words>

**Goal.** "<a quoted example request or task>"

**What the user does today.** <the steps, honestly, including "there is no control for this">

**What the system does.**
```ts
<cross-stack call graph, annotated with A / E / R and [LLM] / [code], cites inline>
```
- <facts with cites and evidence marks>

**Where it hurts.**
- <friction, silent failures, wrong results, extra steps – each tied to a mechanism with a cite>

**What already exists and is not connected.** <optional: half-built pieces>

**Reference tag.** <only with a reference doc: which section, and the doc's category, for example
"Direct action (3.2)", "Conversation", "Belongs to another product", "Not covered">

## J<n> – When something goes wrong
<always include: the failure journey – what the user sees when each dependency is down or input is bad>

## Summary
| Journey | Works today? | How | <Reference tag> | Gap |
```

Derive journeys from the feature inventory, the entry points, and the reference doc's use cases. Always
cover: first use (sign in or first call), each core job, coming back to earlier work, the user's
language(s) if more than one, and failure.

---

## business/feature-inventory.md

Written by the UI-surfaces or consumer-surface reader. The main thread reviews it for plain language.

```
# <Product> – what the user can see and do      (no UI: "what a caller can do")

## How the screen is organised                  (no UI: "How the API is organised")

## <n>. <User goal, for example "Manage conversations">
| Feature | Where | What the user does | What happens | Direct or via <chat / form / job> | Cite |

## Verdict on <reference doc> capabilities      (only with a reference doc)
| Capability | Exists / partly / absent | Evidence |

## Things a product reader should know
```

Description columns contain no code jargon; cites go in the last column.

---

## business/reference-alignment.md (only with a reference doc)

States facts. Does not recommend a product direction.

```
# <Doc name> alignment – what is built against what it asks

<doc title, version, date> · <baseline + legend>

## 1. One-page view
| Position | Section | Built today | Status (met / partly met / not met / contradicts) |

## 2. <The doc's own tests or criteria> applied to every built capability   (if the doc defines any)

## 3. Findings in the doc traced to code
| Finding the doc reports | Mechanism in code | Cite | Level |

## 4. Open questions in the doc that the code already answers
| Question | What the code shows | Cite |

## 5. What exists that the doc's direction could reuse

## 6. Items outside the doc that a product reader should know
```

---

## technical/overview.md

```
# Technical overview – <Product> as built
## 1. Stack                    | Layer | Technology + version | Cite |
## 2. System context           Mermaid flowchart: users, apps, datastores, downstream systems, LLM
## 3. Runtime topology         processes, containers, ports, required vs optional services at startup
## 4. Module map               | Module | Path | Status | Doc | – links every module doc
## 5. <Defining mechanism>     for example the modes, the request pipeline, the plugin system
## 6. One <request> in one picture   short cross-stack call graph
## 7. Size and liveness        lines per area, live vs dead counts from the inventory
## 8. Known-broken paths       from code reading, marked as not run unless [RT]
```

---

## technical/flows.md

```
# End-to-end flows
Channels: `A` data through, `E` failure handling, `R` dependencies.

| Flow | Journey | Detail docs |

## F1 – <flow>
```ts
<client → API → services → downstream, annotated>
```
<Mermaid sequence diagram where the order of calls matters>
- Failure points: <table or list, each with a cite>
```

One flow per journey that crosses more than one module, plus boot or first call.

---

## technical/doc-vs-code.md preface

Write the preface above the `<!-- GENERATED BELOW … -->` marker. `collect_doc_vs_code.py` keeps it and
regenerates the rest. Include:

- the truth rule (code wins, nothing was changed),
- a baseline caveat if the readers' snapshot and the final ref differ,
- "Largest conflicts, in one list" – | Document | Says | Code | – the conflicts a newcomer would trip on.

---

## README.md (write last)

```
# <Product> feature map

<2–3 sentences: what this is, who it is for, the reference doc's role if any>
Open `feature-map.html` in a browser to read everything in one place. It works offline.

## Baseline and method
| | |
| Code baseline | <ref, shas, date> |
| Truth order | Code first. Repository documents second. Conflicts in `technical/doc-vs-code.md` |
| Changes made to the repositories | None |
| Method | A / E / R call graphs for code, C / V / N for UI or API surfaces |
| Diagrams | Call graphs plain text. Data flows and journeys Mermaid |

### Evidence levels      <table of [V] / [R] / [RT]>
### What was and was not checked at runtime

## Reading order          | If you have | Read |  (10 minutes / 30 minutes / a specific task)
### Business              | File | Content |
### Technical             | File | Content |

## What <Product> is today
<numbered statements, as many as there are genuinely defining facts – often 6 to 12. Each statement is
bold, followed by one or two sentences and an evidence mark.>

## Findings that need a decision or a fix
| Finding | Level | Where |
<defects, security issues, data-integrity risks. Listed so they are not lost; none acted on.>

## Limits of this map
<one pass, mostly [R], what was not run, what is outside the repos, persona assumption, out-of-scope items>

## Regenerating the HTML
```bash
S=~/.agents/skills/feature-map/scripts
python3 $S/collect_doc_vs_code.py --root <out>
python3 $S/build_html.py --root <out> --title "<…>" --subtitle "<…>" --label "<…>"
```
```

---

## Final report to the user (phase 9)

In the terminal, short:

```
Done. Open: <absolute path to feature-map.html> (works offline)

## What you get
- <n> .md docs under <out>, one .html built from them; <m> diagrams, render-checked <yes / skipped: why>
- Business: <journeys, inventory, alignment>. Technical: <overview, flows, n module docs, conflict log>.
Start with README, then <the one table that gives the fastest picture>.

## What defines <Product> today
<the README statements, one line each>

## Needs your attention
<verified defects and security items first, each one line>

## Limits – read before trusting
- Evidence: <share at [V] vs [R]>. Open the cited lines before acting on a finding.
- Runtime: <what was checked, what was blocked and why>.
- Cite check: <n cites, problems fixed / remaining>.

## Housekeeping
- Repos untouched, `git status` clean. Processes and containers started: stopped.
- Agents: <models × counts>, max <N> at once. <Any resumes or failures.>
```
