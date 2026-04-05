## Type coercion and equality

### Truthiness traps

`0`, `""`, `NaN`, and `null`/`undefined` are all falsy. `if (value)` guards silently reject valid inputs like `0` or empty string. Use explicit checks instead.

```typescript
// Bug: rejects 0, which is a valid count
function process(count?: number) {
  if (count) {
    return count * 2;
  }
  return -1; // 0 lands here
}

// Fix: check for undefined/null explicitly
function process(count?: number) {
  if (count !== undefined) {
    return count * 2;
  }
  return -1;
}
```

### `==` vs `===` coercion

`==` performs type coercion (`"0" == false` is `true`). Always use `===` unless coercion is intentional.

```typescript
// Bug: coerces before comparing
if (input == false) { ... } // matches "", 0, null, undefined, false

// Fix: strict equality
if (input === false) { ... }
```

### Optional chaining returns undefined

`obj?.foo?.bar` returns `undefined` (not `null`) when short-circuiting. Code that checks `=== null` after optional chaining misses the undefined case.

```typescript
// Bug: misses the undefined from optional chaining
const name = user?.profile?.name;
if (name === null) {
  return "anonymous"; // never reached when user is undefined
}

// Fix: check for both null and undefined explicitly
if (name === null || name === undefined) {
  return "anonymous";
}
```

### `typeof null === "object"`

Type-checking with `typeof` doesn't distinguish null from objects. Use `value === null` explicitly.

```typescript
// Bug: null passes the object check
function process(obj: unknown) {
  if (typeof obj === "object") {
    return obj.toString(); // crashes on null
  }
}

// Fix: check null first
if (obj !== null && typeof obj === "object") {
  return obj.toString();
}
```

## Numbers and parsing

### `parseInt` without radix

`parseInt("08")` works in modern engines but `parseInt("0x10")` returns 16. Always pass the radix.

```typescript
// Bug: hex prefix interpreted
parseInt("0x10"); // 16

// Fix: explicit radix
parseInt("0x10", 10); // NaN, but at least it's obvious
parseInt("42", 10);   // 42
```

### Floating point arithmetic

`0.1 + 0.2 !== 0.3`. Any equality comparison on decimal arithmetic results is suspect.

```typescript
// Bug: evaluates to false
if (0.1 + 0.2 === 0.3) { ... }

// Fix: compare within epsilon
if (Math.abs(0.1 + 0.2 - 0.3) < Number.EPSILON) { ... }
```

### `Date` month is 0-indexed

`new Date(2024, 1, 1)` is February 1st, not January. Off-by-one month bugs are extremely common.

```typescript
// Bug: creates February 1st
const jan1 = new Date(2024, 1, 1);

// Fix: months are 0-indexed
const jan1 = new Date(2024, 0, 1);
```

## Arrays and objects

### `Array.sort()` mutates and sorts lexicographically

`Array.sort()` mutates in place and sorts lexicographically by default.

```typescript
// Bug: sorts as strings, not numbers
[10, 2, 1].sort(); // [1, 10, 2]

// Fix: explicit comparator
[10, 2, 1].sort((a, b) => a - b); // [1, 2, 10]
```

### `Array.find()` returns undefined on no match

The return value is indistinguishable from finding an actual `undefined` in the array. If the array can contain `undefined`, use `findIndex` instead and check for `-1`.

```typescript
// Bug: can't tell "not found" from "found undefined"
const val = [undefined, 1, 2].find((x) => x === undefined);

// Fix: use findIndex
const idx = [undefined, 1, 2].findIndex((x) => x === undefined);
if (idx !== -1) { ... }
```

### Object spread is shallow

`{ ...obj }` only shallow-copies. Nested objects are still shared references.

```typescript
// Bug: mutating the "copy" mutates the original
const original = { nested: { count: 1 } };
const copy = { ...original };
copy.nested.count = 2;
console.log(original.nested.count); // 2

// Fix: deep clone
const copy = structuredClone(original);
```

### `delete` leaves holes in arrays

`delete arr[i]` sets the element to `undefined` but doesn't change length or shift elements. Use `splice` instead.

```typescript
// Bug: leaves a hole
const arr = [1, 2, 3];
delete arr[1];
console.log(arr); // [1, empty, 3], length is still 3

// Fix: use splice
arr.splice(1, 1); // [1, 3], length is 2
```

### `for...in` iterates prototype chain

`for (const key in obj)` includes inherited enumerable properties. Use `Object.keys()`, `Object.entries()`, or `for...of` with appropriate iterables.

```typescript
// Bug: picks up inherited properties
for (const key in obj) {
  console.log(key); // includes prototype properties
}

// Fix: Object.keys or hasOwn check
for (const key of Object.keys(obj)) {
  console.log(key);
}
```

## Async and promises

### Promise error swallowing

A `.then()` chain without `.catch()` (or missing `await` in a try/catch) silently swallows rejections. Especially dangerous when calling an async function without `await`. The returned promise floats away and its rejection is unhandled.

```typescript
// Bug: rejection silently lost
function save(data: Data) {
  db.insert(data).then(() => {
    console.log("saved");
  });
  // no .catch(), no await, no error handling
}

// Fix: await in try/catch or add .catch
async function save(data: Data) {
  try {
    await db.insert(data);
    console.log("saved");
  } catch (err) {
    console.error("save failed:", err);
  }
}
```

### Forgetting `await` on async calls

Forgetting `await` on an async call means you're operating on the Promise object, not the resolved value. TypeScript catches some of these but not all (e.g. in conditional or void positions).

```typescript
// Bug: isValid is a Promise (always truthy)
async function validate(input: string): Promise<boolean> { ... }

if (validate(input)) {
  proceed(); // always runs, Promise is truthy
}

// Fix: await the result
if (await validate(input)) {
  proceed();
}
```

## `this` binding

### Method reference loses context

Passing a method as a callback (`setTimeout(obj.method, 100)`) loses `this` binding. Must use arrow function, `.bind()`, or method shorthand.

```typescript
// Bug: `this` is undefined or window
class Timer {
  count = 0;
  start() {
    setInterval(this.tick, 1000); // `this` is lost
  }
  tick() {
    this.count++; // crash or NaN
  }
}

// Fix: arrow function or bind
class Timer {
  count = 0;
  start() {
    setInterval(() => this.tick(), 1000);
  }
  tick() {
    this.count++;
  }
}
```

## Serialization

### `JSON.stringify` drops values silently

Properties with `undefined` values, function values, and `Symbol` keys are silently omitted from serialization. Sparse array holes become `null`.

```typescript
// Bug: fields vanish during round-trip
const obj = { name: "a", callback: () => {}, value: undefined };
JSON.parse(JSON.stringify(obj)); // { name: "a" }

// Fix: use a replacer or choose a serialization format that handles these
JSON.stringify(obj, (key, val) => (val === undefined ? null : val));
```

## Regex

### Global flag makes regex stateful

A regex with `/g` flag has a `lastIndex` property that advances on each `exec()` or `test()` call. Reusing the same regex object across multiple strings gives alternating true/false results.

```typescript
// Bug: alternates true/false
const re = /foo/g;
re.test("foo"); // true (lastIndex = 3)
re.test("foo"); // false (lastIndex reset to 0)
re.test("foo"); // true again

// Fix: create a new regex each time, or don't use /g with test()
const re = /foo/;
re.test("foo"); // true
re.test("foo"); // true
```

## TypeScript-specific

### Type narrowing invalidated by `await`

Narrowing a variable's type in an `if` block doesn't survive across `await` boundaries. Each `await` is a suspension point where other code can run and mutate shared state, so TypeScript conservatively widens the type back.

```typescript
// Bug: narrowing lost after await
function process(value: string | null) {
  if (value !== null) {
    await someAsyncOp();
    console.log(value.toUpperCase()); // TS error: value might be null
  }
}

// Fix: capture in a const before the await
function process(value: string | null) {
  if (value !== null) {
    const v = value;
    await someAsyncOp();
    console.log(v.toUpperCase()); // v is still string
  }
}
```

### Non-null assertion abuse

`value!` tells TypeScript to trust you. If used incorrectly, it hides a real null/undefined that crashes at runtime. Watch for `!` on values from external input, API responses, or map lookups.

```typescript
// Bug: crashes at runtime if key is missing
const config = new Map<string, string>();
const value = config.get("missing")!;
console.log(value.toUpperCase()); // runtime crash

// Fix: handle the undefined case
const value = config.get("missing");
if (value === undefined) {
  throw new Error("missing required config key");
}
console.log(value.toUpperCase());
```

### Index signatures hide undefined

`Record<string, T>` and index signatures claim to return `T`, but actually return `T | undefined` at runtime. TypeScript doesn't catch missing-key access unless `noUncheckedIndexedAccess` is enabled.

```typescript
// Bug: TS says it's string, runtime says undefined
const dict: Record<string, string> = { a: "hello" };
const val: string = dict["b"]; // no error, but val is undefined
console.log(val.toUpperCase()); // runtime crash

// Fix: enable noUncheckedIndexedAccess, or check manually
const val = dict["b"];
if (val !== undefined) {
  console.log(val.toUpperCase());
}
```

### Numeric enum pitfalls

Numeric enums allow reverse mapping (`MyEnum[0]` returns the name string), so passing an arbitrary number where an enum is expected silently succeeds. Prefer `const` enums or string literal unions.

```typescript
// Bug: any number is accepted
enum Status { Active, Inactive }
function process(s: Status) { ... }
process(999); // no error

// Fix: use string literal unions
type Status = "active" | "inactive";
function process(s: Status) { ... }
process("bogus"); // compile error
```
