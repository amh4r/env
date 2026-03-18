---
description: "Style changes. Defaults to uncommitted changes"
---

The following style guidelines apply to code that is not yet committed to the repository. They are meant to ensure that code is clean, readable, and maintainable before it is merged into the main codebase.

# Go

MUST use `any` instead of `interface{}`.

# TypeScript

MUST avoid braceless returns.

```typescript
// bad
if (condition) return;

// good
if (condition) {
  return;
}
```

MUST avoid braceless single-line blocks in general (if/else/for/while).

```typescript
// bad
if (x) doThing();
for (const i of arr) doThing(i);

// good
if (x) {
  doThing();
}
for (const i of arr) {
  doThing(i);
}
```

MUST avoid ternaries in runtime code. Use if/else instead. Ternaries are acceptable in TypeScript types (since they're necessary for conditional types).

```typescript
// bad
const x = condition ? valueA : valueB;

// good
let x = valueB;
if (condition) {
  x = valueA;
}
```

SHOULD avoid type casting (`as`) if possible. Write a runtime check instead.

```typescript
// bad
stuff(foo as string);

// good
if (typeof foo === "string") {
  stuff(foo);
}
```

SHOULD avoid using `any`.

When a validation function throws an error, SHOULD prefix its name with `validate`.

When a validation function returns a boolean, SHOULD prefix its name with `check`, `is`, or `has`.

# YAML

All string values MUST be quoted.

```yaml
# bad
key: value

# good
key: "value"
```

# Comments

MUST be succinct. Engineers frequently lose focus when reading long comments, so keep them short and informative.

Do not use em dashes.

Use active voice. Do not use passive voice.
