# Ruinage Refactor: Repository-First Project Configuration

## Context

### Original Request
Refactor kimaki, opencode, opencode-projects, and chassis home-configuration to use a "repo-first" approach where the repository URL is the key in an attrset. Projects should be checked out to kimaki and ruinage directories, added to budgey, given opencode-web ports, generate tmuxp profiles, etc. Include multi-agent support (opencode, claude-code, gemini-cli, codex, kimaki) and global options for MCP servers, LSP servers, and model settings.

### Interview Summary
**Key Discussions**:
- Directory convention: `~/Projects/kimaki/<repo>` and `~/Projects/ruinage/<repo>` (flat, namespace-based)
- Auto-clone: Yes, on home-manager activation
- Migration: Leave old paths, user cleans up manually
- Default opencode: Implicit (always available globally)
- Dual namespace: Clone to BOTH if both enabled (separate working directories)
- Caddy: Hybrid (module exposes data, caddy.nix consumes)
- Module naming: `ruinous.ruinage.*`
- Assistants under: `ruinous.ruinage.assistants.<name>.*`
- Harnesses: Pluggable enhancements (oh-my-opencode, ruinagents) under `.harnesses.<name>.enable`
- Per-project model overrides: No (global only)
- Testing: Add Nix tests (tests/ruinage.test.nix)

**Research Findings**:
- Current opencode.nix: 1341 lines
- Current opencode-projects.nix: 795 lines
- Current kimaki.nix: 430 lines
- lib/opencode/wrapper.nix: 178 lines (reusable)
- chassis home-config: 21+ places requiring updates for new projects
- Caddy reads from `config.home-manager.users.jmeskill.ruinous.ai-cli.opencode-projects.projects`
- budgey-extractor depends on opencode-projects.enable

### Metis Review
**Identified Gaps** (addressed):
- Clone authentication: SSH keys must be available; clone failures warn but don't fail activation
- Existing clones at different paths: Detect and skip with warning
- Port uniqueness: Add assertion to prevent collisions
- Service name preservation: Keep `opencode-<project>.service` pattern
- XDG directory preservation: Keep `~/.config/opencode-<project>/` pattern
- Support `repo = null` for local-only projects
- lib/opencode/wrapper.nix: Rename to lib/ruinage/ and reuse

---

## Work Objectives

### Core Objective
Create a unified `ruinous.ruinage` module that defines projects once (by git repository) and generates all outputs: git clones, systemd services, tmuxp sessions, direnv snippets, budgey registry, Caddy route data, and kimaki registration.

### Concrete Deliverables
- `modules/home/default/ruinage/` module hierarchy (7+ files)
- `lib/ruinage/` shared library (renamed from opencode/)
- `tests/ruinage.test.nix` test suite
- Updated `hosts/chassis/users/jmeskill/home-configuration.nix`
- Updated `hosts/chassis/caddy.nix` to consume from ruinage
- Deprecation warnings in old modules

### Definition of Done
- [ ] `nix flake check` passes
- [ ] `just remote-dry-build chassis` passes
- [ ] All 10+ current chassis projects expressible in new schema
- [ ] tests/ruinage.test.nix passes
- [ ] Old modules emit deprecation warnings but still work
- [ ] New project addable with <10 lines of config

### Must Have
- Repository-first project definition with `{ repo, owner, forge }` schema
- Two namespaces: `kimaki` (~/Projects/kimaki/) and `ruinage` (~/Projects/ruinage/)
- Auto-clone on activation (warn on failure, don't block)
- Multi-assistant support: opencode, claude-code, gemini, codex, kimaki
- Assistants grouped under `ruinous.ruinage.assistants.*`
- Harness system for pluggable enhancements (oh-my-opencode, ruinagents)
- Global assistant settings inherited by all projects
- Service generation for opencode web UI
- tmuxp session generation
- direnv snippet generation
- budgey registry generation
- Caddy route data export
- Documentation aggregation with MkDocs index linking to per-project docs
- Port uniqueness assertion
- Nix test suite

### Must NOT Have (Guardrails)
- No per-project model overrides (global only)
- No auto-pull functionality (clone only)
- No auto-migration of existing clones
- No change to XDG directory structure
- No change to existing secrets paths
- No assistants beyond the 5 specified
- No direct Caddy config generation (hybrid pattern)
- No breaking changes to budgey-extractor without migration

---

## Verification Strategy (MANDATORY)

### Test Decision
- **Infrastructure exists**: YES (tests/opencode.test.nix exists)
- **User wants tests**: YES (TDD approach)
- **Framework**: Nix module tests (nixosTest)

### Test Approach

Each major feature includes:
1. Unit test in `tests/ruinage.test.nix`
2. Dry-build verification: `just remote-dry-build chassis`
3. Manual verification for runtime behavior (git clone, services)

---

## Task Flow

```
Phase 1 (Foundation)
    ├─ TODO 1: Create lib/ruinage/ ─────────────────────────┐
    └─ TODO 2: Create module skeleton ──────────────────────┤
                                                            ▼
Phase 2 (Core Schema)                                   
    └─ TODO 3: Project type definition ─────────────────────┤
                                                            ▼
Phase 3 (Clone Logic)
    └─ TODO 4: Auto-clone activation ───────────────────────┤
                                                            ▼
Phase 4 (OpenCode Integration)
    ├─ TODO 5: Global opencode settings ────────────────────┤
    └─ TODO 6: Per-project opencode services ───────────────┤
                                                            ▼
Phase 5 (Kimaki Integration)
    └─ TODO 7: Absorb kimaki into ruinage ──────────────────┤
                                                            ▼
Phase 6 (Supporting Features)
    ├─ TODO 8: tmuxp generation ────────────────────────────┤
    ├─ TODO 9: direnv generation ───────────────────────────┤
    └─ TODO 10: budgey registry ────────────────────────────┤
                                                            ▼
Phase 7 (Multi-Agent Stubs)
    └─ TODO 11: claude-code, gemini, codex stubs ───────────┤
                                                            ▼
Phase 8 (Caddy Integration)
    └─ TODO 12: Caddy data export + update caddy.nix ───────┤
                                                            ▼
Phase 9 (Test Suite)
    └─ TODO 13: Create tests/ruinage.test.nix ──────────────┤
                                                            ▼
Phase 10 (Migration)
    ├─ TODO 14: Update chassis home-configuration.nix ──────┤
    └─ TODO 15: Add deprecation warnings to old modules ────┤
                                                            ▼
Phase 11 (Documentation)
    └─ TODO 16: Update AGENTS.md skills catalog
```

## Parallelization

| Group | Tasks | Reason |
|-------|-------|--------|
| A | 1, 2 | Independent foundation files |
| B | 8, 9, 10 | Independent generators (after TODO 3) |
| C | 14, 15 | Independent migration tasks (after TODO 13) |

| Task | Depends On | Reason |
|------|------------|--------|
| 3 | 1, 2 | Needs lib and module skeleton |
| 4 | 3 | Needs project type definition |
| 5, 6 | 3 | Needs project type for opencode options |
| 7 | 6 | Kimaki needs opencode pattern established |
| 11 | 5 | Agent stubs follow opencode pattern |
| 12 | 6 | Caddy needs opencode.caddy.fqdn |
| 13 | 1-12 | Tests need all features |
| 14, 15 | 13 | Migration after tests pass |
| 16 | 14 | Docs after migration complete |

---

## TODOs

- [ ] 1. Create lib/ruinage/ shared library

  **What to do**:
  - Copy `lib/opencode/wrapper.nix` to `lib/ruinage/wrapper.nix`
  - Rename internal references from "opencode" to "ruinage" where appropriate
  - Keep function signatures compatible for gradual migration
  - Add new helper: `mkGitUrl { owner, repo, forge }` to construct SSH URLs
  - Add new helper: `parseGitUrl url` to extract owner/repo/forge from URL

  **Must NOT do**:
  - Don't change the actual XDG path logic (keep opencode-<project> pattern)
  - Don't modify function behavior, only naming

  **Parallelizable**: YES (with TODO 2)

  **References**:
  - `lib/opencode/wrapper.nix:1-178` - Current implementation to copy and adapt
  - `modules/home/default/ai-cli/opencode-projects.nix:48` - Import pattern to follow

  **Acceptance Criteria**:
  - [ ] File exists: `lib/ruinage/wrapper.nix`
  - [ ] `mkGitUrl { owner = "iamruinous"; repo = "test"; forge = "github.com"; }` returns `"ssh://git@github.com/iamruinous/test.git"`
  - [ ] `mkGitUrl { owner = "iamruinous"; repo = "test"; }` uses default forge
  - [ ] All existing functions preserved

  **Commit**: NO (groups with TODO 2)

---

- [ ] 2. Create ruinage module skeleton

  **What to do**:
  - Create `modules/home/default/ruinage/default.nix` - Main entry, imports sub-modules
  - Create `modules/home/default/ruinage/types.nix` - Shared type definitions (empty initially)
  - Create `modules/home/default/ruinage/projects.nix` - Project processing (stub)
  - Create `modules/home/default/ruinage/assistants/opencode.nix` - OpenCode integration (stub)
  - Create `modules/home/default/ruinage/assistants/kimaki.nix` - Kimaki integration (stub)
  - Add `ruinous.ruinage.enable` option
  - Import from `modules/home/default/default.nix`

  **Must NOT do**:
  - Don't implement any actual logic yet (stubs only)
  - Don't modify existing modules

  **Parallelizable**: YES (with TODO 1)

  **References**:
  - `modules/home/default/ai-cli/opencode.nix:768-1036` - Option definition pattern
  - `modules/home/default/default.nix` - Where to add import

  **Acceptance Criteria**:
  - [ ] Directory exists: `modules/home/default/ruinage/`
  - [ ] Files exist: `default.nix`, `types.nix`, `projects.nix`, `assistants/opencode.nix`, `assistants/kimaki.nix`
  - [ ] `nix flake check` passes
  - [ ] Option `ruinous.ruinage.enable` is available

  **Commit**: YES
  - Message: `feat(ruinage): create module skeleton for repository-first project management`
  - Files: `lib/ruinage/wrapper.nix`, `modules/home/default/ruinage/`, `modules/home/default/default.nix`
  - Pre-commit: `nix flake check`

---

- [x] 3. Define project type and schema

  **What to do**:
  - In `types.nix`, define `projectType` submodule with:
    - `repo` (string, required) - Repository name
    - `owner` (string, default "iamruinous") - Repository owner
    - `forge` (string, default "forge.meskill.farm") - Git forge hostname
    - `ref` (nullOr string, default null) - Branch/tag/commit
    - `namespaces.ruinage.enable` (bool) - Enable ruinage namespace (clone to ~/Projects/ruinage/)
    - `namespaces.kimaki.enable` (bool) - Enable kimaki namespace (clone to ~/Projects/kimaki/)
    - `assistants.opencode.*` (submodule) - OpenCode assistant settings for this project
    - `assistants.claude-code.enable`, `assistants.gemini.enable`, `assistants.codex.enable` (bool stubs)
    - `budgey.*` (submodule) - Budgey tracking settings
    - `environmentFiles` (listOf path)
    - `tmuxp.*` (submodule) - tmuxp settings
    - `direnv.enable` (bool)
  - In `projects.nix`, add `ruinous.ruinage.projects` option using projectType
  - Add port uniqueness assertion

  **Must NOT do**:
  - Don't implement activation/generation logic yet
  - Don't add per-project model overrides

  **Parallelizable**: NO (depends on 1, 2)

  **References**:
  - `modules/home/default/ai-cli/opencode-projects.nix:51-218` - Existing projectType pattern
  - `modules/home/default/ai-cli/kimaki.nix:251-288` - Kimaki project submodule
  - `modules/home/default/ai-cli/opencode.nix:488-621` - configDirType pattern

  **Acceptance Criteria**:
  - [ ] All 10 chassis projects expressible in new schema (verify mentally)
  - [ ] Port uniqueness assertion added
  - [ ] `nix flake check` passes
  - [ ] Schema supports `repo = null` for local-only projects (type: nullOr string)

  **Commit**: YES
  - Message: `feat(ruinage): define project type schema with namespaces and assistants`
  - Files: `modules/home/default/ruinage/types.nix`, `modules/home/default/ruinage/projects.nix`
  - Pre-commit: `nix flake check`

---

- [x] 4. Implement auto-clone activation

  **What to do**:
  - In `projects.nix`, add `home.activation.cloneRuinageProjects`
  - For each project with `ruinage.enable = true`:
    - Construct target path: `~/Projects/ruinage/<repo>`
    - If directory doesn't exist, run `git clone <url> <path>`
    - If directory exists, skip with verbose message
    - On clone failure, warn but continue (don't fail activation)
  - Same for `kimaki.enable = true` → `~/Projects/kimaki/<repo>`
  - Use `lib/ruinage/wrapper.nix` helper `mkGitUrl`

  **Must NOT do**:
  - No auto-pull (clone only)
  - No migration of existing clones at different paths
  - Don't fail activation on clone errors

  **Parallelizable**: NO (depends on 3)

  **References**:
  - `modules/home/default/ai-cli/opencode-projects.nix:614-643` - Activation script pattern
  - `modules/home/default/ai-cli/kimaki.nix:339-349` - Project registration activation

  **Acceptance Criteria**:
  - [ ] Activation script runs: `home.activation.cloneRuinageProjects`
  - [ ] Clone to `~/Projects/ruinage/<repo>` when `ruinage.enable = true`
  - [ ] Clone to `~/Projects/kimaki/<repo>` when `kimaki.enable = true`
  - [ ] Existing directories skipped with message
  - [ ] Clone failures warn but don't block activation
  - [ ] `nix flake check` passes

  **Commit**: YES
  - Message: `feat(ruinage): add auto-clone activation for project repositories`
  - Files: `modules/home/default/ruinage/projects.nix`
  - Pre-commit: `nix flake check`

---

- [x] 5. Port global opencode assistant settings

  **What to do**:
  - In `assistants/opencode.nix`, add global settings under `ruinous.ruinage.assistants.opencode`:
    - `.enable` - Enable opencode assistant globally
    - `.model` - Default model
    - `.mcpServers` - MCP server configurations
    - `.providers` - LLM provider configurations
    - `.plugins` - OpenCode plugins
    - `.harnesses.oh-my-opencode.enable` - Enable oh-my-opencode harness
    - `.harnesses.oh-my-opencode.agents` - oMo agent configurations (sisyphus, oracle, etc.)
    - `.harnesses.oh-my-opencode.categories` - oMo category configurations
    - `.harnesses.oh-my-opencode.lsp` - oMo LSP servers
    - `.harnesses.oh-my-opencode.disabledSkills` - Skills to disable
    - `.harnesses.oh-my-opencode.sisyphusSignature` - Enable commit signature
    - `.harnesses.ruinagents.enable` - Enable ruinagents harness (AGENTS.md, skills)
  - These are global defaults inherited by all projects
  - Generate `~/.config/opencode/` (default config) from these settings

  **Must NOT do**:
  - Don't duplicate the full implementation - reuse patterns from opencode.nix
  - Don't add per-project overrides

  **Parallelizable**: NO (depends on 3)

  **References**:
  - `modules/home/default/ai-cli/opencode.nix:769-1036` - All option definitions
  - `modules/home/default/ai-cli/opencode.nix:1038-1339` - Config generation logic

  **Acceptance Criteria**:
  - [ ] All global opencode options available under `ruinous.ruinage.assistants.opencode.*`
  - [ ] Harnesses configurable under `.harnesses.oh-my-opencode.*` and `.harnesses.ruinagents.*`
  - [ ] Default config generated at `~/.config/opencode/`
  - [ ] `nix flake check` passes

  **Commit**: NO (groups with TODO 6)

---

- [x] 6. Implement per-project opencode services

  **What to do**:
  - For each project with `assistants.opencode.enable = true`:
    - Generate per-project config at `~/.config/opencode-<name>/`
    - Generate systemd service `opencode-<name>.service` (preserve existing names)
    - Generate per-project XDG directories (preserve existing pattern)
    - Set port, caddy.fqdn, web.enable from project config
  - Generate fish `opencode` function for auto-attach
  - Reuse `lib/ruinage/wrapper.nix` for PATH, environment setup

  **Must NOT do**:
  - Don't change service naming pattern
  - Don't change XDG directory pattern

  **Parallelizable**: NO (depends on 5)

  **References**:
  - `modules/home/default/ai-cli/opencode-projects.nix:286-357` - mkWebService function
  - `modules/home/default/ai-cli/opencode-projects.nix:376-408` - Fish function generation
  - `modules/home/default/ai-cli/opencode-projects.nix:543-573` - systemd service generation

  **Acceptance Criteria**:
  - [ ] Systemd services created: `opencode-<name>.service`
  - [ ] Config directories created: `~/.config/opencode-<name>/`
  - [ ] Fish auto-attach function works
  - [ ] `nix flake check` passes

  **Commit**: YES
  - Message: `feat(ruinage): port opencode global settings and per-project services`
  - Files: `modules/home/default/ruinage/assistants/opencode.nix`
  - Pre-commit: `nix flake check`

---

- [x] 7. Absorb kimaki into ruinage

  **What to do**:
  - In `assistants/kimaki.nix`, add global kimaki settings under `ruinous.ruinage.assistants.kimaki`:
    - `.enable` - Enable kimaki assistant globally
    - `.environmentFiles` - Environment files for the service
    - `.configDir`, `.cacheDir`, `.stateDir`, `.dataDir` - XDG directories
    - Other options from current `kimaki.nix`
  - Generate `kimaki.service` systemd unit
  - Auto-discover projects with `namespaces.kimaki.enable = true`
  - Run `npx kimaki add-project` for each discovered project
  - Create `~/.opencode/bin/opencode` symlink (kimaki requires this)

  **Must NOT do**:
  - Don't change kimaki's hardcoded paths (it expects ~/.opencode/bin/opencode)

  **Parallelizable**: NO (depends on 6)

  **References**:
  - `modules/home/default/ai-cli/kimaki.nix:110-306` - All kimaki options
  - `modules/home/default/ai-cli/kimaki.nix:381-426` - systemd service definition
  - `modules/home/default/ai-cli/kimaki.nix:339-378` - Project registration

  **Acceptance Criteria**:
  - [ ] `kimaki.service` generated when `ruinous.ruinage.assistants.kimaki.enable = true`
  - [ ] Projects with `namespaces.kimaki.enable = true` auto-registered
  - [ ] `~/.opencode/bin/opencode` symlink created
  - [ ] `nix flake check` passes

  **Commit**: YES
  - Message: `feat(ruinage): absorb kimaki service into unified project system`
  - Files: `modules/home/default/ruinage/assistants/kimaki.nix`
  - Pre-commit: `nix flake check`

---

- [x] 8. Port tmuxp generation

  **What to do**:
  - Create `modules/home/default/ruinage/tmuxp.nix`
  - For each project with `tmuxp.enable = true`:
    - Generate tmuxp session using `ruinous.tmuxp.sessions`
    - Include: logs window (if web service), opencode attach, editor, shell
    - Support `tmuxp.extraWindows`
  - Use ruinage namespace path as `startDirectory`

  **Must NOT do**:
  - Don't change tmuxp session structure

  **Parallelizable**: YES (with 9, 10 - after TODO 3)

  **References**:
  - `modules/home/default/ai-cli/opencode-projects.nix:240-283` - mkTmuxpSession function
  - `modules/home/default/ai-cli/opencode-projects.nix:537-539` - tmuxp session generation

  **Acceptance Criteria**:
  - [ ] tmuxp sessions generated for projects with `tmuxp.enable = true`
  - [ ] `tmuxp load <project>` works
  - [ ] `nix flake check` passes

  **Commit**: NO (groups with TODO 9, 10)

---

- [x] 9. Port direnv generation

  **What to do**:
  - Create `modules/home/default/ruinage/direnv.nix`
  - For each project with `direnv.enable = true` and `environmentFiles`:
    - Generate snippet at `~/.config/direnv/envrc.d/<name>.sh`
    - Auto-inject into `.envrc.local` if `direnv.autoInject = true`
  - Use ruinage namespace path for injection

  **Must NOT do**:
  - Don't change snippet format

  **Parallelizable**: YES (with 8, 10 - after TODO 3)

  **References**:
  - `modules/home/default/ai-cli/opencode-projects.nix:730-792` - Direnv generation

  **Acceptance Criteria**:
  - [ ] Snippets generated at `~/.config/direnv/envrc.d/<name>.sh`
  - [ ] `.envrc.local` injection works
  - [ ] `nix flake check` passes

  **Commit**: NO (groups with TODO 8, 10)

---

- [x] 10. Port budgey registry generation

  **What to do**:
  - Create `modules/home/default/ruinage/budgey.nix`
  - Generate `~/.config/ruinagents/budgey/projects.json` with all projects that have `budgey.enable = true`
  - Include: id (hash of workdir), name, root, opencode_config_dir, xdg paths, budgets, tags
  - Add default project entry if `ruinous.ruinage.budgey.defaultProject.enable = true`

  **Must NOT do**:
  - Don't change budgey-extractor (only update registry if format compatible)

  **Parallelizable**: YES (with 8, 9 - after TODO 3)

  **References**:
  - `modules/home/default/ai-cli/opencode-projects.nix:648-726` - Budgey registry generation

  **Acceptance Criteria**:
  - [ ] Registry generated at `~/.config/ruinagents/budgey/projects.json`
  - [ ] Format compatible with budgey-extractor (or update extractor)
  - [ ] `nix flake check` passes

  **Commit**: YES
  - Message: `feat(ruinage): add tmuxp, direnv, and budgey integration`
  - Files: `modules/home/default/ruinage/tmuxp.nix`, `modules/home/default/ruinage/direnv.nix`, `modules/home/default/ruinage/budgey.nix`
  - Pre-commit: `nix flake check`

---

- [x] 11. Add claude-code, gemini, codex assistant stubs with harness support

  **What to do**:
  - Create `modules/home/default/ruinage/assistants/claude-code.nix`:
    - `ruinous.ruinage.assistants.claude-code.enable`
    - `ruinous.ruinage.assistants.claude-code.harnesses.ruinagents.enable` (stub)
  - Create `modules/home/default/ruinage/assistants/gemini.nix`:
    - `ruinous.ruinage.assistants.gemini.enable`
    - `ruinous.ruinage.assistants.gemini.harnesses.ruinagents.enable` (stub)
  - Create `modules/home/default/ruinage/assistants/codex.nix`:
    - `ruinous.ruinage.assistants.codex.enable`
    - `ruinous.ruinage.assistants.codex.harnesses.ruinagents.enable` (stub)
  - For now, these are placeholders for future implementation
  - Harness stubs prepare for ruinagents-gemini, ruinagents-claude-code packages

  **Must NOT do**:
  - Don't implement full integration (stubs only)

  **Parallelizable**: NO (depends on 5 for pattern)

  **References**:
  - `modules/home/default/ai-cli/claude-code.nix` - Existing claude-code module
  - `modules/home/default/ai-cli/gemini.nix` - Existing gemini module

  **Acceptance Criteria**:
  - [ ] Stub files exist for all 3 assistants
  - [ ] Global enable options under `ruinous.ruinage.assistants.<name>.enable`
  - [ ] Harness stubs under `ruinous.ruinage.assistants.<name>.harnesses.ruinagents.enable`
  - [ ] Per-project enable options available in projectType
  - [ ] `nix flake check` passes

  **Commit**: YES
  - Message: `feat(ruinage): add claude-code, gemini, codex assistant stubs with harness support`
  - Files: `modules/home/default/ruinage/assistants/claude-code.nix`, `assistants/gemini.nix`, `assistants/codex.nix`
  - Pre-commit: `nix flake check`

---

- [x] 12. Add Caddy data export and update caddy.nix

  **What to do**:
  - In `assistants/opencode.nix`, expose project data for Caddy consumption
  - Update `hosts/chassis/caddy.nix` to read from `ruinous.ruinage.projects` instead of `ruinous.ai-cli.opencode-projects.projects`
  - Keep hybrid pattern: ruinage exposes data, caddy.nix generates routes

  **Must NOT do**:
  - Don't generate Caddy config directly from ruinage module

  **Parallelizable**: NO (depends on 6)

  **References**:
  - `hosts/chassis/caddy.nix:12-116` - Current Caddy consumption pattern

  **Acceptance Criteria**:
  - [ ] caddy.nix updated to read from ruinage
  - [ ] All *.oc.ruinous.ai routes still generated
  - [ ] `just remote-dry-build chassis` passes

  **Commit**: YES
  - Message: `feat(ruinage): expose Caddy route data and update chassis caddy.nix`
  - Files: `modules/home/default/ruinage/assistants/opencode.nix`, `hosts/chassis/caddy.nix`
  - Pre-commit: `just remote-dry-build chassis`

---

- [ ] 13. Add documentation aggregation system

  **What to do**:
  - Create `modules/home/default/ruinage/docs.nix`
  - Add per-project documentation options:
    - `docs.enable` (bool) - Include this project in aggregated docs
    - `docs.flakeOutput` (string, default "<project>-docs") - Flake package output name for built docs
    - `docs.title` (string, default project name) - Display title in index
  - Add global docs options under `ruinous.ruinage.docs`:
    - `.enable` - Enable documentation aggregation
    - `.outputDir` - Where to aggregate docs (e.g., `~/.local/share/ruinage/docs`)
    - `.caddy.fqdn` - FQDN for docs site (default: "docs.ruinage.ai")
    - `.caddy.port` - Port for local serving
  - Aggregation approach (flake-output based):
    - Each project with docs exposes a `<project>-docs` package via its flake.nix
    - The package contains pre-built static HTML (MkDocs site output)
    - Aggregation collects these pre-built outputs, no source building needed
  - Generate index page:
    - Simple HTML/Markdown index linking to each project's docs
    - Each project's docs served at `/<project>/` path
    - Material theme for index page only (or simple static HTML)
  - Create activation script to:
    - Symlink/copy each project's `<project>-docs` output to aggregated directory
    - Generate index page
  - Add Caddy route for serving static docs

  **Architecture**:
  ```
  # Each project exposes docs via flake
  nix-config#nix-config-docs      # Built MkDocs site (static HTML)
  ruinagents#ruinagents-docs      # Built MkDocs site (static HTML)
  
  ~/.local/share/ruinage/docs/    # Aggregated output
  ├── index.html                  # Generated index page
  ├── nix-config/                 # Symlink to nix-config-docs output
  │   └── (pre-built static HTML)
  ├── ruinagents/                 # Symlink to ruinagents-docs output
  │   └── (pre-built static HTML)
  └── ...
  ```

  **Benefits of flake-output approach**:
  - No building docs at activation time (just symlinks)
  - Each project owns its docs build process
  - Docs are cached via Nix store
  - Projects without docs simply don't expose a `-docs` output
  - Simpler aggregation (no MkDocs config generation for sources)

  **Must NOT do**:
  - Don't build docs from source at aggregation time
  - Don't pull docs into ruinagents repo (that's the old pattern)
  - Don't require projects to have docs (gracefully skip if flake output missing)
  - Don't generate a monolithic MkDocs config (each project builds its own)

  **Parallelizable**: NO (depends on 4 for project paths)

  **References**:
  - Nix flake package outputs pattern
  - MkDocs Material theme documentation (for per-project builds)

  **Acceptance Criteria**:
  - [ ] `ruinous.ruinage.docs.enable` option available
  - [ ] Per-project `docs.enable` and `docs.flakeOutput` options available
  - [ ] Activation symlinks project docs outputs to aggregated directory
  - [ ] Index page generated listing all enabled projects
  - [ ] Caddy serves docs at configured FQDN
  - [ ] Missing flake outputs gracefully skipped with warning
  - [ ] `nix flake check` passes

  **Commit**: YES
  - Message: `feat(ruinage): add documentation aggregation with flake-based docs outputs`
  - Files: `modules/home/default/ruinage/docs.nix`
  - Pre-commit: `nix flake check`

---

- [ ] 14. Create tests/ruinage.test.nix

  **What to do**:
  - Create `tests/ruinage.test.nix` following `tests/opencode.test.nix` pattern
  - Test cases:
    - Module loads without errors
    - Project schema validates correctly
    - Port uniqueness assertion triggers on duplicate
    - Git URL construction works
    - Service names follow pattern
    - Config directories follow pattern
  - Add to flake.nix checks

  **Must NOT do**:
  - Don't test actual git clone (mock or skip)
  - Don't test runtime service behavior

  **Parallelizable**: NO (depends on 1-13)

  **References**:
  - `tests/opencode.test.nix:1-89` - Existing test pattern
  - `flake.nix` - Where to add checks

  **Acceptance Criteria**:
  - [ ] Test file exists: `tests/ruinage.test.nix`
  - [ ] `nix flake check` runs tests
  - [ ] All test cases pass

  **Commit**: YES
  - Message: `test(ruinage): add comprehensive test suite for ruinage module`
  - Files: `tests/ruinage.test.nix`, `flake.nix`
  - Pre-commit: `nix flake check`

---

- [ ] 15. Migrate chassis home-configuration.nix

  **What to do**:
  - Update `hosts/chassis/users/jmeskill/home-configuration.nix`
  - Replace `ruinous.ai-cli.opencode-projects` with `ruinous.ruinage.projects`
  - Replace `ruinous.ai-cli.kimaki` with `ruinous.ruinage.kimaki`
  - Keep `ruinous.ai-cli.opencode` for global settings (will be deprecated later)
  - Migrate all 10 projects to new schema
  - Keep age.secrets definitions (unchanged)

  **Must NOT do**:
  - Don't remove old module usage entirely (keep for fallback)
  - Don't change secrets paths

  **Parallelizable**: YES (with TODO 15)

  **References**:
  - `hosts/chassis/users/jmeskill/home-configuration.nix:1-260` - Current config

  **Acceptance Criteria**:
  - [ ] All 10 projects migrated to new schema
  - [ ] `just remote-dry-build chassis` passes
  - [ ] No duplicate project definitions

  **Commit**: NO (groups with TODO 15)

---

- [ ] 15. Add deprecation warnings to old modules

  **What to do**:
  - In `opencode-projects.nix`, add `lib.warn` when enabled:
    "ruinous.ai-cli.opencode-projects is deprecated, use ruinous.ruinage.projects"
  - In `kimaki.nix`, add `lib.warn` when enabled:
    "ruinous.ai-cli.kimaki is deprecated, use ruinous.ruinage.kimaki"
  - Keep modules fully functional (warnings only)

  **Must NOT do**:
  - Don't break existing functionality
  - Don't remove options

  **Parallelizable**: YES (with TODO 14)

  **References**:
  - Nix `lib.warn` function for deprecation warnings

  **Acceptance Criteria**:
  - [ ] Deprecation warning shown when old modules enabled
  - [ ] Old modules still work exactly as before
  - [ ] `nix flake check` passes

  **Commit**: YES
  - Message: `refactor(ruinage): migrate chassis to ruinage and deprecate old modules`
  - Files: `hosts/chassis/users/jmeskill/home-configuration.nix`, `modules/home/default/ai-cli/opencode-projects.nix`, `modules/home/default/ai-cli/kimaki.nix`
  - Pre-commit: `just remote-dry-build chassis`

---

- [ ] 16. Update AGENTS.md skills catalog

  **What to do**:
  - Update skills catalog to reflect new module structure
  - Add notes about ruinage.projects vs deprecated opencode-projects
  - Document new project definition workflow

  **Must NOT do**:
  - Don't rewrite entire AGENTS.md

  **Parallelizable**: NO (depends on 14)

  **References**:
  - `AGENTS.md` - Current skills catalog section

  **Acceptance Criteria**:
  - [ ] Skills catalog updated with ruinage references
  - [ ] Deprecation notes added for old patterns

  **Commit**: YES
  - Message: `docs: update AGENTS.md with ruinage module documentation`
  - Files: `AGENTS.md`
  - Pre-commit: None

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 2 | `feat(ruinage): create module skeleton` | lib/ruinage/, modules/home/default/ruinage/, modules/home/default/default.nix | nix flake check |
| 3 | `feat(ruinage): define project type schema` | types.nix, projects.nix | nix flake check |
| 4 | `feat(ruinage): add auto-clone activation` | projects.nix | nix flake check |
| 6 | `feat(ruinage): port opencode integration` | assistants/opencode.nix | nix flake check |
| 7 | `feat(ruinage): absorb kimaki service` | assistants/kimaki.nix | nix flake check |
| 10 | `feat(ruinage): add tmuxp, direnv, budgey` | tmuxp.nix, direnv.nix, budgey.nix | nix flake check |
| 11 | `feat(ruinage): add assistant stubs` | assistants/claude-code.nix, assistants/gemini.nix, assistants/codex.nix | nix flake check |
| 12 | `feat(ruinage): expose Caddy data` | assistants/opencode.nix, hosts/chassis/caddy.nix | just remote-dry-build chassis |
| 13 | `test(ruinage): add test suite` | tests/ruinage.test.nix, flake.nix | nix flake check |
| 15 | `refactor(ruinage): migrate chassis` | home-configuration.nix, opencode-projects.nix, kimaki.nix | just remote-dry-build chassis |
| 16 | `docs: update AGENTS.md` | AGENTS.md | None |

---

## Success Criteria

### Verification Commands
```bash
nix flake check                    # All tests pass
just remote-dry-build chassis      # Build succeeds
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] All tests pass
- [ ] 10+ projects migrated to new schema
- [ ] New project addable with <10 lines of config
- [ ] Old modules still work with deprecation warning
