# Mirror note — `ashmdev/mnemo-public`

This repository is a **public mirror** of a subset of the private core repository `ashmdev/mnemo`. The private core hosts the engine (consolidation, tiering, cloud, billing, orchestrator) and is intentionally closed-source pre-PMF. This public repo hosts the community-facing assets that benefit from being open: skill packs, agent plugins, the MCP Registry manifest, and user documentation.

---

## What lands here and how

A sync workflow in the private repo (`.github/workflows/sync-public.yml`) mirrors an explicit allow-list onto this repo on each `v*` tag push. The allow-list is the only content path from private to public:

| From `ashmdev/mnemo` | To here |
|---|---|
| `packs/` | `packs/` |
| `plugin/` | `plugin/` |
| `server.json` | `server.json` |
| `docs/SUBMISSIONS.md` | `docs/SUBMISSIONS.md` |
| `docs/USER_GUIDE.md` | `docs/USER_GUIDE.md` |

Bootstrap-only files (`README.md`, `LICENSE`, this note) are laid down on repo creation and never overwritten by the sync workflow.

A path-based firewall in the sync workflow fails the sync if any block-listed pattern (private engine source, internal docs, build configs) appears in the staged tree. If a sync fails, nothing is pushed — failing closed is the correct outcome.

---

## Why the history looks flat

Each sync commit is a single snapshot authored by `mnemo-sync[bot]` with a message of the form `sync: mnemo@<short-SHA>`. Per-file private history is not mirrored — this is intentional. The private repo's commit authors, branch structure, and intermediate WIP state stay private. The public history is a chain of snapshot commits that is human-readable and release-aligned.

---

## Issues & contributions

Issues on `packs/` or `plugin/` are welcome here — file them at https://github.com/ashmdev/mnemo-public/issues. The maintainers will rebase accepted patches onto the private core and the fix will land back here on the next sync.

Please do **not** open pull requests against `server.json`, `docs/SUBMISSIONS.md`, or `docs/USER_GUIDE.md` directly on this repo — those are overwritten by the sync workflow, so any merge here would be reverted on the next `v*` tag push.

---

## License

MIT. Binary distribution happens via [`ashmdev/mnemo-releases`](https://github.com/ashmdev/mnemo-releases) and [`ashmdev/homebrew-tap`](https://github.com/ashmdev/homebrew-tap). The private engine source is MIT-licensed but not published.
