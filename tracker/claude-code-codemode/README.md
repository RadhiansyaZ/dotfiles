# Claude Code codemode investigation

Status: `needs-decision`

Session record: whether a Pi-style `codemode` tool can be built for Claude Code as a plugin. Findings are from one session on Claude Code 2.1.291 (2026-10). The plugin API is in development and may change between builds.

## Reference: Pi codemode

Source: https://pi.dev/docs/latest/codemode

- The model writes one JavaScript script as the tool input.
- The script runs in a QuickJS sandbox with no Node APIs, file system, network, or timers.
- It reaches the outside only through `tools.<name>(args)` and `models`.
- Only the script output returns to the model. Scripts can run calls in parallel and filter large results first.
- Options line: `// @options: {"max_output_tokens": 10000, "timeout_ms": 60000}`. Long output is truncated and spilled to a temp file.
- Globals: `tools`, `text()`, `image()`, `console.log()`, top-level `return`.

## Findings

### Claude Code built-in

No codemode equivalent. The model calls tools one at a time and each result enters context.

### Claude API and Agent SDK

- The Claude API has Programmatic Tool Calling (code execution tool `code_execution_20260120` or later, `allowed_callers` on each tool). The model writes Python in a container.
- It only calls tools defined in the API request. It cannot call Claude Code built-ins.
- The Agent SDK has no programmatic tool calling.
- Source: subagent report, not independently verified. Docs: https://platform.claude.com/docs/en/agents-and-tools/tool-use/programmatic-tool-calling

### Plugin approaches

| Approach | Dedicated tool | Calls built-ins | Calls other MCP tools | Sandbox |
|---|---|---|---|---|
| MCP server in a plugin | yes | no | yes (server proxies) | strong (QuickJS in server) |
| Skill + helper CLI via Bash | no | no (shell equivalents only) | no | optional (Deno flags) |
| Hooks module with `$.tool.register` | yes | yes, via `$.tool.call` | yes | see below |

The third row corrects earlier statements in the session that a plugin cannot add a tool without MCP and cannot call built-ins.

### Hooks-module API (verified in the bundled plugin types)

- `$.tool.register({ name, description, inputSchema })` in `session.start` lists a model-callable tool `mcp__<plugin>__<name>`.
- A `tool.call` hook on that tool name serves it and returns the result.
- `$.tool.call({ tool, ... })` calls any built-in or MCP tool. It runs the permission check and other plugins' hooks.
- Also available: `$.tool.list`, `$.process.run`, `$.process.spawn`, `$.fs`, `$.clock`.
- Limit: the module environment has no `eval`, no `new Function`, and no `WebAssembly`. Model-written JS cannot run directly in the module.

### Script execution options

| Option | How | Trade-off |
|---|---|---|
| A. Bundled JS interpreter | Pure-JS interpreter imported by the module. `tools.x()` maps to `$.tool.call`. | In-module, portable, built-ins work. Slower. Async and parallel support depends on the interpreter. |
| B. External runner | Deno or Node process via `$.process.spawn`. Script requests tool calls over stdout, the hook answers over stdin. | Fast, real sandbox flags. Needs the runtime. Stdin support in `spawn` is unverified. |

## Open decisions

1. Scope: shell/CLI orchestration only (decided in session), or built-ins and MCP tools as well. The hooks-module route covers both.
2. Execution option A or B. Recommendation: prototype A first.
3. Location: Claude Code plugin folder, or a Stow package in this repository. A Stow package follows `docs/stow-packages.md`.
4. Safety default: unrestricted user permissions, or an allowlist. Using `$.tool.call` keeps normal permission checks.

## Proposed next steps

1. Write a design note under `docs/` and add it to the AGENTS.md index (repository rule).
2. Prototype option A: `plugin.json`, `hooks/hooks.json`, `hooks/register.ts` with the registered tool and `tool.call` hook.
3. Verify with `claude plugin test`: three parallel `Read` calls, filtered output returned.
4. Run `claude plugin validate` and `git diff --check`.

## Unverified items

- Programmatic Tool Calling version strings and platform availability (subagent report only).
- Whether `$.process.spawn` accepts stdin (option B).
- Whether an Acorn-based interpreter handles async `tools.x()` calls in parallel (option A).
- Stability of the hooks-module API across Claude Code builds.
