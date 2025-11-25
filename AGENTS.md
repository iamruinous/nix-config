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

This project follows the git behavior guidelines defined in [AGENT_GIT_GUIDELINES.md](./AGENT_GIT_GUIDELINES.md).

See that file for comprehensive guidance on:
- Conventional Commits format
- When and how to commit
- Commit message examples
- Handling commit failures

### Project-Specific Notes

In addition to the general guidelines, this NixOS configuration repository has these specific requirements:

1. **Verify builds before committing**:
   ```bash
   nixos-rebuild dry-build --flake .#<hostname>
   # or for packages
   nix build .#<package-name>
   ```

2. **Secrets**: Never commit unencrypted secrets; always use agenix

3. **Check SSH/GPG agent** before committing:
   ```bash
   ssh-agent-check || echo "Warning: SSH agent not responding"
   ```

4. **All commits must be GPG signed** - never use `--no-gpg-sign`

## Session Logging

### Overview

This repository maintains a running log of development sessions in `SESSION_LOG.md`. This helps track:
- What work was completed in each session
- Context for future sessions
- Historical decisions and rationale
- Unresolved issues and follow-up tasks

### When to Update the Session Log

Update `SESSION_LOG.md` at the **end of each development session** when:
- Significant features were added or modified
- Multiple related changes were made
- Important decisions were documented
- Issues were discovered that need follow-up
- The session lasted more than 15-20 minutes

### How to Update the Session Log

1. **Add a new session entry at the top** (after the format template)
2. **Use the standard format**:
   ```markdown
   ## YYYY-MM-DD - Descriptive Session Title

   **AI Agent:** [Your name/type]
   **Duration:** [Approximate time]
   **Focus Areas:** [Main topics worked on]

   ### Changes Made
   - Bullet list of significant changes
   - Include file paths where relevant
   - Note any breaking changes

   ### Commits Created
   - List of commit messages/summaries
   - Or note if changes are staged but not committed

   ### Issues/Notes
   - Any unresolved issues
   - Follow-up tasks needed
   - Important notes for future sessions
   ```

3. **Be concise but informative**: Focus on what and why, not excessive detail
4. **Group related changes**: Don't list every single file, group by feature/area
5. **Highlight important decisions**: Document why certain approaches were chosen
6. **Note pending work**: Make it easy for the next session to pick up where you left off

### Session Log Best Practices

**Do:**
- Update at the end of productive sessions
- Group changes by feature/area
- Note technical decisions and rationale
- List unresolved issues clearly
- Include file paths for major changes
- Note breaking changes prominently

**Don't:**
- Log trivial changes (typo fixes, formatting)
- Duplicate information from commit messages verbatim
- Write essays - keep it concise
- Update for every tiny edit
- Forget to update before ending the session

### Example Session Entry

```markdown
## 2025-11-23 - Docker Container Security Hardening

**AI Agent:** Claude Code
**Duration:** 1 hour
**Focus Areas:** Container security, secret management

### Changes Made

1. **Container Security** (`hosts/production/containers.nix`)
   - Added security context to all containers
   - Implemented read-only root filesystems
   - Dropped unnecessary capabilities
   - Files: hosts/production/containers.nix

2. **Secret Rotation**
   - Rotated database credentials
   - Updated API keys in agenix
   - Documented rotation process
   - Files: secrets/production/*.age

### Commits Created

- `feat(security): harden container security contexts`
- `chore(secrets): rotate production credentials`

### Issues/Notes

**Pending:**
- Need to test backup restore with new credentials
- Should automate credential rotation (follow-up ticket)

**Important:**
- Breaking change: Containers now require explicit volume mounts
- Old configs will fail with read-only filesystem errors
- Migration guide added to docs/MIGRATION.md
```

### Integrating with Git Workflow

The session log complements, but doesn't replace, git commit messages:

- **Commit messages**: Detailed, per-change documentation
- **Session log**: High-level session summary, context, pending work

Think of it as:
- Commit messages = Chapter details
- Session log = Table of contents

### When to Skip Logging

You can skip updating the session log for:
- Quick typo fixes
- Simple README updates
- Experimental/throwaway work
- Sessions under 10-15 minutes
- Work that was completely reverted

### Session Log Maintenance

Periodically (every few months):
- Review old entries for outdated information
- Archive very old sessions to `SESSION_LOG_ARCHIVE.md`
- Keep recent ~6 months in main log
- Update template if format evolves
