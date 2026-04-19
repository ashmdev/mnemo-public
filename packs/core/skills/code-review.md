# Core: Code Review

## Purpose

Catch defects, share knowledge, and maintain codebase quality through systematic review.
A good review is not about style preferences — it is about correctness, clarity, and
long-term maintainability. Every review is both a quality gate and a teaching opportunity.

## When to Use

Every pull request before merge. Self-review before requesting peer review. Code review
is mandatory, not optional, regardless of the author's seniority.

## Instructions

### 1. Before You Review

- Read the PR description and linked issue first. Understand the *intent*.
- Check the branch is up-to-date with the target branch.
- Pull the branch locally if the diff is large or complex.
- Recall relevant Mnemo context for the area being changed.

### 2. Correctness Check

The most important dimension. Does the code do what it claims to do?

- **Logic errors:** Off-by-one, wrong comparison operator, missing null checks
- **Boundary conditions:** What happens at 0, 1, MAX, empty, nil?
- **Concurrency:** Race conditions, deadlocks, shared mutable state
- **Error handling:** Are errors caught, wrapped with context, and propagated correctly?
- **Resource management:** Are connections closed? Files released? Goroutines/threads bounded?

```
# Red flag examples
if len(items) > 0     // should this be >= 1? Or != 0? Are they the same?
defer db.Close()      // is this in a loop? Deferred close in a loop leaks.
go handleRequest(r)   // unbounded goroutine spawning — what limits concurrency?
```

### 3. Security Check

Every PR is a security review, even if it does not touch auth code.

- **Input validation:** Is all external input validated before use?
- **SQL injection:** Are queries parameterized? No string concatenation with user input.
- **Secrets:** No hardcoded keys, tokens, or passwords. Check for leaked credentials.
- **Authorization:** Does the code verify the user has permission, not just authentication?
- **Data exposure:** Are error messages leaking internal details to users?

### 4. Performance Check

Not premature optimization — targeted awareness of common pitfalls.

- **N+1 queries:** Loop with a database call inside. Batch instead.
- **Unbounded collections:** Loading all records without pagination or limits.
- **Missing indexes:** New query patterns that will table-scan in production.
- **Memory allocation:** Large allocations in hot paths, unnecessary copies.
- **Goroutine/thread leaks:** Started but never stopped.

### 5. Readability Check

Code is read far more than it is written.

- **Naming:** Do variables, functions, and types reveal intent?
- **Function length:** Can you understand the function without scrolling? If not, split it.
- **Abstraction level:** Does the function mix high-level orchestration with low-level detail?
- **Comments:** Do comments explain *why*, not *what*? Are there missing comments on non-obvious logic?

### 6. Maintainability Check

Will this code age well?

- **Test coverage:** Are the new paths tested? Are edge cases covered?
- **Coupling:** Does this change increase coupling between components?
- **Conventions:** Does it follow existing project patterns, or introduce a new way?
- **Reversibility:** If this change is wrong, how hard is it to undo?

### 7. Giving Feedback

Classify every comment:

| Prefix | Meaning | Action Required |
|--------|---------|-----------------|
| **blocking:** | Must fix before merge | Yes, stops merge |
| **suggestion:** | Would improve but not required | Author decides |
| **question:** | Seeking understanding | Needs response |
| **nit:** | Style/trivial, take or leave | No action required |

```markdown
blocking: This query is vulnerable to SQL injection. User input is
concatenated directly into the WHERE clause. Use parameterized queries.

suggestion: Consider extracting this validation into a separate function.
It would make the handler easier to test independently.

question: Why was retryCount set to 5 here? Is there a specific failure
mode that requires multiple retries?

nit: Typo in the error message — "recieve" should be "receive".
```

### 8. Red Flags That Block Merge

These always require resolution before merging:

- Unhandled errors (swallowed silently)
- SQL injection or XSS vulnerabilities
- Hardcoded secrets or credentials
- Missing tests for new behavior
- Broken existing tests
- Data loss potential (DELETE without WHERE conditions, migrations without rollback)
- Unbounded resource consumption

## Output Format

```markdown
## Code Review: PR #<number>

### Summary
<One sentence: what the PR does and overall assessment>

### Blocking Issues
- [ ] <issue with file:line reference and explanation>

### Suggestions
- <suggestion with rationale>

### Questions
- <question about intent or approach>

### Approval Status
APPROVED / CHANGES REQUESTED / NEEDS DISCUSSION
```

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Before review | Conventions, architecture decisions, past bugs in this area |
| Store | After review | Recurring patterns found, new review guidelines established |

## Validation Checklist

- [ ] PR description and linked issue read before reviewing code
- [ ] Correctness checked: logic, boundaries, concurrency, errors
- [ ] Security checked: input validation, injection, secrets, authorization
- [ ] Performance checked: N+1, unbounded queries, resource leaks
- [ ] Readability checked: naming, function length, comments
- [ ] Feedback classified as blocking/suggestion/question/nit
- [ ] All blocking issues clearly identified
