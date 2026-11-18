# Shared brief template (phase 4)

Copy everything below the line into `<S>/BRIEF.md` and fill in the `<…>` fields. Every reader reads this
file first, so the rules live here once instead of being repeated in each prompt. Keep Formats A, B and
C as written. They adapt the "Design Thinking" (A / E / R) and "Design Graph" (C / V / N) method from
r17x's public gist to documenting existing code.

---

# Shared brief – <Product> feature map (read fully before starting)

You are documenting part of "<Product>": <one or two sentences – stack and what users do with it>. This
is a read-only scouting job. The reader is <reader>, who needs onboarding on the product as it is built.

## Hard rules
- Code is the source of truth. Repository `.md` docs are often stale; compare them, never trust them.
- Do not modify anything in the repositories. Do not run the app. Do not call any network service.
- Do not read or copy values from any `.env` file. Variable names taken from config code are fine.
- Do not summarise the content of business or client documents stored in data folders
  (<list folders from recon, for example `documents/`, `seed/`, `fixtures/`>). Note that they exist.
- Security weaknesses: describe them with a cite. Do not write exploit steps.
- Write only the output files named in your task. **Write each file as soon as its content is ready.**
  Do not hold everything until the end: if you are stopped, written files survive and you will be
  resumed.

## Source (snapshot of `<ref>`, read from here only)
- <repo>: `<S>/snapshot/<repo>`
- <repo>: `<S>/snapshot/<repo>`
- Cite as repo-relative paths with line numbers, always including the repo prefix:
  `<repo>/path/to/file.py:120`, `<repo>/src/stores/x.ts:88-95`. Never a bare file name, never the
  snapshot path.
- Other readers' files may already exist under the output root. Link to them; do not rewrite them.
- If an inventory file exists (`technical/<repo>/legacy-files.md` or similar), use it to skip dead code.

## Output root
`<output dir>/` (create sub-directories as needed)

## Format A – code modules (channels A / E / R)
For backend modules, non-visual frontend modules, workers, libraries. One section per module:
1. **Purpose** (1–3 sentences) and **Status**: live / partly live / dead, with import or grep evidence.
2. **Shapes** – records, IDs, variants or states, named errors (with cites).
3. **Call graph** – plain text in a ```ts code block, indented `→` arrows for hierarchy, no rendered
   diagram. Annotate nodes inline: `A:` data in → out, `E:` failure handling, `R:` dependencies. Where
   an LLM is involved mark the node `[LLM]`, otherwise `[code]`. Example:
   ```ts
   POST /api/x                      A: XRequest → SSE<Event>   R: Mongo, auth user
     → XService.run [code]          E: timeout → retry x2, then error event
       → planner.classify [LLM]     E: parse fail → repair x1
         → httpx → Downstream       R: DOWNSTREAM_URL
   ```
4. **Cardinality** – one-shot, stream or paginated, per node.
5. **E table** – break point | kind (retry / escape-fallback / die / unhandled) | behaviour | cite.
6. **R** – dependencies: env var names, external services, DB collections or tables, queues, browser APIs.
7. **Boundary** – where untrusted input (user text, uploaded files, LLM output, downstream responses)
   is validated, and where it is not.
8. **Diagrams** – Mermaid sequence or flowchart for data flow where it helps. Call graphs stay plain
   text. Quote Mermaid labels that contain `;`, `:`, `(` or `"`.
9. **Doc vs code** – heading must contain "Doc vs code". Table: repo doc + line | what it says | what
   the code does + cite.
10. **Unverified / open questions.**

## Format B – visual UI surfaces (channels C / V / N)
For screens, panels, modals and other things a person looks at. One section per surface:
1. **Surface** name, purpose, Status (mounted / dead, with evidence from the component tree).
2. **Units, states, moves** – the things inside it, the states they can be in, what the user can do.
3. **Flow graph** – plain text in a ```ts block, indented `→` arrows, annotated with `C:` content,
   `V:` void states handled, `N:` needs. Example:
   ```ts
   MainApp                              N: signed-in user
     → Sidebar(ChatList)                C: chats[]   V: empty ✓, loading ✓, error ✗
       → select chat → ChatInterface    N: activeChatId
         → "View map" → MapPopup        N: message has map layers
   ```
4. **Cardinality** – detail / list / live.
5. **V table** – state (empty, loading, partial, error, denied) | designed? | what the user sees | cite.
6. **N** – needs: auth, selected record, data, permission, viewport.
7. **Attention scope** – modals and overlays: how each opens and how it is dismissed (Esc, outside click,
   button, none).
8. Mermaid flowchart of navigation where useful.
9. **Doc vs code** table.
10. **Unverified / open questions.**

## Format C – API consumer surfaces (channels C / V / N, for products with no UI)
For HTTP / gRPC endpoints, CLI commands, SDK public functions, webhooks: what a caller sees. One section
per resource or command group:
1. **Surface** – group name, the consumer job it serves, Status (mounted / registered / dead).
2. **Operations and resources** – operations, resource IDs, versions, pagination model.
3. **Flow graph** – a ```ts block of the consumer's moves, annotated with `C:` request → response shape,
   `V:` failure states handled, `N:` needs. Example:
   ```ts
   POST /orders                C: OrderCreate → 201 Order    V: 422 ✓, 409 duplicate ✓, 5xx raw ✗   N: bearer, customer exists
     → GET /orders/{id}        C: → Order                    V: 404 ✓                              N: order id from POST
       → POST /orders/{id}/pay C: PaymentReq → 202 + webhook V: timeout ✗                          N: idempotency key
   ```
4. **Cardinality** – single / list with pagination / stream (SSE, websocket) / async (job + poll,
   webhook).
5. **V table** – state (not found, validation, unauthorised, forbidden, rate limited, conflict, partial,
   timeout, downstream down) | handled? | what the caller receives (status + body shape) | cite.
6. **N** – auth scheme, scopes or roles, required headers, prior resources, quotas.
7. **Boundary** – input validation at the edge: schema, size limits, what reaches the core unchecked.
8. **Contract drift** – OpenAPI / README / client SDK vs actual handler behaviour.
9. **Doc vs code** table.
10. **Unverified / open questions.**

## Writing rules
- Concise, plain English. En dashes (–). Never em dashes. No metaphors, no filler.
- Every factual claim needs a `repo/path:line` cite. If you could not verify something, write
  "unverified".
- Read large files fully, in chunks. Do not guess from file names or function names.
- Tables over prose for anything list-shaped.

## Final reply to the coordinator
Keep it under the word limit in your task. Facts with cites only, no narration of your process. Start
with the list of files written.
