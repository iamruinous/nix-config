# Model Context Protocol (MCP) Standards

## Overview
The Model Context Protocol (MCP) allows AI agents to interact with external tools and data sources. This document defines the standards for managing and documenting MCP servers within the project.

## Registry Location
The **Single Source of Truth** for active MCP servers is:
`.context/project/mcp-registry.md`

## Maintenance Protocol
When adding, removing, or modifying an MCP server:
1.  **Update the Registry:** Modify `.context/project/mcp-registry.md` to reflect the change.
2.  **Update Agent Configs:** Update `.mcp.json` (Claude/OpenCode) and `.gemini/settings.json` (Gemini) if necessary, or instruct the user to do so.
3.  **Verify:** Ensure the server is accessible to the relevant agents.

## Registry Template
The registry file MUST follow this structure:

```markdown
# MCP Server Registry

## Active Servers

### <Number>. <Server Name> (`<internal-id>`)
**Purpose:** <Description of capabilities>
**Source:** `<command to run>` (e.g., `uvx package`) or `<url>`
**Type:** `stdio` | `sse`
**Instances:** (Optional list of named instances if multiple configs exist)
**Configuration:** <Environment variables or arguments required>

---

## Agent Configuration Instructions

### Prerequisites
(Any global prerequisites like `uv`)

### 1. Claude Code
**Configuration File:** `./.mcp.json`
(Specific setup instructions)

### 2. Gemini CLI
**Configuration File:** `./.gemini/settings.json`
(Specific setup instructions)

### 3. OpenCode (VS Code / Cursor)
**Configuration File:** `./.mcp.json`
(Specific setup instructions)

## Environment Variables
(List of required environment variables)
```

## Standard Configuration Files

| Agent | Config File | Format |
|-------|-------------|--------|
| **Claude Code** | `.mcp.json` | JSON (Standard MCP) |
| **Gemini CLI** | `.gemini/settings.json` | JSON (Custom `mcpServers` key) |
| **OpenCode** | `.mcp.json` | JSON (Standard MCP) |

## Global MCP Assumptions

The following servers are assumed to be available globally in the agent's environment:

*   **Todoist:** Available for task management.

## Tool Workflows

### Todoist Workflow
When interacting with tasks via the Todoist MCP server:

1.  **Project Context:** Always check the **Project Specific Settings** (e.g., `GEMINI.md` or project README) for the correct `todoist_project_id`. Do not rely on default/inbox unless explicitly instructed.
2.  **Listing Tasks:**
    *   **Filter:** Filter by the identified Project ID.
    *   **Order:** ALWAYS order results by `priority` (descending) then `due_date` (ascending) to focus on urgent/important items first.
3.  **Completion:**
    *   When a user task is satisfied, explicitly mark the corresponding Todoist task as completed.
    *   Do not delete tasks; use completion to maintain history.

## Best Practices
1.  **Use `uvx`:** Prefer `uvx` for executing Python-based MCP servers to ensure ephemeral, isolated environments.
2.  **Environment Variables:** Document all required env vars. Do not hardcode secrets in the registry; reference them (e.g., `"${VAR_NAME}"`).
3.  **SSE vs STDIO:** Use `stdio` for local tools and `sse` for remote gateways (like `mcp-farm`).
