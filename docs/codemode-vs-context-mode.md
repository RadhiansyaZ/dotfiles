# Codemode vs context-mode

Comparison of Pi's `codemode` tool, a possible Claude Code equivalent, and the context-mode plugin. Findings come from a single investigation on Claude Code 2.1.291 (October 2026). The Claude Code plugin API is in development and may change between builds.

## Pi codemode

Source: https://pi.dev/docs/latest/codemode

- The model sends one JavaScript script as the tool input.
- The script runs in a QuickJS sandbox with no Node APIs, file system, network, or timers. It reaches the outside only through `tools.<name>(args)` and `models`.
- Only the script output returns to the model. Scripts can run calls in parallel and filter large results first.
- Options line: `// @options: {"max_output_tokens": 10000, "timeout_ms": 60000}`. Long output is truncated and written to a temp file.

## Claude Code options

Claude Code has no built-in equivalent. The model calls tools one at a time and each result enters context.

| Approach | Dedicated tool | Calls built-ins | Calls other MCP tools | Sandbox |
|---|---|---|---|---|
| MCP server in a plugin | yes | no | yes, server proxies | strong (QuickJS in the server) |
| Skill and helper CLI through Bash | no | no, shell equivalents only | no | optional (Deno flags) |
| Hooks module with `$.tool.register` | yes | yes, through `$.tool.call` | yes | see script execution below |

The Claude API has Programmatic Tool Calling (Python in a container, tools defined in the API request). It cannot call Claude Code built-ins, and the Agent SDK does not support it. This comes from a subagent report and was not checked against the docs.

### Hooks-module API

Checked in the type definitions bundled with the plugin-authoring skill.

- `$.tool.register({ name, description, inputSchema })` in `session.start` lists a model-callable tool named `mcp__<plugin>__<name>`.
- A `tool.call` hook on that name serves the call and returns the result.
- `$.tool.call({ tool, ... })` calls any built-in or MCP tool and runs the normal permission checks and other plugins' hooks.
- `$.process.run`, `$.process.spawn`, `$.fs`, and `$.clock` are available.
- The module environment has no `eval`, no `new Function`, and no `WebAssembly`. Model-written JavaScript cannot run directly in the module.

### Script execution

| Option | Method | Trade-off |
|---|---|---|
| A. Bundled JS interpreter | A pure-JS interpreter imported by the module. `tools.x()` maps to `$.tool.call`. | Self-contained and portable, built-ins work. Slower. Async and parallel support depends on the interpreter. |
| B. External runner | Deno or Node through `$.process.spawn`. The script requests tool calls over stdout and the hook answers over stdin. | Fast, real sandbox flags. Needs the runtime installed. Stdin support in `spawn` is unverified. |

## Replacing context-mode

| context-mode feature | Codemode as a hooks module |
|---|---|
| `ctx_execute`: run code, return only printed output | Covered for JavaScript. context-mode runs several languages. |
| `ctx_batch_execute`: parallel commands, filtered output | Covered through parallel `tools.Bash()` calls. The indexing of results is not covered. |
| `ctx_execute_file` | Covered through `tools.Read()` or `tools.Bash()`. |
| Call Claude Code built-ins | Covered. context-mode's sandbox cannot call them. |
| `ctx_fetch_and_index` and `ctx_search` (FTS5) | Not covered. The module has no Node, WASM, or SQLite. It needs an external process or a file-based index. |
| Session memory across `/compact` and resume | Partly. `$.state` and `$.store` persist values. Capture, indexing, and search would have to be built. |
| PreToolUse redirects | Covered. A `tool.call` hook can deny or rewrite calls. |
| `ctx_stats`, `ctx_doctor`, `ctx_upgrade`, `ctx_insight` | Not covered. |

## Observed context-mode usage

Tool-call counts from Claude Code and Pi session transcripts, October 2026. Names only were counted.

| | Claude Code | Pi |
|---|---|---|
| Session files scanned | 223 (includes subagent transcripts) | 48 |
| context-mode share of all tool calls | 4.3% | 30.6% |
| Execute-type tools (`ctx_execute`, `ctx_execute_file`, `ctx_batch_execute`) | 95% of context-mode calls | 91% of context-mode calls |
| `ctx_execute` alone | 81% | 64% |
| `ctx_search` and `ctx_fetch_and_index` | 4.5% | 9% |
| Other tools (`ctx_stats`, `ctx_doctor`, and similar) | none | one `ctx_stats` call |

Pi's own `codemode` tool had 9 calls in the same period.

Limits of this data:

- Passive features (session memory, automatic indexing, hook redirects) make no tool calls and are not counted.
- Calls redirected by the PreToolUse hook appear under the original tool name.
- Only 14 of 223 Claude Code files use context-mode, so the plugin was probably installed late and the sample is small.

## Assessment

- A codemode tool covering the three execute-type tools would replace most observed context-mode use, with the added ability to call built-ins.
- Search, fetch-and-index, and session memory need an index and are not covered by the codemode design above.
- Whether those features matter is unmeasured. Disabling context-mode for a trial period would show what is missed.

## Unverified

- Programmatic Tool Calling version strings and platform availability.
- Whether `$.process.spawn` accepts stdin (option B).
- Whether a pure-JS interpreter handles parallel async `tools.x()` calls (option A).
- Stability of the hooks-module API across Claude Code builds.

## Related

- `tracker/claude-code-codemode/README.md` – investigation record and open decisions.
