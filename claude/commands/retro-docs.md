Review this conversation and identify information that would help future AI assistants (or contributors) work faster in this codebase. Focus on things that are NOT obvious from reading the code itself:

- Non-obvious gotchas or footguns
- Hot paths or high-frequency code paths that demand extra care
- Domain concepts that map to unexpected implementation details
- Architectural invariants that aren't enforced by the compiler

For each finding:

1. Draft a concise entry (2-3 sentences max). Lead with the actionable rule, then briefly explain why.
2. Decide where it belongs:
  - `CLAUDE.md` (top-level or subdirectory): instructions for AI assistants — patterns, rules, gotchas
  - A non-CLAUDE doc (e.g. `docs/*.md`, `ARCHITECTURE.md`): knowledge useful to humans — domain context, design rationale, subsystem overviews. Reference it from the relevant `CLAUDE.md` so assistants can find it when needed.
3. If placing in a new or existing doc, check whether the top-level `CLAUDE.md` has a pointer to it that someone investigating the relevant topic would find. If not, add one near related content.

Do NOT:
- Duplicate information already in a `CLAUDE.md` file
- Document things obvious from reading the code (function signatures, standard patterns)
- Add entries that are only useful for the current task and not future work

Present the proposed changes and ask for approval before writing.
