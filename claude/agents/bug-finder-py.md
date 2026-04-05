## Mutability and defaults

### Mutable default arguments

`def f(items=[])` shares the same list across all calls. Mutations accumulate silently. Use `None` as the default and create the container inside the function.

```python
# Bug: shared list accumulates across calls
def append_to(item, items=[]):
    items.append(item)
    return items

append_to(1)  # [1]
append_to(2)  # [1, 2] -- not [2]

# Fix: use None sentinel
def append_to(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items
```

### Shallow copy via slice

`new_list = old_list[:]`, `list(old_list)`, `dict.copy()`, and `copy.copy()` are all shallow copies. Nested mutable objects are shared between the original and the copy.

```python
# Bug: inner lists are shared
grid = [[0] * 3] * 3
grid[0][0] = 1
# grid is now [[1, 0, 0], [1, 0, 0], [1, 0, 0]]

# Fix: create independent rows
grid = [[0] * 3 for _ in range(3)]
```

## Closures and scoping

### Late binding closures

Closures in loops capture the variable, not its value. All closures see the final value of the loop variable.

```python
# Bug: all lambdas return 4
funcs = [lambda: i for i in range(5)]
[f() for f in funcs]  # [4, 4, 4, 4, 4]

# Fix: capture eagerly with default argument
funcs = [lambda i=i: i for i in range(5)]
[f() for f in funcs]  # [0, 1, 2, 3, 4]
```

### Import circular dependencies

Circular imports at module level can cause `ImportError` or attributes being `None`/missing at import time, depending on which module is imported first. The error is often confusing and non-deterministic.

## Exception handling

### `except Exception` too broad

`except Exception` still catches `StopIteration`, `GeneratorExit`, and other flow-control exceptions that should propagate. Be specific about what you catch.

```python
# Bug: swallows StopIteration from a generator
try:
    val = next(gen)
    process(val)
except Exception:
    log("something went wrong")

# Fix: catch only expected errors
try:
    val = next(gen)
    process(val)
except StopIteration:
    log("generator exhausted")
except ValueError as err:
    log(f"processing failed: {err}")
```

### Catching and re-raising without `from`

`raise NewError()` inside an `except` block loses the original traceback. Chain exceptions to preserve context.

```python
# Bug: original traceback is lost
try:
    parse(data)
except json.JSONDecodeError:
    raise ValueError("bad input")

# Fix: chain with from
try:
    parse(data)
except json.JSONDecodeError as err:
    raise ValueError("bad input") from err
```

### `finally` swallowing exceptions

A `return` in a `finally` block silently swallows any exception that was being propagated, including unhandled ones.

```python
# Bug: the ValueError is silently discarded
def get_value():
    try:
        raise ValueError("broken")
    finally:
        return -1  # swallows the exception

get_value()  # returns -1, no error raised
```

## Identity and equality

### `is` vs `==`

`is` checks identity, not equality. CPython interns small integers (-5 to 256) and short strings, so `is` appears to work in tests but fails with larger values in production.

```python
# Bug: works in tests with small numbers, breaks in prod
def check_status(code):
    return code is 200  # True only by accident (interning)

# Fix: use ==
def check_status(code):
    return code == 200
```

### Float as dict key

`float('nan') != float('nan')`, so NaN as a dict key creates entries that can never be retrieved. Also, `1 == 1.0 == True`, so `{1: 'a', True: 'b', 1.0: 'c'}` has one key with value `'c'`.

## Iteration

### Iterator exhaustion

Iterators (generators, `map()`, `filter()`, file objects) can only be consumed once. A second pass over the same iterator silently produces nothing.

```python
# Bug: second loop does nothing
filtered = filter(lambda x: x > 0, data)
total = sum(filtered)
items = list(filtered)  # always []

# Fix: materialize first
filtered = list(filter(lambda x: x > 0, data))
total = sum(filtered)
items = list(filtered)  # correct
```

### Dict mutation during iteration

Adding or removing keys while iterating a dict raises `RuntimeError`. Modifying values is safe, but structural changes require iterating over a copy.

```python
# Bug: RuntimeError: dictionary changed size during iteration
for key in d:
    if should_remove(key):
        del d[key]

# Fix: iterate over a snapshot of the keys
for key in list(d.keys()):
    if should_remove(key):
        del d[key]
```

### Generator return value is lost

`return value` in a generator sets `StopIteration.value`, but `for` loops discard it. Only `yield from` or manual `next()` can access the return value.

## Datetime

### Naive vs aware datetimes

Mixing timezone-naive and timezone-aware datetimes raises `TypeError` on comparison or arithmetic. Code that uses `datetime.now()` (naive) and compares with an API response (often UTC-aware) will crash.

```python
# Bug: TypeError when comparing naive and aware
from datetime import datetime, timezone

created_at = datetime.now()  # naive
expires_at = datetime.now(timezone.utc)  # aware
if created_at < expires_at:  # TypeError
    ...

# Fix: always use aware datetimes
created_at = datetime.now(timezone.utc)
expires_at = datetime.now(timezone.utc)
```

## Strings

### `split()` vs `split(' ')`

`'a  b'.split()` splits on any whitespace and strips empty strings, but `'a  b'.split(' ')` preserves empty strings between consecutive spaces. Mixing these up corrupts parsing.

```python
# Bug: empty strings in result
line = "alice  bob  carol"
names = line.split(' ')   # ['alice', '', 'bob', '', 'carol']

# Fix: split() with no args handles any whitespace
names = line.split()  # ['alice', 'bob', 'carol']
```

### f-string `=` debug format leaking source

`f"{expr=}"` includes the expression text in the output, which can leak source code details into logs or user-facing output.

## Async

### Blocking the event loop

Calling a synchronous blocking function (HTTP request, file I/O, `time.sleep`) inside an `async` function blocks the entire event loop. Use `await`-compatible equivalents or `run_in_executor`.

```python
# Bug: blocks all other coroutines
async def fetch_data():
    response = requests.get(url)  # blocks the event loop
    return response.json()

# Fix: use async HTTP client or executor
async def fetch_data():
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()
```

## Classes

### `__init__` returning early

If `__init__` returns before setting all attributes, subsequent method calls raise `AttributeError`. No compile-time check enforces that all attributes are set on all paths.

```python
# Bug: self.conn is never set if check fails
class Client:
    def __init__(self, host):
        if not host:
            return
        self.conn = connect(host)

    def query(self):
        return self.conn.execute("SELECT 1")  # AttributeError
```

### `__eq__` without `__hash__`

Defining `__eq__` without `__hash__` makes instances unhashable. Python 3 sets `__hash__` to `None` when `__eq__` is defined, so instances can't be used in sets or as dict keys.

```python
# Bug: TypeError: unhashable type
class Point:
    def __init__(self, x, y):
        self.x, self.y = x, y
    def __eq__(self, other):
        return self.x == other.x and self.y == other.y

seen = {Point(1, 2)}  # TypeError

# Fix: define __hash__ too
class Point:
    def __init__(self, x, y):
        self.x, self.y = x, y
    def __eq__(self, other):
        return self.x == other.x and self.y == other.y
    def __hash__(self):
        return hash((self.x, self.y))
```

## Security

### `subprocess` shell injection

`subprocess.run(f"cmd {user_input}", shell=True)` is command injection. Use list form to avoid shell interpretation.

```python
# Bug: user_input = "; rm -rf /" executes arbitrary commands
subprocess.run(f"grep {user_input} log.txt", shell=True)

# Fix: list form, no shell
subprocess.run(["grep", user_input, "log.txt"])
```

### `os.path.join` with absolute component

`os.path.join("/base", "/user/input")` returns `"/user/input"`, discarding the base entirely. User-controlled path components can escape intended directories.

```python
# Bug: user input "/etc/passwd" discards the base
path = os.path.join("/app/uploads", user_filename)

# Fix: strip leading slashes or use Path and check resolved path
path = Path("/app/uploads") / user_filename.lstrip("/")
if not path.resolve().is_relative_to(Path("/app/uploads")):
    raise ValueError("path escapes upload directory")
```
