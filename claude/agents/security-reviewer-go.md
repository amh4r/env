# Go security patterns

Language-specific companion to `security-reviewer.md`. Read this in addition to the generic categories when reviewing Go code. These are pitfalls tied to Go semantics, standard library defaults, or common Go idioms, and don't reliably appear in other languages.

## Constant-time comparison

- Use `hmac.Equal` for MAC comparison and `subtle.ConstantTimeCompare` for token/secret comparison. `==`, `bytes.Equal`, and hex-string equality all short-circuit on first mismatch and leak a timing oracle sufficient to recover signatures over stable network paths.
- Common footgun: computing a MAC and comparing its *hex or base64 string representation* with `!=`. The encoding does not save you. Decode and compare raw bytes with `hmac.Equal`.

## Randomness

- `math/rand` and `math/rand/v2` are not cryptographic and must never be used for tokens, session IDs, nonces, salts, or keys, regardless of Go version's seeding behavior.
- `crypto/rand` is the only correct source for security-sensitive entropy. Third-party UUID libraries vary; verify they're backed by `crypto/rand` (`github.com/google/uuid` is; older libraries often aren't).

## Deserialization

- `encoding/gob` on untrusted input is arbitrary-type deserialization; treat it as code execution. No safe configuration exists across a trust boundary.
- `encoding/json` into `interface{}` / `map[string]interface{}` enforces no schema. Prefer concrete structs and `json.Decoder` with `DisallowUnknownFields()` at trust boundaries.
- JSON has no built-in depth or size limit. Always wrap request bodies with `http.MaxBytesReader`. `io.ReadAll` on any untrusted reader (multipart parts, webhook bodies read before verification, gRPC sidecars, file uploads) is unbounded the same way and needs `io.LimitReader` or an explicit cap.
- `encoding/xml` does not process DTDs or resolve external entities, so classic XXE exfiltration is not available. The realistic risks are memory exhaustion from deeply nested elements (cap input with `io.LimitReader`) and custom entities added via `Decoder.Entity` (never populate this from untrusted input).
- `gopkg.in/yaml.v2` and `v3` into `interface{}` / `map[string]any` are schema-less like JSON. Prefer concrete structs with `yaml.UnmarshalStrict` (v2) or `yaml.Decoder.KnownFields(true)` (v3). Both versions bound alias expansion against billion-laughs, but verify the version pin.
- Protobuf has no native depth limit; recursive messages can stack-overflow the unmarshaler. gRPC's `grpc.MaxRecvMsgSize` defaults to 4 MB but is often raised to unlimited in SDK code. Verify the constraint still exists.
- `proto.Unmarshal(msg.Payload, msg)` instead of `proto.Unmarshal(msg.Payload, &payload)` is a recurring bug class: unmarshaling into the wrong target silently succeeds with zero-valued fields, causing state-machine desync (acks that never clear, retries that amplify). Flag any case where the unmarshal target aliases the source.

## HTTP server defaults

- `http.Server{}` zero-values have no `ReadTimeout`, `WriteTimeout`, `IdleTimeout`, or `ReadHeaderTimeout`, leaving the server slowloris-exposed. `http.ListenAndServe` uses these defaults. Always set timeouts explicitly.
- `http.DefaultServeMux` is process-global. Any imported package that calls `http.Handle` / `http.HandleFunc` on it registers routes silently. `net/http/pprof` and `expvar` do this on import, exposing `/debug/pprof/*` and `/debug/vars`.
- `http.DefaultClient` and `http.Get` have no timeout. Outbound requests hang forever on slow upstreams, an SSRF amplifier and goroutine leak.
- `httputil.ReverseProxy` forwards all non-hop-by-hop headers verbatim, including `X-Forwarded-*` and `Authorization`. A proxy that terminates user auth at the edge and forwards to internal services will leak the caller's credential to every backend unless it strips `Authorization` in its `Rewrite` or `Director`. Proxies behind untrusted networks must also strip and re-set `X-Forwarded-*`.
- `net.Listen("tcp", ":port")` and `"0.0.0.0:port"` bind all interfaces. Admin handlers, pprof servers, and metrics exporters intended for localhost often ship with this default and become exposed once the container's port is mapped. Bind `127.0.0.1:port` explicitly when the surface should not be public.
- HTTP/2 rapid reset (CVE-2023-44487) affects unpatched Go runtimes and any `golang.org/x/net/http2` pin older than the fix. Verify Go and `x/net` are current, and set `http2.Server.MaxConcurrentStreams` on internet-exposed servers.

## Cookies

- `http.Cookie{}` zero value leaves `HttpOnly` and `Secure` false and `SameSite` as `SameSiteDefaultMode` (browser-dependent). Session, auth, and CSRF cookies set through `http.SetCookie` without explicit flags ship insecure. Require `HttpOnly: true`, `Secure: true`, and an explicit `SameSite` for any cookie carrying authentication state.

## CORS

- `github.com/rs/cors` and `github.com/gin-contrib/cors` produce an exploitable configuration when `AllowedOrigins: ["*"]` (or equivalent wildcard) is combined with `AllowCredentials: true`. Modern browsers block this combination, but `AllowOriginFunc` / `AllowOriginRequestFunc` callbacks that echo the request `Origin` back re-enable it: any origin receives `Access-Control-Allow-Origin: <their-origin>` plus credentials. Flag echo-origin patterns; require an explicit allowlist.
- `gorilla/handlers.CORS()` defaults are also permissive; verify an explicit `AllowedOrigins` is set rather than relying on defaults.

## WebSocket origin checks

- `github.com/gorilla/websocket`'s `Upgrader.CheckOrigin` defaults to same-origin enforcement, but the idiomatic workaround applied by developers hitting CORS errors is `CheckOrigin: func(r *http.Request) bool { return true }`. This disables the check and enables cross-site WebSocket hijacking: any attacker page can open a WebSocket to the target, riding the victim's authenticated session cookie. Grep for unconditional `return true` in `CheckOrigin` and require an explicit allowlist.
- `nhooyr.io/websocket`'s `Accept` enforces same-origin by default. `AcceptOptions.InsecureSkipVerify` (deprecated but still honored) and `OriginPatterns: []string{"*"}` are the equivalent escape hatches; both are findings in production paths.
- `github.com/gobwas/ws` performs no origin check — it's a primitive upgrade helper, not a framework. Any server built on it must implement origin validation in handler code before completing the upgrade; grep for `ws.Upgrade` or `ws.UpgradeHTTP` with no surrounding origin check.

## Trusting forwarded headers

- `X-Forwarded-For`, `X-Forwarded-Proto`, `X-Real-IP`, and the `Host` header are attacker-settable unless the request came through a trusted proxy. Trusting them for scheme, client IP, or rate-limit key without a proxy allowlist is routinely exploitable.
- Constructing outbound URLs from `r.Host` + `X-Forwarded-Proto` on an unauthenticated endpoint lets an attacker redirect where the application subsequently sends authenticated requests (the confused-deputy registration pattern).

## Outbound requests and SSRF

- URL-level allowlisting runs before DNS resolution. An attacker-controlled hostname can resolve to RFC 1918, link-local, or cloud metadata addresses (169.254.169.254) at dial time even if the URL passed every string-level check. Enforce destination IP filtering via `net.Dialer.Control` or a custom `http.Transport.DialContext` that rejects private ranges.
- DNS rebinding: a hostname can resolve to a public address on the pre-flight check and an internal address on the subsequent dial. Tie the enforcement to the dial, not to a separate resolution.
- `http.Client` follows redirects by default. A validated initial URL can 302 to an internal target; validate at every hop via `Client.CheckRedirect` or disable redirects on SSRF-sensitive paths.
- `url.Parse` accepts userinfo: `url.Parse("http://internal.example.com@evil.com/")` returns `u.Host == "evil.com"` with `internal.example.com` as the username. Allowlisters that split the raw URL on `/` or `@` before calling `url.Parse` can bin the wrong token as host. Always use `u.Hostname()` on a parsed URL, and reject URLs where `u.User != nil` unless userinfo is explicitly expected.

## gRPC

- Auth interceptors registered only as `grpc.UnaryInterceptor` leave streaming RPCs unauthenticated. Every auth/authz `UnaryInterceptor` needs a corresponding `StreamInterceptor`. This gap commonly appears in codebases that added streaming RPCs after the auth middleware was built.
- `reflection.Register(server)` from `google.golang.org/grpc/reflection` exposes the full service and message graph to any caller that can reach the port. Fine in development, a reconnaissance gift in production. Gate it on an explicit env check or omit from production builds.
- gRPC metadata (`metadata.FromIncomingContext`) is attacker-controllable on the wire the same way HTTP headers are. Authorization decisions based on metadata keys like `x-user-id` or `x-tenant` without verifying against an authenticated principal are trivially spoofed.

## `os/exec` and command execution

- `exec.Command("sh", "-c", userInput)` / `bash -c` passes user input through a shell. Use `exec.Command(name, args...)` with argv-style arguments; no shell is invoked.
- `exec.LookPath` resolves bare names against `$PATH`. On Windows, `exec.Command` historically searched the current working directory before `PATH`; Go 1.19 fixed that (CVE-2022-30580). Binaries built with pre-1.19 toolchains on Windows retain the CWD issue. `$PATH` containing an attacker-writable directory still allows binary planting on any OS.
- `os.Environ()` inherited by subprocesses propagates every parent env var, including unrelated secrets. Filter explicitly when spawning helpers.

## TLS configuration

- `tls.Config{InsecureSkipVerify: true}` disables certificate verification. Grep for this across the codebase. It's almost always wrong outside tests, and test-only setups reach production surprisingly often.
- A `VerifyPeerCertificate` or `VerifyConnection` callback that returns `nil` unconditionally is the same failure as `InsecureSkipVerify: true` dressed up; grep for both when reviewing TLS config.
- Constructing a `tls.Config` without setting `MinVersion` relies on the standard library default, which has shifted across Go versions (clients were raised to TLS 1.2 in 1.18, servers in 1.22). Don't reason about the default; set `MinVersion: tls.VersionTLS12` (or 1.3) explicitly. This also keeps the minimum intact if the service is later rebuilt with an older toolchain.
- Mutating `http.DefaultTransport.TLSClientConfig` changes it globally for the process. Construct a fresh `Transport` per use case.

## SSH host key verification

- `golang.org/x/crypto/ssh`'s `ssh.InsecureIgnoreHostKey()` is the SSH analogue of `InsecureSkipVerify`: it accepts any host key and enables MITM against SFTP, rsync-over-SSH, and `go-git` clones. Grep for it; it's almost always wrong outside local-only tooling.
- A `HostKeyCallback` that returns `nil` without checking the presented key against a known-hosts source is the same vulnerability wearing different clothes. Prefer `knownhosts.New` from `golang.org/x/crypto/ssh/knownhosts`.

## Symmetric encryption

- AES-GCM requires a unique nonce per `(key, plaintext)` pair. Reusing a 96-bit nonce under the same key destroys both confidentiality (plaintexts XOR-leak) and authenticity (the GHASH key can be recovered). A counter-based nonce is safe; a `crypto/rand` 12-byte nonce is safe up to ~2^32 messages per key; anything deterministic derived from the plaintext is a finding. Flag any code that reads a nonce from a user-controlled source and reuses it across calls.
- CBC mode (`cipher.NewCBCEncrypter`) with a predictable or reused IV leaks plaintext equality and, combined with an error oracle on decrypt, enables padding-oracle attacks. Prefer AEAD (GCM, ChaCha20-Poly1305) over CBC in any new code.

## File paths and symlinks

- `filepath.Join` does not prevent traversal: `filepath.Join("/safe", "../etc/passwd")` returns `/etc/passwd`. Prefer `os.Root` (Go 1.24, released Feb 2025) for traversal-safe opens. Without it, resolve symlinks with `filepath.EvalSymlinks` and verify the prefix, but note `EvalSymlinks` is TOCTOU-adjacent: a symlink can be swapped between resolve and open, and it requires the target to already exist.
- `filepath.Clean` normalizes but does not restrict. `../` can still escape the intended root.
- `os.OpenFile` with `O_CREATE` on an attacker-influenced path can be redirected via a pre-placed symlink. Use `os.Root` (Go 1.24, released Feb 2025) for traversal-safe operations, or `O_NOFOLLOW` where available.
- `archive/zip` and `archive/tar` do not validate entry names. The common extraction idiom `os.Create(filepath.Join(dst, header.Name))` allows zip-slip: a crafted archive with `../../etc/authorized_keys` in its header escapes `dst`. Resolve the candidate path and verify `strings.HasPrefix(abs, dstAbs + string(os.PathSeparator))` per entry, or extract through an `os.Root` rooted at `dst`. Symlink entries in tar archives need the same containment check on their target.
- `http.ServeFile(w, r, name)` cleans `name` but does not constrain it to any root. `http.ServeFile(w, r, filepath.Join(base, userInput))` lets `userInput="../etc/passwd"` escape `base`, and the built-in `..` rejection only applies to `r.URL.Path`, not the `name` argument. Prefer `http.FileServer(http.Dir(base))` behind `http.StripPrefix`, which containment-checks the joined path, or an `os.Root`-backed lookup.

## File permissions

- `os.Create` opens with mode `0666` (modified by umask); sensitive outputs (private keys, token caches, session stores, unix sockets carrying auth) written with it are typically group- and world-readable. Use `os.OpenFile(path, O_WRONLY|O_CREATE|O_TRUNC, 0600)` or `os.WriteFile(path, data, 0600)` explicitly for secret-bearing files.
- `os.MkdirAll(path, 0755)` on a directory that will hold per-user secrets exposes them to other local accounts on shared hosts and to sibling containers that share a volume. Use `0700` for secret-holding directories.

## Templates

- `text/template` does not escape output. Rendering user input to HTML with `text/template` is XSS. Only `html/template` auto-escapes.
- `template.HTML`, `template.JS`, `template.URL`, and `template.CSS` are explicit opt-outs from escaping. They must never be constructed from untrusted strings.
- Parsing template source from untrusted input (`template.New().Parse(userInput)`) is effectively remote code execution. Template actions can call any registered function.

## SQL

- `database/sql` placeholder style is driver-specific (`?` for MySQL, `$1` for Postgres). Use the correct style for the driver and never `fmt.Sprintf` into a query.
- `db.Exec(query, args...)` binds parameters; `db.Exec(fmt.Sprintf(query, args...))` does not. The difference is SQL injection.
- ORMs do not eliminate injection. `gorm.Raw(fmt.Sprintf(...))`, `sqlx.In` with pre-interpolated strings, and misuse of `sqlx.Named` all reintroduce it. Parameterization must survive every wrapper, not just the outermost call.

## Password hashing

- `golang.org/x/crypto/bcrypt` silently truncates inputs at 72 bytes. Two long passphrases that share a 72-byte prefix produce the same hash, collapsing password entropy for long passwords. Either pre-hash with SHA-256 before calling `bcrypt.GenerateFromPassword` (and document the scheme so verification matches) or use `argon2id` or `scrypt` from `x/crypto`, which have no such limit.
- `bcrypt.DefaultCost` is 10, set in 2014. New code in 2026 should pick a cost calibrated on production hardware (aim for ~250ms per hash); 10 is now too fast on commodity servers.
- `bcrypt.CompareHashAndPassword` is constant-time against the stored hash, but any surrounding "does this user exist" path that early-returns on unknown users reintroduces a timing oracle. Always execute a hash comparison on the not-found path against a fixed dummy hash. The dummy must be generated at the same cost as real hashes; a cost mismatch reintroduces the oracle.

## JWT

- `github.com/golang-jwt/jwt` requires the `Keyfunc` callback to check `token.Method` and return an error for unexpected algorithms. A callback that returns the key unconditionally accepts any algorithm the attacker supplies, enabling algorithm confusion (signing an HS256 token with the RSA public key as the HMAC secret). v3 additionally honored `alg: none` without an explicit check; projects still pinned to v3 should be flagged.
- `jwt.ParseUnverified` skips signature verification by design; it exists for inspection before key selection. Any use of its result in an authorization decision is equivalent to no auth.
- `jwt.Parser{SkipClaimsValidation: true}` (v4) or omitting `WithExpirationRequired`, `WithAudience`, and `WithIssuer` validators (v5) disables expiration and audience checks. In production auth paths this is a finding.
- `github.com/go-jose/go-jose` (and `gopkg.in/square/go-jose.v2`) does not restrict algorithms by default. `jwt.ParseSigned` accepts any algorithm present in the header unless the caller passes an allowlist (`jose.SignatureAlgorithm` slice in v4) or inspects `headers.Algorithm` before verifying. Nested JWT (JWE-wrapped JWS) verification must be checked at every layer; historically, unwrapping has let unauthenticated claims flow through.

## Error handling and response bodies

- `err.Error()` on a wrapped chain (`fmt.Errorf("%w", ...)`) includes every wrapped layer, often with internal file paths, request context, and stack frames (via libraries like `pkg/errors` or `errors.WithStack`). Writing `err.Error()` into an HTTP response body leaks all of it.
- `recover()` in an HTTP handler should log the stack server-side, never return it in the response body. `debug.Stack()` contains goroutine frames, dependency versions, and captured panic values.
- `errors.Join` concatenates messages from every joined error; collectively they may reveal more than any one individually would.

## Context propagation

- `db.Query`, `db.Exec`, `db.QueryRow`, and transaction methods without the `Context` variant don't observe request cancellation. A slow query continues after the client disconnects and holds a pool connection; enough concurrent slow queries exhaust the pool and take the service offline. Use `QueryContext` / `ExecContext` and pass `r.Context()` through.
- `http.Get`, `http.Post`, and `client.Do(req)` without `req.WithContext(ctx)` outlive the incoming request the same way. Combined with a missing client `Timeout` this is a goroutine and file-descriptor leak reachable from any SSRF-shaped endpoint.

## Concurrency

- Goroutines spawned from a request handler must inherit a cancellable context. Goroutines that capture `context.Background()` or `context.TODO()` outlive the request and leak on client disconnect, enabling slow resource exhaustion under load.
- `sync.Pool` objects are reused across requests. If a pooled buffer is written to but not fully reset before return, the next request may read the previous one's data. This has caused real CVEs in Go HTTP frameworks. The common bug: a pooled `[]byte` re-sliced to zero length (`buf = buf[:0]`) before `Put` still has the previous request's bytes in the underlying array, visible to the next borrower via `buf[:cap(buf)]` or via a library that caps-reads. Pool `*bytes.Buffer` with `Reset()` and keep callers on the `Buffer` API, or zero the backing array explicitly.
- Unbounded goroutine spawn on untrusted input (one goroutine per request, no semaphore) is a DoS vector distinct from CPU or memory limits.
- Channel sends without a `select { case ch <- x: case <-ctx.Done(): }` wrapper can block forever if the receiver has exited.
- `context.WithValue` keys must be an unexported type. String keys collide across packages, and a package in a shared process could overwrite an auth-middleware-set value.
- A panic in a goroutine spawned from a handler with no `recover()` crashes the entire process. User input that can reach such a goroutine is a DoS vector distinct from the ones above. Wrap handler-spawned goroutines with a deferred recover that logs and returns.
- `errgroup.WithContext` cancels all sibling goroutines on the first error return. Using it to run parallel auth or policy checks means the first failure suppresses the others. An input that makes one check error early can skip checks that would have rejected it for a different, more severe reason.
- `os.Setenv` / `os.Unsetenv` were not thread-safe on Unix until recent Go versions added internal synchronization. Handlers or `t.Parallel()` subtests that mutate process env on older toolchains race silently and can corrupt the environment seen by concurrent `exec.Cmd` spawns. Confine env mutation to `init()` or program startup; never set env from a request path.

## Integer conversion at security boundaries

- `int32(id)` where `id` is `uint64` or `int64` silently truncates. IDs above `2^31-1` wrap to smaller or negative values and can collide with an existing user (including admin id 1). Stock `go vet` does not catch this; `gosec` flags it as G115. Unchecked narrowing at an auth boundary is a finding regardless of whether a linter ran.
- `int(header.Size)` from `archive/tar`, `int(r.ContentLength)`, or `int(protoField)` on 32-bit or wasm targets overflows and bypasses subsequent bounds checks (`if size < max`). Compare in the widest type before narrowing.
- Signed/unsigned conversions flip sign at the 2^63 boundary: a negative price, quantity, or quota that was validated as `>= 0` in `int64` becomes a huge positive when cast to `uint64` for downstream arithmetic, and vice versa.

## Map iteration and canonicalization

- Go randomizes map iteration order per iteration. Signing a response by serializing a `map[string]any` produces different bytes each call for the same logical content. If the signed bytes are computed independently from the wire bytes (sign a marshaled copy, then `json.Encode` a second copy), the two can diverge silently. Serialize once and sign the exact bytes sent, or canonicalize (e.g. JCS) before signing.

## Not exploitable in Go

These show up on generic security checklists but are already handled by Go's defaults or standard library. Don't flag them.

- **ReDoS**: Go's `regexp` uses RE2; catastrophic backtracking is not possible. This is a real concern in JS / Python / Java, not here.
- **Handler-panic process crash**: `net/http.Server` recovers panics in the handler goroutine and the process survives. The real risk is panics in goroutines the handler *spawned* without their own `recover`, which is covered under Concurrency.
- **Default header-size exhaustion**: `http.Server.MaxHeaderBytes` defaults to 1 MB. Untuned servers already cap header size; only flag when it has been raised explicitly.

## Module and build supply chain

- `GOSUMDB=off` or `GONOSUMCHECK=1` disables the module checksum database. Review CI and developer setup scripts for these.
- `replace` directives in `go.mod` redirect imports to local paths or forks. Treat `replace` changes as dependency additions.
- `go generate` executes arbitrary commands declared in source comments. Running `go generate ./...` on an untrusted checkout is arbitrary code execution.
- `cgo` directives (`#cgo`, `import "C"`) invoke a C/C++ compiler at build time on files in the module. Untrusted cgo sources are a build-time RCE vector.
