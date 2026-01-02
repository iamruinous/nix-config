# AI Agent Protocols (Global)

This document defines the standard operational protocols for the multi-agent system.

## Agent Role Definition

We operate on a **Hub-and-Spoke** model.

*   **Orchestrator (The Hub):** The primary agent currently interacting with the user.
    *   **Responsibility:** High-level planning, context management, user communication, and delegating sub-tasks to specialists.
*   **Specialists (The Spokes):** Virtual personas or specialized toolsets defined in `.context/project/agents/`.
    *   **Responsibility:** Executing specific, domain-bounded tasks.

## Usage Protocols

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

## Escalation Paths

### When a Specialist Fails
1.  **Retry with Context:** Provide more specific error logs or file contents.
2.  **Fallback to Generic:** If the specialist instruction fails, fall back to standard debugging.
3.  **User Intervention:** Explicitly ask the user to perform the blocked action.

### Ambiguous Requests
*   **Clarify:** If a request spans multiple domains, ask clarifying questions *before* invoking specialists.
*   **Investigate:** Map out dependencies before making changes.
