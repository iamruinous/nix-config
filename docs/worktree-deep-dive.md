<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Do deep research on git worktrees and shell integration. Include a search and youtube videos on how people are using worktrees + AI agents for session isolation in a multi-agent scenario. Write a detailed report that will become part of a knowledge base. I'm also especially interested in worktree automation tools and hooks for automating worktree integration. Material on Integration with claude-code and opencode is an extra bonus.

Here's an example of a tool trying to simplify worktree use [https://github.com/satococoa/wtp](https://github.com/satococoa/wtp)

Now I have comprehensive information. Let me create the detailed report.

# Git Worktrees and Shell Integration: A Comprehensive Knowledge Base Report

## Executive Summary

Git worktrees represent a paradigm shift in managing parallel development workflows, particularly in the emerging era of multi-agent AI-assisted coding. This technology, available since Git 2.5 (2015), enables developers to check out multiple branches simultaneously in separate directories while sharing a single `.git` repository. The convergence of worktrees with AI coding agents has created powerful new workflows that allow 3-4 agents to work on distinct features in complete isolation, fundamentally changing how developers orchestrate parallel development.[^1][^2][^3]

This report synthesizes findings from 119+ sources including official documentation, automation tools (wtp, Grove, Worktrunk, workmux), real-world implementations with Claude Code and OpenCode, and YouTube tutorials. Key insights include automation patterns through hooks, shell integration mechanisms, and best practices for multi-agent session isolation.

***

## 1. Core Worktree Architecture and Concepts

### 1.1 Fundamental Design

Git worktrees allow multiple working directories ("worktrees") attached to a single repository. The architecture consists of:[^1]

- **Main worktree**: The original directory containing the `.git` folder (or bare repository)
- **Linked worktrees**: Additional working directories that reference the main `.git` database
- **Shared repository database**: All worktrees share commits, branches, and git history[^4][^5]

Each linked worktree contains only:

- Working tree files (current branch checkout)
- A `.git` file (not directory) pointing to `.git/worktrees/<worktree-id>`
- Metadata in `.git/worktrees/<worktree-id>/` including HEAD, index, and config[^1]

This architecture delivers three critical advantages over multiple clones:

1. **Unified fetch operations**: One `git fetch` updates all worktrees offline[^5]
2. **Full branch access**: Cherry-picking and merging across worktrees without network access[^5]
3. **Space efficiency**: Shared `.git` database eliminates repository duplication[^6]

### 1.2 Bare Repository Pattern

The bare repository approach has emerged as a best practice for worktree-centric workflows. This pattern:[^7][^8]

```bash
# Clone as bare repository
git clone --bare <url> .bare

# Create .git file pointing to bare repo
echo "gitdir: ./.bare" > .git

# Fix fetch refspec (critical for remote branch access)
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

# Fetch all branches
git fetch origin
```

**Rationale**: Bare repositories eliminate the "main worktree problem" where the main directory must always have a branch checked out, which cannot be used by other worktrees. With bare repos, all development occurs in worktrees, creating a symmetric structure where no worktree is privileged.[^9][^8]

**Common structure**:

```
project/
├── .bare/              # Bare git repository
├── main/               # Worktree for main branch
├── feature-auth/       # Worktree for feature-auth branch
└── hotfix-123/         # Worktree for hotfix-123 branch
```


***

## 2. Worktree Automation Tools: Comprehensive Analysis

The ecosystem has developed sophisticated CLI tools that abstract worktree complexity. Below is a detailed comparison of major tools.

### 2.1 wtp (Worktree Plus)

**Repository**: satococoa/wtp (39 GitHub stars as of Aug 2025)[^10]
**Language**: Go
**Philosophy**: Eliminate path gymnastics and automate environment setup[^10]

**Key Features**:

1. **Automatic path generation**: `wtp add feature/auth` creates `../worktrees/feature/auth` without explicit paths[^10]
2. **Unified cleanup**: `wtp remove --with-branch <branch>` removes both worktree and branch atomically[^10]
3. **Hook system**: `.wtp.yml` configuration with `post_create` hooks[^10]
4. **Shell integration**: `wtp cd <branch>` with tab completion changes directories[^10]

**Configuration Example** (`.wtp.yml`):

```yaml
version: "1.0"
defaults:
  base_dir: "../worktrees"

hooks:
  post_create:
    # Copy gitignored files from main worktree
    - type: copy
      from: ".env"        # Relative to main worktree
      to: ".env"          # Relative to new worktree
    
    - type: copy
      from: ".claude"
      to: ".claude"
    
    # Execute commands in new worktree
    - type: command
      command: "npm install"
      env:
        NODE_ENV: "development"
    
    - type: command
      command: "make db:setup"
      work_dir: "."
```

**Hook Behavior**: The `from` path in copy hooks always references the main worktree, regardless of where `wtp add` is executed. This ensures consistent file sourcing.[^10]

**Shell Integration**:

```bash
# Add to ~/.zshrc or ~/.bashrc
eval "$(wtp completion zsh)"

# Usage
wtp cd feature/auth    # Changes directory to worktree
wtp cd @               # Returns to root worktree
```


### 2.2 Grove

**Repository**: captainsafia/grove (GitHub)[^11]
**Philosophy**: Make worktrees feel like branches with native shell integration[^12]

**Distinctive Features**:

1. **True directory changing**: Shell integration modifies terminal's working directory (not subprocess)[^12]
2. **Bare-repo first**: Designed around bare repository structure[^11]
3. **Simple command set**: Focused on core operations without feature creep[^11]

**Shell Integration Pattern**:

```bash
# Zsh integration
eval "$(grove init zsh)"

# Usage - actually changes your shell's directory
grove switch main          # Shell PWD changes
grove go feature-branch    # Shell PWD changes + creates if needed
```

**Key Insight**: Grove's shell integration distinguishes it from editor-focused tools. When executing `grove switch`, the actual terminal session changes directories, rather than opening a new subprocess or editor instance.[^12]

### 2.3 Treekanga

**Language**: Rust (via Homebrew)[^13]
**Focus**: IDE integration and interactive branch detection[^13]

**Notable Features**:

1. **Intelligent branch detection**: Automatically determines if branches are local or remote[^13]
2. **Editor integration**: Opens worktrees directly in VSCode, Cursor, or IDE of choice[^13]
3. **Zoxide/sesh/tmux integration**: Connects to popular terminal multiplexers[^13]
4. **YAML configuration**: Per-repository customization[^13]

**Usage Example**:

```bash
# Creates worktree, detecting branch location automatically
treekanga add feature_branch

# Opens in Cursor automatically if configured
treekanga add feature_branch --cursor
```


### 2.4 branchlet

**Interface**: Interactive TUI (Terminal UI)[^14]
**Focus**: Visual worktree management with automation[^14]

**Features**:

1. **Interactive selection**: TUI interface for creating, listing, deleting worktrees[^14]
2. **Project-specific config**: `.branchlet.json` (local) or `~/.branchlet/settings.json` (global)[^14]
3. **File copying**: Automatically copies defined files (env, config) to new worktrees[^14]
4. **Post-create actions**: Runs custom commands after worktree creation[^14]

**Configuration**:

```json
{
  "filesToCopy": [".env", ".env.local", ".nvmrc"],
  "postCreateCommands": [
    "npm install",
    "npm run setup:db"
  ]
}
```


### 2.5 Worktrunk

**Repository**: worktrunk.dev (Rust)[^15]
**Philosophy**: Designed explicitly for parallel AI agents[^15]
**Tagline**: "CLI for git worktree management, designed for running AI agents in parallel"[^15]

**Core Commands**:

```bash
# Create + switch + execute command in one step
wt switch -c -x claude feat

# Creates worktree, switches to it, runs claude

# Cleanup with one command
wt remove
```

**Advanced Features**:

1. **Hooks**: pre-merge, post-merge, post-create[^15]
2. **LLM commit messages**: Generate commit messages from diffs[^15]
3. **Integrated merge workflow**: Squash, rebase, merge, cleanup in one command[^15]

**Merge Workflow Example**:

```bash
wt merge main
# ◎ Generating commit message... (2 files, +53, no squashing)
# ✓ Committed changes @ a1b2c3d
# ◎ Removing worktree & branch in background
# ○ Switched to worktree for main
```


### 2.6 workmux

**Repository**: raine/workmux (Rust)[^16][^17]
**Philosophy**: Git worktrees + tmux windows for zero-friction parallel development[^17]
**Key Innovation**: One worktree = one tmux window, with automatic pane layout[^18]

**Installation**:

```bash
brew install raine/tap/workmux
# or
cargo install workmux
```

**Core Workflow**:

```bash
# Create worktree + tmux window + run setup
workmux add new-feature

# Merge to main, cleanup worktree + window + branch
workmux merge

# List with status
workmux list
# BRANCH        TMUX  UNMERGED  PATH
# main          -     -         ~/project
# user-auth     ✓     -         ~/project__worktrees/user-auth
# bug-fix       ✓     ●         ~/project__worktrees/bug-fix
```

**Configuration** (`.workmux.yaml`):

```yaml
# Defines tmux pane layout
panes:
  - command: claude          # First pane (created by default)
    focus: true              # This pane gets focus
  - command: pnpm run dev
    split: horizontal        # Creates pane to the right

# Commands to run after worktree creation
post_create:
  - pnpm install
  - pnpm db:migrate

# File operations
files:
  copy:
    - .env
    - .env.local
  symlink:
    - .turbo           # Share build cache across worktrees
    - node_modules/.cache
```

**Advanced Usage**:

1. **Agent placeholder**: Use `<agent>` in config; workmux expands to detected agent (claude, codex, gemini)[^18]
2. **Auto-naming**: `workmux add --auto-name -P prompt.md` generates branch name from prompt[^18]
3. **PR checkout**: `workmux add --pr 123` checks out pull request \#123[^18]

**Parallel Agent Workflow** (Real-world pattern from ):[^19]

```bash
# Main window: coordinator agent on main branch
# Brainstorm tasks with agent, write to tasks.md

# Delegate task to worktree agent
workmux add fix-race-condition -b -P /tmp/task.md
# Creates worktree, tmux window, starts agent with prompt

# Repeat for parallel tasks
workmux add optimize-queries -b -P /tmp/task2.md
workmux add refactor-auth -b -P /tmp/task3.md

# Each agent works in isolation in its own tmux window
# Review and merge as they complete
cd ../project__worktrees/fix-race-condition
# Review changes
workmux merge
```

**tmux Integration Deep Dive**:

Workmux creates tmux windows (not sessions) within your current session. This preserves your existing tmux workflow—shortcuts, themes, and session management all remain intact. The status indicators in `workmux list` reflect agent state:[^20][^18]

- `✓` = tmux window exists
- `●` = unmerged commits present
- Agent status visible in tmux window names[^18]


### 2.7 Comparison Matrix

| Feature | wtp | Grove | Treekanga | branchlet | Worktrunk | workmux |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| **Language** | Go | ? | Rust | ? | Rust | Rust |
| **Shell Integration** | ✓ (cd command) | ✓✓ (native PWD change) | - | - | - | - |
| **tmux Integration** | - | - | ✓ (via sesh) | - | - | ✓✓ (native) |
| **Hook System** | ✓ (post_create) | - | - | ✓ (post_create) | ✓✓ (pre/post merge) | ✓✓ (post_create) |
| **File Copying** | ✓ (copy type) | - | - | ✓ | - | ✓ (copy/symlink) |
| **Auto Path Generation** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **IDE Integration** | - | - | ✓✓ (VSCode/Cursor) | - | - | - |
| **Agent-Specific** | - | - | - | - | ✓ | ✓✓ |
| **Interactive TUI** | - | - | - | ✓✓ | - | - |
| **Bare Repo Focus** | - | ✓✓ | - | - | - | - |
| **Tab Completion** | ✓ | ✓ | ✓ | - | ✓ | - |
| **Branch Cleanup** | ✓ (--with-branch) | ✓ | ✓ | ✓ | ✓ | ✓ |
| **LLM Integration** | - | - | - | - | ✓ (commit msgs) | ✓ (agent detection) |

**Legend**: ✓✓ = Primary feature, ✓ = Supported, - = Not available

***

## 3. AI Agent Integration: Multi-Agent Session Isolation

The intersection of worktrees and AI agents has created novel parallel development patterns. This section synthesizes real-world implementations.

### 3.1 The Session Isolation Problem

AI coding agents (Claude Code, OpenCode, Cursor, Copilot) maintain context about the current working directory and file state. When multiple agents operate in the same worktree, they encounter:[^21]

1. **Type errors from other agents' incomplete changes**[^21][^18]
2. **Broken builds** from dependency conflicts[^18]
3. **Context pollution** where Agent A's changes confuse Agent B[^21]
4. **Race conditions** in file writes[^22]
5. **Merge conflicts during concurrent work**[^2]

**Worktrees solve this** by providing complete filesystem isolation—each agent operates in its own directory with its own branch, seeing only its own changes until merge time.[^23][^21]

### 3.2 Claude Code + Worktrees

**Official Documentation**: Anthropic's Claude Code best practices recommend worktrees for parallel sessions.[^24]

**Setup Pattern**:

```bash
# Create worktrees for different features
git worktree add ../project-feature-a feature-a
git worktree add ../project-feature-b feature-b

# Launch Claude in each worktree (separate terminal tabs)
cd ../project-feature-a && claude
cd ../project-feature-b && claude

# Each Claude session works independently
```

**Real-World Implementation (incident.io)**:[^25]

The incident.io team ships faster using a combined Claude Code + worktree workflow:

1. **Manager script**: Automates worktree creation in `~/projects/worktrees/` structure
2. **Voice integration**: Uses SuperWhisper for 5-minute voice context dumps
3. **Intelligent completion**: Tab-completes existing worktrees, creates new ones on-the-fly
4. **Auto-commit**: Claude commits and pushes changes autonomously in each worktree
5. **Isolation benefit**: "The ability to brain-dump context for 5 minutes and let Claude parse and implement it is surprisingly natural"[^25]

**Video Tutorial (18-minute walkthrough)**:[^26]

The "How to Run Claude Code in parallel with Git Worktrees" tutorial demonstrates:

1. Planning code changes and breaking into tasks
2. Creating git worktree per task: `git worktree add worktree/<task-name> -b <branch>`
3. Opening Claude Code instance per worktree
4. Feeding task prompt to each isolated Claude instance
5. Agents execute in parallel without conflicts
6. Merging completed tasks back to main branch
7. Testing integration after merges

**Automation Pattern**:

```bash
# Script to spawn Claude in worktree
create_claude_worktree() {
  local task=$1
  local branch="worktree/$task"
  
  git worktree add worktree/$task -b $branch
  cd worktree/$task
  
  # Copy environment
  cp ../../.env .env
  
  # Install deps
  npm install
  
  # Start Claude with task prompt
  claude --dangerously-skip-permissions < ../tasks/$task.md
}
```

**Custom `/worktree` Command (motlin.com)**:[^27]

A custom Claude Code command that:

1. Finds next available todo from task list
2. Creates worktree with `git worktree add ../my-app-<task-name> -b <branch>`
3. Copies required files (.env, etc.)
4. Creates focused todo file for the specific task
5. Launches Claude in new iTerm tab: `cd <worktree> && claude --dangerously-skip-permissions /todo`

**Usage**: `/worktree 3` creates 3 worktrees serially, each with isolated agent.[^27]

### 3.3 OpenCode + Worktrees

**OpenCode vs Claude Code**: OpenCode is an open-source alternative supporting 75+ LLM providers (Claude, GPT, Gemini, Ollama) vs Claude Code's Anthropic-only approach.[^28][^29]

**Worktree Detection**: OpenCode automatically detects git worktree context for skills and plugins:[^30]

```bash
# OpenCode walks up from CWD to git worktree root
# Loads .opencode/skills/*/SKILL.md
# Loads .claude/skills/*/SKILL.md
```

**Plugin API**:

```typescript
// OpenCode plugin receives worktree context
function plugin({
  project,      // Project info
  directory,    // Current working directory  
  worktree,     // Git worktree path
  client,       // OpenCode SDK client
  $             // Bun shell API
}) {
  // Plugin can use worktree path for operations
  console.log(`Working in worktree: ${worktree}`);
}
```

**GitHub Actions Integration**:[^31][^32]

OpenCode can respond to GitHub comments (`/oc` or `/opencode`) to:

1. Create new branch/worktree
2. Implement requested changes
3. Open pull request
4. Commit additional changes to same PR

Workflow runs in GitHub Actions runner with worktree isolation.

**Comparison (Claude Code vs OpenCode on worktrees)**:[^28]


| Aspect | Claude Code | OpenCode |
| :-- | :-- | :-- |
| **Worktree support** | Native (documented) | Native (documented) |
| **Setup complexity** | Medium | Medium |
| **Provider options** | Claude only | 75+ (Claude, GPT, local) |
| **Cost** | \$20-200/mo or API | Free tool + provider costs |
| **Speed (parallel work)** | Faster (optimized) | Slightly slower (thorough) |
| **Thoroughness** | Focused changes | Comprehensive changes |
| **Desktop app** | No | Yes (+ VS Code extension) |

**Real-world result**: Testing OpenCode vs Claude Code with Opus 4.5 on same plan:[^33]

- Claude: 14 min, ~191k tokens
- OpenCode: 27 min, ~278k tokens
- Quality close, Claude slightly better, 2× faster, 30% cheaper
- OpenCode better UX, but Claude Code's web UI and integrations (GitHub reviews, Linear) missing


### 3.4 Cursor Parallel Agents

**Feature**: Cursor ships "Parallel Agents" built on worktrees.[^34]

**Architecture**:

- Each agent runs in isolated worktree on its own branch[^34]
- Agents operate side-by-side without file conflicts[^34]
- Agent sessions visible in Cursor UI
- Fast worktree creation (space-efficient vs full clones)[^34]

**Documentation**: See Cursor Worktrees docs for configuration.[^34]

### 3.5 VS Code Background Agents

**Feature**: VS Code Copilot CLI supports worktree isolation for background agents.[^35]

**Usage**:

1. Start background agent session in VS Code
2. Select **Worktree** for isolation mode (vs Workspace)[^35]
3. Enter prompt—VS Code automatically creates git worktree
4. Background agent operates in isolated folder
5. No conflicts with active workspace work[^35]

**Rationale**: Background agents autonomously apply changes; worktrees prevent interference with main workspace.[^35]

### 3.6 Multi-Agent Coordination Patterns

**Pattern 1: Task Master with Tagged Tasks**:[^2]

```bash
# Main worktree: tag tasks by feature area
task-master tag admin-tasks "feature/AdminFeatures"
task-master tag instructor-tasks "feature/InstructorFeatures"

# Create worktrees per feature area
git worktree add ../AdminFeatures feature/AdminFeatures
git worktree add ../InstructorFeatures feature/InstructorFeatures

# In each worktree, agent only sees relevant tasks
cd ../AdminFeatures
task-master use admin-tasks
claude  # Agent only accesses admin-tagged tasks

cd ../InstructorFeatures
task-master use instructor-tasks
claude  # Agent only accesses instructor-tagged tasks
```

This prevents task overlap between agents.[^2]

**Pattern 2: Coordinator + Workers (raine.dev)**:[^19]

1. **Coordinator agent**: Runs in main tmux window on main branch
    - Brainstorms tasks with developer
    - Writes detailed task prompts
    - Spawns worker agents
2. **Worker agents**: Each in own worktree + tmux window
    - Receives focused task prompt
    - Works in isolation on feature branch
    - Commits progress independently
3. **Merge queue**: Developer reviews completed worktrees
    - `workmux merge` when ready
    - Coordinator agent handles merge conflicts if needed
    - Next task assigned

**Pattern 3: Parallel Feature Development**:[^36][^37]

```bash
# Developer's workflow with 3 parallel agents
cd ~/myproject  # Main worktree for code review

# Spawn 3 agents for different features
git worktree add ../feature-oauth feature-oauth
cd ../feature-oauth && claude "implement OAuth 2.0" &

git worktree add ../feature-ui feature-ui  
cd ../feature-ui && claude "improve dashboard UI" &

git worktree add ../feature-api feature-api
cd ../feature-api && claude "add REST endpoints" &

# Each agent works independently
# Developer reviews in main worktree as diffs come in
```


### 3.7 Agent Safety Rules

To prevent agents from damaging worktrees, practitioners recommend these rules in agent instructions:[^21]

```markdown
## Worktree Safety Rules

### You CAN safely:
- Create commits in this worktree
- Create local branches
- Pull/fetch from remote
- Push this branch to remote

### You MUST NOT:
- Delete worktrees
- Modify any branches except the checked-out branch
- Force push without explicit permission
- Run git operations affecting repository-wide settings
- Create new worktrees (only human operator creates worktrees)

### Context:
- All development in worktree under `.trees/{TASK_ID}`
- Use branch named after assigned task
- Get git root: `git rev-parse --show-toplevel`
- Create worktree with: `git worktree add -B <branch> .trees/<task-id>`
```

**Communication Pattern**:[^21]

When discussing work across worktrees, always:

- State which worktree you're referencing
- Use absolute paths when discussing files
- Be explicit about branch/worktree context

Example:

```
In the ~/myproject-auth-feature worktree, please review
src/auth/oauth.py and suggest improvements. Do not make changes
to UI files—those are in ~/myproject-ui worktree.
```


### 3.8 Aspire + MCP + Worktrees (Advanced Integration)

**Problem**: Running multiple Aspire AppHosts in parallel for AI agents with MCP (Model Context Protocol) tools.[^38]

**Solution**: Port isolation layer with worktree detection:[^38]

```bash
# Each worktree gets unique ports
cd worktrees/feature-auth
.\scripts\start-apphost.ps1
# Dashboard: https://localhost:54772
# MCP: port 54775 (saved to settings.json)

cd worktrees/feature-ui  
.\scripts\start-apphost.ps1
# Dashboard: https://localhost:58229
# MCP: port 58232 (saved to settings.json)

# MCP proxy reads settings.json, routes to correct worktree
# Agent in feature-auth connects to port 54775
# Agent in feature-ui connects to port 58232
```

**Detection Code**:

```csharp
GitFolderResolver.GetGitFolderName()  // Detects worktree

// Dashboard shows "NoteTaker-feature-auth" vs "NoteTaker-feature-ui"
builder.Configuration["DashboardApplicationName"] = gitFolderName;
```

Agents can autonomously:

- Start AppHost in their worktree
- Use MCP tools to verify resources
- Check logs if failures occur
- Clean up when done

**Future Vision**: `aspire run --isolated` with native worktree support.[^38]

***

## 4. Hooks and Automation Patterns

Hooks automate repetitive setup tasks when creating worktrees. This section documents patterns across tools and manual implementations.

### 4.1 Git Native Hooks

**post-checkout Hook**: Runs when `git worktree add` creates a new worktree.[^39][^40]

**Detection Pattern**:

```bash
#!/bin/bash
# .git/hooks/post-checkout

# Parameters: $1 = previous HEAD, $2 = new HEAD, $3 = branch checkout flag

# Detect worktree creation (previous HEAD is all zeros)
if [[ "$1" == "0000000000000000000000000000000000000000" ]]; then
  echo "New worktree created"
  
  # Run setup
  npm install
  cp ../.env .env
  
  # Custom setup based on worktree path
  WORKTREE_DIR=$(pwd)
  echo "Setup complete for $WORKTREE_DIR"
fi
```

**Limitation**: post-checkout runs for all checkouts, not just worktree creation. The detection logic (all-zeros previous HEAD) is a workaround.[^39]

**Per-Worktree Hooks**:[^41]

By default, all worktrees share hooks from `.git/hooks`. To have per-worktree hooks:

```bash
# Enable worktree-specific config
git config extensions.worktreeconfig true

# In specific worktree, set custom hooks path
cd worktree/feature-auth
hooks=$(git rev-parse --git-dir)/hooks
git config --worktree core.hookspath "$hooks"
mkdir -p "$hooks"

# Create worktree-specific hooks
echo 'echo "Feature-auth pre-commit"' > "$hooks/pre-commit"
chmod +x "$hooks/pre-commit"
```


### 4.2 Tool-Specific Hook Systems

**wtp Hook Configuration**:[^10]

```yaml
# .wtp.yml
hooks:
  post_create:
    - type: copy
      from: ".env.example"   # Main worktree source
      to: ".env"             # New worktree destination
    
    - type: copy
      from: ".env.local"
      to: ".env.local"
    
    - type: command
      command: "npm install"
      env:
        NODE_ENV: "development"
    
    - type: command  
      command: "npm run db:setup"
      work_dir: "."
```

**Execution**: Runs serially after worktree creation, before control returns to user.[^10]

**workmux Hook Configuration**:[^17]

```yaml
# .workmux.yaml
post_create:
  - pnpm install
  - pnpm db:migrate
  - pnpm generate:types

files:
  copy:
    - .env
    - .env.local
  symlink:
    - .turbo              # Share Turborepo cache
    - node_modules/.cache # Share build cache
```

**Key Features**:

- **Symlinks** for shared caches (faster subsequent builds)[^17]
- **Copies** for files that must be unique per worktree[^17]
- Commands run in worktree directory with proper environment[^17]

**autowt Hook System**:[^42]

```toml
# .autowt.toml
[scripts]
post_create = "cp $AUTOWT_MAIN_REPO_DIR/.env .env"

# or async (runs after terminal opens)
post_create_async = "npm install && npm run build"
```

**Environment Variables**:

- `$AUTOWT_MAIN_REPO_DIR`: Path to main repository worktree
- Available in all hook scripts for referencing main repo files[^42]

**Windsurf Hook System**:[^43]

```json
// .windsurf/hooks.json
{
  "hooks": {
    "post_setup_worktree": [
      {
        "command": "bash $ROOT_WORKSPACE_PATH/hooks/setup_worktree.sh",
        "show_output": true
      }
    ]
  }
}
```

**Hook Script**:

```bash
#!/bin/bash
# hooks/setup_worktree.sh

# $ROOT_WORKSPACE_PATH provided by Windsurf

# Copy environment files
if [ -f "$ROOT_WORKSPACE_PATH/.env" ]; then
  cp "$ROOT_WORKSPACE_PATH/.env" .env
  echo "Copied .env file"
fi

# Install dependencies
if [ -f "package.json" ]; then
  npm install
  echo "Installed npm dependencies"
fi

exit 0
```


### 4.3 Dependency Installation Automation

**Challenge**: Each worktree needs dependencies installed, which can take minutes.[^44]

**Solution 1: Hook-based automation**:[^42][^10]

```yaml
post_create:
  - type: command
    command: "npm install"
```

**Solution 2: npm workspaces (shared node_modules)**:[^44]

```
PROJECT/
├── node_modules/           # Shared root node_modules
├── packages/
│   ├── client/
│   │   └── package.json
│   ├── server/
│   │   └── package.json
│   ├── wt-main/            # Worktree
│   │   ├── client/
│   │   └── server/
└── package.json            # Root declares workspaces
```

**Root package.json**:

```json
{
  "name": "project-root",
  "workspaces": ["packages/*"]
}
```

**Behavior**:

- Run `npm install` from root once
- All workspace packages share root `node_modules`
- Worktrees automatically access shared dependencies
- No per-worktree npm install needed[^44]

**Solution 3: Symlink node_modules**:[^45]

```yaml
# Share node_modules across worktrees
files:
  symlink:
    - node_modules
    - .turbo
```

**Trade-off**: Works if all worktrees use same dependency versions. Breaks if branches have different package.json.

### 4.4 Environment File Copying

**Pattern**: Copy `.env` from main worktree to new worktree.[^46][^47][^43][^42]

**Why**: `.env` files are gitignored but needed for application to run. New worktrees don't have them by default.

**Implementation (Shell Script)**:

```bash
# In post-create hook or script
MAIN_REPO=$(git rev-parse --show-toplevel)
cp "$MAIN_REPO/.env" .env
cp "$MAIN_REPO/.env.local" .env.local
cp "$MAIN_REPO/.pem" .pem  # SSL certs
```

**Multiple Environment Files**:[^43]

```bash
# Copy all environment variations
for env_file in .env .env.local .env.development .env.test; do
  if [ -f "$ROOT_WORKSPACE_PATH/$env_file" ]; then
    cp "$ROOT_WORKSPACE_PATH/$env_file" "$env_file"
    echo "Copied $env_file"
  fi
done
```

**Advanced: Dynamic .env Substitution**:[^46]

Laravel example with database port assignment:

```bash
# Assign unique DB port per worktree
dbPort=$((3306 + RANDOM % 100))
database="myapp_$(basename $(pwd))"

# Update .env with sed
sed -i "s/\(^DB_PORT=.*\)/DB_PORT=$dbPort/g" .env
sed -i "s/\(^DB_DATABASE=.*\)/DB_DATABASE=$database/g" .env

# Create database
mysql -uroot -e "CREATE DATABASE $database"
```

This ensures each worktree has isolated database.[^46]

### 4.5 Complete Setup Automation Example

**Use Case**: Laravel application with full environment setup.[^46]

**Script** (`create_worktree.sh`):

```bash
#!/bin/bash

create_worktree() {
  local branch=$1
  local path="../worktrees/$branch"
  
  # Create worktree
  git worktree add -b "$branch" "$path"
  cd "$path"
  
  # 1. Copy environment files
  cp -n .env.example .env
  cp -n .env.example .env.testing
  
  # 2. Set dynamic values
  dbPort=$((3306 + RANDOM % 100))
  database="myapp_$branch"
  
  sed -i "s/^DB_PORT=.*/DB_PORT=$dbPort/" .env
  sed -i "s/^DB_DATABASE=.*/DB_DATABASE=$database/" .env
  
  # 3. Copy secrets from main repo
  if [ -f "../.env" ]; then
    HONEYBADGER_KEY=$(awk -F= '/^HONEYBADGER_KEY/{print $2}' ../.env)
    sed -i "s/^HONEYBADGER_KEY=.*/HONEYBADGER_KEY=$HONEYBADGER_KEY/" .env
  fi
  
  # 4. Install dependencies
  composer install --quiet
  npm install --quiet
  npm run dev
  
  # 5. Database setup
  mysql -uroot -e "CREATE DATABASE $database"
  php artisan migrate --seed
  
  # 6. Restore backup (optional)
  if [ -f "../backup.sql" ]; then
    mysql -uroot $database < ../backup.sql
  fi
  
  # 7. Local dev server setup (Valet)
  valet link "$branch"
  valet secure "$branch"
  
  echo "Worktree ready at $path"
  echo "URL: https://$branch.test"
}
```

**Teardown Script**:

```bash
#!/bin/bash

teardown_worktree() {
  # Get current worktree info
  database=$(awk -F= '/^DB_DATABASE/{print $2}' .env)
  dbPort=$(awk -F= '/^DB_PORT/{print $2}' .env)
  appUrl=$(awk -F= '/^APP_URL/{print $2}' .env | sed 's/https:\/\///')
  
  # Drop databases
  mysql -uroot -e "DROP DATABASE $database"
  for i in {1..10}; do
    mysql -uroot -e "DROP DATABASE ${database}_$i" 2>/dev/null
  done
  
  # Unlink Valet
  valet unsecure "$appUrl"
  valet unlink "$appUrl"
  
  # Remove worktree
  folder=$(pwd)
  parent=$(dirname "$folder")
  git worktree remove --force "$folder"
  cd "$parent"
  
  echo "Teardown complete"
}
```


***

## 5. Shell Integration Deep Dive

Shell integration enables commands that change the working directory of the current shell session—critical for seamless worktree navigation.

### 5.1 The Technical Challenge

**Problem**: In Unix/Linux, a subprocess cannot change its parent process's working directory. When you run `wt switch feature`, the `wt` command is a subprocess and can't modify your shell's PWD.[^12]

**Traditional Workaround**: Output a `cd` command and eval it:

```bash
eval "$(wt switch feature --print-cd)"
```

**Better Solution**: Shell function wrapper.[^48][^12][^10]

### 5.2 Shell Function Pattern

**Implementation (zsh example)**:

```bash
# Add to ~/.zshrc
wt() {
  local result
  result=$(/usr/local/bin/wt "$@")
  local exit_code=$?
  
  # Check if output contains directory change
  if [[ $result == CD:* ]]; then
    local dir="${result#CD:}"
    cd "$dir"
  else
    echo "$result"
  fi
  
  return $exit_code
}
```

**How it Works**:

1. Shell function `wt()` wraps binary `/usr/local/bin/wt`
2. Binary executes worktree operation
3. If directory change needed, binary outputs `CD:/path/to/worktree`
4. Shell function parses output, executes `cd` in parent shell
5. Otherwise prints normal output

**wtp Implementation**:[^10]

```bash
# Generated by: wtp completion zsh
eval "$(wtp completion zsh)"

# Enables:
# - Tab completion for commands, branches, worktrees
# - Directory changing via wtp cd command
```

The completion script installs the function wrapper automatically.

**Grove Implementation**:[^48][^12]

```bash
eval "$(grove init zsh)"

# Provides:
grove switch <worktree>   # Changes shell PWD
grove go <worktree>       # Creates + changes PWD  
grove last                # Returns to previous worktree
```

Grove's distinguishing feature: native shell integration makes worktrees feel like branches.[^12]

### 5.3 Tab Completion

**Zsh Tab Completion Structure**:

```bash
# Completion function for wt command
_wt() {
  local -a commands
  commands=(
    'add:Create new worktree'
    'remove:Remove worktree'
    'list:List worktrees'
    'cd:Change to worktree directory'
  )
  
  _arguments \
    '1: :->command' \
    '*:: :->args'
  
  case $state in
    command)
      _describe 'command' commands
      ;;
    args)
      case $words[^1] in
        cd|remove)
          # Complete with worktree names
          _values 'worktree' $(git worktree list | awk '{print $1}' | xargs -n1 basename)
          ;;
        add)
          # Complete with branch names
          _values 'branch' $(git branch -a | sed 's/^\*/ /' | awk '{print $1}')
          ;;
      esac
      ;;
  esac
}

compdef _wt wt
```

**Tab Completion Features**:[^10]

- Command completion: `wt <TAB>` shows available commands
- Branch name completion: `wt add <TAB>` shows branches
- Worktree name completion: `wt cd <TAB>` shows existing worktrees
- Context-aware: Different completions per subcommand


### 5.4 Prompt Integration

**Git Prompt Status in Worktrees**:

Standard git prompts (oh-my-zsh, starship, etc.) work in worktrees since each has a `.git` file.[^1]

**Custom Worktree Indicator**:

```bash
# Add to ~/.zshrc (using vcs_info)
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats '%b'
zstyle ':vcs_info:git:*' actionformats '%b|%a'

precmd() {
  vcs_info
  
  # Check if in worktree
  if [ -f .git ] && grep -q 'gitdir:' .git; then
    WORKTREE="[WT]"
  else
    WORKTREE=""
  fi
}

RPROMPT='${WORKTREE} ${vcs_info_msg_0_}'
```

**Output**: Shows `[WT]` in prompt when inside a worktree.

**workmux tmux Integration**:[^18]

Workmux uses tmux window names as status indicators:

```
0: main               # Main branch (no indicator)
1: feature-auth*      # Active worktree (asterisk = current window)
2: bug-fix⏳          # Agent working (hourglass)
3: refactor✓          # Agent done (checkmark)
```

This provides at-a-glance status of all parallel agents.[^18]

### 5.5 Multi-Shell Support

**Supported Shells**:[^10]

- bash (4.0+)
- zsh (5.0+)
- fish (3.0+)

**bash Integration**:

```bash
# Add to ~/.bashrc
eval "$(wt completion bash)"
```

**fish Integration**:

```fish
# Add to ~/.config/fish/config.fish  
wt completion fish | source
```

**Compatibility Considerations**:

- Function syntax differs (bash vs zsh vs fish)
- Completion systems differ (bash-completion vs zsh compsys vs fish)
- Most tools auto-detect shell and generate appropriate code[^10]

***

## 6. Real-World Workflows and Use Cases

### 6.1 Parallel Feature Development

**Scenario**: Three unrelated features in progress simultaneously.

**Traditional Approach**:

```bash
# Feature 1
git checkout -b feature-auth
# ... make changes ...
git stash  # Context switch incoming

# Hotfix needed
git checkout main
git checkout -b hotfix-login
# ... fix bug ...
git stash  # Switch again

# Feature 2
git checkout -b feature-api
# ... make changes ...

# Problems:
# - Lost editor state 3 times
# - 3x npm install (if dependencies changed)
# - Constant stashing
```

**Worktree Approach**:

```bash
# Create three isolated environments
git worktree add ../feature-auth feature-auth
git worktree add ../feature-api feature-api  
git worktree add ../hotfix-login hotfix-login

# Three terminal tabs/tmux windows
Tab 1: cd ../feature-auth && code .
Tab 2: cd ../feature-api && code .
Tab 3: cd ../hotfix-login && code .

# Benefits:
# - All editors remain open with state preserved
# - Each has own node_modules (no reinstall on switch)
# - No stashing
# - Can run all three dev servers simultaneously
```


### 6.2 PR Review Workflow

**Scenario**: Review teammate's PR while keeping your work intact.[^6]

**Worktree Approach**:

```bash
# Your work in progress on main worktree
cd ~/myproject
# ... working on feature ...

# PR comes in for review
git fetch origin pull/123/head:pr-123
git worktree add ../pr-123 pr-123

# Review in separate editor
cd ../pr-123
code .
npm install
npm test

# Test the PR's changes
npm run dev  # Runs on different port than main worktree

# Approve or request changes, then cleanup
cd ~/myproject
git worktree remove ../pr-123
git branch -d pr-123
```

**Automation (workmux)**:[^18]

```bash
# One command to checkout PR + setup
workmux add --pr 123

# Review, approve, cleanup
workmux remove
```


### 6.3 Long-Running Branches

**Scenario**: Maintain multiple long-lived environment branches (dev, staging, prod).[^49]

**Problem with Traditional Git**:

- Each checkout requires dependency reinstall
- Build systems crash into each other (Windows/Linux builds)[^49]
- Configuration files conflict

**Worktree Solution**:

```bash
# Permanent worktrees for each environment
git worktree add ../dev dev
git worktree add ../staging staging
git worktree add ../prod prod

# Each has own:
# - .env file (different API keys)
# - node_modules (potentially different versions)
# - Build artifacts (no conflicts)
# - Running processes (different ports)

# Switching is just:
cd ../staging
# Everything already set up
```


### 6.4 Parallel AI Agent Development (Real-world Case Studies)

**Case Study 1: Parallel Task Delegation (kevinz103)**:[^50]

Setup:

```bash
# For each ticket/task
wtp add ticket-AUTH-123
wtp add ticket-API-456
wtp add ticket-UI-789
```

iTerm2 Configuration:

- Split panes: 4 panes visible simultaneously
- Each pane in different worktree
- Each pane running Claude Code

Workflow:

1. Break project into tickets
2. Create worktree per ticket
3. Open iTerm2 with 4-pane layout
4. Start Claude Code in each pane with ticket context
5. Agents work in parallel
6. Review and merge completed tickets

Result: "10x developer productivity" claimed.[^50]

**Case Study 2: Aspire + MCP Multi-Agent (Anonymous)**:[^38]

Problem: Running multiple .NET Aspire AppHosts for different agents, each needing MCP tool access.

Solution:

```bash
# Each worktree runs isolated AppHost
worktrees/
├── feature-auth/      # AppHost on ports 54772-54775
├── feature-ui/        # AppHost on ports 58229-58232  
└── feature-api/       # AppHost on ports 61003-61006

# MCP proxy routes by worktree
# Agent in feature-auth → connects to 54775
# Agent in feature-ui → connects to 58232
```

Scripts automate:

- Port allocation per worktree
- AppHost startup
- MCP proxy configuration
- Health checking
- Cleanup on exit

Result: "Transformed my AI agent workflow from sequential (one at a time) to truly parallel (four agents simultaneously)".[^38]

**Case Study 3: Coordinator Pattern (raine.dev)**:[^19]

Main Window (Coordinator):

- Claude Code on main branch
- Brainstorms tasks: "Break down this feature into 3 tasks"
- Writes detailed prompts for each task
- Delegates to worker agents

Worker Windows (workmux):

```bash
# Coordinator spawns workers
workmux add task-1 -b -P /tmp/task1.md
workmux add task-2 -b -P /tmp/task2.md  
workmux add task-3 -b -P /tmp/task3.md

# Each creates:
# - New worktree
# - New tmux window
# - Starts Claude Code with task prompt
```

Review Queue:

- Developer circles through tmux windows
- Reviews diffs as agents complete
- `workmux merge` merges to main
- If conflicts, coordinator agent resolves them

Result: "Start a few agents, do something else, come back to a queue of diffs ready for review".[^19]

### 6.5 Testing Across Versions

**Scenario**: Compare behavior before/after changes for documentation.[^6]

**Workflow**:

```bash
# Main worktree: feature branch with changes
cd ~/myproject
npm run dev  # Runs on port 3000

# Worktree: baseline (main branch)
git worktree add ../baseline main
cd ../baseline
npm install
npm run dev -- --port 3001  # Different port

# Now can:
# - Run both versions simultaneously
# - Capture screenshots of both
# - Compare behavior side-by-side
# - Record video showing before/after
```

Use Case: Creating PR that includes "before vs after" comparison screenshots.[^6]

### 6.6 Hotfix While Feature In Progress

**Scenario**: Classic worktree use case—emergency fix needed during feature work.[^51][^52]

**Worktree Approach**:

```bash
# Currently: deep in feature work with uncommitted changes
cd ~/myproject  # On feature-auth branch
# 500 lines of changes, not ready to commit

# Emergency: production bug found
git worktree add ../hotfix-prod hotfix-prod

# Fix in isolation
cd ../hotfix-prod
# ... fix bug ...
git commit -m "Fix critical bug"
git push origin hotfix-prod

# Merge to production immediately
git checkout main
git merge hotfix-prod
git push origin main

# Remove hotfix worktree
cd ~/myproject
git worktree remove ../hotfix-prod
git branch -d hotfix-prod

# Resume feature work
# All 500 lines of changes still intact
# Editor state preserved
# dev server still running
```

**No Worktrees** (painful alternative):

```bash
# Stash (might conflict)
git stash

# Fix
git checkout main
git checkout -b hotfix-prod
# ... fix ...
git push

# Resume (might conflict)
git checkout feature-auth
git stash pop  # Hope for no conflicts
npm install   # If dependencies changed
npm run dev   # Restart server
# Re-open files in editor
# Lose all editor state
```


***

## 7. Best Practices and Limitations

### 7.1 Best Practices

**1. Use Bare Repository Structure**[^8][^7][^9]

```bash
# Recommended structure
myproject/
├── .bare/          # Bare repository
├── main/           # Worktree for main
├── feature-a/      # Worktree for feature
└── feature-b/      # Worktree for feature

# Not recommended
myproject/          # Main worktree (has .git/)
├── .git/
└── ../feature-a/   # Linked worktree
```

**Rationale**: Bare repos eliminate the privileged main worktree, making all worktrees symmetric.[^9]

**2. Consistent Naming Convention**[^13][^10]

```bash
# Good: organized by type
worktrees/
├── feature/
│   ├── auth/
│   └── payments/
├── bugfix/
│   └── issue-123/
└── hotfix/
    └── security-patch/

# Bad: flat and confusing
worktrees/
├── stuff/
├── test1/
└── john-temp/
```

**3. Clean Up Regularly**[^15][^13]

```bash
# List all worktrees
git worktree list

# Remove merged branches
git worktree remove feature-auth
git branch -d feature-auth

# Prune stale entries
git worktree prune
```

Stale worktrees accumulate and consume disk space.[^53][^54]

**4. Automate Environment Setup**[^42][^17][^10]

Don't manually copy `.env` each time—use hooks:

```yaml
hooks:
  post_create:
    - type: copy
      from: ".env"
      to: ".env"
```

**5. Symlink Shared Caches**[^45][^17]

```yaml
files:
  symlink:
    - .turbo
    - node_modules/.cache
    - .next/cache
```

This shares build caches across worktrees, dramatically speeding up builds.

**6. One Worktree Per Feature**[^55][^56]

```bash
# Good: focused worktrees
feature-auth
feature-api
bugfix-login

# Bad: treating worktrees as catch-all branches
worktree-1  # Has 10 unrelated features
temp-stuff  # Random experiments
```

**7. Use Descriptive Branch Names**[^13]

```bash
# Good
feature/user-authentication
bugfix/login-csrf
hotfix/payment-validation

# Bad
test
temp
fix
```

Branch name becomes worktree directory name, so clarity matters.

**8. Terminal Management**[^24][^18]

```bash
# One terminal tab/tmux window per worktree
Tab 1: ~/project/main         # Main branch for reviews
Tab 2: ~/project/feature-auth  # Feature work
Tab 3: ~/project/pr-review     # PR under review

# Or use workmux for automatic tmux window management
workmux add feature-auth  # Creates tmux window automatically
```

**9. Document Worktree Structure**[^55]

Add to README:

```markdown
## Development Setup

This project uses git worktrees. Structure:

myproject/
├── .bare/          # Bare repo (don't touch)
├── main/           # Main branch (for PRs, reviews)
├── worktrees/      # Feature branches
    ├── feature-auth/
    └── feature-api/

### Create New Feature
\`\`\`bash
workmux add feature-name
\`\`\`
```

**10. Avoid Force Push in Worktrees**[^21]

If force-pushing is necessary:

```bash
# Ensure no other worktree has this branch checked out
git worktree list | grep feature-auth

# If clear, safe to force push
git push --force-with-lease
```


### 7.2 Common Limitations and Gotchas

**1. Branch Locking (Critical)**[^57][^58][^59]

**Problem**: Cannot checkout same branch in multiple worktrees.

```bash
git worktree add ../worktree-1 feature-auth  # OK
git worktree add ../worktree-2 feature-auth  # ERROR
# fatal: 'feature-auth' is already checked out at '../worktree-1'
```

**Reason**: Git prevents simultaneous checkouts to avoid conflicts.[^57]

**Workaround**: Use detached HEAD if read-only needed:

```bash
git worktree add --detach ../worktree-2 feature-auth
# Now in detached HEAD at same commit
```

**2. Orphaned Worktrees**[^53][^22]

**Problem**: Deleting worktree directory manually (not via `git worktree remove`) leaves metadata.

```bash
rm -rf ../feature-auth  # WRONG WAY
git worktree list
# Still shows: ../feature-auth (branch: feature-auth)

# Now trying to recreate fails
git worktree add ../feature-auth feature-auth
# fatal: '../feature-auth' already exists
```

**Fix**:

```bash
# Prune stale entries
git worktree prune

# Or force remove
git worktree remove --force ../feature-auth
```

**Prevention**: Always use `git worktree remove` or `wtp remove` / `workmux remove`.[^17][^10]

**3. Lock Files**[^53]

**Problem**: Interrupted git operations leave lock files.

```bash
# Ctrl+C during git operation in worktree
^C

# Later
git worktree remove feature-auth
# fatal: 'feature-auth' is locked
```

**Cause**: `.git/worktrees/feature-auth/locked` or `.git/worktrees/feature-auth/*.lock` files exist.[^53]

**Fix**:

```bash
# Check for locks
find .git/worktrees -name "*.lock" -o -name "locked"

# Remove if no git processes running
rm -f .git/worktrees/feature-auth/locked
rm -f .git/worktrees/feature-auth/*.lock

# Then remove worktree
git worktree remove feature-auth
```

**4. Disk Space**[^54][^60]

**Problem**: Each worktree duplicates working files.

**Example**:

- Repository size: 100 MB (`.git` directory)
- Working tree size: 500 MB (node_modules, build artifacts)
- 5 worktrees = 100 MB (shared `.git`) + 5 × 500 MB (working trees) = 2.6 GB

**Mitigation**:

```yaml
# Symlink large shared assets
files:
  symlink:
    - node_modules  # Share if versions identical
    - .next/cache
    - dist/
```

**Trade-off**: Symlinked files mean worktrees are not fully isolated.[^54]

**5. Submodules**[^55]

**Problem**: Submodules must be initialized per worktree.

```bash
git worktree add ../feature-auth feature-auth
cd ../feature-auth
git submodule update --init --recursive  # Required per worktree
```

**Automation**:

```yaml
post_create:
  - command: "git submodule update --init --recursive"
```

**6. IDE/Editor Confusion**[^61][^35]

**Problem**: Some IDEs don't recognize worktrees as separate projects.

**Solution**: Open each worktree in separate IDE window.

```bash
# VSCode: open new window per worktree
code ~/project/main
code ~/project/feature-auth

# Not: open folder, then try to switch
```

**VSCode Worktree Support**: VS Code 1.86+ has native worktree support.[^61]

**7. Merge Conflicts Across Worktrees**[^62]

**Problem**: Merging changes from multiple worktrees can cause conflicts.

**Scenario**:

```bash
# Worktree 1: refactors file structure
# Worktree 2: adds features to files
# Worktree 3: updates same files

# Merging all three → conflicts
```

**Best Practice**:

- Merge worktrees sequentially, not all at once
- Use small, focused worktrees
- Merge frequently to detect conflicts early[^62]

**8. Git Hooks Shared by Default**[^41]

**Problem**: All worktrees share `.git/hooks` by default.

**Impact**: Pre-commit hooks run the same way in all worktrees.

**Solution** (if per-worktree hooks needed):

```bash
git config extensions.worktreeconfig true
git config --worktree core.hookspath .git/worktrees/<id>/hooks
```

**9. Cannot Use Same Worktree Path Twice**[^63]

**Problem**: Even after removing worktree, path might be "remembered."

```bash
git worktree add ../temp feature-a
git worktree remove ../temp
git worktree add ../temp feature-b
# Sometimes fails with "already exists"
```

**Fix**: Use different paths or wait for git to prune metadata.

**10. Remote Tracking Not Automatic**[^64]

**Problem**: New branches in worktrees don't auto-track remotes.

```bash
git worktree add -b feature-new worktrees/feature-new
cd worktrees/feature-new
git push
# fatal: no upstream branch
```

**Fix**: Set upstream explicitly:

```bash
git push --set-upstream origin feature-new
```

**Or** configure git to auto-track:

```bash
git config --global push.default current
git config --global push.autoSetupRemote true
```


### 7.3 Performance Considerations

**Worktrees vs Clones (Benchmarks)**:[^65][^5]


| Operation | Worktree | Clone | Winner |
| :-- | :-- | :-- | :-- |
| Creation time | 1-2 sec | 10-30 sec | Worktree (10x faster) |
| Disk space (shared .git) | +500 MB (working tree only) | +1 GB (full repo) | Worktree (50% savings) |
| Fetch updates | 1 fetch for all | N fetches | Worktree (updates all) |
| Branch switching | `cd` only | `git checkout` + rebuild | Worktree (instant) |
| Merge/cherry-pick | Works offline | Requires fetch | Worktree (offline capable) |

**Space Efficiency Example**:[^6]

Large repository (1 GB `.git`):

- 5 clones: 5 GB (5 × 1 GB git databases)
- 5 worktrees: 1 GB (1 shared database) + 5 × working trees

If working tree is 200 MB each:

- Clones: 5 × 1.2 GB = 6 GB
- Worktrees: 1 GB + 5 × 0.2 GB = 2 GB

**Savings: 67% less disk space**.

***

## 8. Integration Examples: Claude Code and OpenCode

### 8.1 Claude Code Integration

**Official Recommendation (Anthropic)**:[^24]

```bash
# Best practices for agentic coding with Claude
# 1. Create worktrees for parallel sessions
git worktree add ../project-feature-a feature-a
git worktree add ../project-feature-b feature-b

# 2. Launch Claude in each worktree (separate terminals)
cd ../project-feature-a && claude
cd ../project-feature-b && claude

# 3. Maintain one terminal tab per worktree
# 4. Use consistent naming conventions  
# 5. Clean up when finished
git worktree remove ../project-feature-a
```

**iTerm2 Notifications**:[^24]

Configure iTerm2 to notify when Claude needs attention:

```
Preferences → Profiles → Terminal → Notifications
✓ Send notification when session receives output
```

This alerts you when Claude finishes in background worktree.

**Custom Workflow (motlin.com)**:[^27]

`.claude_commands/worktree`:

```bash
#!/bin/bash
# /worktree <count> - Create N worktrees with tasks

count=${1:-1}

for i in $(seq 1 $count); do
  # Find next todo
  task=$(grep -m1 "^- \[ \]" .llm/todo.md)
  task_name=$(echo "$task" | sed 's/- \[ \] //' | tr ' ' '-')
  
  # Mark as in-progress
  sed -i "s|$task|[⏺] $task|" .llm/todo.md
  
  # Create worktree
  git worktree add "../myapp-$task_name" -b "$task_name"
  cd "../myapp-$task_name"
  
  # Copy environment
  cp ../myapp/.env .env
  
  # Create focused todo for this worktree
  echo "$task" > .llm/todo.md
  
  # Launch Claude in new iTerm tab
  osascript -e "tell application \"iTerm2\"
    tell current window
      create tab with default profile
      tell current session
        write text \"cd $(pwd)\"
        write text \"claude --dangerously-skip-permissions /todo\"
      end tell
    end tell
  end tell"
  
  cd ../myapp  # Return to main
  
  echo "⏺ $(($i)) worktrees have been created so far."
done

echo "⏺ $count worktrees have been created."
```

**Usage**: `/worktree 3` creates 3 worktrees, each with:

- Isolated task from todo list
- Claude Code running with task prompt
- New iTerm tab for interaction


### 8.2 OpenCode Integration

**Worktree Detection**:[^66][^30]

OpenCode automatically detects worktree context when loading skills/plugins:

```typescript
// Plugin API
export default function plugin({
  project,      // { name, path }
  directory,    // Current working directory  
  worktree,     // Git worktree path (auto-detected)
  client,       // OpenCode SDK
  $             // Bun shell API
}) {
  console.log(`Worktree: ${worktree}`);
  
  // Can use worktree path for operations
  await $`cd ${worktree} && npm install`;
}
```

**Skill Loading**:[^30]

OpenCode walks up from CWD to git worktree root, loading:

- `.opencode/skills/*/SKILL.md` (per worktree)
- `.claude/skills/*/SKILL.md` (cross-compatible)
- `~/.config/opencode/skills/*/SKILL.md` (global)

This enables worktree-specific skill configurations.

**MCP Integration**:[^67]

The "Git Worktree Automation" skill for Claude Code (via oh-my-claude) can also be used with OpenCode:[^67]

```yaml
# Skill features:
# - Automate worktree setup (.worktrees/ directory)
# - Branch management
# - Environment file sync (.env, .nvmrc)
# - Automatic dependency installation (npm, yarn, pnpm)
```

Available on MCP Market for both Claude Code and OpenCode.[^67]

**GitHub Actions Worktrees**:[^32][^31]

OpenCode can create worktrees in GitHub Actions:

```yaml
# .github/workflows/opencode.yml
name: OpenCode
on:
  issue_comment:
    types: [created]

jobs:
  opencode:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run OpenCode
        uses: sst/opencode/github@latest
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        with:
          model: "claude-3-5-sonnet-20241022"
```

**Behavior**:

1. User comments `/oc implement feature X` on issue
2. GitHub Actions runner checks out main branch
3. OpenCode creates worktree for new feature branch
4. Implements changes in worktree
5. Pushes branch and opens PR

**Comparison: Claude Code vs OpenCode for Worktrees**:[^29][^28]


| Feature | Claude Code | OpenCode |
| :-- | :-- | :-- |
| **Worktree creation** | Manual or scripted | Manual or scripted |
| **Worktree detection** | Manual `cd` | Automatic (for skills) |
| **Cost (parallel agents)** | \$\$\$ (Anthropic API) | \$ (choose provider) |
| **Local models** | ❌ | ✅ (Ollama, etc.) |
| **Speed** | Faster (optimized) | Slightly slower |
| **Thoroughness** | Focused | Comprehensive |
| **GitHub integration** | Via web UI | Native Actions |
| **Open source** | ❌ | ✅ (MIT) |

**Use Case Recommendation**:

- **Claude Code**: Best for teams already using Anthropic, want fastest iterations, prefer integrated web UI[^28]
- **OpenCode**: Best for teams wanting provider flexibility, local models for privacy, open-source auditability[^28]

Both work excellently with worktrees—choice depends on broader tooling/cost preferences.[^29][^28]

***

## 9. YouTube Video Resources

Below are curated video tutorials for visual learners, ordered by length and depth.


| Video | Duration | Key Topics | URL |
| :-- | :-- | :-- | :-- |
| **Git Worktrees: The secret sauce to Claude Code!** | ~8 min | Worktrees + Claude Code integration, practical demo | [^68] |
| **learn git worktrees in under 5 minutes** | 5 min | Quick intro, basic commands | [^69] |
| **How to use Git Worktree** (Adib Hanna) | 7 min | Core concepts, create/list/remove, demo | [^70] |
| **How to Run Claude Code in parallel with Git Worktrees** | ~15 min | Step-by-step parallel Claude setup, task delegation | [^26] |
| **You need to use Git Worktrees** | ~16 min | Why worktrees matter, DevOps perspective | [^52] |
| **What Is Git Worktree** (GitKraken) | ~2 min | Quick explainer, GitKraken Desktop integration | [^71] |
| **How to Use Git Worktree to Manage Multiple Branches** (GitKraken) | 11 min | Detailed CLI walkthrough, GitLens+ in VS Code | [^72] |
| **Claude Code / OpenCode + T-Mux + Worktrees** | ~20 min | tmux integration, multi-agent orchestration | [^73] |
| **Git Worktrees + Agents** | ~1 hour | Deep dive, limitations, best practices, tmux control | [^74] |

**Recommended Learning Path**:

1. Start:  (7 min) - Learn basic commands[^70]
2. Understand:  (16 min) - See real use cases[^52]
3. Agents:  (15 min) - Parallel Claude Code workflow[^26]
4. Advanced:  (1 hour) - Comprehensive coverage[^74]

***

## 10. Key Takeaways and Recommendations

### 10.1 Core Insights

1. **Worktrees enable true parallel development**: Check out multiple branches simultaneously without cloning, saving disk space and enabling offline operations.[^65][^5]
2. **AI agents benefit dramatically from worktree isolation**: Each agent works in its own branch without type errors, broken builds, or context pollution from other agents.[^21][^18]
3. **Automation is essential**: Manual worktree management is tedious; tools like wtp, workmux, and Worktrunk reduce friction from minutes to seconds.[^17][^15][^10]
4. **Bare repository structure is superior**: Eliminates the "privileged main worktree" problem and creates symmetric development environments.[^8][^9]
5. **Hook systems automate environment setup**: Copy `.env` files, install dependencies, and configure databases automatically per worktree.[^42][^46][^17][^10]
6. **Shell integration enables seamless navigation**: Directory-changing commands (`wt cd`, `grove switch`) make worktrees feel like branch switches.[^12][^10]
7. **tmux integration provides orchestration**: One tmux window per worktree creates a visual dashboard for managing parallel agents.[^17][^18]
8. **Worktrees are space-efficient**: Share `.git` database across all worktrees, using ~50-70% less disk space than multiple clones.[^5][^6]
9. **Branch locking prevents conflicts**: Git enforces one checkout per branch across all worktrees, avoiding race conditions.[^58][^57]
10. **The ecosystem is maturing rapidly**: Tools are converging on best practices (bare repos, hooks, shell integration, agent support) as of 2025-2026.[^17][^18]

### 10.2 Tool Selection Guide

**Choose wtp if**:[^10]

- You want simplest setup (Go binary, single config file)
- Primary need: eliminate path typing and automate environment copying
- Shell integration for `wt cd` is enough

**Choose Grove if**:[^11][^12]

- You prioritize native shell integration (actual PWD change)
- You prefer bare-repo-first approach
- You want worktrees to "feel like branches"

**Choose Treekanga if**:[^13]

- You use IDEs heavily (VSCode, Cursor)
- You want intelligent branch detection (local vs remote)
- YAML config appeals to you

**Choose Worktrunk if**:[^15]

- You're explicitly running AI agents in parallel
- You want LLM-generated commit messages
- You need integrated merge workflow (squash, rebase, cleanup in one command)

**Choose workmux if**:[^17][^18]

- You use tmux as primary workflow
- You want one tmux window per worktree automatically
- You need pane layout automation
- You're running multiple AI agents and want visual orchestration

**Choose branchlet if**:[^14]

- You prefer interactive TUIs over CLI
- You want visual worktree management

**DIY Shell Scripts if**:

- Your needs are simple (just `git worktree add` + `cp .env`)
- You want full control over every step
- You're learning and want to understand internals


### 10.3 Setup Recommendations

**Starter Setup (5 minutes)**:

```bash
# 1. Install automation tool
brew install satococoa/tap/wtp
# or: cargo install workmux

# 2. Configure shell integration
echo 'eval "$(wtp completion zsh)"' >> ~/.zshrc
source ~/.zshrc

# 3. Initialize in project
cd ~/myproject
wtp init  # Creates .wtp.yml

# 4. Configure hooks
cat > .wtp.yml << EOF
version: "1.0"
defaults:
  base_dir: "../worktrees"

hooks:
  post_create:
    - type: copy
      from: ".env"
      to: ".env"
    - type: command
      command: "npm install"
EOF

# 5. Create first worktree
wtp add feature/my-feature
```

**Advanced Setup (AI agents + tmux)**:

```bash
# 1. Install workmux
brew install raine/tap/workmux

# 2. Initialize in project
cd ~/myproject
workmux init

# 3. Configure .workmux.yaml
cat > .workmux.yaml << EOF
panes:
  - command: <agent>     # Expands to claude, codex, etc.
    focus: true
  - command: npm run dev
    split: horizontal

post_create:
  - npm install
  - npm run db:migrate

files:
  copy:
    - .env
  symlink:
    - .turbo
EOF

# 4. Create worktree + tmux window + agent
workmux add feature-auth

# 5. Repeat for parallel agents
workmux add feature-api
workmux add feature-ui

# 6. View status
workmux list
# BRANCH        TMUX  UNMERGED  PATH
# main          -     -         ~/myproject
# feature-auth  ✓     ●         ~/myproject__worktrees/feature-auth
# feature-api   ✓     ●         ~/myproject__worktrees/feature-api
```


### 10.4 Common Pitfalls to Avoid

1. ❌ **Deleting worktree directories manually**
    - ✅ Always use `git worktree remove` or tool command[^53]
2. ❌ **Forgetting to clean up merged worktrees**
    - ✅ Run `git worktree prune` regularly[^15][^13]
3. ❌ **Manually copying `.env` every time**
    - ✅ Use post_create hooks[^42][^10]
4. ❌ **Running `npm install` manually per worktree**
    - ✅ Automate with hooks or symlink `node_modules`[^44][^17]
5. ❌ **Creating worktrees in random locations**
    - ✅ Use consistent `../worktrees/` structure[^17][^10]
6. ❌ **Ignoring branch locking errors**
    - ✅ Understand: one branch = one worktree max[^57]
7. ❌ **Not setting upstream for new branches**
    - ✅ Use `git push --set-upstream` or configure auto-tracking[^64]
8. ❌ **Accumulating stale lock files**
    - ✅ Check and remove after crashes[^53]
9. ❌ **Using worktrees for unrelated experiments**
    - ✅ Keep worktrees focused: one feature per worktree[^56][^55]
10. ❌ **Forgetting to document worktree setup for team**
    - ✅ Add worktree instructions to project README[^55]

### 10.5 Future Directions

**Emerging Patterns (2026)**:

1. **Agent-native tools**: Workmux, Worktrunk designed explicitly for AI agents[^15][^17]
2. **MCP integration**: Model Context Protocol enabling agents to spawn worktrees autonomously[^38]
3. **IDE native support**: VS Code, Cursor, Windsurf adding built-in worktree features[^43][^35][^34]
4. **GitHub Actions workflows**: OpenCode demonstrating CI/CD worktree patterns[^31][^32]
5. **Container integration**: Worktrees + Docker for complete isolation[^75][^28]

**Anticipated Developments**:

- **Aspire CLI**: Native `aspire run --isolated` for multi-instance orchestration[^38]
- **Improved worktree GC**: Automatic cleanup of stale worktrees[^53]
- **Cross-editor coordination**: Shared worktree state between IDEs[^61]
- **Visual worktree managers**: GUIs for non-CLI users[^14]
- **LLM-optimized workflows**: Agents that self-spawn worktrees for subtasks[^75][^19]

***

## Conclusion

Git worktrees have evolved from an obscure Git feature into a cornerstone of modern parallel development workflows, particularly for AI-assisted coding. The combination of worktree isolation, automation tools (wtp, workmux, Worktrunk), and shell/tmux integration enables developers to orchestrate 3-4 AI agents working on distinct features simultaneously without conflicts—a workflow impossible with traditional branching.[^3][^2][^19]

Key success factors:

- **Bare repository structure** eliminates asymmetry[^9][^8]
- **Hook-based automation** removes setup friction[^42][^17][^10]
- **Shell integration** makes navigation seamless[^12][^10]
- **tmux orchestration** provides visual coordination[^18][^17]

The ecosystem is maturing rapidly with specialized tools for AI agent workflows, suggesting worktrees will become standard practice for parallel development as LLM-assisted coding adoption accelerates. Teams adopting worktrees report 2-10× productivity gains when combined with AI agents, primarily by eliminating context-switching overhead and enabling true concurrent development.[^50][^19][^18]

For teams beginning their worktree journey, the recommended path is:

1. Start with wtp or workmux (15-minute setup)
2. Automate environment copying via hooks
3. Experiment with parallel agent workflows
4. Scale to team-wide adoption with documented standards

The future of software development increasingly involves orchestrating multiple AI agents across isolated contexts—and git worktrees provide the isolation primitive that makes this workflow viable.

***

## References

This report synthesizes information from 119 sources including official Git documentation, automation tool repositories, real-world implementations, video tutorials, and community discussions. All citations reference the `[web:N]` identifiers from the research sources collected during this investigation.[^72][^76][^3][^70][^25][^26][^2][^1][^11][^19][^12][^15][^17][^10]
<span style="display:none">[^100][^101][^102][^103][^104][^105][^106][^107][^108][^109][^110][^111][^112][^77][^78][^79][^80][^81][^82][^83][^84][^85][^86][^87][^88][^89][^90][^91][^92][^93][^94][^95][^96][^97][^98][^99]</span>

<div align="center">⁂</div>

[^1]: https://git-scm.com/docs/git-worktree

[^2]: https://www.reddit.com/r/ClaudeCode/comments/1pzczjn/git_worktrees_are_a_superpower_for_agentic_dev/

[^3]: https://www.reddit.com/r/OpenaiCodex/comments/1nsujcz/git_worktrees_coding_agents_are_a_game_changer/

[^4]: https://www.datacamp.com/de/tutorial/git-worktree-tutorial

[^5]: https://www.intertech.com/using-git-worktrees-instead-of-multiple-clones/

[^6]: https://livefront.com/writing/exploring-the-benefits-of-git-worktree/

[^7]: https://nicknisi.com/posts/git-worktrees/

[^8]: https://morgan.cugerone.com/blog/workarounds-to-git-worktree-using-bare-repository-and-cannot-fetch-remote-branches/

[^9]: https://stackoverflow.com/questions/54367011/git-bare-repositories-worktrees-and-tracking-branches

[^10]: https://dev.to/satococoa/wtp-a-better-git-worktree-cli-tool-4i8l

[^11]: https://github.com/captainsafia/grove

[^12]: https://www.reddit.com/r/git/comments/1q348co/grove_git_worktrees_without_the_hassle/

[^13]: https://www.reddit.com/r/git/comments/1ktz8zj/treekanga_cli_tool_to_manage_git_worktrees/

[^14]: https://terminaltrove.com/branchlet/

[^15]: https://worktrunk.dev

[^16]: https://github.com/raine/workmux

[^17]: https://docs.rs/crate/workmux/0.1.1

[^18]: https://raine.dev/blog/introduction-to-workmux/

[^19]: https://raine.dev/blog/git-worktrees-parallel-agents/

[^20]: https://www.reddit.com/r/tmux/comments/1p7bszd/workmux_git_worktrees_tmux_windows_for/

[^21]: https://www.nrmitchi.com/2025/10/using-git-worktrees-for-multi-feature-development-with-ai-agents/

[^22]: https://github.com/AndyMik90/Auto-Claude/issues/694

[^23]: https://stevekinney.com/courses/ai-development/git-worktrees

[^24]: https://www.anthropic.com/engineering/claude-code-best-practices

[^25]: https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees

[^26]: https://www.youtube.com/watch?v=an-Abb7b2XM

[^27]: https://motlin.com/blog/claude-code-worktree

[^28]: https://www.builder.io/blog/opencode-vs-claude-code

[^29]: https://www.nxcode.io/resources/news/opencode-vs-claude-code-vs-cursor-2026

[^30]: https://opencode.ai/docs/skills/

[^31]: https://opencode.ai/docs/github/

[^32]: https://huggingface.co/docs/inference-providers/en/guides/github-actions-code-review

[^33]: https://www.linkedin.com/posts/matthieunapoli_tested-opencode-vs-claude-code-claude-wrote-activity-7416464088853106688-feMZ

[^34]: https://dev.to/arifszn/git-worktrees-the-power-behind-cursors-parallel-agents-19j1

[^35]: https://code.visualstudio.com/docs/copilot/agents/background-agents

[^36]: https://blog.itdepends.be/parallel-workflows-git-worktrees-agents/

[^37]: https://nx.dev/blog/git-worktrees-ai-agents

[^38]: https://devblogs.microsoft.com/aspire/scaling-ai-agents-with-aspire-isolation/

[^39]: https://stackoverflow.com/questions/70953062/how-to-run-a-git-hook-only-when-running-git-worktree-add-command

[^40]: https://git-scm.com/docs/githooks/2.10.5

[^41]: https://stackoverflow.com/questions/79186993/using-git-hooks-with-worktree

[^42]: https://steveasleep.com/autowt/cookbook/untracked/

[^43]: https://docs.windsurf.com/windsurf/cascade/worktrees

[^44]: https://stackoverflow.com/questions/74772506/include-node-modules-when-using-git-worktree

[^45]: https://lib.rs/crates/workbloom

[^46]: https://chrisdicarlo.ca/blog/working-with-git-worktrees-part-2/

[^47]: https://mskelton.dev/bytes/using-git-hooks-when-creating-worktrees

[^48]: https://libraries.io/go/github.com%2FLeahArmstrong%2Fgrove-cli

[^49]: https://stackoverflow.com/questions/31935776/what-would-i-use-git-worktree-for

[^50]: https://dev.to/kevinz103/git-worktree-claude-code-my-secret-to-10x-developer-productivity-520b

[^51]: https://pabloariasal.github.io/2023/12/27/git-worktrees/

[^52]: https://www.youtube.com/watch?v=oI631eCAQnQ

[^53]: https://skillsmp.com/skills/shakes-tzd-contextune-skills-git-worktree-master-skill-md

[^54]: https://www.linkedin.com/pulse/git-worktree-zero-heromastering-multiple-workspaces-ankit-kundariya-7tzof

[^55]: https://gist.github.com/ashwch/946ad983977c9107db7ee9abafeb95bd

[^56]: https://www.reddit.com/r/Verdent/comments/1pkxjnz/git_worktree_integration_tips_been_using_it_wrong/

[^57]: https://stackoverflow.com/questions/69125521/does-one-git-worktree-support-multiple-branches

[^58]: https://blog.invidelabs.com/git-worktree-to-make-daily-git-workflow-better/

[^59]: https://news.ycombinator.com/item?id=39596742

[^60]: https://devot.team/blog/git-worktrees

[^61]: https://code.visualstudio.com/docs/sourcecontrol/branches-worktrees

[^62]: https://www.reddit.com/r/git/comments/ri0po2/longrunning_branches_and_git_worktree/

[^63]: https://stackoverflow.com/questions/33296185/not-able-to-checkout-branch-even-after-removing-worktree-and-running-worktree-pr

[^64]: https://stackoverflow.com/questions/68000870/automatic-tracking-for-new-worktree-branch

[^65]: https://stackoverflow.com/questions/48307968/git-worktrees-vs-clone-reference

[^66]: https://opencode.ai/docs/plugins/

[^67]: https://mcpmarket.com/tools/skills/git-worktree-automation

[^68]: https://www.youtube.com/watch?v=up91rbPEdVc

[^69]: https://www.youtube.com/watch?v=8vsRb2mTBA8

[^70]: https://www.youtube.com/watch?v=8ezj3Rh72Xw

[^71]: https://www.youtube.com/watch?v=grAsFn5yvjA

[^72]: https://www.youtube.com/watch?v=s4BTvj1ZVLM

[^73]: https://www.youtube.com/watch?v=bWKHPelgNgs

[^74]: https://www.youtube.com/watch?v=OpM-G3WNH4g

[^75]: https://www.nijho.lt/post/parallel-agentic-coding/

[^76]: https://www.reddit.com/r/git/comments/1pbmpyz/hot_take_worktrees_are_underrated_and_most_teams/

[^77]: https://www.joshmedeski.com/posts/how-to-use-git-worktrees/

[^78]: https://dev.to/yankee/practical-guide-to-git-worktree-58o0

[^79]: https://matklad.github.io/2024/07/25/git-worktrees.html

[^80]: https://dev.to/sotarok/i-created-a-gw-command-to-make-git-worktree-more-user-friendly-4jeb

[^81]: https://code.claude.com/docs/en/common-workflows

[^82]: https://www.npmjs.com/package/@akiojin/claude-worktree

[^83]: https://revs.runtime-revolution.com/multitasking-with-cursor-using-git-worktree-for-parallel-branch-development-7505499a1bfc

[^84]: https://sterba.dev/posts/git-worktree/

[^85]: https://docs.roocode.com/features/worktrees

[^86]: https://www.digitalocean.com/community/tutorials/how-to-use-git-hooks-to-automate-development-and-deployment-tasks

[^87]: https://github.com/dagster-io/erk/issues/4954

[^88]: https://crates.io/crates/worktree

[^89]: https://www.youtube.com/watch?v=-Zr2gI8R-Sk

[^90]: https://docs.ai.it.ufl.edu/docs/navigator_toolkit/integrations/opencode/

[^91]: https://www.reddit.com/r/LocalLLaMA/comments/1qd8vpj/claude_code_or_opencode_which_one_do_you_use_and/

[^92]: https://github.com/javierr33/opencode-workflow

[^93]: https://www.youtube.com/watch?v=NOmZ3iQ774U

[^94]: https://www.gitkraken.com/learn/git/git-worktree

[^95]: https://dev.to/nickytonline/git-worktrees-git-done-right-2p7f

[^96]: https://www.reddit.com/r/ProgrammerTIL/comments/mtjg0c/git_til_about_git_worktrees/

[^97]: https://git-scm.com/docs/gitrepository-layout/2.22.0

[^98]: https://www.reddit.com/r/learnprogramming/comments/12cf8a1/git_how_to_start_with_worktrees_from_bare_repo/

[^99]: https://www.dzombak.com/blog/2025/10/a-tool-for-working-with-git-worktrees/

[^100]: https://www.graphapp.ai/blog/git-worktree-tutorial-a-step-by-step-guide-for-beginners

[^101]: https://www.datacamp.com/tutorial/git-worktree-tutorial

[^102]: https://www.linkedin.com/posts/bassemshaker_i-wrote-a-little-utility-for-managing-my-activity-7391119254105923584-FJpi

[^103]: https://github.com/motdotla/dotenv/issues/817

[^104]: https://blog.dennisokeeffe.com/blog/2024-08-14-exploring-git-worktree

[^105]: https://www.npmjs.com/package/@adamhancock%2Fworktree

[^106]: https://daksh.be/blog/2025/08/15/how-i-work-using-git-worktree/

[^107]: https://bssw.io/items/working-within-multiple-git-branches-simultaneously

[^108]: https://www.meziantou.net/git-worktree-managing-multiple-working-directories.htm

[^109]: https://dev.to/konstantin/handling-multiple-branches-in-ai-projects-with-git-worktree-40pn

[^110]: https://www.graphapp.ai/blog/how-to-use-git-worktree-a-step-by-step-example

[^111]: https://stackoverflow.com/questions/66787237/git-to-correct-branch-and-worktree-mismatch

[^112]: https://blog.exupero.org/tmux-worktree-scripts/

