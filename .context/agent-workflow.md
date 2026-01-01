# AI Agent Workflow & Delegation

This document defines the operational protocols for the multi-agent system used in this repository.

## Agent Role Definition

We operate on a **Hub-and-Spoke** model.

*   **Orchestrator (The Hub):** The primary agent (Claude Code, Gemini CLI, etc.) currently interacting with the user.
    *   **Responsibility:** High-level planning, context management, user communication, and delegating sub-tasks to specialists.
*   **Specialists (The Spokes):** Virtual personas or specialized toolsets defined in `.context/agents/`.
    *   **Responsibility:** Executing specific, domain-bounded tasks (e.g., "encrypt this file", "create a DNS record").

### Available Specialists
*   **`agenix`**: Secrets management expert.
*   **`cfnix`**: Cloudflare & Networking expert.
*   **`containnix`**: Container orchestration expert.
*   **`nix-packager`**: Nix packaging expert.
*   **`codebase_investigator`** (Tool): Deep architectural analysis.

## Task Delegation Matrix

| Task Category | Primary Agent | Secondary/Support |
| :--- | :--- | :--- |
| **Secrets Management** | | |
| Encrypt/Edit `.age` files | `agenix` | |
| Rekey secrets | `agenix` | |
| Create Docker env files | `agenix` | `containnix` (for context) |
| **Infrastructure** | | |
| Deploy new container | `containnix` | `agenix` (secrets), `cfnix` (DNS) |
| Update Caddy config | `containnix` | `agenix` (if encrypted), `cfnix` (DNS) |
| Create DB | `containnix` (via recipes) | |
| **Networking** | | |
| Manage DNS records | `cfnix` | |
| Create Cloudflare Tunnels | `cfnix` | `agenix` (creds), `containnix` (service) |
| **Development** | | |
| Create new package | `nix-packager` | |
| Fix build errors | `nix-packager` | `codebase_investigator` |
| **Architecture** | | |
| Refactor modules | Orchestrator | `codebase_investigator` |
| Analyze dependencies | `codebase_investigator` | |

## Usage Protocols

### 1. Planning Phase (Mandatory)
Before executing complex changes, the Orchestrator **MUST** create a plan.
*   **Analyze:** Use `codebase_investigator` or `search` tools to understand current state.
*   **Draft:** Outline steps, identifying which Specialist is needed for each step.
*   **Confirm:** Present the plan to the user.

### 2. Delegation Protocol
When executing a step requires a Specialist:
1.  **Context Loading:** Read the relevant instructions in `.context/agents/<agent>.md`.
2.  **Persona Adoption:** Explicitly adopt the constraints and methods of that agent.
    *   *Example:* "Acting as `agenix`, I will now encrypt the file using `dangerouslyDisableSandbox: true`..."
3.  **Execution:** Perform the task using the specialist's specific tools and workflows.
4.  **Handoff:** Return to Orchestrator mode to verify and proceed to the next step.

### 3. Knowledge Management
*   **Read:** Always check `.context/` first.
*   **Write:** Only update `.context/` files for shared knowledge. Do not update tool-specific config (like `.claude/`) unless necessary for technical reasons.

## Escalation Paths

### When a Specialist Fails
1.  **Retry with Context:** Provide more specific error logs or file contents to the model.
2.  **Fallback to Generic:** If the specialist instruction fails, fall back to standard NixOS debugging (read logs, check docs).
3.  **User Intervention:** Explicitly ask the user to perform the blocked action (e.g., "I cannot access the YubiKey for decryption. Please run `agenix-helper unlock`").

### Ambiguous Requests
*   **Clarify:** If a request spans multiple domains (e.g., "Deploy a secure app"), ask clarifying questions to build the plan *before* invoking specialists.
*   **Investigate:** Use `codebase_investigator` to map out the dependencies before making changes.
