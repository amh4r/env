# General

"MUST" rules MUST never be violated without my permission. You MAY ask permission to violate a "MUST" rule.

"SHOULD" rules are strong suggestions. They should only be violated if there is a good reason.

# Preferences

My preferences MUST only apply to new code. Do not change existing code to conform to my preferences.

## Go

MUST use `any` instead of `interface{}`.

## TypeScript

MUST avoid braceless returns. For example, prefer `if (condition) { return }` over `if (condition) return`.

SHOULD avoid ternaries if possible in runtime code (ternaries are often necessary for TypeScript types).

SHOULD avoid type casting if possible. For example, instead of doing `stuff(foo as string)`, actually write an runtime check.

SHOULD avoid using `any`.
