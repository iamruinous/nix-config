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

## Git Workflow

This project adheres to the [Conventional Commits](https://www.conventionalcommits.org/) specification. This creates a structured and easily understandable commit history.

### Commit Message Format

Each commit message consists of a **header**, a **body**, and a **footer**.

```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

-   **type**: This describes the kind of change you're making. Common types include:
    -   `feat`: A new feature.
    -   `fix`: A bug fix.
    -   `docs`: Documentation only changes.
    -   `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc).
    -   `refactor`: A code change that neither fixes a bug nor adds a feature.
    -   `test`: Adding missing tests or correcting existing tests.
    -   `chore`: Changes to the build process or auxiliary tools and libraries such as documentation generation.
-   **scope** (optional): This provides additional contextual information and is contained within parentheses, e.g., `feat(parser): add ability to parse arrays`.
-   **description**: A short, imperative-tense description of the change.

### Examples

```
feat: allow provided config object to extend other configs
```

```
fix(jbookpro): correct brew package installation
```

```
docs: explain the git workflow
```

## AI Agent Instructions for Git Commits

### When to Commit

Create commits at logical breakpoints during feature development:

1. **Per-Feature Commits**: Create a commit for each complete, self-contained feature or fix
2. **After Testing**: Only commit after verifying the change builds successfully
3. **Before Major Changes**: Commit working code before starting significant refactoring
4. **Logical Groupings**: Group related changes together (e.g., package + overlay + docs)

### Commit Creation Guidelines

When creating commits, follow these steps:

1. **Verify the Build**: Always test that the configuration builds before committing
   ```bash
   nixos-rebuild dry-build --flake .#<hostname>
   # or for packages
   nix build .#<package-name>
   ```

2. **Stage Related Files**: Group related changes together
   ```bash
   git add <files>
   ```

3. **Write a Descriptive Commit Message**: Use the conventional commits format with a detailed body

### Detailed Commit Message Structure

#### Header (Required)
- Use present tense, imperative mood: "add" not "added" or "adds"
- Keep under 72 characters
- Be specific about what changed

#### Body (Recommended for non-trivial changes)
- Explain **what** and **why**, not **how**
- Wrap at 72 characters
- Separate from header with a blank line
- Include:
  - Motivation for the change
  - How it differs from previous behavior
  - Any breaking changes or migration notes
  - Related issue numbers or documentation

#### Footer (Optional)
- Reference issues: `Closes #123` or `Fixes #456`
- Note breaking changes: `BREAKING CHANGE: <description>`
- Add co-authors: `Co-authored-by: Name <email>`

### Commit Message Examples for Common Scenarios

#### Adding a New Package
```
feat(packages): add agenix-helper for managing encrypted age identities

Add a new package that simplifies working with passphrase-protected
age identities. This allows unlocking the identity once per session
instead of entering the passphrase for every agenix operation.

Key features:
- unlock/lock/status commands
- Quiet mode for direnv integration
- Stores decrypted key in /tmp with 600 permissions
- Automatic environment variable export

The package is inspired by suderman/nixos and includes:
- Package definition in packages/agenix-helper/
- Overlay integration for all hosts
- direnv integration in .envrc
- Comprehensive documentation

This dramatically improves the developer experience when working
with multiple encrypted secrets during development.
```

#### Fixing a Bug
```
fix(pilaster): correct container port mappings for nutify

The nutify container was missing required port mappings (3493, 5050)
which prevented the service from being accessible. Added the missing
ports to both the container configuration and firewall rules.

Also added the ports to the firewall allowedTCPPorts to ensure
external access is permitted.

Changes:
- Add ports 3493:3493, 5050:5050, 443:443 to container
- Update firewall to allow TCP ports 3493 and 5050
```

#### Refactoring
```
refactor(packages): rename agenix-unlock to agenix-helper

Rename the package to agenix-helper to make it more generic and
extensible for future agenix-related utilities beyond just
unlock/lock functionality.

Changes:
- Rename package directory: packages/agenix-unlock → packages/agenix-helper
- Update binary name: agenix-unlock → agenix-helper
- Update all references in overlay, configs, and documentation
- Update meta.description to be more generic
- Maintain same functionality and commands (unlock, lock, status)

This naming better reflects the package's purpose as a general
helper for agenix operations and allows for future expansion.
```

#### Documentation
```
docs(packages): add comprehensive README for agenix-helper

Add detailed documentation covering:
- Purpose and background (inspired by suderman/nixos)
- How the unlock/lock workflow operates
- Usage examples and typical workflows
- direnv integration details
- Security considerations and best practices
- Installation instructions

Also updated:
- packages/README.md: Added agenix-helper to package list
- README.md: Updated custom packages and secrets management sections
- .scripts/README.md: Note about package migration

The documentation provides users with everything needed to
understand and effectively use the package.
```

#### Multiple Related Changes
```
feat(pilaster): add nutify container with encrypted environment

Add nutify container for NUT (Network UPS Tools) management with
proper security configuration.

Changes:
1. Container configuration (hosts/pilaster/containers.nix):
   - Add nutify OCI container with dartsteven/nutify image
   - Configure privileged mode and USB device access
   - Set up proper capabilities (SYS_ADMIN, SYS_RAWIO, MKNOD)
   - Add environment variables via encrypted file

2. Secrets management:
   - Create age.secrets.pilaster_docker_env_nutify entry
   - Add encrypted environment file with agenix
   - Include rekeyed secrets for deployment

3. Network configuration:
   - Add ports 3493, 5050 to firewall allowedTCPPorts
   - Connect container to servicenet network

4. Documentation:
   - Add nutify container workflow to hosts/pilaster/README.md
   - Document environment file management process

This enables UPS monitoring and management through the nutify
web interface while maintaining security through encrypted
configuration and restricted permissions.
```

### Git Commands for AI Agents

When making commits, use this workflow:

```bash
# 1. Check current status
git status

# 2. Review changes
git diff

# 3. Stage specific files (preferred over `git add .`)
git add <file1> <file2> <file3>

# 4. Verify staged changes
git diff --cached

# 5. Create commit with detailed message
git commit -m "type(scope): short description" -m "
Detailed explanation of what changed and why.

- Bullet points for key changes
- Context about the motivation
- Any breaking changes or notes

Fixes #123
"

# 6. Verify commit
git log -1 --stat
```

### Special Considerations

1. **Don't commit without testing**: Always verify builds succeed first
2. **One feature per commit**: Keep commits focused and atomic
3. **Update documentation**: Include doc updates in the same commit as code changes
4. **Secrets**: Never commit unencrypted secrets; always use agenix
5. **Large changes**: Consider breaking into multiple commits with clear progression
6. **Rebase, don't merge**: Keep history linear when possible

### Commit Frequency

- **Too frequent**: Don't commit every single file change
- **Too infrequent**: Don't bundle multiple unrelated features
- **Just right**: Commit when a feature is complete and tested

### When NOT to Commit

- Configuration doesn't build
- Tests are failing
- Temporary/debugging code is present
- Secrets are exposed
- Work is incomplete and non-functional

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
