---
name: inngest-ts
description: "Help with Inngest TypeScript SDK development. TRIGGER when: user mentions Inngest and is working with JavaScript or TypeScript."
---

# Inngest v4 TypeScript SDK

This skill covers the Inngest **v4** SDK only. If the project uses v3 (check `package.json` for `"inngest": "^3"`), tell the user this skill only covers v4 and link them to the migration guide: https://www.inngest.com/docs/reference/typescript/v4/migrations/v3-to-v4

## Creating a Client

```ts
import { Inngest } from "inngest";

const inngest = new Inngest({ id: "my-app" });
```

- The client is typically defined once in a `client.ts` file and imported by all functions.

## Creating a Function

```ts
import { eventType } from "inngest";
import { inngest } from "./client";

const userSignup = inngest.createFunction(
  { id: "user-signup", triggers: [{ event: eventType("user.created") }] },
  async ({ event, step }) => {
    // Function logic here
  },
);
```

- Look for the existing Inngest client import path in the project.
- Keep the function ID kebab-cased and descriptive.
- Keep event names namespaced with a slash (e.g., `app/user.created`).

## Typed Events with eventType()

Use `eventType()` for typed, validated events:

```ts
import { eventType } from "inngest";
import { z } from "zod";

const userCreated = eventType("user.created", {
  schema: z.object({ userId: z.string(), email: z.string() }),
});

inngest.createFunction(
  { id: "on-user-created", triggers: userCreated },
  async ({ event }) => {
    // event.data is typed and validated
  },
);
```

Use `staticSchema<T>()` for type-only (no runtime validation).

## Cron Triggers

```ts
inngest.createFunction(
  { id: "daily-cleanup", triggers: [{ cron: "0 0 * * *" }] },
  async ({ step }) => {
    // Runs daily at midnight
  },
);
```

## Steps

All non-deterministic code must go inside a `step.run()`. This includes:

- IO: database reads/writes, HTTP requests, file access
- Pseudo-random calls: `Date.now()`, `Math.random()`

This ensures results are memoized and replayed consistently across retries. `step` methods cannot be nested inside other `step` methods.

```ts
const result = await step.run("fetch-user", async () => {
  return db.users.find(event.data.userId);
});

await step.sleep("cooldown", "1h");

await step.run("send-email", async () => {
  await sendEmail(result.email);
});
```

### Step Types

- `step.run(id, fn)` - Run a unit of work with retryability
- `step.invoke(id, { function, data })` - Call another Inngest function like an RPC
- `step.sendEvent(id, eventPayload)` - Send an event
- `step.waitForEvent(id, { event, timeout })` - Pause execution until a specific event is received
- `step.sleep(id, duration)` - Sleep for a duration (e.g., `"1h"`, `"30m"`)

### Parallel

Run steps concurrently with `Promise.all()`:

```ts
const [user, order] = await Promise.all([
  step.run("fetch-user", () => db.users.find(userId)),
  step.run("fetch-order", () => db.orders.find(orderId)),
]);
```

Use `Promise.race()` with `group.parallel()` to act on the first step to complete:

```ts
const fastest = await group.parallel(async () => {
  return Promise.race([
    step.run("api-primary", () => fetchFromPrimary()),
    step.run("api-fallback", () => fetchFromFallback()),
  ]);
});
```

Without `group.parallel()`, `Promise.race()` waits for all steps to settle before resolving.

## Durable Endpoints

Durable endpoints let you use steps directly inside API route handlers, without creating a full Inngest function.

The client needs an `endpointAdapter` for the framework:

```ts
import { Inngest } from "inngest";
import { endpointAdapter } from "inngest/next";

export const inngest = new Inngest({
  id: "my-app",
  endpointAdapter,
});
```

Then use `inngest.endpoint()` to wrap a route handler, importing `step` from `"inngest"`:

```ts
import { step } from "inngest";
import { inngest } from "@/inngest/client";

export const POST = inngest.endpoint(async (req: NextRequest) => {
  const msg = new URL(req.url).searchParams.get("name");

  const greeting = await step.run("create-greeting", async () => {
    return `Hello, ${msg}!`;
  });

  return Response.json(greeting);
});
```

Durable endpoints cannot read request bodies yet. Pass data via query params.

## Local Development

The SDK defaults to cloud mode. For local development:

- Set `INNGEST_DEV=1` in your environment. Best in the `package.json` dev script.
- Run the Inngest Dev Server with the Inngest endpoint URL: `npx --ignore-script=false inngest-cli@latest dev -u http://localhost:3000/api/inngest` (replace `3000` with their port)

## Logging

See https://www.inngest.com/docs/reference/typescript/logging

## Production

- Set `INNGEST_SIGNING_KEY` env var. Get it from https://app.inngest.com/env/production/manage/signing-key
- Set `INNGEST_EVENT_KEY` env var. Get it from https://app.inngest.com/env/production/manage/keys
- `INNGEST_DEV` is not needed. The SDK defaults to cloud mode.

## Instructions

1. Ask the user what they want to build if not specified.
2. Find the existing Inngest client in the project before creating files.
3. Use steps for any operation that should be independently retryable.
