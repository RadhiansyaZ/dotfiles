# Claude Code workflow authoring

## Overview

`/workflow-authoring` is a bundled Claude Code skill for writing and modifying dynamic workflow scripts. No third-party plugin is required.

The skill loads the script-writing reference into Claude's context. Claude writes JavaScript that coordinates subagents through Claude Code's workflow runtime. The skill supplies authoring instructions; the runtime executes the scripts.

## Requirements

- Claude Code v2.1.248 or later for the authoring skill.
- Dynamic workflows enabled. On Pro, enable them in `/config`.
- Dynamic workflows are available on paid plans, with Anthropic API access, and through supported cloud providers.

## How it works

1. Describe a task and request a workflow.
2. Claude writes an orchestration script.
3. The runtime executes the script in the background and launches subagents.
4. The script coordinates parallel work, verification, and any programmed retry loops.
5. Results return to the conversation.

Intermediate results stay in script variables, reducing coordination held in the main conversation.

The script uses plain JavaScript with top-level `await` and workflow helpers:

| Helper | Purpose |
| --- | --- |
| `agent()` | Launch a subagent, optionally returning schema-validated JSON |
| `pipeline()` | Process a list through agent tasks |
| `parallel()` | Run multiple agent tasks concurrently |

JavaScript loops and branching support iterative fixes and verification. Saved scripts include an exported `meta` object with their name and description.

## Usage

Load the authoring reference:

```text
/workflow-authoring
```

Then describe the workflow:

```text
Create a workflow that reviews changed files in parallel, independently verifies each finding, and returns a deduplicated report. Show me the script before running it.
```

You can also ask Claude to “use a workflow” without loading the authoring skill explicitly. Loading the skill is particularly useful before editing a saved script.

## Manage and reuse workflows

| Action | Command or location |
| --- | --- |
| Monitor runs | `/workflows` |
| Pause or resume a selected run | `p` in the workflow view |
| Save a run as a reusable command | `s` in the workflow view |
| Store project workflows | `.claude/workflows/` |
| Store personal workflows | `~/.claude/workflows/` |
| Reload edited scripts | `/reload-skills` |
| Run a saved workflow | `/<name>` |

Saved workflows are `.js` files. They can accept structured input through the global `args` value.

Completed agent results are retained for resumption within the same session. After leaving Claude Code, resume the original session and ask Claude to relaunch the workflow. Starting a fresh session starts a new run. Changes to agent call ordering or inputs can cause previously completed work to run again.

## Operational considerations

- Workflows can consume substantially more tokens than ordinary conversation. Start with a narrow task.
- Workflow subagents remain subject to session permission rules and sandboxing. Launch approval depends on permission mode.
- Parallel editing needs explicit ownership or isolation to avoid conflicting changes.
- `/effort ultracode` enables automatic workflow orchestration for the session. It is optional when explicitly requesting a workflow.
- If workflows are disabled, `/workflow-authoring` and workflow commands are unavailable.

## Sources

- [Official dynamic workflow documentation](https://code.claude.com/docs/en/workflows)
- [Authoring and editing saved scripts](https://code.claude.com/docs/en/workflows#edit-a-saved-script)
- [Anthropic introduction](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code)

Version requirements and availability reflect the documentation consulted for this research and may change.
