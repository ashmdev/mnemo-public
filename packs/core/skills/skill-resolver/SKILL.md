# Core: Skill Resolver — Automatic Context Matching

## Purpose

Automatically match installed skills to the current task based on file context
and task type. When delegating work to sub-agents, inject only the relevant
compact rules (50-150 tokens each) instead of full skill files (800+ tokens).
This saves tokens and improves sub-agent focus.

## When to Use

This is a PROTOCOL, not a standalone skill. It activates automatically when:
- An orchestrator delegates work to sub-agents (judgment-day, SDD phases)
- The skill-registry exists (`.mnemo/skill-registry.md` or in Mnemo memory)
- Files are being processed that match skill patterns

## Instructions

### Resolution Flow

When an orchestrator needs to delegate work:

#### Step 1: Obtain the Registry

Try in order (stop at first success):
1. `mem_search(query: "skill-registry", project: "{project}", type: "config")` → use content
2. Read `.mnemo/skill-registry.md` from project root
3. If neither found → warn and skip skill injection

#### Step 2: Identify Context

Determine what the sub-agent will work with:
- **File context**: List all files in scope → extract extensions (`.tsx`, `.go`, `.py`, etc.)
- **Task context**: What is the sub-agent doing? (review, implement, test, document, etc.)
- **Module context**: What area of the codebase? (auth, api, ui, database, etc.)

#### Step 3: Match Skills

From the registry's Compact Rules section, select skills that match:

**By file extension:**
| Extension | Likely Skills |
|-----------|--------------|
| `.ts`, `.tsx` | typescript, react, nextjs |
| `.go` | go-patterns, go-testing |
| `.py` | python patterns |
| `.rs` | rust patterns |
| `.vue` | vue patterns |
| `.css`, `.scss` | styling, tailwind |
| `Dockerfile`, `.yaml` | devops, docker |
| `*.test.*`, `*.spec.*` | testing-discipline |
| `*.md` | documentation |

**By task type:**
| Task | Likely Skills |
|------|--------------|
| review code | framework + language skills + code-review |
| implement feature | framework + language skills + architecture-guard |
| write tests | testing-discipline + framework test patterns |
| create PR | branch-pr, commit-hygiene |
| fix bug | framework skills + error-handling |
| write docs | documentation, docs-alignment |

**Maximum 5 skill blocks** per delegation (token budget: ~400-600 tokens).
Prioritize by: framework-specific > language-specific > generic.

#### Step 4: Build Injection Block

Construct the block to inject into the sub-agent prompt:

```markdown
## Project Standards (auto-resolved)

The following rules are from the project's skill registry. Follow them.

### {skill-name-1}
- Rule 1
- Rule 2
- ...

### {skill-name-2}
- Rule 1
- Rule 2
- ...
```

#### Step 5: Inject into Sub-Agent Prompt

When launching the sub-agent (via Agent tool or delegate), include the block
AFTER the task description and BEFORE any file content.

#### Step 6: Report Resolution Status

The sub-agent should include in its return:

```yaml
skill_resolution:
  status: "injected"          # injected | fallback-registry | fallback-path | none
  skills_applied:
    - react-19
    - typescript
  skills_source: "mnemo"      # mnemo | file | none
```

If the sub-agent reports anything other than `injected`, the orchestrator
should re-read the registry (self-correction loop).

### Self-Correction

If a sub-agent reports `fallback-registry` or `none`:
1. Re-read the skill registry from Mnemo or file
2. Check if new skills were installed since last read
3. If registry is stale, run `skill-registry` to regenerate it
4. Retry delegation with updated compact rules

### Semantic Matching (Mnemo Enhancement)

When file extension matching is insufficient, use Mnemo's semantic search:
```
mem_search(query: "{task description}", type: "skill", limit: 5)
```

This finds skills whose CONTENT is semantically similar to the task,
even if the file extension doesn't match. Example: a `.go` file doing
HTTP routing might benefit from `api-gateway-patterns` skill that wouldn't
match on extension alone.

## Token Economics

| Approach | Tokens per Delegation | Quality |
|----------|----------------------|---------|
| No skills | 0 | Low (generic) |
| Full SKILL.md files (3-4) | 2,400-3,200 | High but wasteful |
| **Compact rules (3-4)** | **400-600** | **High and efficient** |

Compact rules deliver ~80% of the value at ~20% of the token cost.

## Memory-Aware Skill Resolution

When the skill resolver runs, it enhances delegation with execution history:

### Step 7: Inject Execution Context

After resolving skills (Step 4), enrich the injection block with memory-aware context:

1. For each matched skill, call `skill_track_execution` to check past outcomes:
   ```
   summary = SkillExecutionSummary(skill_name, project)
   ```

2. If the skill has execution history (total_uses > 0), append context:
   ```markdown
   ### {skill-name} (used {N} times, last outcomes: success, success, partial)
   - Rule 1
   - Rule 2
   - Recent feedback: {any feedback from last 3 runs}
   ```

3. This enables sub-agents to:
   - **Avoid repeating failures**: "This skill failed last time with X, try alternative approach"
   - **Build on success patterns**: "Last 3 uses were successful with hexagonal architecture"
   - **Learn from feedback**: Agent feedback propagates to future invocations

### Step 8: Track Sub-Agent Outcomes

After the sub-agent completes, the orchestrator MUST report the outcome:

```
skill_track_execution(
  skill_name: "{skill}",
  project: "{project}",
  outcome: "success|partial|failed",
  feedback: "Brief description of what worked or didn't"
)
```

This closes the feedback loop: skills → sub-agents → outcomes → better skills.

### Anti-Patterns

- **DO NOT** load full skill execution history into the prompt (max 500 tokens)
- **DO NOT** block skill loading on tracking (tracking is fire-and-forget async)
- **DO NOT** skip tracking on failure — failure data is the most valuable signal
- **DO NOT** inject execution context for skills with < 3 total uses (insufficient data)

## Graceful Degradation

- No registry → skip injection, sub-agent works without project standards
- Mnemo unavailable → try file-based registry only
- No matching skills → inject empty block (sub-agent uses generic knowledge)
- Sub-agent ignores standards → orchestrator cannot enforce, but logs the gap
- Skill tracking unavailable → resolution works normally without memory-aware context
- Execution history empty → skip context injection, use standard compact rules only
