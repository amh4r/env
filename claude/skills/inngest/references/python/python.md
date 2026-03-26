# Inngest Python SDK

## Creating a Client

```python
import inngest

inngest_client = inngest.Inngest(app_id="my-app")
```

- The client is typically defined once in a `client.py` file and imported by all functions.

## Creating a Function

Use the `@inngest_client.create_function()` decorator. Choose async or sync based on your framework:

**Async** (FastAPI, Connect):

```python
import inngest
from .client import inngest_client

@inngest_client.create_function(
    fn_id="user-signup",
    trigger=inngest.TriggerEvent(event="app/user.created"),
)
async def user_signup(ctx: inngest.Context) -> str:
    # Function logic here
    return "done"
```

**Sync** (Flask, Django):

```python
import inngest
from .client import inngest_client

@inngest_client.create_function(
    fn_id="user-signup",
    trigger=inngest.TriggerEvent(event="app/user.created"),
)
def user_signup(ctx: inngest.ContextSync) -> str:
    # Function logic here
    return "done"
```

- `inngest.Context` for async functions, `inngest.ContextSync` for sync functions.
- Keep `fn_id` kebab-cased and descriptive.
- Keep event names namespaced with a slash (e.g., `app/user.created`).

## Triggers

### Event Trigger

```python
@inngest_client.create_function(
    fn_id="on-signup",
    trigger=inngest.TriggerEvent(event="app/user.created"),
)
```

`TriggerEvent` accepts an optional `expression` for CEL-based filtering:

```python
trigger=inngest.TriggerEvent(event="app/order.placed", expression="event.data.total > 100")
```

### Cron Trigger

```python
@inngest_client.create_function(
    fn_id="daily-cleanup",
    trigger=inngest.TriggerCron(cron="0 0 * * *"),
)
```

### Multiple Triggers

Pass a list:

```python
trigger=[
    inngest.TriggerEvent(event="app/user.created"),
    inngest.TriggerCron(cron="0 9 * * *"),
]
```

## Steps

All non-deterministic code (IO, randomness, timestamps) must go inside a step. Step results are memoized and replayed consistently across retries.

Steps cannot be nested inside other steps.

### step.run

Run a unit of work with automatic retryability:

```python
# Async
result = await ctx.step.run("fetch-user", fetch_user, user_id)

# Sync
result = ctx.step.run("fetch-user", fetch_user, user_id)
```

The handler function and its arguments are passed separately:

```python
async def fetch_user(user_id: str) -> dict:
    return await db.users.find(user_id)

await ctx.step.run("fetch-user", fetch_user, event.data["user_id"])
```

Or with a lambda/inline function:

```python
user = await ctx.step.run("fetch-user", lambda: db.users.find(user_id))
```

### step.sleep

Sleep for a duration (int milliseconds or `datetime.timedelta`):

```python
await ctx.step.sleep("cooldown", datetime.timedelta(hours=1))
```

### step.sleep_until

Sleep until a specific datetime:

```python
await ctx.step.sleep_until("wait-until-morning", target_datetime)
```

### step.send_event

Send one or more events:

```python
ids = await ctx.step.send_event(
    "notify",
    inngest.Event(name="app/email.send", data={"to": user.email}),
)
```

Send multiple events by passing a list:

```python
ids = await ctx.step.send_event("notify-all", [
    inngest.Event(name="app/email.send", data={"to": email})
    for email in emails
])
```

### step.invoke

Call another Inngest function and get its result:

```python
result = await ctx.step.invoke(
    "process-payment",
    function=payment_fn,
    data={"order_id": order_id},
    timeout=datetime.timedelta(minutes=5),
)
```

Or invoke by ID string:

```python
# Same app
result = await ctx.step.invoke_by_id(
    "process-payment",
    function_id="payment-processor",
    data={"order_id": order_id},
)

# Different app
result = await ctx.step.invoke_by_id(
    "process-payment",
    app_id="other-app",
    function_id="payment-processor",
    data={"order_id": order_id},
)
```

### step.wait_for_event

Pause execution until a matching event arrives:

```python
event = await ctx.step.wait_for_event(
    "wait-for-approval",
    event="app/approval.received",
    if_exp="async.data.request_id == event.data.request_id",
    timeout=datetime.timedelta(hours=24),
)

if event is None:
    # Timed out
    pass
```

- `timeout` is required.
- Returns the matching `Event` or `None` on timeout.

In the expression, `async.data` refers to the data in incoming events and `event.data` is the data in the event that triggered the function run.

## Parallel Steps

Use `ctx.group.parallel()` to run steps concurrently:

```python
# Async
user, order = await ctx.group.parallel((
    lambda: ctx.step.run("fetch-user", fetch_user, user_id),
    lambda: ctx.step.run("fetch-order", fetch_order, order_id),
))

# Sync
user, order = ctx.group.parallel((
    lambda: ctx.step.run("fetch-user", fetch_user, user_id),
    lambda: ctx.step.run("fetch-order", fetch_order, order_id),
))
```

Race mode (return on first completion):

```python
from inngest._internal.server_lib import ParallelMode

fastest = await ctx.group.parallel(
    (
        lambda: ctx.step.run("api-primary", fetch_primary),
        lambda: ctx.step.run("api-fallback", fetch_fallback),
    ),
    parallel_mode=ParallelMode.RACE,
)
```

## Error Handling

### NonRetriableError

Prevent automatic retries:

```python
raise inngest.NonRetriableError("Invalid input, will not retry")
```

### RetryAfterError

Retry at a specific time:

```python
raise inngest.RetryAfterError(
    "Rate limited",
    retry_after=datetime.timedelta(minutes=5),
)
```

### StepError

Raised when a step fails after exhausting all retries. Has `.message`, `.name`, `.stack` properties.

## Framework Integration

### FastAPI

```python
import fastapi
import inngest.fast_api

app = fastapi.FastAPI()

inngest.fast_api.serve(app, inngest_client, functions)
```

### Flask

```python
import flask
import inngest.flask

app = flask.Flask(__name__)

inngest.flask.serve(app, inngest_client, functions)

app.run(port=3939)
```

### Connect (standalone, no web framework)

```python
import asyncio
from inngest.connect import connect

asyncio.run(
    connect(
        apps=[(inngest_client, functions)],
    ).start()
)
```

Requires the `connect` extra: `inngest[connect]`.

## Local Development

- Set `INNGEST_DEV=1` in your environment.
- Use `uv` as the package manager.
- Run with: `INNGEST_DEV=1 uv run ./app.py`

## Production

- Set `INNGEST_SIGNING_KEY` env var. Get it from https://app.inngest.com/env/production/manage/signing-key
- Set `INNGEST_EVENT_KEY` env var. Get it from https://app.inngest.com/env/production/manage/keys
- `INNGEST_DEV` is not needed. The SDK defaults to cloud mode.
