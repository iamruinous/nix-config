The latest development in this space (late 2024/2025) is the move away from running "parallel agents" (multiple terminals open, copy-pasting context) toward a **Hub-and-Spoke** architecture powered by the **Model Context Protocol (MCP)**.

The industry is coalescing around a standard where one agent acts as the "Driver" (orchestrator) and the others act as "Tools" or "Consultants" that share the driver's context window.

Here is a straightforward solution to unify your `gemini-cli`, `claude-code`, and `opencode` workflow without duplicating context files.

### 1. The Architecture: Hub-and-Spoke

Instead of maintaining three separate context windows, choose one **primary driver** (usually `claude-code` due to its superior reasoning/orchestration or `opencode` for its open-source flexibility) and treat the others as *tools* that the driver can invoke.

**Why this fixes your problem:**

* **Zero Duplication:** You only maintain context in the Driver. When the Driver calls Gemini, it passes the relevant context automatically.
* **Best-of-Breed:** You use Claude for reasoning, but "dispatch" heavy-context tasks to Gemini (1M+ context window) or local tasks to Opencode.

### 2. The Solution: MCP (Model Context Protocol)

The **Model Context Protocol (MCP)** is the new open standard (supported by Anthropic, Google, and others) that allows agents to "see" each other as tools.

**How to set it up (The "Straightforward" Way):**

If you use **Claude Desktop/Code** as your driver:

1. **Install the Gemini MCP Server:** This effectively turns `gemini-cli` into a tool callable by Claude.
* *What it does:* Adds a tool `consult_gemini` or `delegate_to_gemini` to Claude.
* *Usage:* You are in Claude. You type: "This file is huge. Ask Gemini to analyze the dependency structure and summarize it for us." Claude sends the file content to Gemini, Gemini processes it (using its massive context), and returns the summary to Claude's context.


2. **Configure `claude_desktop_config.json`:**
```json
{
  "mcpServers": {
    "gemini-helper": {
      "command": "npx",
      "args": ["-y", "@google-cloud/mcp-server-gemini"] 
    }
  }
}

```


*(Note: You will need to check the specific package name for the latest community wrapper, as official wrappers are releasing rapidly. `gemini-cli-mcp` is a common community variant.)*

### 3. The "Hacker" Solution: CLI Sub-Agents (Works Today)

If you don't want to configure MCP servers, you can use the "Sub-Agent" pattern by editing your `CLAUDE.md` or `gemini.md` system instructions. This creates a "soft" integration.

**Add this to your `CLAUDE.md` (Project Rules):**

```markdown
# Tool: Gemini Dispatch
When I ask you to "ask gemini" or "consult gemini", generate a shell command to run gemini-cli with the current task.
Format: `gemini -p "Context: <summary of current problem>. Task: <specific question>."`

```

**Workflow:**

1. You are in `claude-code`.
2. **You:** "I'm stuck on this error. Ask Gemini to review the `server.logs` file since it's too large for your context."
3. **Claude:** Runs `gemini -p "Review server.logs..."` in your terminal.
4. **Result:** Gemini's answer appears in your Claude stream.

### 4. Unified Context Management (The "One File" Strategy)

Stop duplicating context files. Create a single "Source of Truth" folder that all three agents are instructed to read.

* **Create a `.context/` directory** in your project root.
* **Create `master_spec.md`:** The high-level architecture and current goals.
* **Create `.ign` (Ignore) files:**
* `gemini` supports `.geminiignore`
* `claude` supports `.claudeignore`
* **The Hack:** Symlink them. `ln -s .gitignore .geminiignore` and `ln -s .gitignore .claudeignore`.



**The "Context Beacon" Pattern:**
In the root of your project, place a file named `AGENTS.md`. All your agents should be primed (via their system prompt or config) to read this file *first*.

```markdown
# AGENTS.md
## Current Project State
- Phase: Refactoring API
- Active Task: Migrating to GraphQL

## Context Pointers
- Architecture: .context/architecture.md
- Database Schema: .context/schema.sql

```

When you start a session in *any* CLI, your first command is simply: "Read AGENTS.md".

### 5. Summary of Agent Strengths (for delegation)

* **Claude-Code:** **The Manager.** Use for reasoning, planning, and writing the final code. Best at following complex instructions.
* **Gemini-CLI:** **The Librarian.** Use for "Needle in a haystack" searches. "Find where variable X is defined across these 500 files." (Use the `-p` flag to pipe output back to Claude).
* **Opencode:** **The Intern.** Use for rapid, low-stakes iteration or when you want to use a local model to save costs on simple tasks.

### Next Step

Would you like me to generate a `CLAUDE.md` "Project Instruction" file that automatically pre-configures Claude to use Gemini as a sub-agent for large-file analysis?

[OpenCode: The BEST AI Coding Agent Ever! BYE Gemini CLI & ClaudeCode! (Opensource)](https://www.youtube.com/watch?v=ipY_e9sldFM)
I selected this video because it specifically reviews **OpenCode**, one of your primary tools, and contrasts it directly against Gemini CLI and Claude Code, helping you decide if you can consolidate your workflow into this single open-source agent.





Here is a `CLAUDE.md` specifically designed to turn `claude-code` into an orchestrator that leverages `gemini-cli` for heavy lifting.

Place this file in the **root** of your project directory.

### `CLAUDE.md`

```markdown
# Project Role: Lead Architect & Orchestrator

## Core Directive
You are the lead developer and orchestrator for this project. You are responsible for logic, architecture, and code quality. You have access to a specialized "Sub-Agent" tool: **Gemini CLI**.

## Tool: Gemini CLI (The Researcher)
Gemini has a significantly larger context window (2M tokens) than you. You must delegate tasks to Gemini when they involve:
1. Summarizing or searching across the entire codebase.
2. analyzing single files larger than 500 lines.
3. "Needle in a haystack" queries (finding where a variable is used across 100+ files).

### How to Invoke Gemini
Do not ask me permission to run Gemini. If a task fits the criteria above, immediately generate and run a shell command using the following syntax:

`gemini -p "Your detailed prompt here. Context: [Specific Files or 'ALL']"`

*Note: If the output is likely to be long, pipe it to a temporary file and read the file: `gemini -p '...' > .gemini_response.txt && cat .gemini_response.txt`*

## Context Management Protocols
1. **Single Source of Truth:** Always check `.context/master_spec.md` (if it exists) before starting new features to ensure alignment.
2. **Context Preservation:** Do not output full files when only a few lines changed. Use `sed` or unified diff format to apply changes to keep your own context window clear.

## User Triggers
* **"Deep Dive":** If I say "Deep Dive on X", this is an explicit command to run `gemini` with a prompt asking for a comprehensive analysis of X, then ingest the output.
* **"Summarize State":** Run `gemini` against the entire `src/` directory to generate a bulleted status report of the current code.

```

### How to use this workflow

1. **Start Claude:** Run `claude` in your terminal.
2. **The Trigger:** When you hit a complex issue, simply type:
> "Deep dive on the authentication flow in the `utils` folder. I think there's a race condition."


3. **The Result:**
* Claude reads your `CLAUDE.md`.
* It recognizes the "Deep Dive" trigger.
* It executes: `gemini -p "Analyze the authentication flow in utils/ for race conditions..."`
* It reads Gemini's answer and presents you with the solution.



### Next Step

To complete this "Unified Context" setup, would you like the template for the **`AGENTS.md`** file (the shared "brain" file I mentioned earlier that keeps Gemini, Claude, and OpenCode aligned on the project goals)?
