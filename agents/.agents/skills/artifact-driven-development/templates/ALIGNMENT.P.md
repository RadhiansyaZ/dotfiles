# Generate design from alignment

Read approved ALIGNMENT.md and relevant repository instructions and source.

Produce a candidate DESIGN.md using its template. Preserve approved scope and constraints. Reference acceptance criteria by ID.

Specify:
- Interfaces, types, invariants, relevant files, and existing conventions.
- Successful execution flow and task dependencies.
- Expected failures, recovery, validation boundaries, and resource lifetimes.
- UI states and accessibility behavior when applicable.
- Verification commands, expected outcomes, and coverage of acceptance criteria.

Include brief rationale for consequential decisions. Keep the design sufficient for bounded implementation by the user's cheaper model tier. Avoid unnecessary detail.

If requirements conflict or a missing requirement prevents design, report the evidence and ask for alignment revision. Identify unresolved technical decisions explicitly.

Return a candidate or proposed diff plus questions requiring approval. Preserve approved manual edits. Do not implement code or mark the design approved.

Input order: stable instructions, this prompt, output format, stable relevant context, approved ALIGNMENT.md, current revision instructions.
