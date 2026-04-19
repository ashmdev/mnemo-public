# Core: Performance Awareness

## Purpose

Build performance thinking into everyday development without falling into premature
optimization. The goal is not to make everything fast — it is to avoid making things
unnecessarily slow and to know when and how to measure before optimizing.

## When to Use

During implementation and code review. Performance awareness is a background concern
on every change, becoming a foreground concern when touching data access, hot paths,
or user-facing latency.

## Instructions

### 1. The First Rule: Measure Before Optimizing

Never optimize based on intuition. Measure first, optimize the bottleneck, measure again.

```bash
# Profile before touching anything
go test -bench=. -benchmem ./...
go tool pprof cpu.prof

# Or for web services
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:8080/api/users

# Or application-level timing
start = time.now()
result = expensive_operation()
duration = time.since(start)
logger.info("operation took", duration=duration)
```

If you cannot demonstrate the problem with numbers, you do not have a performance problem.
You have a guess.

### 2. Common Performance Pitfalls

#### N+1 Queries

The most common database performance bug. One query fetches N records, then N more
queries fetch related data one at a time.

```go
// BAD — N+1 queries
users, _ := db.Query("SELECT * FROM users")
for _, user := range users {
    orders, _ := db.Query("SELECT * FROM orders WHERE user_id = ?", user.ID)
    // one query per user
}

// GOOD — single query with JOIN or batch
rows, _ := db.Query(`
    SELECT u.*, o.* FROM users u
    LEFT JOIN orders o ON o.user_id = u.id
`)
```

#### Unbounded Queries

Loading all records without a limit is a time bomb. The table has 100 rows today and
10 million next year.

```go
// BAD — loads entire table
db.Query("SELECT * FROM events")

// GOOD — paginated with limit
db.Query("SELECT * FROM events ORDER BY created_at DESC LIMIT $1 OFFSET $2", limit, offset)
```

#### Goroutine/Thread Leaks

Starting concurrent work without ensuring it terminates:

```go
// BAD — goroutine runs forever if context is never cancelled
go func() {
    for {
        processItem()
    }
}()

// GOOD — respects context cancellation
go func() {
    for {
        select {
        case <-ctx.Done():
            return
        case item := <-ch:
            processItem(item)
        }
    }
}()
```

#### Unnecessary Allocations in Hot Paths

```go
// BAD — allocates a new buffer every call in a tight loop
func process(data []byte) string {
    var buf bytes.Buffer // allocated every call
    buf.Write(data)
    return buf.String()
}

// GOOD — reuse via sync.Pool or pre-allocated buffer
var bufPool = sync.Pool{New: func() any { return new(bytes.Buffer) }}
```

### 3. Database Performance

#### Indexes

Add indexes for:
- Columns in WHERE clauses that filter large tables
- Columns used in JOIN conditions
- Columns used in ORDER BY on large result sets
- Composite indexes for multi-column queries (column order matters)

```sql
-- Query: SELECT * FROM orders WHERE user_id = ? AND status = 'active' ORDER BY created_at
-- Index that covers this query:
CREATE INDEX idx_orders_user_status_created ON orders(user_id, status, created_at);
```

Do NOT add indexes speculatively. Each index slows writes and uses storage.
Add them when query performance data demands it.

#### Connection Pooling

- Set maximum open connections based on load testing, not guesses
- Set idle connection timeout to prevent stale connections
- Monitor connection pool saturation in production

### 4. Caching Strategies

Cache when the same data is read frequently and changes rarely:

| Strategy | When | Example |
|----------|------|---------|
| **In-memory** | Single instance, small dataset | User session data, config |
| **Redis/Memcached** | Multi-instance, shared cache | API responses, computed results |
| **HTTP caching** | Static or rarely changing content | Assets, public API responses |
| **Query result cache** | Expensive queries, tolerant of staleness | Dashboard aggregations |

**Cache invalidation rules:**
- Set TTLs. Do not cache forever.
- Invalidate on write when consistency matters.
- Use cache-aside pattern: check cache, miss goes to DB, populate cache.
- Accept eventual consistency for read-heavy, write-light data.

### 5. When to Care About Performance

| Situation | Performance Priority |
|-----------|---------------------|
| Hot path (runs per request) | High — measure and optimize |
| Background job (runs hourly) | Low — correctness first |
| Startup code (runs once) | Minimal — unless blocking deployment |
| User-facing latency (API response) | High — set and monitor SLOs |
| Data pipeline (batch processing) | Medium — throughput matters, latency less so |

### 6. Performance Review Checklist for PRs

During code review, flag these:
- New database queries without LIMIT
- Queries inside loops (potential N+1)
- New goroutines/threads without lifecycle management
- Large allocations in request-scoped code
- Missing indexes for new query patterns
- Synchronous calls that could be async

## Output Format

When reporting performance findings:

```markdown
### Performance Assessment
| Area | Finding | Severity | Recommendation |
|------|---------|----------|----------------|
| DB queries | N+1 in user listing | High | Batch with JOIN |
| Memory | Buffer allocation per request | Low | Pool if profiled as hot |
| Indexes | New query on orders.status | Medium | Add index after measuring |
```

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Before optimization | Known bottlenecks, prior performance decisions |
| Store | After optimization | What was slow, why, what fixed it, measurements |
| Store | After adding index | Index rationale, query patterns it serves |

## Validation Checklist

- [ ] Performance claims backed by measurements, not intuition
- [ ] No N+1 queries introduced
- [ ] All queries have appropriate LIMIT clauses
- [ ] Concurrent work has lifecycle management (context cancellation, shutdown)
- [ ] Indexes considered for new query patterns
- [ ] Caching has TTL and invalidation strategy
- [ ] No premature optimization of cold paths
