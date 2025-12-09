# AI Agent Context

This file provides context to AI coding assistants (Claude Code, Gemini, Copilot, etc.) to help them understand the structure and conventions of this NixOS configuration repository.

## Project Overview

This is a NixOS configuration repository that uses the `blueprint` flake to map the directory structure to flake outputs. It manages the configurations for multiple NixOS and Darwin (macOS) machines.

The repository is structured as follows:

-   `flake.nix`: The main entry point for the Nix flake, defining inputs and outputs.
-   `hosts/`: Contains the main configuration for each individual machine. Each machine has its own subdirectory (e.g., `hosts/framework/`) with a `configuration.nix`, `system-configuration.nix`, or `darwin-configuration.nix` file.
-   `modules/`: Contains reusable NixOS and home-manager modules that are imported by the host configurations.
    -   `modules/nixos/`: NixOS specific modules.
    -   `modules/darwin/`: Darwin specific modules.
    -   `modules/home/`: home-manager modules, with subdirectories for different operating systems.
-   `users/`: Contains user-specific configurations, primarily for home-manager.
-   `lib/`: Contains helper functions and libraries.
-   `packages/`: Contains custom packages (see `packages/README.md`).
-   `secrets/`: Contains encrypted secrets managed with agenix.

## Building and Running

To build a specific host configuration, use the following command:

```bash
nixos-rebuild switch --flake .#<hostname>
```

For example, to build the configuration for the `framework` host, run:

```bash
nixos-rebuild switch --flake .#framework
```

To build a darwin configuration, use the following command:

```bash
darwin-rebuild switch --flake .#<hostname>
```

For example, to build the configuration for the `jbookpro` host, run:

```bash
darwin-rebuild switch --flake .#jbookpro
```

To build a system configuration, use the following command:

```bash
nix run 'github:numtide/system-manager' -- switch --flake .#<system>
```

For example, to build the configuration for the `pit` host, run:

```bash
nix run 'github:numtide/system-manager' -- switch --flake .#pit
```

## Development Conventions

-   **Modularity:** Configurations are highly modular, with reusable components in the `modules/` directory.
-   **Blueprint:** The `blueprint` flake is used to map the directory structure to flake outputs, which simplifies the `flake.nix` file.
-   **Secrets Management:** Secrets are managed using `agenix` and `agenix-rekey`.
-   **Home Manager:** User-specific configurations are managed with `home-manager`.
-   **Disko:** Some hosts use `disko` for declarative disk partitioning.
-   **Lanzaboote:** Some hosts use `lanzaboote` for secure boot.
-   **Custom Packages:** Custom packages in `packages/` are automatically discovered by blueprint and exposed via overlay.

## Custom AI Agents

This repository includes custom AI agents that provide specialized expertise for specific tasks. Agents are defined in `.claude/agents/` and are automatically available to Claude Code.

### Available Agents

#### nix-packager

**Location:** `.claude/agents/nix-packager.md`

**Purpose:** Expert NixOS package developer specializing in:
- Creating new Nix packages from scratch
- Converting shell scripts and binaries into reproducible Nix packages
- Setting up proper dependencies (buildInputs, nativeBuildInputs, propagatedBuildInputs)
- Configuring build phases and package metadata
- Integrating packages with the blueprint flake structure
- Testing and debugging package builds

**Automatic Invocation:** Claude Code will automatically delegate to this agent when you ask for help with:
- Creating packages in `packages/`
- Converting scripts to Nix packages
- Fixing package build errors
- Setting up stdenv.mkDerivation or specialized builders
- Integrating packages with overlays

**Explicit Invocation:** You can explicitly request this agent:
```
"Use the nix-packager agent to convert this bash script into a Nix package"
```

**Tools Available:**
- File operations: Read, Grep, Glob, Edit, Write
- Shell commands: Bash (for nix build, testing, etc.)
- NixOS MCP server: Access to nixos package search, options lookup, and version history

**Example Usage:**
```
# Automatic delegation:
"Create a Nix package for this Python script that manages Docker containers"

# Explicit invocation:
"Use the nix-packager agent to package the backup script as a proper Nix package"

# Complex task:
"Convert the mariadb-backup.sh script into a Nix package with proper dependencies
and integrate it with the overlay so it's available on all hosts"
```

### Creating Additional Custom Agents

To create your own custom agents:

1. **Create agent file:** `.claude/agents/<agent-name>.md`
2. **Add YAML frontmatter:**
   ```yaml
   ---
   name: agent-name
   description: "Detailed description of when/why to invoke this agent"
   tools: Read, Grep, Glob, Bash, Edit, Write
   model: sonnet
   ---
   ```
3. **Write system prompt:** Define the agent's expertise, workflow, and best practices in markdown below the frontmatter
4. **Document the agent:** Add it to this section of CLAUDE.md

**Configuration Fields:**
- `name` (required): Unique identifier in kebab-case
- `description` (required): Detailed explanation of the agent's purpose and when to invoke it
- `tools` (optional): Comma-separated list of tool names; inherits all if omitted
- `model` (optional): Override model (`sonnet`, `opus`, `haiku`, or `inherit`)

**Agent Context:**
- Each agent runs in isolated context
- Prevents information overload
- Can be parallelized with other agents
- All configured MCP servers are automatically available

**Best Practices:**
- Store agents in `.claude/agents/` (project-level) for team sharing
- Write detailed descriptions for accurate auto-delegation
- Include comprehensive system prompts with examples
- Document agents in this CLAUDE.md file
- Test agents with explicit invocation before relying on auto-delegation

## Git Workflow

**⚠️ IMPORTANT: The main branch is protected and does not allow direct commits.**

**Before making any code changes**, you MUST:
1. **Check if you're on a feature branch** - if on `main`, create a new branch first
2. **Create a draft pull request** immediately after creating the branch and making your first commit
3. **Never commit directly to main** - all commits must go through pull requests
4. **Follow the branching conventions** in the guidelines (e.g., `feat/`, `fix/`, `docs/`)

**Recommended workflow:**
```bash
# 1. Create feature branch
git checkout -b feat/my-feature

# 2. Make initial changes and commit
git add <files>
git commit -m "feat: initial implementation"

# 3. Push and create draft PR with task list
git push -u origin feat/my-feature
gh pr create --draft --title "feat: my feature" --body "$(cat <<'EOF'
## Summary
Brief description of the changes.

## Tasks
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
EOF
)"

# 4. Continue making commits on the branch
# 5. Update PR description to mark tasks complete or add new tasks
gh pr edit --body "$(cat <<'EOF'
## Summary
Brief description of the changes.

## Tasks
- [x] Task 1 (completed)
- [ ] Task 2
- [ ] Task 3
- [ ] New task discovered during implementation
EOF
)"

# 6. Mark PR ready for review when complete
gh pr ready
```

**Keep the PR updated:** As you work, update the PR description to reflect progress by marking tasks complete (`- [x]`) and adding any new tasks discovered during implementation.

This project follows the git behavior guidelines defined in [AGENT_GIT_GUIDELINES.md](./AGENT_GIT_GUIDELINES.md). You must read this before making any git commits.


### Project-Specific Notes

In addition to the general guidelines, this NixOS configuration repository has these specific requirements:

1. **Verify builds before committing**:
   ```bash
   nixos-rebuild dry-build --flake .#<hostname>
   # or for packages
   nix build .#<package-name>
   ```

2. **Secrets**: Never commit unencrypted secrets; always use agenix
   - When creating `.env.template` files for Docker containers, after the user has filled in the secret values, encrypt using:
     ```bash
     agenix edit -i input.env.template output.env.age
     ```
   - This encrypts non-interactively, reading from the template file
   - To view an encrypted file: `agenix view path/to/file.age`
   - To update an existing encrypted file (e.g., Caddyfile):
     1. View current contents: `agenix view path/to/file.age > /tmp/file.txt`
     2. Edit the temporary file
     3. Remove old encrypted file: `rm path/to/file.age`
     4. Re-encrypt: `agenix edit -i /tmp/file.txt path/to/file.age`
     5. Clean up: `rm /tmp/file.txt`

3. **Adding Docker containers with reverse proxy**:
   - Add container definition to `hosts/<host>/containers.nix`
   - Create encrypted env file in `hosts/<host>/files/docker/env/<service>.env.age`
   - Add agenix secret definition in the same containers.nix file
   - Update Caddyfile at `hosts/<host>/files/caddy/Caddyfile.age` to add reverse proxy entry
   - Container names on `servicenet` are resolvable as hostnames in Caddy (e.g., `reverse_proxy wikijs:3000`)
   - **Create DNS entry for the service** (see DNS Management below)

4. **DNS Management**:
   Each container host has a DNS entry `<hostname>.meskill.farm` that can be used as a CNAME target. When adding a new service to Caddy, you must create a corresponding DNS entry.

   **DNS Naming Convention:**
   - Each service should have its own DNS entry: `<service>.meskill.farm`
   - Use CNAME records pointing to the host's DNS entry: `<hostname>.meskill.farm`

   **Using cfcli to manage DNS:**
   The `cfcli` tool (available in the devshell) can be used to create DNS records:
   ```bash
   # List existing DNS records
   cfcli --domain meskill.farm ls

   # Add a CNAME record for a new service
   cfcli --domain meskill.farm --type CNAME add <name> <container_hostname>.meskill.farm

   # Example: Adding docs.meskill.farm pointing to pilaster.meskill.farm
   cfcli --domain meskill.farm --type CNAME add docs pilaster.meskill.farm

   # Edit an existing record (e.g., if a container moved to a different host)
   cfcli --domain meskill.farm --type CNAME edit <name> <container_hostname>.meskill.farm
   ```

   **When adding a new service to Caddy, always offer to create the DNS entry using cfcli.**

5. **Check SSH/GPG agent** before committing:
   ```bash
   ssh-agent-check || echo "Warning: SSH agent not responding"
   ```

6. **All commits must be GPG signed** - never use `--no-gpg-sign`

## Changelog

This repository maintains a changelog in `CHANGELOG.md` following the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

### Guiding Principles

- Changelogs are for **humans**, not machines
- One entry per version/release
- Group similar changes together
- Latest version appears first
- Use ISO 8601 dates (YYYY-MM-DD)

### Change Categories

Use these standard sections to categorize changes:

- **Added** - New features or capabilities
- **Changed** - Modifications to existing functionality
- **Deprecated** - Features marked for future removal
- **Removed** - Features that have been deleted
- **Fixed** - Bug corrections
- **Security** - Vulnerability patches

### Unreleased Section

Always maintain an `[Unreleased]` section at the top of the changelog. This:
- Tracks upcoming changes before they're released
- Makes it easy to see what's changed since last release
- Simplifies the release process (just move items to a new version section)

### When to Update the Changelog

Update `CHANGELOG.md` when:
- Adding new features or packages
- Making breaking changes
- Fixing significant bugs
- Deprecating or removing functionality
- Addressing security issues

**Skip updates for:**
- Typo fixes
- Internal refactoring with no user impact
- Documentation-only changes (unless significant)
- Work-in-progress on feature branches

### Format

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- New docker-image-updater Go implementation with Bubbletea TUI

### Changed
- Updated flake inputs

## [2025-11-29]

### Added
- Initial docker-image-updater shell script package
- Custom nix-packager AI agent

### Fixed
- SSH agent check script permissions
```

### Best Practices

**Do:**
- Write entries from the user's perspective
- Be concise but descriptive
- Include context for breaking changes
- Group related changes under a single bullet
- Link to PRs or issues where relevant

**Don't:**
- Copy commit messages verbatim
- Include every tiny change
- Use technical jargon without explanation
- Forget to move Unreleased items when releasing

### Relationship to Git

The changelog complements git history:

| Git History | Changelog |
|-------------|-----------|
| Every commit | Notable changes only |
| Technical details | User-facing summary |
| Chronological | Grouped by category |
| For developers | For users |

### Example Entry

```markdown
## [Unreleased]

### Added
- `docker-image-updater` package: Interactive TUI for checking Docker image updates in NixOS container configurations
- Support for multiple container registries (Docker Hub, ghcr.io)

### Changed
- Migrated docker-image-updater from shell script to Go for better maintainability

### Deprecated
- The `--verbose` flag is deprecated; use `--debug` instead

### Fixed
- Container scanner now correctly parses quoted container names in Nix files
```
- always use a limit when running docker-image-updater so we don't have to wait for 70+ checks
