# Concurrency

## Purpose

Write safe, efficient concurrent Go code using goroutines, channels, and synchronization primitives with proper lifecycle management and cancellation.

## When to Use

- Launching background work or parallel computations
- Building worker pools or fan-out/fan-in pipelines
- Coordinating multiple goroutines with shared state
- Handling timeouts, cancellation, and graceful shutdown

## Instructions

### Goroutine Lifecycle Rules

1. **Never fire-and-forget.** Every goroutine must have a clear termination path. If you start it, you must know how and when it stops.
2. **Own the goroutine you start.** The caller that launches a goroutine is responsible for ensuring it exits.
3. **Use `context.Context` for cancellation.** Pass it as the first parameter. Check `ctx.Done()` in loops and selects.

### Channel Patterns

- **Directional channels in signatures.** Accept `<-chan T` or `chan<- T`, not bidirectional `chan T`.
- **Close from the sender side only.** Never close a channel from the receiver. One sender, one close.
- **Range over channels** to consume until closed: `for v := range ch { ... }`.
- **Buffered channels** for known bounded work. Unbuffered for synchronization points.

### Select Statement

- Always include a `case <-ctx.Done():` branch for cancellation.
- Use `default` only when you explicitly want non-blocking behavior.
- Avoid `time.After` inside loops (leaks timers). Use `time.NewTimer` and reset it.

### Sync Primitives

- **`sync.Mutex`**: Protect shared state. Keep critical sections small. Never copy a mutex.
- **`sync.WaitGroup`**: Call `Add` before launching goroutines, `Done` in a deferred call inside the goroutine.
- **`sync.Once`**: Lazy initialization. The function passed to `Do` runs exactly once.
- **`sync.Pool`**: Reuse expensive allocations (byte buffers, structs). Not for connection pooling.
- **`sync.Map`**: Only when keys are stable and contention is high. Prefer regular map + mutex otherwise.

### Worker Pool Pattern

```go
func Pool(ctx context.Context, jobs <-chan Job, workers int) <-chan Result {
    results := make(chan Result, workers)
    var wg sync.WaitGroup
    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for job := range jobs {
                select {
                case <-ctx.Done():
                    return
                case results <- process(job):
                }
            }
        }()
    }
    go func() {
        wg.Wait()
        close(results)
    }()
    return results
}
```

### Bounded Goroutines

Use a semaphore channel to limit concurrent goroutines:

```go
sem := make(chan struct{}, maxConcurrent)
for _, item := range items {
    sem <- struct{}{} // acquire
    go func(it Item) {
        defer func() { <-sem }() // release
        process(it)
    }(item)
}
```

### errgroup for Coordinated Error Handling

```go
g, ctx := errgroup.WithContext(ctx)
for _, url := range urls {
    g.Go(func() error {
        return fetch(ctx, url)
    })
}
if err := g.Wait(); err != nil {
    return err
}
```

## Examples

**Bad** -- goroutine leak, no cancellation:
```go
go func() {
    for {
        val := <-ch // blocks forever if ch is never closed
        process(val)
    }
}()
```

**Good** -- proper lifecycle with context:
```go
go func() {
    for {
        select {
        case <-ctx.Done():
            return
        case val, ok := <-ch:
            if !ok { return }
            process(val)
        }
    }
}()
```

## Validation

- Run with `-race` flag: `go test -race ./...` and `go run -race .`
- Every goroutine has a cancellation path reachable from context or channel close
- No `sync.Mutex` is ever copied (pass by pointer, embed in struct)
- `WaitGroup.Add` is always called before `go func`, never inside
- Worker pools drain fully on context cancellation
- No `time.After` inside `for/select` loops
