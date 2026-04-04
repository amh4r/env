## Concurrency

### Map concurrent access

Reading and writing a map from multiple goroutines without a mutex or `sync.Map` is a data race that causes a fatal crash, not just wrong results.

```go
// Bug: concurrent map read/write panic
go func() { m["key"] = 1 }()
fmt.Println(m["key"])

// Fix: protect with mutex
mu.Lock()
m["key"] = 1
mu.Unlock()
```

### Goroutine leaks

Goroutines blocked on a channel send/recv or select with no exit path. Look for missing `context.Context` cancellation, unbuffered channels with no guaranteed reader, and `time.After` in loops (each iteration allocates a new timer that won't GC until it fires).

```go
// Bug: goroutine blocks forever if nobody reads from ch
ch := make(chan int)
go func() {
    result := doWork()
    ch <- result // blocks forever if receiver is gone
}()

// Fix: select with context cancellation
go func() {
    result := doWork()
    select {
        case ch <- result:
        case <-ctx.Done():
    }
}()
```

### Bare channel operations

A `<-ch` or `ch <-` outside a `select` with `ctx.Done()` will hang forever if the other side panics, never sends, or the context is canceled. Bare channel ops are almost always a bug in production code.

```go
// Bug: hangs forever if producer dies
val := <-ch

// Fix: select with cancellation
select {
case val := <-ch:
    process(val)
case <-ctx.Done():
    return ctx.Err()
}
```

### Premature goroutine launch

Starting a goroutine that accesses a shared resource before the setup that makes that access safe has completed. If the setup fails and the error path also touches that resource, you have a data race.

```go
// Bug: goroutine may access conn before it's validated
go handleConn(conn)
if err := conn.Validate(); err != nil {
    conn.Close() // race with handleConn
    return err
}

// Fix: launch after preconditions are established
if err := conn.Validate(); err != nil {
    conn.Close()
    return err
}
go handleConn(conn)
```

### sync.WaitGroup misuse

Calling `wg.Add` inside the goroutine instead of before `go func()` creates a race where `wg.Wait` can return before all goroutines start.

```go
// Bug: wg.Wait may return before Add is called
for i := 0; i < n; i++ {
    go func() {
        wg.Add(1)
        defer wg.Done()
        doWork()
    }()
}
wg.Wait()

// Fix: Add before launching
for i := 0; i < n; i++ {
    wg.Add(1)
    go func() {
        defer wg.Done()
        doWork()
    }()
}
wg.Wait()
```

### Struct copying with mutex

Copying a struct that contains a `sync.Mutex` (or any sync type) copies the lock state, leading to deadlocks or unprotected access on the copy. Same applies to structs containing channels or other reference-like fields.

```go
// Bug: copies the mutex along with the struct
type Server struct {
    mu   sync.Mutex
    data map[string]string
}
s2 := s1 // s2.mu is a copy of s1.mu's state

// Fix: use a pointer receiver, never copy the struct
func (s *Server) Handle() { ... }
```

### Context misuse

Using `context.Background()` deep in a call chain instead of propagating the caller's context defeats cancellation and timeout. Also: storing contexts in structs (they should be passed as the first parameter).

```go
// Bug: ignores caller's cancellation
func (s *Server) Process() error {
    return s.db.Query(context.Background(), query)
}

// Fix: propagate context
func (s *Server) Process(ctx context.Context) error {
    return s.db.Query(ctx, query)
}
```

### errgroup context cancellation

`errgroup.WithContext` cancels the derived context when any goroutine returns an error. Other goroutines that don't check `ctx.Done()` keep running with a canceled context, leading to confusing secondary failures.

```go
// Bug: if fetchA fails, fetchB gets a canceled context but no clear signal
g, ctx := errgroup.WithContext(ctx)
g.Go(func() error { return fetchA(ctx) })
g.Go(func() error { return fetchB(ctx) }) // ctx canceled mid-flight if fetchA errors
if err := g.Wait(); err != nil {
    // error may be from fetchB's canceled context, not the root cause
}

// Fix: handle context cancellation in each goroutine
g.Go(func() error {
    if err := fetchB(ctx); err != nil {
        if ctx.Err() != nil {
            return nil // another goroutine failed, don't mask the real error
        }
        return err
    }
    return nil
})
```

### sync.Once swallowing init errors

`sync.Once.Do` runs the function exactly once, even if it fails. A failed initialization stays failed forever with no way to retry.

```go
// Bug: if loadConfig fails, cfg stays nil forever
var once sync.Once
var cfg *Config
once.Do(func() {
    cfg, _ = loadConfig() // error swallowed, never retried
})

// Fix: use sync.OnceValue (Go 1.21+) or handle error explicitly
var getConfig = sync.OnceValues(func() (*Config, error) {
    return loadConfig()
})
cfg, err := getConfig()
```

### time.After in select loops

`time.After` in a loop body allocates a new timer each iteration. The timer isn't GC'd until it fires, causing unbounded memory growth in hot loops.

```go
// Bug: leaks a timer every iteration
for {
    select {
    case msg := <-ch:
        handle(msg)
    case <-time.After(5 * time.Second):
        return errTimeout
    }
}

// Fix: reuse a single timer
timer := time.NewTimer(5 * time.Second)
defer timer.Stop()
for {
    timer.Reset(5 * time.Second)
    select {
    case msg := <-ch:
        handle(msg)
    case <-timer.C:
        return errTimeout
    }
}
```

### select with default defeating blocking

A `select` with a `default` case in what should be a blocking receive turns it into a busy-loop or silently drops messages.

```go
// Bug: spins CPU if ch isn't ready, or silently drops
for {
    select {
    case msg := <-ch:
        handle(msg)
    default:
        // busy-loops here
    }
}

// Fix: block until a message or cancellation
for {
    select {
    case msg := <-ch:
        handle(msg)
    case <-ctx.Done():
        return
    }
}
```

## Defer

### Deferred call argument evaluation

Arguments to a deferred function are evaluated at the `defer` statement, not when the function runs. `defer f(x)` captures `x` now; `defer func() { f(x) }()` captures `x` later.

```go
// Bug: always logs the initial value of status
defer log.Printf("status: %s", status)
status = "done"

// Fix: closure captures the final value
defer func() { log.Printf("status: %s", status) }()
status = "done"
```

### defer in loops

`defer` doesn't run until the function returns, not at end of loop iteration. In a loop that opens resources, all closes pile up until function exit, causing resource exhaustion.

```go
// Bug: all files stay open until function returns
for _, path := range paths {
    f, err := os.Open(path)
    if err != nil { return err }
    defer f.Close()
    process(f)
}

// Fix: extract to a function, or close explicitly
for _, path := range paths {
    if err := processFile(path); err != nil {
        return err
    }
}
```

### Named return values + defer interaction

A deferred function can silently modify named return values. This is sometimes intentional but frequently accidental, especially when a later refactor adds a named return to a function that already had defers.

```go
// Subtle: defer modifies the returned error
func doWork() (err error) {
    defer func() {
        err = fmt.Errorf("wrapped: %w", err) // changes what caller sees
    }()
    return originalWork()
}
```

### recover scope

`recover` only works inside a directly deferred function. Calling `recover()` in a nested function called from a deferred function does nothing.

```go
// Bug: recover is not direct -- does nothing
defer func() {
    handlePanic() // recover() inside here won't catch anything
}()

// Fix: call recover directly in the deferred function
defer func() {
    if r := recover(); r != nil {
        log.Printf("recovered: %v", r)
    }
}()
```

## Slices and maps

### Slice aliasing after append

`append` may or may not allocate a new backing array. Code that appends to a sub-slice and expects the original to be unchanged (or vice versa) is a latent bug.

```go
// Bug: append may overwrite original's elements
a := []int{1, 2, 3, 4}
b := append(a[:2], 5) // if cap(a[:2]) > 2, a[2] is now 5

// Fix: force a copy with full slice expression
b := append(a[:2:2], 5) // cap is limited, so append allocates
```

### Range over map non-determinism

Code that depends on map iteration order is broken. This includes building deterministic output (serialization, hashing, logging) from map contents.

```go
// Bug: output order varies between runs
for k, v := range config {
    fmt.Fprintf(w, "%s=%s\n", k, v)
}

// Fix: sort keys first
keys := slices.Sorted(maps.Keys(config))
for _, k := range keys {
    fmt.Fprintf(w, "%s=%s\n", k, config[k])
}
```

### reflect.DeepEqual nil vs empty

`reflect.DeepEqual([]int{}, []int(nil))` is `false`, and same for nil map vs empty map. Breaks comparison logic and tests.

```go
// Bug: fails even though both are "empty"
assert.True(t, reflect.DeepEqual(got, []int{})) // got is []int(nil)

// Fix: use cmp.Equal with EquateEmpty
if diff := cmp.Diff(want, got, cmpopts.EquateEmpty()); diff != "" {
    t.Errorf("mismatch (-want +got):\n%s", diff)
}
```

## Interfaces and types

### Nil interface vs nil pointer

A concrete nil pointer stored in an interface is not `== nil`. Functions returning `(*T)(nil)` as `error` or any interface silently break nil checks upstream.

```go
// Bug: err is not nil, even though the pointer is
func validate() error {
    var err *MyError // nil pointer
    return err       // interface{type: *MyError, value: nil} != nil
}

if err := validate(); err != nil {
    // always enters here
}

// Fix: return nil explicitly
func validate() error {
    return nil
}
```

### Single-value type assertion panic

`v := x.(T)` crashes at runtime if `x` doesn't hold `T`. The two-value form should be used unless the assertion is provably safe.

```go
// Bug: panics if x is not a string
s := x.(string)

// Fix: use comma-ok
s, ok := x.(string)
if !ok {
    return fmt.Errorf("unexpected type %T", x)
}
```

### Embedded interface nil method panic

A struct embeds an interface but doesn't implement all methods. This compiles, but calling an unimplemented method panics at runtime with a nil pointer dereference.

```go
// Bug: compiles but panics at runtime
type MyWriter struct {
    io.ReadWriter // embedded interface
}
w := MyWriter{}
w.Read(buf) // nil pointer dereference -- Read is not implemented
```

### Value receiver on mutating method

A method with a value receiver that modifies struct fields silently operates on a copy; the caller's struct is unchanged.

```go
// Bug: caller's counter is never incremented
func (c Counter) Increment() {
    c.n++
}

// Fix: pointer receiver
func (c *Counter) Increment() {
    c.n++
}
```

## Error handling

### Error wrapping breakage

Wrapping with `fmt.Errorf("...%v", err)` instead of `%w` breaks `errors.Is` and `errors.As` chains. Wrapping a sentinel error with `%w` when you don't intend callers to match on it leaks implementation detail.

```go
// Bug: breaks error matching
return fmt.Errorf("failed: %v", err)

// Fix: use %w to preserve the chain
return fmt.Errorf("failed: %w", err)
```

### Short variable declaration shadowing

`:=` in an inner scope can shadow an outer `err` or other variable, causing the outer variable to silently retain its old value.

```go
// Bug: outer err is never set
var err error
if condition {
    result, err := doWork() // shadows outer err
    process(result)
}
return err // always nil

// Fix: declare result separately
var err error
if condition {
    var result int
    result, err = doWork() // assigns to outer err
    process(result)
}
return err
```

## Resource leaks

### HTTP response body leak

Not closing `resp.Body` (or closing it only on the success path, not the error path) leaks connections. The body must be read and closed even when you don't need the content.

```go
// Bug: body not closed on non-2xx responses
resp, err := http.Get(url)
if err != nil { return err }
if resp.StatusCode != 200 {
    return fmt.Errorf("bad status: %d", resp.StatusCode) // body leaked
}
defer resp.Body.Close()

// Fix: close immediately after error check
resp, err := http.Get(url)
if err != nil { return err }
defer resp.Body.Close()
```

### time.Ticker leak

Creating a `time.NewTicker` without calling `Stop()` when done leaks the ticker goroutine.

```go
// Bug: ticker runs forever
ticker := time.NewTicker(time.Second)
for range ticker.C {
    if done { break }
}
// ticker never stopped

// Fix: defer Stop
ticker := time.NewTicker(time.Second)
defer ticker.Stop()
```

### io.Reader consumed twice

Reading `http.Request.Body` or any `io.Reader` twice silently returns empty on the second read. Must buffer with `io.ReadAll` + `io.NopCloser` reset, or use `io.TeeReader`.

```go
// Bug: second read gets nothing
body, _ := io.ReadAll(r.Body)
log.Println(string(body))
json.NewDecoder(r.Body).Decode(&v) // empty

// Fix: reset the body
body, _ := io.ReadAll(r.Body)
r.Body = io.NopCloser(bytes.NewReader(body))
log.Println(string(body))
json.NewDecoder(r.Body).Decode(&v)
```

## Testing

### t.Parallel with loop variable capture

Table-driven tests using `t.Run` + `t.Parallel()` without capturing the loop variable run all subtests with the last table entry. Fixed in Go 1.22+ but common in older codebases.

```go
// Bug: all subtests use the last value of tc
for _, tc := range tests {
    t.Run(tc.name, func(t *testing.T) {
        t.Parallel()
        assert.Equal(t, tc.want, doWork(tc.input)) // tc is the last entry
    })
}

// Fix: capture the variable (pre-Go 1.22)
for _, tc := range tests {
    tc := tc
    t.Run(tc.name, func(t *testing.T) {
        t.Parallel()
        assert.Equal(t, tc.want, doWork(tc.input))
    })
}
```

### t.Fatal in goroutines

Calling `t.Fatal`, `t.FailNow`, or `require.*` from a goroutine spawned in a test calls `runtime.Goexit` on that goroutine, not the test goroutine. The test may pass despite the failure, or panic.

```go
// Bug: t.Fatal in a non-test goroutine
go func() {
    result := doWork()
    require.Equal(t, expected, result) // wrong goroutine
}()

// Fix: collect errors and check on the test goroutine
errCh := make(chan error, 1)
go func() {
    result := doWork()
    if result != expected {
        errCh <- fmt.Errorf("got %v, want %v", result, expected)
        return
    }
    errCh <- nil
}()
require.NoError(t, <-errCh)
```

## Encoding and strings

### String bytes vs runes

`s[i]` yields a byte, `for _, c := range s` yields runes. Mixing indexing and range over multi-byte strings corrupts data or gives wrong offsets. `len(s)` returns byte count, not character count.

```go
// Bug: truncates mid-character for multi-byte strings
func truncate(s string, n int) string {
    return s[:n] // byte offset, not character offset
}

// Fix: count runes
func truncate(s string, n int) string {
    runes := []rune(s)
    if len(runes) <= n { return s }
    return string(runes[:n])
}
```

### strings.TrimRight vs strings.TrimSuffix

`strings.TrimRight` trims a *set of characters*, not a suffix. It removes any trailing characters that appear in the cutset, which can over-trim.

```go
// Bug: TrimRight removes characters, not a suffix
s := strings.TrimRight("foo.tar.gz", ".gz") // "foo.tar" (correct by accident)
s := strings.TrimRight("foog.gz", ".gz")    // "foo" (over-trimmed)

// Fix: use TrimSuffix to remove an exact suffix
s := strings.TrimSuffix("foog.gz", ".gz") // "foog"
```

### json.Unmarshal into non-zeroed struct

Unmarshaling into an existing struct doesn't clear fields absent from the JSON payload. Reusing a struct across multiple unmarshals silently carries stale values from previous calls.

```go
// Bug: stale fields from first unmarshal leak into second
var msg Message
json.Unmarshal(data1, &msg) // sets msg.Name and msg.Age
json.Unmarshal(data2, &msg) // data2 has no Age -- msg.Age is stale

// Fix: use a fresh struct each time
var msg Message
json.Unmarshal(data2, &msg)
```

## Filesystem and paths

### filepath.Join cleaning

Strips trailing slashes, which can break directory-indicating paths in cloud APIs (S3, GCS). Also `filepath.Join` is OS-aware (backslashes on Windows) while `path.Join` always uses forward slashes; using the wrong one breaks URL construction or cross-platform filesystem operations.

```go
// Bug: trailing slash stripped, S3 treats as file not prefix
prefix := filepath.Join(bucket, "logs/") // becomes "bucket/logs"

// Fix: use path.Join for URLs/cloud paths, add slash explicitly
prefix := path.Join(bucket, "logs") + "/"
```
