---
description: "Thoroughly review a PR using focused subagents"
---

Thoroughly review the changes in this PR. To do so, perform each of the following tasks in a separate agent:

- Find user-facing breaking changes
- Ensure code is readable and maintainable
- Find bugs
- Find security vulns

Each of these sub agents must produce a summary of its review. Then you must create a summary of these summaries, and output it in `review-summary.md`.
