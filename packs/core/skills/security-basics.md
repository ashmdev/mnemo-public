# Core: Security Basics

## Purpose

Apply baseline security practices to every change so that common vulnerabilities are
caught during development, not in production. Security is not a separate review phase —
it is a dimension of every line of code.

## When to Use

Every PR. Every new endpoint. Every form that accepts input. Every query that touches
a database. Security review is continuous and mandatory.

## Instructions

### 1. Input Validation

All external input is untrusted until validated. External input includes:

- HTTP request bodies, query parameters, headers, cookies
- File uploads (filename, content type, content)
- Environment variables and configuration files
- Messages from queues, webhooks, third-party APIs
- URL path parameters

**Validation rules:**
- Validate type, length, range, and format before use
- Use allowlists over denylists: accept known-good, reject everything else
- Validate at the system boundary, not deep inside business logic

```go
// Good: explicit validation at the boundary
func (h *Handler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var input CreateUserInput
    if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
        respondError(w, http.StatusBadRequest, "invalid request body")
        return
    }
    if err := input.Validate(); err != nil {
        respondError(w, http.StatusBadRequest, err.Error())
        return
    }
    // input is now trusted within this boundary
}
```

### 2. SQL Injection Prevention

Never construct SQL queries with string concatenation or interpolation:

```go
// VULNERABLE
query := fmt.Sprintf("SELECT * FROM users WHERE email = '%s'", email)

// SAFE — parameterized query
query := "SELECT * FROM users WHERE email = $1"
row := db.QueryRow(query, email)
```

```python
# VULNERABLE
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")

# SAFE
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
```

This applies to all query languages: SQL, LDAP, GraphQL, ORM query builders.

### 3. Cross-Site Scripting (XSS)

Never render user-provided content without escaping:

- Use template engines that auto-escape by default (Go `html/template`, React JSX)
- Sanitize HTML if rich text is required (use a library, never roll your own)
- Set `Content-Type` headers explicitly
- Use Content Security Policy headers to limit script execution

```typescript
// VULNERABLE — raw HTML insertion
element.innerHTML = userInput;

// SAFE — text content only
element.textContent = userInput;

// SAFE — framework auto-escaping (React)
<div>{userInput}</div>
```

### 4. Authentication and Authorization

- **Authentication** (who are you?) must happen before **authorization** (what can you do?)
- Check authorization on every request, not just the first
- Verify authorization server-side, never trust client-side checks alone
- Use middleware for authentication; check permissions in the handler or service layer

```go
// Every handler that accesses a resource must verify ownership
func (h *Handler) GetDocument(w http.ResponseWriter, r *http.Request) {
    userID := auth.UserFromContext(r.Context())
    doc, err := h.service.GetDocument(docID)
    if err != nil { ... }
    if doc.OwnerID != userID {
        respondError(w, http.StatusForbidden, "access denied")
        return
    }
}
```

### 5. Secrets Management

**Never hardcode secrets.** Not in source code, not in comments, not in test files.

- Use environment variables or a secrets manager (Vault, AWS Secrets Manager, etc.)
- Add secret file patterns to `.gitignore`: `.env`, `*.pem`, `credentials.json`
- Use pre-commit hooks to detect accidentally committed secrets
- Rotate secrets immediately if they are ever exposed

```bash
# .gitignore
.env
.env.local
*.pem
*.key
credentials.json
service-account.json
```

### 6. Dependency Vulnerabilities

Third-party dependencies are attack surface:

- Run vulnerability scans regularly: `npm audit`, `go vuln check`, `pip audit`
- Pin dependency versions (use lock files)
- Review new dependencies before adding them: maintainer reputation, update frequency, known issues
- Update dependencies with known vulnerabilities promptly

### 7. Logging Security

- Never log secrets, tokens, passwords, or full credit card numbers
- Never log PII unless required and the log destination is secured
- Log security-relevant events: failed auth attempts, permission denials, input validation failures
- Include request IDs for correlation, not user credentials

```go
// BAD
logger.Info("login attempt", "password", password)

// GOOD
logger.Info("login attempt", "email", email, "success", false, "reason", "invalid_password")
```

### 8. HTTPS and Transport Security

- All production traffic over HTTPS, no exceptions
- Set HSTS headers for web applications
- Validate TLS certificates in outbound HTTP clients (do not skip verification)
- Use secure cookie flags: `Secure`, `HttpOnly`, `SameSite`

## Output Format

When reviewing security for a change:

```markdown
### Security Review: <PR or Feature>
| Check | Status | Notes |
|-------|--------|-------|
| Input validation | PASS | All endpoints validated |
| SQL injection | PASS | Parameterized queries used |
| XSS | N/A | No HTML rendering |
| Auth/Authz | PASS | Ownership verified in handler |
| Secrets | PASS | No hardcoded secrets |
| Dependencies | WARN | lodash has known CVE, update needed |
```

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Before security review | Known vulnerabilities, security patterns |
| Store | After finding vulnerability | Vulnerability details, fix applied, prevention strategy |

## Validation Checklist

- [ ] All external input validated at system boundary
- [ ] No SQL/query injection vectors (all queries parameterized)
- [ ] User content escaped before rendering (XSS prevention)
- [ ] Authorization checked on every protected endpoint
- [ ] No hardcoded secrets in source, tests, or configuration
- [ ] Dependencies scanned for known vulnerabilities
- [ ] Security-relevant events logged (without leaking secrets)
- [ ] Transport security enforced (HTTPS, secure cookies)
