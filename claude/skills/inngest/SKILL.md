---
name: inngest
description: "Help with Inngest SDK development. TRIGGER when: user mentions Inngest and is working with any supported language (TypeScript, Go, Python)."
---

# Inngest

Inngest is a durable execution engine. You write functions that are triggered by events or cron schedules, and Inngest handles retries, scheduling, and state management.

## Core Concepts

### Steps

Steps are the fundamental unit of durable execution. All non-deterministic code (IO, randomness, timestamps) must go inside a step. Step results are memoized and replayed consistently across retries.

Steps cannot be nested inside other steps.

### Step Types

- **Run** - Execute a unit of work with automatic retryability
- **Invoke** - Call another Inngest function like an RPC
- **Send Event** - Emit an event to trigger other functions
- **Wait for Event** - Pause execution until a matching event arrives
- **Sleep** - Pause execution for a duration

### Events

Events trigger functions. Event names should be namespaced (e.g., `app/user.created`). Events carry a `data` payload that can be schema-validated.

### Cron Triggers

Functions can be triggered on a schedule using cron expressions instead of events.

### Parallelism

Steps can run concurrently. The specifics depend on the language SDK.

## How to Use

1. Detect the language from the project (check for `package.json`, `go.mod`, `pyproject.toml`, etc.).
2. Read the language-specific reference:
   - TypeScript/JavaScript: read `references/typescript/typescript.md`
3. If a language-specific reference doesn't exist yet, use the core concepts above and the official docs at https://www.inngest.com/docs.
4. Ask the user what they want to build if not specified.
5. Find the existing Inngest client in the project before creating files.
6. Use steps for any operation that should be independently retryable.
