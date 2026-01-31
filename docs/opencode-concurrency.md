# OpenCode Concurrency & Multi-Client Architecture

> Research notes on how OpenCode handles multiple CLI clients, session concurrency, and the attach/serve model.

## Overview

OpenCode uses a **centralized server model** where multiple CLI clients can connect to a single `opencode serve` instance. The architecture uses an event bus for real-time synchronization and session-level state management.

## Client/Server Architecture

### Server Mode (`opencode serve`)

The server exposes:
- **REST API**: OpenAPI-compliant endpoints for session/message management
- **SSE Stream**: `/event` endpoint for real-time event streaming
- **Port Handling**: Default port 4096, falls back to OS-assigned if occupied

```typescript
// Port binding logic (src/server/server.ts)
const tryServe = (port: number) => {
  try {
    return Bun.serve({ ...args, port })
  } catch {
    return undefined
  }
}
const server = opts.port === 0 ? (tryServe(4096) ?? tryServe(0)) : tryServe(opts.port)
```

### Client Mode (`opencode attach`)

The TUI connects to a remote server via HTTP:
```bash
opencode attach http://localhost:9500
opencode attach http://localhost:9500 --session <session-id>
```

## Multi-Client Behavior

### Can Multiple Clients Connect?

**Yes.** The server handles any number of concurrent connections:

| Aspect | Behavior |
|--------|----------|
| **Connection** | Multiple `attach` clients can connect simultaneously |
| **Session Sharing** | Clients join the same session by using `--session <id>` |
| **Real-time Sync** | All clients receive updates via SSE event bus |
| **Isolation** | Different session IDs = complete isolation |

### Event Synchronization

All attached clients receive real-time updates through the global `Bus`:

```typescript
// Server publishes events to all connected clients
Bus.publish(sessionId, {
  type: "message.created",
  payload: message
})
```

## Session Concurrency Model

### Simultaneous Messages

When two clients send messages to the same session:

1. **Message Appending**: Both messages are appended to history in arrival order
2. **Single Processor**: Only ONE AI loop runs per session at any time
3. **Continuous Processing**: The loop iterates and processes new messages

```typescript
// Detection logic (src/session/prompt.ts)
if (lastUser.id > lastAssistant.id) {
  // New user messages detected, continue processing
}
```

### Session States

| State | Description | New Messages | State Changes |
|-------|-------------|--------------|---------------|
| **Idle** | No active processing | Processed immediately | Allowed |
| **Busy** | AI is thinking/executing | Queued as Promises | Rejected with `BusyError` |

### Busy State Handling

```typescript
// Queuing behavior when busy
if (session.busy) {
  // New prompts: Queued, resolved when loop finishes
  // Shell/Revert operations: Rejected with Session.BusyError
}
```

## No File Locking

OpenCode does **NOT** use cross-process file locking:

- **In-memory locks only**: Synchronizes async tasks within a single process
- **Session files**: Multiple processes may race on `~/.local/share/opencode/storage`
- **Mitigation**: Use XDG isolation for multi-instance deployments

```typescript
// Lock implementation (src/util/lock.ts) - PROCESS-LOCAL ONLY
export namespace Lock {
  const locks = new Map<string, {
    readers: number
    writer: boolean
    waitingReaders: (() => void)[]
    waitingWriters: (() => void)[]
  }>()
}
```

## Contended Resources

When running multiple instances without XDG isolation:

| Resource | Path | Risk |
|----------|------|------|
| Session data | `~/.local/share/opencode/storage` | Race conditions |
| Logs | `~/.local/share/opencode/log` | Interleaved entries |
| Cache | `~/.cache/opencode` | Minor conflicts |
| Config | `~/.config/opencode` | Usually read-only |

## XDG Isolation Strategy

For conflict-free multi-instance operation, isolate via XDG paths:

```bash
# Per-project isolation
export OPENCODE_CONFIG_DIR=~/.config/opencode-myproject
export XDG_STATE_HOME=~/.local/state/opencode-myproject
export XDG_DATA_HOME=~/.local/share/opencode-myproject
export XDG_CACHE_HOME=~/.cache/opencode-myproject

opencode serve --port 9500
```

### Shared Authentication

Auth tokens can be shared via symlinks:

```bash
# Symlink auth files to shared location
ln -s ~/.local/share/opencode/auth.json \
      ~/.local/share/opencode-myproject/opencode/auth.json
```

## Port Assignment Patterns

### Deterministic Allocation (nix-config pattern)

```nix
# Sort projects alphabetically for deterministic ports
sortedProjectNames = sort (a: b: a < b) (attrNames projects);
projectPortMap = listToAttrs (imap0 (idx: name: {
  name = name;
  value = 9500 + idx;  # Base port + index
}) sortedProjectNames);
```

| Project | Port |
|---------|------|
| alpha-project | 9500 |
| beta-project | 9501 |
| gamma-project | 9502 |

## Best Practices

### For Interactive CLI

1. **Different sessions**: Use separate session IDs to avoid conflicts
2. **Same session**: Expect queued message handling when both send simultaneously
3. **XDG isolation**: Use environment variables for true multi-instance isolation

### For Service Deployments

1. **Systemd services**: One service per project with isolated XDG paths
2. **Deterministic ports**: Use sorted alphabetical assignment
3. **Auth sharing**: Symlink auth files to avoid re-authentication

### For Shared Sessions

1. **Real-time collaboration**: All clients see same updates via SSE
2. **Turn-taking**: Avoid simultaneous input for cleaner interaction
3. **Busy awareness**: Check session state before sending commands

## References

- OpenCode source: `packages/opencode/src/server/server.ts`
- Concurrency logic: `packages/opencode/src/session/prompt.ts`
- Lock implementation: `packages/opencode/src/util/lock.ts`
- nix-config patterns: `modules/home/default/ruinage/assistants/opencode.nix`
