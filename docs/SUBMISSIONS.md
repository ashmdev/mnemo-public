# Mnemo — Registry Submissions Runbook

**Roadmap task**: [`T-Q2W01-01`](./ROADMAP_2026.md) · Register Mnemo on MCP Registry + PulseMCP (SkillsIndex skipped — own marketplace)
**Last updated**: 2026-04-17

This runbook consolidates the steps needed to list Mnemo on the two target directories. Some steps require maintainer-only credentials (GitHub OAuth as `ashmdev`) and are flagged **ACTION: USER**.

Mnemo's core source repo `ashmdev/mnemo` is private by design (closed-core, MIT-licensed binaries distributed via `ashmdev/mnemo-releases`). The registry entry is therefore **discovery-only**: `server.json` carries no `packages[]` array. Clients read the metadata, follow the `repository.url` to the public release repo, and install via Homebrew / shell installer / direct binary download.

---

## 1. MCP Registry (`registry.modelcontextprotocol.io`)

**Source of truth**: [`server.json`](../server.json) at repo root.

The registry hosts *metadata only* — it does not redistribute artifacts. A discovery-only entry is valid: it lists the server by name, points at a public repository, and lets users follow the README's install instructions.

### 1.1 Distribution posture

`server.json` omits `packages[]` deliberately. The closed-core posture means we do **not** publish a public OCI image, a public Go module, or anything else tied to `ashmdev/mnemo`. Users install via:

- `brew install ashmdev/tap/mnemo` (Homebrew tap, public)
- `curl -fsSL https://mnemo.dev/install | sh` (shell installer)
- Direct download from https://github.com/ashmdev/mnemo-releases/releases

The `repository.url` field points at [`ashmdev/mnemo-public`](https://github.com/ashmdev/mnemo-public) — the dedicated public repo for community-facing assets (`packs/`, `plugin/`, `server.json`, `docs/SUBMISSIONS.md`, `docs/USER_GUIDE.md`, bespoke public README). Synced from this private core via [`.github/workflows/sync-public.yml`](../.github/workflows/sync-public.yml) on each `v*` tag — see [`docs/PUBLIC-REPO.md`](./PUBLIC-REPO.md) for the split rationale, allow-list / block-list firewall, and PAT setup.

Binary distribution continues to live on [`ashmdev/mnemo-releases`](https://github.com/ashmdev/mnemo-releases) (GoReleaser-published archives). `server.json` `_meta.installation.binary` points there; `repository.url` points at `mnemo-public` (source-of-community-truth, not a source-of-engine-truth — the core stays private by design).

### 1.2 Install `mcp-publisher`

```bash
# Clone the registry repo somewhere outside the Mnemo checkout:
git clone https://github.com/modelcontextprotocol/registry /tmp/mcp-registry
cd /tmp/mcp-registry
make publisher
export PATH="$PWD/bin:$PATH"
mcp-publisher --help
```

Alternatively, wait for an upstream binary release of `mcp-publisher` and install via `go install github.com/modelcontextprotocol/registry/cmd/mcp-publisher@latest` once available.

### 1.3 Authenticate

**ACTION: USER** — required because the namespace `io.github.ashmdev/mnemo` can only be claimed by the `ashmdev` GitHub account:

```bash
mcp-publisher login github
# Opens a browser; sign in as ashmdev; approve OAuth scopes.
```

### 1.4 Publish

From the Mnemo repo root (where `server.json` lives):

```bash
cd /path/to/mnemo
mcp-publisher publish
```

The CLI validates the file against the 2025-12-11 schema, checks that the namespace matches the authenticated user, and submits the entry. Expect a status URL in the output.

### 1.5 Verify

```bash
curl -s "https://registry.modelcontextprotocol.io/v0/servers?search=mnemo" | jq
```

The entry should appear within minutes. If it does not, check `mcp-publisher publish` output for validation errors and re-run after fixing `server.json`.

---

## 2. PulseMCP (`pulsemcp.com`)

**Effort: zero.** PulseMCP auto-ingests the Official MCP Registry daily and publishes weekly. Once §1 succeeds, Mnemo will appear on PulseMCP within ~1 week with no additional action.

If the listing has not appeared after 7 days, email PulseMCP support (see https://www.pulsemcp.com/submit) with the registry entry URL to request a manual sync. No submission form or PR is needed.

---

## 3. Claude Skills Registry (community "SkillsIndex") — **SKIPPED**

**Status**: **Cancelled 2026-04-17.** Mnemo ships its own [skills marketplace](./SKILLS_MARKETPLACE.md) with publish, search, and Bayesian trust ratings. Submitting hero skills to `majiayu000/claude-skill-registry-core` would split community signal and dilute the own-marketplace narrative.

**History**: PR [majiayu000/claude-skill-registry-core#24](https://github.com/majiayu000/claude-skill-registry-core/pull/24) was opened and immediately closed after strategy review. Fork `ashmdev/claude-skill-registry-core` pending deletion (`gh auth refresh -h github.com -s delete_repo` then `gh repo delete ashmdev/claude-skill-registry-core --yes`).

If a future quarter decides to re-list for reach (e.g. `T-Q3W11-XX` or later), the entry draft below is kept as an archive reference. Do not submit without re-opening the strategy decision.

<details>
<summary>Archived entries (reference only — do not submit without strategy review)</summary>

**Target repo**: [`majiayu000/claude-skill-registry-core`](https://github.com/majiayu000/claude-skill-registry-core)
**Mechanism**: PR adding entries to `sources/community.json`.

Mnemo is not a single skill — it is a platform shipping 55 skills across 8 packs. Submit a small curated set of hero skills (not every skill; the directory is for discovery, not inventory). The five entries below are the highest-signal picks: unique to Mnemo, cross-stack relevance, and likely to attract skill-only users who might then install the whole binary.

### 3.1 Entries to add to `sources/community.json`

Fork `majiayu000/claude-skill-registry-core`, append the block below to the `community.json` array, open a PR titled `Add Mnemo skills (memory-protocol, roadmap-keeper, judgment-day, skill-resolver, mnemo-architect)`.

Append these five objects inside the top-level `skills` array of `sources/community.json` (single-line format to match the file's existing convention):

```json
{"name": "mnemo-memory-protocol", "repo": "ashmdev/mnemo", "path": "packs/core/skills/memory-protocol.md", "description": "Always-active protocol that forces AI coding agents to proactively persist decisions, conventions, bugs, discoveries, and preferences. The behavioural contract that makes persistent memory automatic.", "category": "productivity", "tags": ["memory", "persistence", "always-on", "claude-code", "cursor", "windsurf", "mcp"], "stars": 0, "featured": true},
{"name": "mnemo-roadmap-keeper", "repo": "ashmdev/mnemo", "path": "packs/core/skills/roadmap-keeper.md", "description": "Keep a single-source-of-truth roadmap alive — stable task IDs, status transitions, dependency chains, weekly reconciliation, and the execution protocol that moves tasks from [ ] through [~] to [x] without drift.", "category": "productivity", "tags": ["roadmap", "project-management", "workflow", "documentation"], "stars": 0},
{"name": "mnemo-judgment-day", "repo": "ashmdev/mnemo", "path": "packs/quality/skills/judgment-day/SKILL.md", "description": "Adversarial pre-merge review. Pretends to be the meanest staff engineer on the team and tears the diff apart on correctness, security, performance, maintainability, and DX before humans see it.", "category": "development", "tags": ["code-review", "quality", "adversarial", "pre-merge"], "stars": 0, "featured": true},
{"name": "mnemo-skill-resolver", "repo": "ashmdev/mnemo", "path": "packs/core/skills/skill-resolver/SKILL.md", "description": "Picks the right Mnemo skill for the job via memory-aware recommendation — pulls from past execution outcomes, Bayesian trust ratings, and the active project's context.", "category": "productivity", "tags": ["skills", "recommendation", "memory-aware"], "stars": 0},
{"name": "mnemo-architecture-guard", "repo": "ashmdev/mnemo", "path": "packs/core/skills/architecture-guard.md", "description": "Enforce system boundaries, dependency rules, and structural consistency continuously as the codebase grows. Not about preventing change — about respecting contracts that keep components decoupled.", "category": "development", "tags": ["architecture", "boundaries", "hexagonal", "dependencies"], "stars": 0}
```

### 3.2 PR description template

```
This PR adds five high-signal skills from the Mnemo project
(https://github.com/ashmdev/mnemo), a persistent-memory + skills platform
for AI coding agents distributed as a single Go binary.

Each skill is a standalone Markdown file with YAML frontmatter and is
useful whether or not the reader installs the full Mnemo binary.
Descriptions are specific to each skill's unique contribution; no
generic summaries.

Mnemo is MIT-licensed. Skills follow the standard SKILL.md convention.

Related: Mnemo is also being listed on the Official MCP Registry
(io.github.ashmdev/mnemo).
```

### 3.3 Additional community directories (optional, low-effort follow-up)

| Directory | Mechanism | Effort |
|---|---|---|
| OneSkill (`oneskill.dev`) | Auto-indexed from GitHub. Verify Mnemo repo is tagged with `claude-skill` in GitHub topics. | 2 min |
| Skills Directory (`skillsdirectory.com`) | Security-scanned; manual submission form. | 10 min |
| mcpmarket.com | Auto-indexed from Official MCP Registry. Zero extra action after §1. | 0 |

Skip these if time-boxed to the quarter-day scope; add as follow-up task if marketing post-launch calls for more surface area. **Note** — these auto-indexers are lower-risk than `majiayu000/claude-skill-registry-core` because they point at the repo, not at individual skills, so they do not dilute the own-marketplace narrative.

</details>

---

## 4. Completion checklist

A checkpoint for flipping [`T-Q2W01-01`](./ROADMAP_2026.md) from `[~]` to `[x]`:

- [ ] `mcp-publisher publish` returned success; entry visible at `registry.modelcontextprotocol.io/v0/servers?search=mnemo`
- [ ] PulseMCP — no action; record a note in `BACKLOG.md` that ingest is expected within 7 days of §1
- [ ] `BACKLOG.md` §✅ updated with row: `T-Q2W01-01 · MCP Registry discovery-only + PulseMCP auto-ingest (SkillsIndex skipped, OCI skipped — closed-core posture) · <commit SHA> · 2026-04-??`

Once the first three land, flip the roadmap checkbox and commit with message `roadmap(done): T-Q2W01-01 registry listings shipped`.
