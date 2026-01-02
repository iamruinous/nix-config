# AI Agent Protocols (Global)

This document defines the standard operational protocols for the multi-agent system.

## Agent Role Definition

We operate on a **Hub-and-Spoke** model.

*   **Orchestrator (The Hub):** The primary agent currently interacting with the user.
    *   **Responsibility:** High-level planning, context management, user communication, and delegating sub-tasks to specialists.
*   **Specialists (The Spokes):** Virtual personas or specialized toolsets defined in `.context/project/agents/`.
    *   **Responsibility:** Executing specific, domain-bounded tasks.

## Usage Protocols

### 0. Initialization Phase (Mandatory)
At the start of any new session or task:
1.  **Verification:** Execute `make context-check` to validate environment integrity.
2.  **Absorption:** Read the summary output to orient yourself.
3.  **Failure:** If the check fails, STOP and report the missing files to the user.

### 1. Planning Phase (Mandatory)
Before executing complex changes, the Orchestrator **MUST** create a plan.
*   **Analyze:** Use tools to understand current state.
*   **Draft:** Outline steps, identifying which Specialist is needed for each step.
*   **Confirm:** Present the plan to the user.

### 2. Delegation Protocol
When executing a step requires a Specialist:
1.  **Context Loading:** Read the relevant instructions in `.context/project/agents/<agent>.md`.
2.  **Persona Adoption:** Explicitly adopt the constraints and methods of that agent.
3.  **Execution:** Perform the task using the specialist's specific tools and workflows.
4.  **Handoff:** Return to Orchestrator mode to verify and proceed to the next step.

### 3. Knowledge Management
*   **Read:** Always check `.context/` first.
*   **Write:** Only update `.context/` files for shared knowledge. Do not update tool-specific config (like `.claude/` or `.gemini/`) unless necessary for technical reasons.
*   **Index Maintenance:** When creating or moving files within `.context/`, you MUST update [.context/index.md](../index.md) to maintain the single source of truth.

### 4. Context Bootstrapping (Memory Beacon)
To ensure agents have immediate access to critical context without initial file reads:
1.  **Beacon Files:** Files like `GEMINI.md` or `CLAUDE.md` serve as the agent's "Working Memory" and "Context Anchor".
2.  **Structure:** These files MUST follow a split structure:
    *   **Top (Mutable):** Agent memories, scratchpad, and active task tracking.
    *   **Divider:** A clear delimiter line: `<!-- CONTEXT_BOOTSTRAP_START - DO NOT EDIT BELOW THIS LINE -->`.
    *   **Bottom (Immutable):** A summarized injection of the Global Standards and Project Specifics.
3.  **Constraint:** Agents **MUST NOT** edit anything below the divider line. This section is managed by repo maintainers/scripts to keep context fresh.
4.  **Content:** The bootstrapped context should minimally include:
    *   Pointer to the SSOT (`.context/index.md`).
    *   Key Protocols (Planning, Delegation).
    *   Project Architecture Summary.

## Escalation Paths

### When a Specialist Fails
1.  **Retry with Context:** Provide more specific error logs or file contents.
2.  **Fallback to Generic:** If the specialist instruction fails, fall back to standard debugging.
3.  **User Intervention:** Explicitly ask the user to perform the blocked action.

### Ambiguous Requests
*   **Clarify:** If a request spans multiple domains, ask clarifying questions *before* invoking specialists.
*   **Investigate:** Map out dependencies before making changes.
