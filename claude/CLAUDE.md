# Code Style Rules

EVERY piece of new code you write MUST follow these rules. Review them before writing any code.

"MUST" rules MUST never be violated without my permission. You MAY ask permission to violate a "MUST" rule.

"SHOULD" rules are strong suggestions. They should only be violated if there is a good reason.

These rules MUST only apply to new code. Do not change existing code to conform.

## Go

MUST use `any` instead of `interface{}`.

## TypeScript

MUST avoid braceless returns.
```typescript
// bad
if (condition) return

// good
if (condition) { return }
```

MUST avoid braceless single-line blocks in general (if/else/for/while).
```typescript
// bad
if (x) doThing()
for (const i of arr) doThing(i)

// good
if (x) { doThing() }
for (const i of arr) { doThing(i) }
```

SHOULD avoid ternaries in runtime code. Use if/else instead. Ternaries are acceptable in TypeScript types where they are often necessary.
```typescript
// bad
const x = condition ? valueA : valueB

// good
let x = valueB
if (condition) { x = valueA }
```

SHOULD avoid type casting (`as`) if possible. Write a runtime check instead.
```typescript
// bad
stuff(foo as string)

// good
if (typeof foo === "string") { stuff(foo) }
```

SHOULD avoid using `any`.

## Comments

MUST be succinct. Engineers frequently lose focus when reading long comments, so keep them short and informative.
