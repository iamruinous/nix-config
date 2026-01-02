# Upgrade & Migration Protocols

This document defines how to manage the evolution of the Multi-Agent System (MAS) context structure itself. As we add new protocols, refine schemas, or restructure the `.context/` directory, we must ensure these changes are versioned, documented, and replicable.

## 1. Versioning Strategy

We use **Date-Based Versioning (YYYY.MM.DD)** for the context schema. This allows for frequent, granular updates without the strict semantics of software releases.

*   **Current Version:** Defined in `.context/index.md` (or tracked in `migrations.md`).
*   **Scope:** A "version" represents the state of the `.context/` directory structure and the contents of `global/` files.

## 2. Migration Log (`.context/migrations.md`)

All structural changes to the MAS context must be logged in `.context/migrations.md`. This file serves as the "Instruction Manual" for upgrading other repositories that use this system.

### Log Entry Format
Each entry in the migration log must follow this template:

```markdown
## [YYYY.MM.DD] - <Short Title of Change>
**Type:** [Feature | Refactor | Fix | Deprecation]

### Summary
Brief description of what changed and why.

### Manual Upgrade Steps
1.  **File Created/Modified:** `path/to/file.md`
    *   *Instruction:* "Add the following section..." or "Copy content from..."
2.  **Directive Added:** "Update AGENTS.md to include..."
3.  **Verification:** "Run `make context-check` to verify..."

### Automated Script (Optional)
If a script can perform this upgrade, reference it here.
```

## 3. The Upgrade Process

When improving the system (e.g., adding a new global protocol):

1.  **Implement:** Make the changes in the `.context/` directory (usually in `global/`).
2.  **Document:** Create a new entry in `.context/migrations.md` documenting exactly how to replicate this change.
3.  **Version:** Update the "Current Version" badge/text in `.context/index.md`.
4.  **Verify:** Ensure `scripts/context-check.sh` (if applicable) is updated to validate the new structure.

## 4. Replicating Upgrades (for other repos)

Agents working in other repositories should check the upstream source (this repo) for new migration entries.

1.  **Check Upstream:** Read `.context/migrations.md` in the source repo.
2.  **Compare:** Check the local `.context/migrations.md` (or lack thereof) to see which updates are missing.
3.  **Apply:** Execute the "Manual Upgrade Steps" sequentially for each missing version.
4.  **Log:** Append the applied entries to the local `.context/migrations.md`.
