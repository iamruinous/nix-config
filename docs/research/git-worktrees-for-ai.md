# Git Worktrees for AI Assistants

> Research notes on using git worktrees to isolate AI coding sessions, enabling parallel execution without directory conflicts.

## Overview

Git worktrees allow multiple working directories linked to a single `.git` database. This is the "secret weapon" for running multiple AI agents in parallel without context-switching or file conflicts.

## Core Commands

### Create

```bash
# Create worktree from existing branch
git worktree add <path> <branch>
git worktree add ../feature-x feature-branch

# Create worktree with new branch
git worktree add <path> -b <new-branch>
git worktree add ../ai-fix -b ai-bug-investigation

# Create from current HEAD (detached)
git worktree add ../experiment HEAD
```

### List

```bash
git worktree list
# /home/user/project        abc1234 [main]
# /home/user/project-ai     def5678 [ai-feature]
```

### Remove

```bash
# Safe removal (fails if uncommitted changes)
git worktree remove <path>

# Force removal
git worktree remove --force <path>
```

### Prune

```bash
# Clean up stale metadata (after manual directory deletion)
git worktree prune
```

## Naming Conventions

### Dedicated Parent Directory

Keep worktrees outside main repo to avoid confusion:

```
~/projects/my-repo/                    # Main working directory
~/projects/my-repo-worktrees/          # Worktree container
  ├── ai-refactor/
  ├── feature-auth/
  └── experiment-perf/
```

### Hidden Worktrees (Alternative)

Use `.worktrees/` inside repo (add to `.gitignore`):

```
~/projects/my-repo/
  ├── .worktrees/                      # Gitignored
  │   ├── session-alpha/
  │   └── session-beta/
  ├── src/
  └── .gitignore                       # Contains: .worktrees/
```

### Semantic Naming Patterns

| Pattern | Example | Use Case |
|---------|---------|----------|
| Feature-based | `wt-402-auth-fix` | Issue-linked work |
| Agent-based | `claude-session-alpha` | AI agent sessions |
| Timestamp-based | `session-1706649600` | Ephemeral sessions |
| Kimaki-style | `opencode/kimaki-thread-name` | Discord thread mapping |

## Capturing and Applying Diffs

### Patch Method

```bash
# In AI worktree: capture changes
git diff > ai-changes.patch
git diff --staged >> ai-changes.patch

# In main worktree: apply changes
git apply ai-changes.patch
```

### Selective Checkout

```bash
# Pull specific files from AI branch
git checkout ai-branch -- src/components/Button.tsx

# Interactive patch selection
git checkout -p ai-branch
```

### Commit & Cherry-pick (Cleanest)

```bash
# In AI worktree: commit work
git add -A && git commit -m "AI: implement feature"

# In main worktree: cherry-pick
git cherry-pick <commit-hash>
```

### Kimaki Pattern (Diff Capture/Apply)

```typescript
// Capture current state before creating worktree
const diff = await execAsync('git diff HEAD', { cwd: mainDir })
const stagedDiff = await execAsync('git diff --staged', { cwd: mainDir })

// Apply to worktree after creation
await execAsync(`git apply --3way`, { input: diff, cwd: worktreeDir })
```

## Cleanup Strategies

### TTL-Based Cleanup

```bash
# Find worktrees older than 3 days
find ~/project-worktrees -maxdepth 1 -type d -mtime +3 -exec git worktree remove {} \;
```

### Post-Merge Hook

```bash
#!/bin/bash
# .git/hooks/post-merge
# Auto-remove worktrees for merged branches

for wt in $(git worktree list --porcelain | grep 'worktree' | cut -d' ' -f2); do
  branch=$(git -C "$wt" branch --show-current)
  if git branch --merged main | grep -q "$branch"; then
    git worktree remove "$wt"
  fi
done
```

### Manual Bulk Cleanup

```bash
# List all worktrees
git worktree list

# Remove all in worktrees directory
for dir in ~/project-worktrees/*/; do
  git worktree remove "$dir" 2>/dev/null || git worktree remove --force "$dir"
done

# Prune stale references
git worktree prune
```

## Common Pitfalls & Solutions

### node_modules (Disk Space)

**Problem**: Each worktree needs its own `node_modules` (slow, massive disk usage)

**Solutions**:
- **pnpm/bun**: Global content-addressable store, near-instant installs
- **Symlink**: `ln -s ~/project/node_modules ~/worktree/node_modules`
- **Shared cache**: `npm config set cache ~/.npm-shared`

### Submodules

**Problem**: Worktrees don't auto-initialize submodules

**Solution**: Always run after creating worktree:
```bash
git submodule update --init --recursive
```

### Environment Variables (.env)

**Problem**: `.env` files are gitignored, won't exist in worktree

**Solutions**:
- **Symlink**: `ln -s ~/project/.env ~/worktree/.env`
- **direnv**: Manage environment context across directories
- **Copy on create**: Part of worktree creation script

### Editor Context

**Problem**: VS Code may not recognize worktree as same project

**Solutions**:
- Open worktree as separate window
- Use Multi-Root Workspace (`.code-workspace`)
- Configure LSP to include both directories

### Lock Files

**Problem**: Worktrees share `.git` but lock files can conflict

**Solution**: Worktree operations are atomic, but avoid concurrent git operations on same worktree

## AI Assistant Implementations

### Kimaki (Discord Bot)

Maps Discord threads to isolated worktrees:

```typescript
// Worktree creation for thread
const response = await clientV2.worktree.create({
  directory,
  worktreeCreateInput: { name: `opencode/kimaki-${threadName}` }
})

// Initialize environment
await execAsync('git submodule update --init --recursive', { cwd: worktreeDir })
await execAsync('npx -y ni', { cwd: worktreeDir })
```

### Agentree

Purpose-built for AI agent worktree management:
```bash
agentree create --name "claude-session" --from main
agentree list
agentree merge --name "claude-session" --into main
agentree cleanup --older-than 3d
```

### CLI Pattern (Proposed)

```bash
# Create session with worktree isolation
opencode session create --worktree

# Attach to session (works in worktree)
opencode attach http://localhost:9500 --session ses_abc123

# Merge and cleanup when done
opencode session merge ses_abc123
```

## Worktree Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                    WORKTREE LIFECYCLE                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. CREATE                                                  │
│     git worktree add <path> -b <branch>                     │
│     └── Initialize submodules                               │
│     └── Install dependencies (pnpm/bun)                     │
│     └── Apply current diff (optional)                       │
│                                                             │
│  2. WORK                                                    │
│     AI operates in isolated directory                       │
│     └── No conflicts with main worktree                     │
│     └── Can run tests, builds independently                 │
│                                                             │
│  3. REVIEW                                                  │
│     git diff, git log in worktree                           │
│     └── Cherry-pick specific commits                        │
│     └── Interactive patch selection                         │
│                                                             │
│  4. MERGE                                                   │
│     git checkout main && git merge <branch>                 │
│     └── Or cherry-pick commits                              │
│     └── Or apply patches                                    │
│                                                             │
│  5. CLEANUP                                                 │
│     git worktree remove <path>                              │
│     git branch -d <branch>                                  │
│     git worktree prune                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## References

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Supercharge Your AI Coding Workflow with Git Worktrees](https://dev.to/bhaidar/supercharge-your-ai-coding-workflow-a-complete-guide-to-git-worktrees-with-claude-code-60m)
- [Git Worktrees: Secret Weapon for Parallel AI Agents](https://medium.com/@mabd.dev/git-worktrees-the-secret-weapon-for-running-multiple-ai-coding-agents-in-parallel-e9046451eb96)
- [Agentree](https://github.com/AryaLabsHQ/agentree)
- [Kimaki worktree-utils.ts](https://github.com/remorses/kimaki/blob/main/discord/src/worktree-utils.ts)
