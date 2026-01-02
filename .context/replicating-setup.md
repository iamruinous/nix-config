# Multi-Agent Orchestration Implementation Guide

## Objective
To establish a robust, deterministic, and self-documenting environment where AI agents (Claude, Gemini, etc.) operate as a cohesive team using a **Hub-and-Spoke** model. This setup relies on a **Single Source of Truth (SSoT)** located in a `.context/` directory, referenced by root-level "beacons".

## 1. Directory Structure Setup

First, establish the physical structure. This separation is critical: it isolates reusable **Global Standards** from **Project Specifics**.

**Action:** Create the following directory tree in the target repository root:

```text
.context/
├── index.md                # THE BEACON: The entry point for all context.
├── global/                 # STANDARDS: Reusable across projects.
│   ├── git.md              # Git workflows (Branches, PRs, Commits).
│   ├── protocols.md        # Agent behavior (Hub-and-Spoke, Planning).
│   ├── standards.md        # Code style, security, testing.
│   └── mcp.md              # Tool/Server standards.
└── project/                # SPECIFICS: Unique to this repo.
    ├── architecture.md     # Tech stack, directory layout.
    ├── roster.md           # Active agents and delegation matrix.
    ├── mcp-registry.md     # Active tools/servers.
    ├── agents/             # Persona definitions (The "Spokes").
    │   └── [agent-name].md # Specific instructions for a specialist.
    └── recipes/            # Standard Operating Procedures.
        └── [recipe-name].md
```

---

## 2. Core Implementation (Global Layer)

These files define *how* agents behave. They are generally project-agnostic.

**Source of Truth:** You can copy these standard files directly from the public reference repository:
👉 **[github.com/iamruinous/nix-config](https://github.com/iamruinous/nix-config)** (Check the `.context/global/` directory).

### A. `global/protocols.md` (The Operating System)
**Purpose:** Defines the Hub-and-Spoke model.
**Key Content to Include:**
*   **Roles:** Define the **Orchestrator** (the agent talking to the user) and **Specialists** (virtual personas defined in `project/agents/`).
*   **Planning Protocol:** Mandate that the Orchestrator must "Understand -> Plan -> Confirm" before acting.
*   **Delegation Protocol:** Explain how to "switch hats" by reading a specialist file, adopting its persona/constraints, executing, and then returning to Orchestrator mode.

### B. `global/git.md` (The Version Control Law)
**Purpose:** Enforces safe Git practices.
**Key Content to Include:**
*   **Branching:** Mandate feature branches (`feat/`, `fix/`). Ban direct commits to `main`.
*   **Commits:** Enforce Conventional Commits (`type(scope): description`). Require detailed bodies explaining *why*.
*   **PRs:** Mandate Draft PRs for visibility.

### C. `global/standards.md` (The Quality Gate)
**Purpose:** Defines code quality and security.
**Key Content to Include:**
*   **Security:** "NEVER commit secrets."
*   **Testing:** "Run X before committing."
*   **Filesystem:** "Use `./tmp/` for temporary files, not system `/tmp`."

---

## 3. Context Implementation (Project Layer)

These files define *what* the project is. You must analyze the target project to fill these out.

### A. `project/architecture.md` (The Map)
**Purpose:** High-level overview.
**How to Fill:**
1.  **Overview:** What does this repo do?
2.  **Directory Structure:** Map key folders to their purpose.
3.  **Tech Stack:** List languages, frameworks, and key libraries.
4.  **Build/Deploy:** What commands run tests? How is it deployed?
5.  **Conventions:** Any specific naming rules or patterns?

### B. `project/roster.md` (The Team)
**Purpose:** Defines who does what.
**How to Fill:**
1.  Identify complex domains in the project (e.g., "Database", "Frontend", "DevOps").
2.  Create a "Specialist" for each domain.
3.  Create a **Delegation Matrix** table: `Task Category | Primary Agent | Support`.

### C. `project/agents/[name].md` (The Personas)
**Purpose:** Detailed instructions for each specialist.
**How to Fill:**
*   **Name & Description:** Identity.
*   **Core Responsibilities:** What do they own?
*   **Constraints:** What are they FORBIDDEN from doing? (e.g., "DB Agent cannot drop tables without flag").
*   **Tools/Commands:** Specific CLI commands they use.
*   **Common Patterns:** "How to add a new API endpoint" (step-by-step).

### D. `project/mcp-registry.md` (The Tools)
**Purpose:** Registry of available MCP servers.
**How to Fill:**
*   List all active MCP servers (e.g., `postgres`, `filesystem`, `github`).
*   Provide configuration snippets for `.mcp.json` or agent-specific settings.

---

## 4. The Beacons (Root Level)

Agents start at the root. You need file-system "hooks" to catch their attention immediately.

### A. `.context/index.md` (The Source of Truth)
**Purpose:** The central index linking everything together.
**Content:**
*   Links to all Global and Project files.
*   "Quick Start" for agents entering the repo.

### B. Root Files (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`)
**Purpose:** Platform-specific entry points.
**Content:**
*   **⚠️ STOP:** First line must tell the agent to read `.context/index.md`.
*   **Summary:** Brief overview of the project.
*   **Pointers:** Links to `architecture.md` and `protocols.md`.
*   *Note:* Create `CLAUDE.md` for Anthropic, `GEMINI.md` for Google, etc., containing instructions specific to their tool quirks (e.g., specific sandbox flags).

---

## 5. Migration Strategy (Transitioning Existing Projects)

If the project already has `CLAUDE.md`, `GEMINI.md`, or `AGENTS.md` with mixed instructions, follow this transition plan to separate concerns.

### Phase 1: Audit & Split
Analyze the existing root files. Identify which instructions are **Global** (apply to any project) vs **Project** (specific to this repo).

| Instruction Type | Destination | Example |
| :--- | :--- | :--- |
| **Code Style** | `.context/global/standards.md` | "Use 2 spaces for indentation" |
| **Git Rules** | `.context/global/git.md` | "Always squash commits" |
| **Agent Roles** | `.context/global/protocols.md` | "Act as a Senior Engineer" |
| **Build Commands** | `.context/project/architecture.md` | `npm run build` |
| **Directory Map** | `.context/project/architecture.md` | "src/components contains UI" |
| **Special Tools** | `.context/project/agents/<name>.md` | "How to use the internal CLI" |

### Phase 2: Populate Context
1.  Move the **Global** content into the respective `global/` files (or simply replace with the standard set if the existing rules are generic).
2.  Move the **Project** content into `project/architecture.md` or specialized agent files.

### Phase 3: Replace Beacons
Once the content is safely migrated to `.context/`, **overwrite** the original root files with the standard beacon template.

**New Beacon Template (for `AGENTS.md`, `CLAUDE.md`, etc.):**
```markdown
# AI Agent Context Beacon

## ⚠️ Primary Context Source
**STOP:** Before proceeding, read **[.context/index.md](.context/index.md)**.
This directory is the **Single Source of Truth** for this project.

*   **Standards & Protocols:** `.context/global/`
*   **Project Specifics:** `.context/project/`

## Project Overview
[Insert 1-2 sentence summary of the project here]

## Directives
1.  **Read Context First:** Always start by reading `.context/index.md`.
2.  **Follow Protocols:** Adhere to the workflows defined in `.context/global/protocols.md`.
3.  **Upstream Improvements:** If you improve the Global Standards (`.context/global/`), you MUST contribute these back to the source of truth. Create a PR at [github.com/iamruinous/nix-config](https://github.com/iamruinous/nix-config).
```

---

## 6. Replicating: The Step-by-Step Workflow

When setting this up in a new repo, follow this algorithm:

1.  **Analyze the Codebase:**
    *   *Scan:* Run `ls -R` or `tree` to understand the structure.
    *   *Read:* Check `package.json`, `Cargo.toml`, `Makefile`, etc., to find build commands.
    *   *Identify Domains:* Does it have a complex DB? (Create `db-specialist`). Heavy React UI? (Create `frontend-specialist`).

2.  **Scaffold the `.context` Directory:**
    *   **Copy Global Layer:** Clone the `global/` folder from [iamruinous/nix-config](https://github.com/iamruinous/nix-config).
    *   **Create Project Layer:** Create empty files for `project/architecture.md`, `project/roster.md`.

3.  **Populate Project Specifics:**
    *   Write `project/architecture.md` based on your analysis in Step 1.
    *   Define 2-3 initial agents in `project/roster.md`.
    *   Write the agent files in `project/agents/`. Start simple.

4.  **Establish Beacons:**
    *   Create `.context/index.md` linking to your new files.
    *   Create `AGENTS.md` (and tool specifics) in the root, pointing to `index.md`.

5.  **Establish Git Hooks (Prek):**
    *   **Install Prek:** Ensure `prek` is installed (via `devshell` or `nix`).
    *   **Configure Hooks:** Create `.pre-commit-config.yaml` with standard hooks (see below).
    *   **Configure Commitlint:** Create `commitlint.config.js` with the AI footer rule (see below).
    *   **Install:** Run `prek install --hook-types pre-commit commit-msg`.

    *Standard `.pre-commit-config.yaml`:*
    ```yaml
    repos:
      - repo: local
        hooks:
          - id: gitleaks
            name: gitleaks
            entry: gitleaks protect --verbose --redact --staged
            language: system
            pass_filenames: false

      - repo: local
        hooks:
          - id: commitlint
            name: commitlint
            entry: commitlint --edit
            language: system
            stages: [commit-msg]

      - repo: https://github.com/pre-commit/pre-commit-hooks
        rev: v4.6.0
        hooks:
          - id: no-commit-to-branch
            args: ['--branch', 'main']
    ```

    *Standard `commitlint.config.js`:*
    ```javascript
    module.exports = {
      extends: ['@commitlint/config-conventional'],
      plugins: [
        {
          rules: {
            'ai-footer': ({raw}) => {
              const footer = '🤖 Generated with [ruinous.ai](https://agent.ruinous.ai) 🦾✨';
              return [
                raw.includes(footer),
                `AI agents must include the footer: ${footer}`,
              ];
            },
          },
        },
      ],
      rules: {
        'ai-footer': [1, 'always'],
      },
    };
    ```

6.  **Verify:**
    *   Ask the agent: "What is the plan for adding a feature?"
    *   *Success Criteria:* The agent should quote the `global/protocols.md`, check `project/roster.md`, and propose using a specific specialist.

## 7. Maintenance Protocol

Add this rule to `global/protocols.md`:
*   **Read:** Always check `.context/` first.
*   **Write:** Only update `.context/` files for *shared* knowledge.
*   **Index Maintenance:** "If you create a new file in `.context/`, you MUST update `.context/index.md`."

## 8. Upgrade & Migration Protocol

To keep your replicated system up-to-date with the latest protocols:
1.  **Reference:** Read `.context/global/upgrades.md` for the versioning strategy.
2.  **Track:** Maintain a local `.context/migrations.md` to log applied updates.
3.  **Sync:** Periodically check the upstream `migrations.md` and apply manual upgrade steps for new versions.
