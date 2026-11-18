# Alignment message template (phase 2)

Send this after recon. Keep it short enough to read in two minutes. Fill in every section with what
recon showed; do not pad sections that have nothing to say. Say what you read so far ("light recon only:
inventory script, root READMEs, reference doc"), so the user knows nothing deep has happened yet.

---

## What I understand

- **Job**: read-only scouting of <product> as built. Document it. No code changes.
- **Reader**: <who, and what they need – for example "you, new to the project, onboarding on the product">.
- **Truth order**: code > repository docs > reference doc. Conflicts are logged, not fixed.
- **Reference doc role**: <none | "PRD written after the build, a target rather than a description – used
  as a lens and for an alignment file">.
- **Business view**: <user journeys from the UI | API consumer view: callers, endpoints / commands, what
  they get back>.
- **Out of scope**: <items the user named, plus anything recon suggests, such as vendored code or
  generated clients>.

## What recon shows

| Repo | Branch now | Origin default | Source lines | UI | Notes |
|---|---|---|---|---|---|
| `<name>` | `<branch>` | `<default>` | <n> | yes / no | <largest files, legacy root files, many stale docs, …> |

## Proposed output

```
<output dir>/
  README.md                     index, baseline, evidence levels, key statements, findings, limits
  business/
    journeys.md                 per journey: goal, what the user does, what the system does, where it hurts
    feature-inventory.md        every user-visible feature (or consumer-facing capability)
    reference-alignment.md      only with a reference doc: built vs each position
  technical/
    overview.md                 stack, system context, runtime topology, module map
    flows.md                    end-to-end flows across repos
    doc-vs-code.md              conflict log (generated)
    <repo or layer>/<module>.md one per reader scope
  feature-map.html              one offline file built from the .md sources
```

## Scope plan

| # | Scope | Main paths | ~Lines | Model | Why this model | Output files |
|---|---|---|---|---|---|---|
| 0 | Inventory: routes, live vs dead, env names | all repos | – | haiku | mechanical | `technical/<repo>/http-api.md`, `legacy-files.md` |
| 1 | <scope> | `<paths>` | <n> | sonnet / opus | <one line> | `<files>` |

At most <N> agents run at once; the rest queue. Cost drivers: <the Opus scopes>.

## Assumptions – correct any that are wrong

1. "Feature map" means an as-built map, not a design for the future.
2. Static reading is primary. <Runtime check: proposed / not proposed, and what it would cover>.
3. `.env` values are never read into docs; variable names only.
4. Downstream systems are documented only as far as this code shows.
5. <Persona assumption – one persona unless the reference doc defines roles>.
6. <Anything recon raised: legacy vs live code, monorepo boundaries, generated code>.

## Decisions needed

1. **Baseline** – which branch or ref per repo? <Recommendation: origin default, or `main` if that is
   what is deployed. Name the difference if the current branch differs.>
2. **Output directory** – where should the docs go? <Recommendation, for example the parent folder of the
   targets when they are separate repos, so no repo gets untracked files.> Or give a custom path.
3. **Runtime check** – may I start the app locally to confirm routes and startup? <What it needs: Docker,
   a venv, ports. What I will not do: LLM calls, auth bypass, side-effect endpoints.>
4. **Reference doc** – <if given: confirm its role; if not: "Is there a PRD, spec or ticket set I should
   compare against?">
5. **Depth** – <Recommendation: full inventory of everything, deep reading on the core paths: list them.>
6. **Parallel limit** – <N> agents at once. Change it?
7. <Any open question recon raised. Drop this item if there is none.>

Answer these and I start.
