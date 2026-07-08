---
name: writing-spec
description: Use when writing, reviewing, revising, outlining, or critiquing technical specs, design docs, RFCs, proposals, implementation plans, or engineering requirements. Follow the preferred spec structure, audience split, section depth, and style for explaining problems, solutions, risks, release plans, context, implementation details, alternatives, research, and references.
---

# Writing Specs

Write specs for two audiences:

- Technical leaders need to understand the decision and risk quickly.
- Developers need enough detail to implement the solution without reconstructing the reasoning.

Keep the leader-facing sections high-level and brief. Put implementation detail, investigation notes, and deep tradeoff analysis in the developer-facing sections.

## Section Order

Use these sections in this order when they apply:

1. Problem
2. Solution
3. Out of scope
4. Risks
5. Release
6. Blocked by
7. Context
8. Implementation
9. Testing
10. Alternatives
11. Research
12. References

Omit sections that truly do not apply. Do not invent fake blockers, risks, research, or alternatives just to fill the outline. If a section matters but information is missing, include it with explicit open questions or `TBD` items.

## Audience Split

Treat these sections as the technical-leader path:

- Problem
- Solution
- Out of scope
- Risks
- Release
- Blocked by

Make these sections skimmable by an engineering manager, CTO, or other technical leader. They must be able to understand the problem, proposed direction, boundaries, key risks, and rollout safety without reading the rest of the spec.

Treat these sections as the developer path:

- Context
- Implementation
- Alternatives
- Research
- References

These sections may be detailed. Use them to preserve the implementation plan, technical decisions, discarded approaches, investigation findings, and useful context for future maintainers.

## Section Guidance

### Problem

Answer: Which problems are we solving?

State the current pain, user impact, operational impact, or product gap. Keep this focused on symptoms, constraints, and goals. Avoid implementation detail and avoid smuggling the solution into the problem statement.

### Solution

Answer: How are we solving the problems?

Describe the proposed approach at the system or product level. Explain the important shape of the solution, why it addresses the problem, and any major behavioral or architectural changes. Keep mechanics and step-by-step work out of this section unless they are necessary to understand the proposal.

### Out of scope

Answer: What are things we explicitly are not doing?

List non-goals and boundaries. Use this section to prevent reasonable but incorrect assumptions about what the spec includes. Be direct and specific.

### Risks

Answer: What could go wrong?

Call out meaningful technical, product, operational, migration, performance, reliability, security, compatibility, and delivery risks. Include mitigations when known. Keep this section leader-readable; detailed test plans and implementation mechanics belong in `Implementation`.

### Release

Answer: How will we safely release the solution?

Describe rollout, gates, migration sequencing, feature flags, monitoring, rollback, support, and validation. Make the safety story clear enough for leadership to assess whether the plan is controlled.

### Blocked by

Answer: What other work must be completed before implementing this solution?

List required dependencies, decisions, migrations, approvals, upstream work, or research. Distinguish hard blockers from helpful prerequisites when that distinction matters.

### Context

Answer: What background is important for understanding the solution?

Document useful context that is not itself the problem, solution, or implementation plan. Include prior art, important existing behavior, related systems, historical decisions, current architecture, constraints, terminology, and business rules. Keep this developer-facing; move only the context required for leadership decision-making into the leader-facing sections.

### Implementation

Answer: How will we implement the solution?

Provide the developer-facing plan. Include phases, code areas, data model or API changes, migration details, observability, cleanup work, and edge cases as needed. This section can be in-depth because it is not the leader path.

### Testing

Answer: How will we test the implementation?

Document the critical behaviors that need testing. Tests must be valuable; do not test for the sake of testing.

### Alternatives

Answer: What else did we consider?

Document meaningful alternatives and why they were not chosen. Preserve tradeoffs, not strawmen. Include enough detail that future readers understand why the selected approach was preferred.

### Research

Answer: What research findings are worth documenting?

Capture investigation notes, constraints discovered, prior behavior, production data, benchmarks, dependency behavior, and other findings that support the spec. Prefer concise findings with evidence over a chronological research diary.

### References

Answer: What related things are worth noting?

Link relevant docs, issues, PRs, dashboards, specs, code pointers, vendor docs, incidents, or discussion threads. Use this as supporting context, not as a replacement for the spec's core reasoning.

## Style

Readability is critical. Be succinct as much as possible; engineers do not like walls of text.

Prefer clear, direct prose. Use bullets when they make the spec easier to scan. Keep headings stable and predictable.

Write the leader-facing sections so a technical leader can stop there. Do not force leaders to read `Context`, `Implementation`, `Alternatives`, or `Research` to understand the proposed decision.

When reviewing a spec, check first whether the audience split is working. If leader-facing sections are too detailed, move detail down. If developer-facing sections lack enough implementation context, ask for or add the missing specifics.

Use tables sparingly. Putting too much content in them hurts readability when reading the raw markdown file.

Do not use Title Case in headings.

Subheadings are OK. For example, putting `## Testing` within `# Implementation` is OK. In fact, subheadings can be a great way to break up walls of text. 

Do not wrap text yourself.
