# Kimaki Isolation Architecture

> Research notes on how Kimaki implements project and session isolation for Discord-based AI coding assistants.

## Overview

Kimaki is a Discord bot that connects channels to OpenCode projects. It implements **two levels of isolation**:

1. **Project Isolation**: Separate git clones + XDG paths per project
2. **Session Isolation**: Git worktrees per Discord thread

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         KIMAKI ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Discord                    Kimaki Bot                   OpenCode    │
│  ────────                   ──────────                   ────────    │
│                                                                      │
│  ┌──────────┐              ┌────────────┐              ┌──────────┐ │
│  │ Channel  │──registers───│  Project   │──spawns─────▶│ opencode │ │
│  │ #my-proj │              │  Registry  │              │  serve   │ │
│  └──────────┘              │   (SQLite) │              │ :random  │ │
│       │                    └────────────┘              └──────────┘ │
│       │                          │                          ▲       │
│       ▼                          ▼                          │       │
│  ┌──────────┐              ┌────────────┐              ┌──────────┐ │
│  │  Thread  │──creates────▶│  Worktree  │──isolates───▶│ Session  │ │
│  │ "bug-fix"│              │  Manager   │              │ in WT    │ │
│  └──────────┘              └────────────┘              └──────────┘ │
│                                                                      │
│  Filesystem:                                                         │
│  ~/Projects/kimaki/<project>/              (Project clone)           │
│  ~/Projects/kimaki/<project>/.worktrees/   (Thread worktrees)        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Project Isolation

### Separate Workdirs

Each project gets its own git clone in `~/Projects/kimaki/<name>/`:

```
~/Projects/kimaki/
  ├── nix-config/           # Clone 1
  ├── ruinagents/           # Clone 2  
  └── my-project/           # Clone 3
```

**Why separate from ruinage?** Prevents workspace conflicts when running kimaki services alongside interactive development.

### XDG Path Isolation

Each project gets isolated XDG directories:

```nix
# nix-config pattern
mkProjectPaths = projectName: {
  config = "${homeDir}/.config/opencode-${projectName}";
  state = "${homeDir}/.local/state/opencode-${projectName}";
  cache = "${homeDir}/.cache/opencode-${projectName}";
  data = "${homeDir}/.local/share/opencode-${projectName}";
};
```

### Shared Authentication

Auth tokens are symlinked from the global location:

```nix
mkAuthSymlinks = { dataDir, homeDirectory, mkOutOfStoreSymlink }: {
  "${dataDir}/opencode/auth.json".source =
    mkOutOfStoreSymlink "${homeDirectory}/.local/share/opencode/auth.json";
  "${dataDir}/opencode/mcp-auth.json".source =
    mkOutOfStoreSymlink "${homeDirectory}/.local/share/opencode/mcp-auth.json";
};
```

**Result**: Log in once, all projects share authentication.

## Thread/Worktree Isolation

### Database Schema

Kimaki uses SQLite to map Discord threads to worktrees:

```sql
-- discord-sessions.db

-- Maps channels to project directories
CREATE TABLE channel_directories (
  channel_id TEXT PRIMARY KEY,
  directory TEXT NOT NULL,
  channel_type TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Maps threads to worktrees  
CREATE TABLE thread_worktrees (
  thread_id TEXT PRIMARY KEY,
  worktree_name TEXT NOT NULL,
  worktree_directory TEXT,
  project_directory TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  error_message TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Worktree Naming

Thread names are formatted into worktree names:

```typescript
// discord/src/commands/worktree.ts
export function formatWorktreeName(name: string): string {
  const formatted = name
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '')

  return `opencode/kimaki-${formatted}`
}

// Examples:
// "Bug Fix Auth" → "opencode/kimaki-bug-fix-auth"
// "Feature #123" → "opencode/kimaki-feature-123"
```

### Creation Flow

When a Discord thread is created:

```typescript
// discord/src/worktree-utils.ts
export async function createWorktreeWithSubmodules({ clientV2, directory, name }) {
  // 1. Create worktree via OpenCode SDK
  const response = await clientV2.worktree.create({
    directory,
    worktreeCreateInput: { name }
  })
  
  const worktreeDir = response.data.directory
  
  // 2. Initialize submodules
  await execAsync('git submodule update --init --recursive', { cwd: worktreeDir })
  
  // 3. Install dependencies
  await execAsync('npx -y ni', { cwd: worktreeDir })
  
  return response.data
}
```

### Lifecycle States

```
┌─────────────────────────────────────────────────────────────┐
│                   WORKTREE LIFECYCLE                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────┐     ┌─────────┐     ┌─────────┐               │
│  │ PENDING │────▶│  READY  │────▶│ MERGED  │               │
│  └─────────┘     └─────────┘     └─────────┘               │
│       │               │               │                     │
│       ▼               │               ▼                     │
│  ┌─────────┐          │         ┌─────────┐                │
│  │  ERROR  │          │         │ CLEANUP │                │
│  └─────────┘          │         └─────────┘                │
│       │               │                                     │
│       ▼               ▼                                     │
│  ┌─────────────────────────┐                               │
│  │ FALLBACK: Use main dir  │                               │
│  └─────────────────────────┘                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

| State | Description | Database Update |
|-------|-------------|-----------------|
| **pending** | Worktree creation started | `status = 'pending'` |
| **ready** | Worktree created, deps installed | `status = 'ready', worktree_directory = <path>` |
| **error** | Creation failed | `status = 'error', error_message = <msg>` |
| **merged** | Changes merged to main | (manual cleanup) |

### Error Handling

```typescript
// discord/src/discord-bot.ts
if (worktreeResult instanceof Error) {
  const errMsg = worktreeResult.message
  
  // Update database with error
  setWorktreeError({ threadId: thread.id, errorMessage: errMsg })
  
  // Notify user and fallback
  await thread.send({
    content: `⚠️ Failed to create worktree: ${errMsg}\nUsing main project directory instead.`,
    flags: SILENT_MESSAGE_FLAGS,
  })
}
```

**Fallback behavior**: If worktree fails, session uses main project directory.

## OpenCode Config Generation

For each kimaki project, generate `.opencode/opencode.json`:

```nix
# kimaki.nix activation script
home.activation.generateKimakiOpencodeConfigs = let
  # Inherit from global opencode or kimaki-specific instructions
  instructions =
    if cfg.instructions != []
    then cfg.instructions
    else opencodeAssistant.instructions or [];
in ''
  # For each project workdir
  CONFIG_DIR="${workdir}/.opencode"
  CONFIG_FILE="$CONFIG_DIR/opencode.json"
  
  # Inject model, plugins, instructions, MCP servers
  jq --argjson new_model '${model}' \
     --argjson new_plugins '${plugins}' \
     --argjson new_instructions '${instructions}' \
     '...' "$CONFIG_FILE" > "$TMP_FILE"
'';
```

## Multi-Instance Handling

### Port Assignment

Each project spawns `opencode serve` on a random port:

```typescript
// discord/src/opencode.ts
const serverProcess = spawn(opencodeCommand, ['serve', '--port', port.toString()], {
  stdio: 'pipe',
  detached: false,
  cwd: directory,
  shell: true,
  env: {
    ...process.env,
    OPENCODE_CONFIG_CONTENT: JSON.stringify({
      $schema: 'https://opencode.ai/config.json',
      lsp: false,
      formatter: false,
      permission: { edit: 'allow', bash: 'allow', ... },
    }),
    OPENCODE_PORT: port.toString(),
  },
})
```

### Process Registry

Kimaki maintains a `Map` of running processes:

```typescript
// Track all running opencode instances
const processes = new Map<string, ChildProcess>()

// Get or spawn process for directory
function getOrSpawnProcess(directory: string): ChildProcess {
  if (processes.has(directory)) {
    return processes.get(directory)!
  }
  const proc = spawnOpencode(directory)
  processes.set(directory, proc)
  return proc
}
```

## nix-config Integration

### Project Registration

```nix
# Kimaki projects are registered in ruinage config
ruinous.ruinage.projects.my-project = {
  repo = "my-project";
  assistants.kimaki = {
    enable = true;              # Register with kimaki
    direnvSnippet = "my-project";  # Inject direnv
  };
};
```

### Auto-Clone Activation

```nix
# Clone to ~/Projects/kimaki/<name>
home.activation.cloneKimakiProjects = lib.hm.dag.entryAfter ["writeBoundary"] ''
  if [ ! -d "${workdir}" ]; then
    git clone "${gitUrl}" "${workdir}"
  fi
'';
```

### Registration Activation

```nix
# Register with kimaki after clone
home.activation.registerKimakiProjects = lib.hm.dag.entryAfter ["cloneKimakiProjects"] ''
  if [ -d "${workdir}" ]; then
    npx -y kimaki@latest add-project "${workdir}"
  fi
'';
```

## Comparison: Project vs Thread Isolation

| Aspect | Project Isolation | Thread Isolation |
|--------|-------------------|------------------|
| **Scope** | Different repositories | Different tasks in same repo |
| **Mechanism** | Separate git clones + XDG | Git worktrees |
| **Filesystem** | `~/Projects/kimaki/<proj>/` | `<proj>/.worktrees/<thread>/` |
| **Config** | Per-project opencode.json | Inherits from project |
| **Lifecycle** | Permanent | Ephemeral (per conversation) |
| **Cleanup** | Manual | Merge + remove |

## Applying to CLI

### XDG Isolation (Per-Project)

```bash
# Wrapper script pattern
opencode-myproject() {
  export OPENCODE_CONFIG_DIR=~/.config/opencode-myproject
  export XDG_STATE_HOME=~/.local/state/opencode-myproject
  export XDG_DATA_HOME=~/.local/share/opencode-myproject
  export XDG_CACHE_HOME=~/.cache/opencode-myproject
  opencode "$@"
}
```

### Worktree Isolation (Per-Session)

```bash
# Create isolated session
SESSION="feature-$(date +%s)"
git worktree add .worktrees/$SESSION -b $SESSION

# Work in isolation
cd .worktrees/$SESSION
opencode

# Cleanup when done
cd ..
git worktree remove .worktrees/$SESSION
git branch -d $SESSION
```

### Combined Pattern

```bash
# Full isolation: project + session
PROJECT=myproject
SESSION=feature-x

# Project-level
export OPENCODE_CONFIG_DIR=~/.config/opencode-$PROJECT

# Session-level  
git worktree add .worktrees/$SESSION -b $SESSION
cd .worktrees/$SESSION
opencode attach http://localhost:9500
```

## References

- Kimaki source: [remorses/kimaki](https://github.com/remorses/kimaki)
  - `discord/src/database.ts` - SQLite schema
  - `discord/src/worktree-utils.ts` - Worktree creation
  - `discord/src/opencode.ts` - Process spawning
- nix-config: `modules/home/default/ruinage/assistants/kimaki.nix`
- OpenCode worktree API: `clientV2.worktree.create()`
