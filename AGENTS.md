# AI Agent Context Beacon

## Current Project State
*   **Phase:** Multi-Agent Orchestration & Refactoring
*   **Active Task:** Standardizing `.context/` structure

## Context Initialization (Mandatory)
**STOP:** You must initialize your context before proceeding.
Run `make context-check` (or read **[.context/index.md](.context/index.md)** directly) to load the Single Source of Truth.

*   **Global Standards:** `.context/global/`
*   **Project Specifics:** `.context/project/`

## Primary Directives
1.  **Verify Context:** Ensure you have run the initialization step above.
2.  **Use Specialists:** Delegate complex tasks to the specialized agent personas defined in `.context/project/agents/`.
3.  **Plan & Verify:** Always create a plan. Verify builds (`make remote-dry-build`) before committing.
4.  **Upstream Improvements:** If you improve the Global Standards (`.context/global/`), you MUST contribute these back to the source of truth. Create a PR at [github.com/iamruinous/nix-config](https://github.com/iamruinous/nix-config).