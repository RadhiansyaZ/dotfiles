# BMAD shared skills

This repository records shared [BMAD v7 preview](https://github.com/bmad-code-org/BMAD-METHOD)
skills from upstream `main`. The installed module manifests currently identify it as
`6.13.0-next`; upstream describes this development line as v7 preview alpha.
Expect breaking changes.

## Install or restore

Prerequisites: Git, Node.js/npm, and `uv`. The preview setup script requires Python
3.11 or newer; `uv` can provision that runtime. Unix dotfiles provisioning already
includes Node and `uv`. On native Windows, ensure Node/npm are available separately.

After deploying the dotfiles `agents` package, run:

```sh
npx --yes skills add bmad-code-org/BMAD-METHOD --skill '*' --global --agent pi --yes
```

This installs all upstream skills into `~/.agents/skills`, shared across projects
and discoverable by Pi and Codex. The initial installation contains 33 skills,
including the `bmad` hub and module records `bmod-core-tools`, `bmod-method`, and
`bmod-toolsmith`. Module records are metadata; do not invoke them as workflows.

The CLI records sources and folder hashes in the tracked
`agents/.agents/.skill-lock.json`. Existing skills are preserved. Downloaded BMAD
files remain machine-local, following the repository's third-party skills policy.
`setup.sh` and `setup-windows.ps1` do not download these skills automatically;
run the command above on each machine. It restores the latest upstream contents,
not an immutable snapshot of the lockfile hashes. Review the lockfile diff afterward.

Claude Code uses a separate skills directory. To enable it too, rerun the command
with `--agent pi claude-code --copy`; copies avoid adding unmanaged repository links.

## Try it in another project

From the target project's root:

```sh
cd /path/to/project
pi
```

In Pi, reload skills if the session predates installation, then run:

```text
/reload
/skill:bmad bmad setup
/skill:bmad bmad status
/skill:bmad-build Implement <a small, clearly scoped change>
```

Setup asks for configuration and creates the project's `_bmad/` runtime. Keep
that project's configuration and artifacts there. No `_bmad/` installation is
needed inside dotfiles to make the shared skills available elsewhere.

## Pick the next workflow

Start with the smallest path that fits the work:

| What you need | Run in Pi |
| --- | --- |
| Guidance on what to do next | `/skill:bmad What should I do next for <goal>?` |
| A small feature or bug fix | `/skill:bmad-build Implement <change>` |
| Turn detailed notes into a spec | `/skill:bmad-spec Create a spec from <notes or file>` |
| Split a spec into stories | `/skill:bmad-ticket Break <spec folder> into stories` |
| Implement a planned story | `/skill:bmad-build Implement <ticket path>` |
| Review existing changes | `/skill:bmad-code-review Review the current diff` |

For a larger change, use `bmad-spec`, then `bmad-ticket`, then `bmad-build` per
story. If the idea is still vague, ask `bmad` whether a product brief, research,
UX, or architecture work would help first. These are optional steps.

For an existing codebase, start with a small change or ask `bmad` for guidance.
Use a fresh agent context for each substantial workflow and pass the relevant
artifact or ticket path. Review generated project files before committing, and
keep personal `_bmad/custom/*.user.toml` answers ignored.

## Updates and cautions

Rerun the install command to refresh only BMAD from upstream, then run `bmad setup`
in each project to refresh its runtime. Review and commit the dotfiles lockfile
change. `npx skills update --global --yes` updates all global skill sources.

Global installation affects every project on this machine and stays installed
when switching Git branches. Preview skills run with the coding agent's full
permissions. The installer's automated scanners reported alerts for several
skills; these are signals to review, not a security certification. Start in a
throwaway project or a clean test branch.

## Move to stable v7 when available

Checked on **2026-10-13**: the latest official stable release is
[v6.12.2](https://github.com/bmad-code-org/BMAD-METHOD/releases/tag/v6.12.2).
The upstream README labels v7 **preview alpha**. Stable v7 is not available yet.
`npx bmad-method install` currently installs the stable v6 line; it is not a
v7 upgrade command.

When you want to switch:

1. Check the [official releases](https://github.com/bmad-code-org/BMAD-METHOD/releases)
   and [installation README](https://github.com/bmad-code-org/BMAD-METHOD#start-building).
   Confirm that a v7 release is marked stable, not alpha, beta, or release candidate.
2. Commit or back up each project's BMAD configuration and planning artifacts.
   Follow that release's installation and migration instructions. The current
   shared-skills command follows upstream `main`, so rerunning it alone does not
   guarantee a stable version.
3. Reload Pi, then run `/skill:bmad bmad setup` and `/skill:bmad bmad status`
   in each project. Review any proposed updates before applying them. Setup may
   update skills globally, affecting other projects too.
4. For an older v6 project's planning artifacts, ask
   `/skill:bmad bmad migrate method`. Review and approve its migration plan first.
   This migrates project artifacts; it does not select a stable release.
5. Try a small build, review the project and dotfiles lockfile diffs, and commit
   the intended changes.

No skills or project runtimes are upgraded automatically by this documentation.

## Official references

- [Documentation home](https://docs.bmad-method.org/)
- [Build your first change](https://docs.bmad-method.org/start/build-your-first-change/)
- [Start in an existing codebase](https://docs.bmad-method.org/existing-codebases/start-in-an-existing-codebase/)
- [Choose a planning path](https://docs.bmad-method.org/plan/choose-a-planning-path/)
- [Installation and release status](https://github.com/bmad-code-org/BMAD-METHOD#start-building)
- [Release history](https://github.com/bmad-code-org/BMAD-METHOD/releases)
- [Setup flow](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/skills/bmad/references/setup.md)
- [Migration flow](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/skills/bmad/references/migrate.md)

The docs and `main` branch change during the preview. For stable v6, use the
[V6.12 source and documentation](https://github.com/bmad-code-org/BMAD-METHOD/tree/V6.12).
