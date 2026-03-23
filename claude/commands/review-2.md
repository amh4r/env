---
description: "Review a PR using focused subagents for quality, bugs, and security"
allowed-tools: "Bash(git diff*), Bash(gh pr view*)"
---

Gather context for the review:

1. Get the diff by running `git diff` against the base branch
2. Get a description of the changes from one of these sources (in priority order):
   - The user's argument to this command, if provided (e.g. `/review-2 adding retry logic to the ingest pipeline`)
   - The PR description, if a PR exists for the current branch (`gh pr view`)
   - If neither is available, ask the user to briefly describe what the changes do and why

Then spawn three subagents **in parallel**, one for each of the following agents:

1. **code-quality** agent
2. **bug-finder** agent
3. **security-reviewer** agent

Include the full diff and the description (if available) in each subagent's prompt. The subagents have Read, Grep, and Glob tools to explore surrounding code for context, but the diff is their starting point and primary focus. The purpose of using subagents is to keep context small and stay focused. Each subagent must return its findings.

Once all three complete, write `review-summary.md` that combines their results. The summary should:

- Group findings by agent (code quality, bugs, security), with a section for each
- Within each section, list findings sorted by severity (critical > high > medium > low)
- Omit agents that had no findings rather than listing "no issues found"
- If all agents found nothing, say so in one line
