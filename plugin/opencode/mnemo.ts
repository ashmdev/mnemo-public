// Mnemo plugin for OpenCode — persistent memory for AI coding agents.
//
// This plugin connects to the Mnemo HTTP server to provide cross-session
// memory, semantic search, and context recovery for OpenCode sessions.
//
// Mnemo exposes 21 MCP tools (17 agent + 3 admin + 1 sync):
//
//   Agent tools:
//     mem_save             - Save a memory to persistent storage
//     mem_search           - Hybrid full-text and semantic search
//     mem_context          - Get formatted context summary (memories, skills, workflows)
//     mem_session_start    - Start a coding session
//     mem_session_end      - End a coding session
//     mem_session_summary  - Save session summary and end session
//     mem_get              - Retrieve a memory by ID
//     mem_update           - Update an existing memory
//     mem_capture_passive  - Passively capture context from the session
//     mem_save_prompt      - Save a user prompt for future reference
//     mem_suggest_topic    - Suggest a topic_key for a memory
//     skill_load           - Load a reusable skill by name
//     persona_get          - Get active persona configuration
//     workflow_phases      - Get phases of a named workflow
//     workflow_start       - Start a new workflow run
//     workflow_execute     - Execute current phase of a workflow
//     workflow_complete    - Mark a workflow phase as complete
//
//   Admin tools:
//     mem_delete           - Delete a memory by ID
//     mem_stats            - Get memory store statistics
//     mem_timeline         - Get memory timeline
//
//   Sync:
//     mem_sync_status      - Get cloud sync status

interface MnemoConfig {
  host: string;
  port: number;
  project: string;
}

interface MnemoSession {
  id: string;
  project: string;
  agent: string;
}

interface MnemoMemory {
  id: string;
  type: string;
  title: string;
  content: string;
  project: string;
  created_at: string;
}

interface PassiveCapture {
  type: string;
  content: string;
}

// Resolve configuration from environment with sensible defaults.
function resolveConfig(): MnemoConfig {
  const host = process.env.MNEMO_HOST ?? "127.0.0.1";
  const port = parseInt(process.env.MNEMO_PORT ?? "7437", 10);
  const project =
    process.env.CLAUDE_PROJECT ??
    process.env.OPENCODE_PROJECT ??
    detectProject(process.cwd());
  return { host, port, project };
}

// detectProject walks up from startDir looking for .mnemorc (matches the
// Go-side ProjectConfigService.Detect logic) and falls back to the CWD
// basename. This keeps project detection consistent across all Mnemo agents.
function detectProject(startDir: string): string {
  const fromMnemorc = walkUpMnemorc(startDir);
  if (fromMnemorc) return fromMnemorc;
  return basename(startDir);
}

// Regex matches internal/domain/projectconfig.go projectNameRe.
const PROJECT_NAME_RE = /^[a-z][a-z0-9._-]{0,63}$/;

// walkUpMnemorc walks up the directory tree looking for a .mnemorc file and
// returns its `project:` field. Returns empty string if not found or invalid.
function walkUpMnemorc(startDir: string): string {
  // Lazy require so the plugin still loads if node:fs is unavailable.
  let fs: typeof import("fs");
  let path: typeof import("path");
  try {
    fs = require("fs");
    path = require("path");
  } catch {
    return "";
  }

  let dir = path.resolve(startDir);
  while (true) {
    const candidate = path.join(dir, ".mnemorc");
    try {
      if (fs.statSync(candidate).isFile()) {
        const content = fs.readFileSync(candidate, "utf8");
        const project = parseMnemorcProject(content);
        if (project && PROJECT_NAME_RE.test(project)) {
          return project;
        }
        // Found .mnemorc but project invalid/missing — stop walking.
        return "";
      }
    } catch {
      // Not a file or not readable — keep walking.
    }

    const parent = path.dirname(dir);
    if (parent === dir) return "";
    dir = parent;
  }
}

// parseMnemorcProject extracts the `project:` field from a .mnemorc YAML.
// Handles surrounding whitespace, trailing comments, and optional quotes.
function parseMnemorcProject(content: string): string {
  for (const line of content.split(/\r?\n/)) {
    const match = line.match(/^\s*project\s*:\s*(.+?)\s*$/);
    if (!match) continue;
    let value = match[1];
    // Strip trailing comments (not inside quotes — keep it simple).
    const hashIdx = value.indexOf("#");
    if (hashIdx >= 0) value = value.slice(0, hashIdx).trim();
    // Strip surrounding quotes.
    value = value.replace(/^["']|["']$/g, "");
    return value.trim();
  }
  return "";
}

function basename(p: string): string {
  const parts = p.replace(/\\/g, "/").split("/");
  return parts[parts.length - 1] || "unknown";
}

function baseURL(cfg: MnemoConfig): string {
  return `http://${cfg.host}:${cfg.port}`;
}

// Generate a session ID from the current timestamp and process ID.
// OpenCode does not expose a stable per-conversation id the way Claude Code
// does via hook stdin, so we synthesize our own. Keep the "oc-" prefix so the
// dashboard can still tell opencode sessions apart from Claude Code ones.
function generateSessionID(): string {
  const now = new Date();
  const ts = now
    .toISOString()
    .replace(/[-:T]/g, "")
    .slice(0, 15);
  return `oc-${ts}-${process.pid}`;
}

// ─── Session handoff (CWD-keyed file, mirrors the bash/Go helpers) ─────────

// Writes the session ID to ~/.mnemo/sessions/by-cwd/<hash>.txt so the Mnemo
// MCP subprocess (which does not share opencode's address space) can bind
// mem_save() calls to this same session on the next tool invocation. Must
// stay byte-for-byte compatible with the Go readSessionHandoff() in
// internal/transport/mcp/session_handoff.go and the bash helper in
// plugin/claude-code/scripts/_helpers.sh — any change here requires both
// other sides to change too.
async function writeSessionHandoff(sessionID: string, cwd: string): Promise<void> {
  if (!sessionID) return;
  try {
    const fs = await import("fs/promises");
    const path = await import("path");
    const os = await import("os");
    const crypto = await import("crypto");

    const dataDir = process.env.MNEMO_DATA_DIR ?? path.join(os.homedir(), ".mnemo");
    const handoffDir = path.join(dataDir, "sessions", "by-cwd");
    await fs.mkdir(handoffDir, { recursive: true });

    // Resolve symlinks so both sides land on the same canonical path.
    let absCwd = path.resolve(cwd);
    try {
      absCwd = await fs.realpath(absCwd);
    } catch {
      // Path may not exist — use the unresolved absolute form. Matches the
      // Go side which also falls back to the literal on EvalSymlinks error.
    }

    const hash = crypto
      .createHash("sha256")
      .update(absCwd)
      .digest("hex")
      .slice(0, 16);

    const target = path.join(handoffDir, `${hash}.txt`);
    const tmp = `${target}.${process.pid}`;
    await fs.writeFile(tmp, `${sessionID}\n`, "utf8");
    await fs.rename(tmp, target);
  } catch {
    // Best-effort — the MCP will fall back to auto-generating a session if
    // the handoff is missing.
  }
}

async function clearSessionHandoff(cwd: string): Promise<void> {
  try {
    const fs = await import("fs/promises");
    const path = await import("path");
    const os = await import("os");
    const crypto = await import("crypto");

    const dataDir = process.env.MNEMO_DATA_DIR ?? path.join(os.homedir(), ".mnemo");
    let absCwd = path.resolve(cwd);
    try {
      absCwd = await fs.realpath(absCwd);
    } catch {
      /* ignore */
    }
    const hash = crypto
      .createHash("sha256")
      .update(absCwd)
      .digest("hex")
      .slice(0, 16);
    const target = path.join(dataDir, "sessions", "by-cwd", `${hash}.txt`);
    await fs.unlink(target);
  } catch {
    /* file already gone — fine */
  }
}

// Check if the Mnemo server is healthy.
async function checkHealth(cfg: MnemoConfig): Promise<boolean> {
  try {
    const resp = await fetch(`${baseURL(cfg)}/health`, {
      signal: AbortSignal.timeout(2000),
    });
    return resp.ok;
  } catch {
    return false;
  }
}

// Start the Mnemo server in the background if it is not already running.
async function ensureServer(cfg: MnemoConfig): Promise<void> {
  if (await checkHealth(cfg)) return;

  const mnemo = process.env.MNEMO_BIN ?? "mnemo";
  const { spawn } = await import("child_process");
  const child = spawn(mnemo, ["serve", String(cfg.port)], {
    detached: true,
    stdio: "ignore",
  });
  child.unref();

  // Wait for the server to become ready (up to 10 seconds).
  for (let i = 0; i < 20; i++) {
    if (await checkHealth(cfg)) return;
    await sleep(500);
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Create a new session on the Mnemo server.
async function createSession(
  cfg: MnemoConfig,
  sessionID: string
): Promise<void> {
  try {
    await fetch(`${baseURL(cfg)}/sessions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: sessionID,
        project: cfg.project,
        agent: "opencode",
      } satisfies MnemoSession),
      signal: AbortSignal.timeout(3000),
    });
  } catch {
    // Best-effort: server may not support this endpoint yet.
  }
}

// End a session on the Mnemo server.
async function endSession(
  cfg: MnemoConfig,
  sessionID: string
): Promise<void> {
  try {
    await fetch(`${baseURL(cfg)}/sessions/${sessionID}/end`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      signal: AbortSignal.timeout(2000),
    });
  } catch {
    // Best-effort cleanup.
  }
}

// Load memory context for the current project.
// Returns a formatted summary including memories, loaded skills, and active
// workflow state so the agent can resume where it left off.
async function loadContext(cfg: MnemoConfig): Promise<string> {
  try {
    const resp = await fetch(
      `${baseURL(cfg)}/context?project=${encodeURIComponent(cfg.project)}`,
      { signal: AbortSignal.timeout(5000) }
    );
    if (!resp.ok) return "";
    return await resp.text();
  } catch {
    return "";
  }
}

// Send a passive capture to the Mnemo server (learning extraction).
async function capturePassive(
  cfg: MnemoConfig,
  capture: PassiveCapture
): Promise<void> {
  try {
    await fetch(`${baseURL(cfg)}/memories/passive`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(capture),
      signal: AbortSignal.timeout(3000),
    });
  } catch {
    // Fire-and-forget.
  }
}

// ─── Plugin Lifecycle ───────────────────────────────────────────────────────

let _cfg: MnemoConfig;
let _sessionID: string;

// setup is called when the plugin is loaded by OpenCode.
export async function setup(): Promise<void> {
  _cfg = resolveConfig();
  _sessionID = generateSessionID();

  await ensureServer(_cfg);
  await createSession(_cfg, _sessionID);
  // Hand off the session ID to the MCP subprocess via a CWD-keyed file so
  // its resolveSession() returns the same id we just created instead of
  // auto-spawning a parallel session.
  await writeSessionHandoff(_sessionID, process.cwd());
}

// activate is called when the plugin becomes active in a session.
// Returns memory context (including skills and workflows) that OpenCode can
// inject into the system prompt.
export async function activate(): Promise<string> {
  const context = await loadContext(_cfg);
  return context;
}

// deactivate is called when the session ends.
export async function deactivate(): Promise<void> {
  await endSession(_cfg, _sessionID);
  await clearSessionHandoff(process.cwd());
}

// teardown is called when the plugin is unloaded.
export async function teardown(): Promise<void> {
  await endSession(_cfg, _sessionID);
  await clearSessionHandoff(process.cwd());
}

// capture sends a passive learning event to Mnemo.
// Can be called by OpenCode when it detects significant agent output.
export async function capture(
  type: string,
  content: string
): Promise<void> {
  await capturePassive(_cfg, { type, content: content.slice(0, 8192) });
}

export default { setup, activate, deactivate, teardown, capture };
