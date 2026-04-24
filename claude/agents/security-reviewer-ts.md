# TypeScript / JavaScript security patterns

Language-specific companion to `security-reviewer.md`. Read this in addition to the generic categories when reviewing TypeScript, JavaScript, or Node.js code. These are pitfalls tied to JS semantics, Node APIs, or common JS frameworks, and don't reliably appear in other languages.

## Class serialization exposes "private" fields

- TypeScript `private`, `protected`, and `readonly` are compile-time only. Own fields remain enumerable at runtime, so `JSON.stringify(instance)`, `util.inspect`, `structuredClone`, log libraries, and `Object.assign` will walk them. Class instances serialized directly into HTTP response bodies, log entries, or error payloads leak fields the author believed were private.
- A particularly dangerous variant: a class that stores the entire `process.env` (or a `headers` bag, or a `config` object holding secrets) as an "internal" field and is then stringified anywhere in the request path.
- Bracket notation (`obj["privateField"]`) silently bypasses TS access modifiers across files; grep for it around sensitive state to find callers that are reaching into internals, often in ways that evade type-level review.

## Code execution primitives

- `eval`, `new Function(...)`, `Function(...)`: direct code execution from strings
- `node:vm` (`runInNewContext`, `runInThisContext`, `Script`): not a sandbox; escapable via `this.constructor.constructor`
- `child_process.exec` / `execSync` with template-string argument construction (shell metacharacters in user input). Prefer `execFile` / `spawn` with an argv array
- Dynamic `require(userInput)` / `import(userInput)`: module-path traversal and arbitrary code load

## Prototype pollution

- Recursive merge/set functions (`Object.assign` in loops, `lodash.merge`, `lodash.set`, custom `deepMerge`) that write keys named `__proto__`, `constructor`, or `prototype` from untrusted input
- `JSON.parse` reviver functions that don't filter these keys
- Query-string parsers that return plain objects instead of `Object.create(null)` (older `qs`, Express defaults in older versions)
- Downstream impact: polluted prototypes can flip default values on every object in the process (authentication flags, sandbox escape, denial of service)

## Regular expression denial of service (ReDoS)

- V8's regex engine backtracks and has no timeout. Nested quantifiers (`(a+)+`), overlapping alternation (`(a|a)*`), and catastrophic patterns run against attacker input freeze the event loop for the whole process
- Especially suspect: hand-rolled validators for email, URL, phone, semver, dates. Prefer vetted libraries; for untrusted regex input, use the `re2` npm package

## DOM and HTML rendering

- `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write` with untrusted strings
- React `dangerouslySetInnerHTML` with untrusted input
- Vue `v-html`, Svelte `{@html ...}`, Angular `bypassSecurityTrust*`
- `window.postMessage` without origin/source check on the receiver; `postMessage(msg, "*")` on the sender (any page that ever held a reference can read)

## Error objects leak request context

- Node's built-in `fetch` / undici attaches the request URL (and sometimes a `RequestInit`) to `error.cause`. `console.error(err)`, `util.inspect(err)`, or any log library that walks `cause` will print credentials that were embedded in the URL or headers
- `serialize-error` and similar libraries recursively serialize `cause` by default. When the result is returned in an HTTP response body (common for SDKs reporting step failures to an orchestrator), upstream request internals propagate to the caller
- Custom `Error` subclasses that override `toJSON` should whitelist fields, not spread `this`

## `process.env` pitfalls

- `process.env` is a globally readable bag. Any object that holds a reference to it, or to a subset of it, is at risk of being stringified in full by log middleware, error reporters, monitoring SDKs, or 405/500 handlers
- Passing `process.env` into `Worker` / `child_process` subprocesses without filtering propagates every secret variable, including unrelated ones (AWS creds, API keys for other services)
- Env-based feature flags that silently flip safety behavior (`NODE_ENV !== "production"` as a bypass condition). The variable may be unset in hardened deployments, causing fail-open

## Cookies and sessions (Express / Fastify / Koa family)

- Cookies set without `httpOnly`, `secure`, and `sameSite`. Node web frameworks leave all three unset by default; `res.cookie(name, val)` produces an insecure cookie
- `express-session` running against the default `MemoryStore` (not suitable for production; documented but often shipped anyway) or with a short/guessable `secret`

## JWT libraries

- Libraries that accept `alg: none` or honor the `alg` header without a server-side allowlist (older `jsonwebtoken`, many hand-rolled implementations)
- `verify(token, secret)` where `secret` may be `undefined` at runtime: some libraries silently skip verification instead of throwing

## Package and build supply chain

- Typosquatted packages in `dependencies` / `devDependencies`
- `postinstall` / `preinstall` scripts in third-party packages run arbitrary code during `npm install`
- `.npmrc` / `.yarnrc` committed with registries or auth tokens
- Lockfile-less installs in CI (`npm install` without `npm ci`) allow supply-chain substitution
