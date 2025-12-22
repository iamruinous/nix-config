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

### Agent Workflow Requirements

**Before making any code changes**, all AI agents MUST follow this workflow:

1. **Create a plan with todos**
   - Use the TodoWrite tool to create a structured task list
   - Break down the work into clear, actionable steps
   - Include research/exploration tasks before implementation tasks

2. **Maintain a progress log**
   - Update todo status as you work (pending → in_progress → completed)
   - Only mark tasks complete when fully finished
   - Add new tasks discovered during implementation

3. **Confirm the plan with the user before taking action**
   - Present the plan to the user for review
   - Wait for explicit approval before making changes
   - Adjust the plan based on user feedback

**Example workflow:**
```
User: "Add a new Docker container for WikiJS"

Agent:
1. Creates todo list:
   - [ ] Research existing container patterns in hosts/
   - [ ] Identify target host for deployment
   - [ ] Plan container configuration
   - [ ] Plan Caddy reverse proxy entry
   - [ ] Plan DNS entry
   - [ ] Update host README documentation

2. Presents plan to user:
   "Here's my plan for adding WikiJS:
   - Add container to hosts/monolith/containers.nix
   - Create env file at hosts/monolith/files/docker/env/wikijs.env.age
   - Add reverse proxy entry to Caddyfile
   - Create DNS entry wikijs.meskill.farm → monolith.meskill.farm
   - Update hosts/monolith/README.md with new service

   Does this look correct? Should I proceed?"

3. Waits for user confirmation before implementing
```

**Why this matters:**
- Prevents wasted effort on misunderstood requirements
- Gives the user visibility into planned changes
- Catches errors before they're made
- Creates a clear audit trail of work

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

#### agenix

**Location:** `.claude/agents/agenix.md`

**Purpose:** Expert in agenix secrets management for NixOS, specializing in:
- Viewing, creating, and editing encrypted `.age` files
- Managing Docker environment secrets
- Updating Caddyfile configurations
- Setting up Cloudflare tunnel credentials
- Rekeying secrets after changes

**Automatic Invocation:** Claude Code will automatically delegate to this agent when you ask for help with:
- Encrypting files with agenix
- Updating Caddyfiles or other encrypted configs
- Managing Docker environment secrets (`.env.age` files)
- Working with cloudflared credentials
- Any operation on `.age` files

**Explicit Invocation:** You can explicitly request this agent:
```
"Use the agenix agent to add a new environment file for the wikijs container"
```

**Tools Available:**
- File operations: Read, Grep, Glob, Edit, Write
- Shell commands: Bash (with `dangerouslyDisableSandbox: true` for agenix commands)

**Key Commands:**
```bash
agenix-helper unlock          # Unlock before working with secrets
agenix view file.age          # View encrypted file
agenix edit -i input output.age  # Encrypt file non-interactively
agenix rekey -a               # Rekey all secrets after changes
agenix-helper lock            # Lock when done
```

**Common Patterns:**
- Caddyfiles: `hosts/<hostname>/files/caddy/Caddyfile.age`
- Docker env: `hosts/<hostname>/files/docker/env/<service>.env.age`
- Cloudflared: `hosts/<hostname>/files/cloudflared/*.age`
- Secret naming: `<hostname>_<purpose>` (e.g., `zenith_caddy_caddyfile`)

**Example Usage:**
```
# Automatic delegation:
"Update the Caddyfile on zenith to add a new service"

# Explicit invocation:
"Use the agenix agent to create an encrypted environment file for the new database"

# Complex task:
"Set up Cloudflare tunnel credentials for the new service with proper encryption"
```

#### containnix

**Location:** `.claude/agents/containnix.md`

**Purpose:** Expert in containerizing services using NixOS OCI containers, specializing in:
- Docker container definitions in `containers.nix`
- Network configuration (servicenet, proxynet, datanet)
- Caddy reverse proxy setup
- DNS management with cfcli
- Environment secrets integration
- GPU passthrough (NVIDIA and AMD ROCm)
- Cloudflare tunnel configuration

**Automatic Invocation:** Claude Code will automatically delegate to this agent when you ask for help with:
- Adding Docker containers to hosts
- Configuring container networks
- Setting up reverse proxies
- Managing container environment files
- Deploying containerized services

**Explicit Invocation:** You can explicitly request this agent:
```
"Use the containnix agent to add a new WikiJS container to pilaster"
```

**Tools Available:**
- File operations: Read, Grep, Glob, Edit, Write
- Shell commands: Bash (for docker, cfcli, etc.)

**Network Architecture:**
```
┌─────────────┐
│   Caddy     │ ← proxynet + servicenet (ports 80, 443)
└──────┬──────┘
       │
┌──────▼──────┐
│  servicenet │ ← Apps accessible via Caddy
└──────┬──────┘
       │
┌──────▼──────┐
│   datanet   │ ← Databases (internal only)
└─────────────┘
```

**Common Patterns:**
- Web app + DB: App on servicenet+datanet, DB on datanet only
- GPU container: Add device mounts for `/dev/kfd`, `/dev/dri` (AMD) or `nvidia.com/gpu=all` (NVIDIA)
- Reverse proxy: Add service to Caddyfile, create DNS CNAME

**Example Usage:**
```
# Automatic delegation:
"Add an n8n container to monolith with postgres database"

# Explicit invocation:
"Use the containnix agent to deploy Ollama with GPU support on zenith"

# Complex task:
"Set up a new service with Cloudflare tunnel for external access"
```

#### cfnix

**Location:** `.claude/agents/cfnix.md`

**Purpose:** Expert in Cloudflare integration with NixOS, specializing in:
- DNS management with cfcli
- Cloudflare Tunnels setup and configuration
- Domain naming conventions (production vs staging)
- SSL/TLS configuration
- External service exposure

**Automatic Invocation:** Claude Code will automatically delegate to this agent when you ask for help with:
- Creating or modifying DNS records
- Setting up Cloudflare tunnels
- Configuring external access to services
- Managing the meskill.farm domain

**Explicit Invocation:** You can explicitly request this agent:
```
"Use the cfnix agent to set up a Cloudflare tunnel for the new service"
```

**Tools Available:**
- File operations: Read, Grep, Glob, Edit, Write
- Shell commands: Bash (with `dangerouslyDisableSandbox: true` for cfcli)

**Environment Pattern:**
```
Production:      <service>.meskill.farm     → production host
Testing/Staging: <service>.x.meskill.farm   → zenith (testing)
```

**Key Commands:**
```bash
cfcli --domain meskill.farm ls                    # List records
cfcli --domain meskill.farm --type CNAME add ...  # Add record
cfcli --domain meskill.farm --type CNAME edit ... # Edit record
cfcli --domain meskill.farm --type CNAME rm ...   # Delete record
```

**Tunnel DNS Pattern:**
```bash
# Internal (for Caddy)
cfcli --domain meskill.farm --type CNAME add <service>-int <host>.meskill.farm

# External (proxied through tunnel)
cfcli --domain meskill.farm --type CNAME --activate add <service> <tunnel-id>.cfargotunnel.com
```

**Example Usage:**
```
# Automatic delegation:
"Create a DNS entry for the new documentation site"

# Explicit invocation:
"Use the cfnix agent to set up external access via Cloudflare tunnel"

# Complex task:
"Migrate the service from pilaster to monolith and update all DNS records"
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

3. **Adding Docker Containers**:
   When adding a new Docker container, follow this comprehensive workflow.

   **Questions to Ask the User:**
   Before implementing, gather the following information:

   1. **Which host should run this container?** (e.g., monolith, pilaster, zenith)
   2. **Does this container require environment variables or secrets?**
      - If yes: Create a `.env.template` file for the user to fill in
   3. **Does this container need a reverse proxy (Caddy)?**
      - If yes: What domain name? (e.g., `myservice.meskill.farm`)
      - If no: What port(s) should be opened in the firewall?
   4. **Will this container be accessible over a Cloudflare Tunnel?**
      - If yes: Follow the Cloudflare Tunnels setup (item 5 below)
   5. **Does this container need to communicate with other containers?**
      - Database access → use `datanet` network
      - Service-to-service → use `servicenet` network
      - Direct host port binding → use `proxynet` network

   **Step 1: Unlock agenix (if working with secrets)**
   ```bash
   agenix-helper unlock
   ```

   **Step 2: Create directory structure**
   ```bash
   mkdir -p hosts/<hostname>/files/docker/env
   ```

   **Step 3: Create environment template (if needed)**
   Create `hosts/<hostname>/files/docker/env/<service>.env.template`:
   ```env
   # Example template - user fills in actual values
   DB_PASSWORD=
   API_KEY=
   SECRET_TOKEN=
   ```
   Ask the user to fill in the values, then encrypt:
   ```bash
   agenix edit -i hosts/<hostname>/files/docker/env/<service>.env.template \
               hosts/<hostname>/files/docker/env/<service>.env.age
   rm hosts/<hostname>/files/docker/env/<service>.env.template
   ```

   **Step 4: Add container definition to containers.nix**
   ```nix
   virtualisation.oci-containers.containers.<service> = {
     image = "registry/image:tag";
     environmentFiles = [config.age.secrets.<hostname>_docker_env_<service>.path];
     networks = ["servicenet"];  # or datanet, proxynet as needed
     volumes = [
       "/data/docker/<service>/data:/app/data"
     ];
     # For services behind Caddy, no ports needed
     # For direct access, add: ports = ["8080:8080"];
   };
   ```

   **Step 5: Add age.secrets definition**
   Add at the end of `containers.nix`:
   ```nix
   age.secrets.<hostname>_docker_env_<service> = {
     rekeyFile = ./files/docker/env/<service>.env.age;
     mode = "600";
   };
   ```

   **Step 6: Rekey secrets**
   ```bash
   agenix rekey -a
   ```

   **Step 7: Configure access (choose one)**

   **Option A: Reverse Proxy (Caddy)**
   - Update Caddyfile:
     ```bash
     # View current Caddyfile
     agenix view hosts/<hostname>/files/caddy/Caddyfile.age > /tmp/Caddyfile

     # Edit to add new entry:
     # <service>.meskill.farm {
     #   reverse_proxy <service>:8080
     # }

     # Re-encrypt
     rm hosts/<hostname>/files/caddy/Caddyfile.age
     agenix edit -i /tmp/Caddyfile hosts/<hostname>/files/caddy/Caddyfile.age
     rm /tmp/Caddyfile
     ```
   - Container names on `servicenet` are resolvable as hostnames in Caddy
   - Create DNS entry (see DNS Management below)

   **Option B: Direct Port Access**
   - Add port to container definition: `ports = ["8080:8080"];`
   - Add to firewall in containers.nix:
     ```nix
     networking.firewall.allowedTCPPorts = [80 443 8080];  # add your port
     ```

   **Option C: Cloudflare Tunnel**
   - See Cloudflare Tunnels documentation (item 5 below)
   - No firewall ports needed - tunnel handles external access

   **Step 8: Lock agenix when done**
   ```bash
   agenix-helper lock
   ```

   **Step 9: Update documentation**
   - Add service to `hosts/<hostname>/README.md`
   - Update `hosts/README.md` if adding significant new capability

   **Naming Conventions:**
   - Secret names: `<hostname>_docker_env_<service>` (e.g., `pilaster_docker_env_wikijs`)
   - Env files: `hosts/<hostname>/files/docker/env/<service>.env.age`
   - Data volumes: `/data/docker/<service>/`

   **Network Reference:**
   | Network | Purpose | Use When |
   |---------|---------|----------|
   | `servicenet` | Container-to-container communication | Services accessed via Caddy |
   | `datanet` | Internal-only (no external access) | Databases, caches |
   | `proxynet` | Host port binding | Caddy, UDP services, special protocols |

4. **DNS Management**:
   Each container host has a DNS entry `<hostname>.meskill.farm` that can be used as a CNAME target. When adding a new service to Caddy, you must create a corresponding DNS entry.

   **DNS Naming Convention:**
   - Production services: `<service>.meskill.farm`
   - Testing/Staging services: `<service>.x.meskill.farm`
   - Use CNAME records pointing to the host's DNS entry: `<hostname>.meskill.farm`

   **Environment Pattern:**
   | Environment | Domain Pattern | Example |
   |-------------|----------------|---------|
   | Production | `<service>.meskill.farm` | `ai.meskill.farm` → obelisk |
   | Testing/Staging | `<service>.x.meskill.farm` | `ai.x.meskill.farm` → zenith |

   The `x.meskill.farm` subdomain is used for testing new services or configurations before promoting to production. This allows side-by-side testing without affecting production traffic.

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

5. **Cloudflare Tunnels**:
   Cloudflare Tunnels allow exposing services to the internet without opening ports. See existing examples in `hosts/monolith/cloudflared.nix` and `hosts/pilaster/cloudflared.nix`.

   **References:**
   - [NixOS Wiki - Cloudflared](https://wiki.nixos.org/wiki/Cloudflared)
   - [Blog: Nix Cloudflare Tunnels](https://olai.dev/blog/nix-cloudflare-tunnels/)

   **Step 1: Authenticate with Cloudflare (one-time per host)**
   ```bash
   # cloudflared is available in the devshell
   cloudflared tunnel login
   ```
   This opens a browser to authenticate. After success, it creates `~/.cloudflared/cert.pem`.

   **Step 2: Create a tunnel**
   ```bash
   # Create the tunnel (use a descriptive name)
   # cloudflared is available in the devshell
   cloudflared tunnel create <tunnel-name>
   ```
   This outputs:
   - A **tunnel ID** (UUID like `9b4d96ca-4911-46d3-979e-38f3d6dae733`)
   - A **credentials JSON file** at `~/.cloudflared/<tunnel-id>.json`

   **Keep both the cert.pem and JSON file secure** - they grant tunnel access.

   **Step 3: Encrypt secrets with agenix**
   ```bash
   # Create the cloudflared directory for the host
   mkdir -p hosts/<hostname>/files/cloudflared

   # Encrypt the cert.pem (one per host, can be reused for multiple tunnels)
   agenix edit -i ~/.cloudflared/cert.pem hosts/<hostname>/files/cloudflared/cert.pem.age

   # Encrypt the tunnel credentials JSON
   agenix edit -i ~/.cloudflared/<tunnel-id>.json hosts/<hostname>/files/cloudflared/<tunnel-name>.json.age

   # Clean up unencrypted files
   rm ~/.cloudflared/cert.pem ~/.cloudflared/<tunnel-id>.json
   ```

   **Step 4: Create cloudflared.nix**
   Create `hosts/<hostname>/cloudflared.nix`:
   ```nix
   {config, ...}: {
     services.cloudflared = {
       enable = true;
       tunnels = {
         "<tunnel-id>" = {
           credentialsFile = "${config.age.secrets.<hostname>_cloudflared_<tunnel_name>.path}";
           ingress = {"<subdomain>.meskill.farm" = "https://<internal-service>:port";};
           default = "http_status:404";
         };
       };
     };

     # cert.pem is required for tunnel management (creating/deleting tunnels)
     age.secrets.<hostname>_cloudflared_cert_pem = {
       rekeyFile = ./files/cloudflared/cert.pem.age;
       path = "/etc/cloudflared/cert.pem";
       mode = "644";
     };

     # Tunnel credentials JSON
     age.secrets.<hostname>_cloudflared_<tunnel_name> = {
       rekeyFile = ./files/cloudflared/<tunnel-name>.json.age;
       mode = "644";
     };
   }
   ```

   **Step 5: Import in configuration.nix**
   Add to the host's `configuration.nix`:
   ```nix
   imports = [
     ./cloudflared.nix
     # ... other imports
   ];
   ```

   **Step 6: Update Caddyfile with both internal and external domains**
   For tunneled services, Caddy must handle requests for both the internal (`*-int.meskill.farm`) and external (`*.meskill.farm`) domains. Add both domains on the same line:
   ```
   <service>-int.meskill.farm <service>.meskill.farm {
     reverse_proxy <container>:<port>
   }
   ```
   Example:
   ```
   monica-int.meskill.farm monica.meskill.farm {
     reverse_proxy monica:80
   }
   ```
   This is required because the tunnel routes external requests to the internal domain, and Caddy needs to accept both.

   **Step 7: Configure DNS in Cloudflare**
   Two DNS records are required for tunneled services:

   1. **Internal domain** - CNAME pointing to the host (for Caddy to resolve):
      ```bash
      cfcli --domain meskill.farm --type CNAME add <service>-int <hostname>.meskill.farm
      ```

   2. **External domain** - CNAME pointing to the tunnel (for Cloudflare routing):
      ```bash
      cfcli --domain meskill.farm --type CNAME --activate add <service> <tunnel-id>.cfargotunnel.com
      ```

   **Adding additional tunnels to an existing host:**
   1. Create the new tunnel: `cloudflared tunnel create <new-tunnel-name>`
   2. Encrypt the new JSON: `agenix edit -i ~/.cloudflared/<new-tunnel-id>.json hosts/<hostname>/files/cloudflared/<new-tunnel-name>.json.age`
   3. Add a new entry to the `tunnels` attribute set in cloudflared.nix
   4. Add a new `age.secrets` entry for the credentials
   5. Update Caddyfile with both domains: `<service>-int.meskill.farm <service>.meskill.farm { ... }`
   6. Add the internal DNS CNAME: `cfcli --domain meskill.farm --type CNAME add <service>-int <hostname>.meskill.farm`
   7. Add the external DNS CNAME: `cfcli --domain meskill.farm --type CNAME --activate add <service> <tunnel-id>.cfargotunnel.com`

   **Naming conventions:**
   - Secret names: `<hostname>_cloudflared_<purpose>` (e.g., `monolith_cloudflared_n8n_webhook`)
   - Tunnel names: Descriptive of the service (e.g., `n8n-webhook`, `music-assistant`)

6. **Check SSH/GPG agent** before committing:
   ```bash
   ssh-agent-check || echo "Warning: SSH agent not responding"
   ```

7. **All commits must be GPG signed** - never use `--no-gpg-sign`

8. **Documentation Updates**:
   When adding containers, services, or making significant changes to a host, update the relevant documentation:

   **Host-specific README (`hosts/<host>/README.md`):**
   - Add new services to the "Services" section
   - Update container lists if adding Docker containers
   - Document any new network configurations or ports

   **Hosts overview (`hosts/README.md`):**
   - Update host descriptions if adding major new capabilities
   - Update the "Container Orchestration" section if adding Docker to a new host
   - Update the "Infrastructure Services" section for new backup, monitoring, or network services
   - Keep the "Platform Summary" table current

   **Main README (`README.md`):**
   - Update host counts if adding a new host
   - Add new packages to the "Custom Packages" section if applicable

   **Example: Adding a WikiJS container to monolith:**
   ```markdown
   # In hosts/monolith/README.md, add to Services section:
   - **WikiJS**: Documentation wiki (wikijs.meskill.farm)
   ```

9. **MCP Gateway Catalog Management**:
   The MCP Gateway on pilaster uses a custom catalog called `farm-catalog` to define available MCP servers. The catalog and configuration files are managed from this repository.

   **File Locations:**
   ```
   hosts/pilaster/files/docker/mcp/
   ├── catalogs/
   │   ├── docker-mcp.yaml      # Official Docker MCP catalog (reference)
   │   └── farm-catalog.yaml    # Our custom MCP server definitions
   ├── config.yaml              # Gateway configuration
   ├── registry.yaml            # Active server registry
   └── tools.yaml               # Tool configurations
   ```

   These files are copied (not symlinked) to `~/.docker/mcp/` on pilaster via a home-manager activation script. Symlinks won't work because Docker containers can't follow symlinks to paths outside their mounted volumes (like `/nix/store`). See `hosts/pilaster/users/jmeskill/home-configuration.nix`.

   **Current Servers in farm-catalog:**
   | Server | Category | Description |
   |--------|----------|-------------|
   | docker | devops | Use the Docker CLI |
   | gemini-api-docs | ai | Search and retrieve Google Gemini API documentation |
   | git | devops | Git repository interaction and automation |
   | github-official | devops | Official GitHub MCP Server by GitHub |
   | google-flights | travel | Search for flights between airports |
   | postgres | database | Read-only access to PostgreSQL databases |
   | redis | database | Access to Redis database operations |
   | time | devops | Time and timezone conversion capabilities |
   | wikipedia-mcp | devops | Retrieve information from Wikipedia |

   **Catalog Format (version 2):**
   ```yaml
   version: 2
   name: farm-catalog
   displayName: Meskill Farm Catalog
   registry:
     server-name:
       description: "Short description (max 125 chars)"
       title: "Display Name"
       type: "server"
       image: "registry/image:tag"
       secrets:
         - name: "server-name.secret_key"
           env: "SECRET_ENV_VAR"
           example: "example_value"
       env:
         - name: "CONFIG_VAR"
           value: "{{server-name.config_value}}"
       metadata:
         category: "category-name"
         tags: ["tag1", "tag2"]
       source: "https://github.com/org/repo"
   ```

   **Adding a New MCP Server:**

   1. **Find the server in the official catalog or Docker Hub**
      - **Official catalog**: Check `hosts/pilaster/files/docker/mcp/catalogs/docker-mcp.yaml` first
      - **Docker Hub MCP**: Browse https://hub.docker.com/mcp for additional servers
      - Copy the server definition exactly from the official source (including sha256 digest)

   2. **Add the server to farm-catalog.yaml**
      Copy the entry from docker-mcp.yaml or create one matching the official format:
      ```yaml
      # In hosts/pilaster/files/docker/mcp/catalogs/farm-catalog.yaml
      registry:
        # ... existing servers ...
        new-server:
          description: "Description from official catalog"
          title: "Server Title"
          type: server
          image: mcp/server-name@sha256:abc123...  # Use digest, not :latest
          source: https://github.com/org/repo
          upstream: https://github.com/org/repo
          secrets:  # Only if required
            - name: new-server.api_key
              env: API_KEY
              example: <YOUR_TOKEN>
          metadata:
            category: category-name
            tags:
              - tag1
              - tag2
            license: MIT License
            owner: owner-name
      ```

   3. **Register the server in registry.yaml**
      The registry tracks which servers are active. Add an entry for each server you want enabled:
      ```yaml
      # In hosts/pilaster/files/docker/mcp/registry.yaml
      registry:
        # ... existing servers ...
        new-server:
          ref: ""
      ```
      - The key must match the server name in farm-catalog.yaml
      - The `ref` field can be empty for the default/latest version
      - Without a registry entry, the server won't be available to clients

   4. **Add secrets to mcp-gateway.env.age** (if required)
      ```bash
      # View current secrets
      agenix view hosts/pilaster/files/docker/env/mcp-gateway.env.age > /tmp/mcp.env

      # Add new secret (use the format: server-name.secret_key=value)
      echo 'new-server.api_key=your-actual-key' >> /tmp/mcp.env

      # Re-encrypt
      rm hosts/pilaster/files/docker/env/mcp-gateway.env.age
      agenix edit -i /tmp/mcp.env hosts/pilaster/files/docker/env/mcp-gateway.env.age
      rm /tmp/mcp.env
      ```

   5. **Deploy changes**
      The gateway uses `--watch=true`, so changes to the catalog file are picked up automatically after deployment:
      ```bash
      sudo nixos-rebuild switch --flake .#pilaster
      ```

   **Secret Naming Convention:**
   - Format: `server-name.secret_key` (e.g., `github.personal_access_token`)
   - The `name` in the catalog's `secrets` array must match the key in the env file
   - The `env` field specifies the environment variable name passed to the container

   **Finding MCP Servers:**
   - **Official catalog** (local): `hosts/pilaster/files/docker/mcp/catalogs/docker-mcp.yaml`
   - **Docker Hub MCP**: https://hub.docker.com/mcp (browse all available servers)
   - Always use the `@sha256:...` digest from the official catalog, not `:latest`

   **References:**
   - [Docker MCP Gateway Docs](https://docs.docker.com/ai/mcp-catalog-and-toolkit/mcp-gateway/)
   - [MCP Catalog Format](https://github.com/docker/mcp-gateway/blob/main/docs/catalog.md)
   - [Docker Hub MCP Catalog](https://hub.docker.com/mcp)

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
- agenix commands cannot be run inside the sandbox
