# Reader prompts (phase 5)

Every prompt is short because the shared rules live in `BRIEF.md`. A prompt names the format, the scope,
the boundaries, the key questions, the output files and the reply contract. Key questions do most of the
work: they decide what the reader looks for. Write them from three sources:

1. The bank for the module type below.
2. The reference doc, if there is one. Turn each position or complaint it makes that touches this scope
   into a question the code can answer. Example: the PRD says "same query gives different results" →
   "Anything that could make the same request return different results across sessions? Cache, memory,
   ordering, randomness?"
3. Recon and earlier reports. Example: the inventory shows a `legacy/` folder → "Which files under
   `legacy/` are imported by live code?"

Call shape (every reader):

```
Agent(subagent_type="general-purpose", model="<haiku|sonnet|opus>",
      description="<3-5 words>", prompt=<filled template>)
```

## Inventory template (Haiku, wave 1)

```
First read <S>/BRIEF.md and follow its hard rules and writing rules. Formats A/B/C do not apply to you.

YOUR TASK: mechanical inventory of <repo(s)> for other readers to build on. Extract; do not interpret.

1. Entry points: how the app starts (<main files, CLI entry, server bootstrap>), cited.
2. Route / command table for EVERY router, controller or command registered from the entry points:
   method | path or command | handler file:line | auth dependency or decorator | streaming? | one-line purpose
   from the handler name or docstring. <If a runtime route list exists, give it: "the running app exposes
   N routes under prefixes …; account for all of them".>
3. Live vs dead files: for each source file outside <main package dirs>, is it imported (directly or
   transitively) from an entry point? Table: file | live / dead | evidence (importing file:line, or the
   grep with no hits).
4. Config: every env var name read in code | file:line | default present (yes/no – never the value).
5. External services named in config or clients: name | env var | client file:line.

OUTPUT files:
- technical/<repo>/http-api.md (or cli-commands.md) – item 2
- technical/<repo>/legacy-files.md – item 3
- technical/<repo>/config.md – items 1, 4 and 5

FINAL REPLY (under 300 words): files written; route or command count by prefix; count of dead files;
external services list.
```

## Module reader template (Sonnet / Opus, wave 2)

```
First read <S>/BRIEF.md and follow it exactly. Use Format <A|B|C>.<For Opus scopes with LLM steps: " Mark
every call-graph node [LLM] or [code].">

YOUR SCOPE: <one line>.
- `<path/glob>` (<note: "4.5k lines, read fully in chunks">)
- `<path/glob>`
- Repository docs to compare against code: `<doc paths>`
Other readers cover <other scopes>; for those document only the call edges in and out (function +
file:line).<If inventory exists: " Inventory files under technical/<repo>/ list live vs dead files and
routes; use them.">

KEY QUESTIONS (answer each with evidence):
- <5–10 questions: bank + reference doc + recon>

OUTPUT files:
- <path>.md (<what goes in it; which Mermaid diagrams are required>)

FINAL REPLY (under <400–700> words): files written; <the scope's core sequence in ~10 lines>; one or two
lines with cite per key question; doc-vs-code conflicts; anything you could not verify.
```

## Key-question banks by module type

Pick the questions that apply. Rephrase them with the module's real names.

**Platform / entry / config / auth**
- Startup sequence: what must be reachable for the app to start, and what is optional?
- Auth: scheme, token validation, where it is enforced, routes with no auth, debug bypasses.
- Middleware order and what each layer does to requests and logs (token or PII logging?).
- Persistence: stores, collections or tables, who owns each, per-user isolation.
- Observability: logging, tracing, metrics; what leaks into logs.

**Request / turn lifecycle (chat, job, request pipeline)**
- Full lifecycle of one request: entry → service → each stage → persistence → response. Every
  branch condition.
- Catalogue of response or stream event types: name | payload | when | cite.
- How structured results reach the client (inline, separate fetch, stored artifact).
- Cancellation, timeouts, and what the user sees on each failure.

**LLM / agent orchestration / planner** (usually Opus)
- Which steps call an LLM and which are deterministic code? How many LLM calls per request?
- Plan or graph data model: nodes, routing conditions, loops, recursion limits.
- Where numbers in the final answer come from: tool output passed through unchanged, or rewritten by the
  LLM? Any check afterwards?
- Validation and repair: what is rejected, what is auto-fixed, maximum attempts.
- Memory and state across turns: what persists, where, and can it override fresh input?
- Provider configuration: which providers and models, defaults in code, timeouts, retries.
- Prompt or language handling for the user's language(s).

**Tools / integrations / downstream systems**
- Catalogue: tool or client | inputs | output shape | downstream endpoint | what the user sees | cite.
- Per downstream: base URL env var name, auth method (user token or shared service account), timeouts,
  retries (including retries on non-idempotent calls).
- Side effects: anything that creates, orders, sends or deletes in another system; how it is gated.
- Determinism: candidate selection, ordering, caching, fuzzy matching.
- Any non-company internet service called at runtime.

**Data / documents / search / RAG**
- Ingestion: upload → parse (types, size limits) → chunk → embed (model, local or remote) → index.
- Retrieval: when it runs, in which modes, how sources are shown to the user.
- Isolation and deletion per user or tenant.
- Live vs dead scripts around the pipeline.

**Frontend non-visual (stores, API clients, streaming)**
- Boot: auth flow, token storage and refresh, route guards, initial data loads.
- Route table. Each store: state shape, actions, callers, persistence.
- API client table: function | method + path | backend route exists? | used by. Flag calls with no
  backend route and unused functions.
- Stream handling: transport, every event type handled and what it does to state, events ignored.
- Error and auth-expiry handling in the API layer.

**Frontend UI surfaces** (Format B; also writes `business/feature-inventory.md`)
- ASCII wireframe of the main screen after sign-in. What is the primary surface?
- Inventory of every user-visible feature: name | where | what the user does | what happens | cite |
  direct control or via <chat / form / other>.
- For each capability the reference doc asks for: exists / partly / absent, with evidence.
- UI that sends the user to another platform. Raw or machine output that can reach the user.
- Dead components. Unsanitised HTML rendering.

**API consumer surface** (Format C, no UI; also writes `business/feature-inventory.md`)
- Who calls this (other services, CLI users, SDK users, webhooks), per the code and docs?
- Capability inventory grouped by consumer goal: capability | operation | what the caller sends | what
  comes back | cite.
- Error contract: consistent error shape? Status codes used correctly? What leaks (stack traces)?
- Pagination, idempotency, versioning, rate limits.
- Contract drift between OpenAPI / README / SDK and handlers.

**Jobs / workers / schedulers**
- Triggers (cron, queue, event), concurrency, retries, dead-letter handling, idempotency.
- What happens on a crash halfway through a job; what is left inconsistent.
