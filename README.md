<div align="center">

# Mnemo — Public Assets

**Community-facing surface for [Mnemo](https://mnemo.dev) — packs, plugins, MCP manifest, and user docs.**

[![License: MIT](https://img.shields.io/badge/License-MIT-89b4fa.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/ashmdev/mnemo-releases?label=latest&color=cba6f7)](https://github.com/ashmdev/mnemo-releases/releases)
[![Homebrew](https://img.shields.io/badge/brew-ashmdev%2Ftap%2Fmnemo-f5a97f)](https://github.com/ashmdev/homebrew-tap)

</div>

---

Mnemo is persistent memory plus 55 expert skills plus workflows for AI coding agents, shipped as a single Go binary. This repo holds the **community-facing assets** — the pieces that are useful to read, fork, or extend independently of the engine:

- [`packs/`](packs/) — 8 skill packs, 55 skills covering `core`, `go`, `typescript`, `react`, `nextjs`, `sdd`, `quality`, and `chilean-dev`.
- [`plugin/`](plugin/) — per-agent plugin sources for Claude Code, Cursor, Windsurf, Codex, OpenCode, Gemini CLI, Confluence, and Notion.
- [`server.json`](server.json) — the MCP Registry manifest.
- [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md) — end-user quickstart.
- [`docs/SUBMISSIONS.md`](docs/SUBMISSIONS.md) — registry submissions runbook.

The **core engine source** (consolidation, tiering, cloud, billing, orchestrator) lives in a private repo at `ashmdev/mnemo` by design — closed core, open community. See the [repo split explained](#repo-split) below.

---

## Install

Mnemo is distributed as pre-built binaries, not as source. The public binary surface is [`ashmdev/mnemo-releases`](https://github.com/ashmdev/mnemo-releases).

```bash
# macOS / Linux (Homebrew)
brew install ashmdev/tap/mnemo

# Or grab a pre-built binary
curl -fsSL https://mnemo.dev/install | sh

# Or download directly
# https://github.com/ashmdev/mnemo-releases/releases/latest
```

Then wire up your agent:

```bash
mnemo setup claude-code
```

See [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md) for the full quickstart.

---

## Packs & skills

Each pack is a directory under [`packs/`](packs/) containing a `pack.json` manifest plus one or more skill definitions and personas. Install a pack to get its skills available to your agent:

```bash
mnemo pack install core
mnemo pack install typescript
mnemo skill list
```

Skills are single Markdown files with YAML frontmatter. Browse them directly — they are useful reading even without installing Mnemo. Highlighted skills:

- [`memory-protocol`](packs/core/skills/memory-protocol.md) — the always-active contract that makes persistent memory automatic.
- [`roadmap-keeper`](packs/core/skills/roadmap-keeper.md) — keep a single-source-of-truth roadmap alive; status transitions, dependency chains, weekly reconciliation.
- [`judgment-day`](packs/core/skills/judgment-day.md) — adversarial pre-merge review.
- [`architecture-guard`](packs/core/skills/architecture-guard.md) — enforce system boundaries and dependency rules.
- [`commit-hygiene`](packs/core/skills/commit-hygiene.md) — conventional commits, HEREDOC, trailer discipline.

---

## Agent plugins

[`plugin/`](plugin/) holds the per-agent integration source. Each subdirectory targets one agent:

| Agent | Plugin path |
|---|---|
| Claude Code | [`plugin/claude-code/`](plugin/claude-code/) |
| Cursor | [`plugin/cursor/`](plugin/cursor/) |
| Windsurf | [`plugin/windsurf/`](plugin/windsurf/) |
| Codex | [`plugin/codex/`](plugin/codex/) |
| OpenCode | [`plugin/opencode/`](plugin/opencode/) |
| Gemini CLI | [`plugin/gemini-cli/`](plugin/gemini-cli/) |
| Confluence importer | [`plugin/confluence-importer/`](plugin/confluence-importer/) |
| Notion importer | [`plugin/notion-importer/`](plugin/notion-importer/) |

---

## Repo split

Mnemo runs four public surfaces and one private surface:

| Repo | Visibility | Role |
|---|---|---|
| [`ashmdev/mnemo`](https://github.com/ashmdev/mnemo) | private | Core engine source — consolidation, tiering, cloud, billing, orchestrator |
| [`ashmdev/mnemo-public`](https://github.com/ashmdev/mnemo-public) | **public** | This repo — community-facing assets (packs, plugins, manifest, user docs) |
| [`ashmdev/mnemo-releases`](https://github.com/ashmdev/mnemo-releases) | public | Binary archives (one GitHub Release per `v*` tag) |
| [`ashmdev/homebrew-tap`](https://github.com/ashmdev/homebrew-tap) | public | Homebrew cask — the `brew install` path |

This repo is mirrored from the private core on each `v*` tag push via a sync workflow. Only an explicit allow-list (`packs/`, `plugin/`, `server.json`, two doc files, `LICENSE`) reaches this repo. Private engine source never touches it.

See [`.github/README-MIRROR.md`](.github/README-MIRROR.md) for the mirror mechanics and issue-posture.

---

## Contributing

Contributions to packs and plugins are welcome via issues on this repo. Because this repo is mirrored from the private core, pull requests against `packs/` or `plugin/` directly here will be rebased onto the private repo — please file an issue first so we can coordinate the patch flow.

Roadmap lives in the private repo; public snapshots of completed work will appear in release notes on [`ashmdev/mnemo-releases`](https://github.com/ashmdev/mnemo-releases/releases).

---

## License

MIT. See [`LICENSE`](LICENSE).
