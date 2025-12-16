# Custom Packages

This directory contains custom Nix packages developed specifically for this infrastructure. These packages are not available in the standard nixpkgs repository and provide specialized functionality for various hosts.

## Available Packages

### [agenix-helper](agenix-helper/README.md)

Helper utility for managing passphrase-protected age identities.

**Purpose**: Simplifies working with encrypted age identities by providing unlock/lock commands. Decrypt your identity once per session and reuse it for all agenix operations.

**Key Features**:
- One-time unlock per session (no repeated passphrase prompts)
- Temporary storage in `/tmp/id_age` with `600` permissions
- Automatic direnv integration
- Quiet mode for scripting
- Simple commands: `unlock`, `lock`, `status`

**Used By**: All hosts (development workflow for managing encrypted secrets)

**Dependencies**: age, coreutils

**Version**: 0.1.0

---

### [backup-docker-mariadb](backup-docker-mariadb/README.md)

Automated backup solution for MariaDB databases running in Docker containers.

**Purpose**: Provides scheduled backups of all MariaDB databases (excluding system databases) with integrated NixOS module support.

**Key Features**:
- Automatic database discovery and backup
- Excludes system databases (information_schema, performance_schema, mysql, sys)
- Daily scheduled backups at 01:30 via systemd timer
- Integrated NixOS module with options
- Secure password management via environment files
- SQL dump format backups

**Used By**: Hosts running MariaDB in Docker containers

**Dependencies**: docker, coreutils

**NixOS Usage**:
```nix
ruinous.mariadb.docker.backup.enable = true;
```

---

### [backup-docker-postgres](backup-docker-postgres/README.md)

Automated backup solution for PostgreSQL databases running in Docker containers.

**Purpose**: Provides scheduled backups of all PostgreSQL databases (excluding system databases) with integrated NixOS module support.

**Key Features**:
- Automatic database discovery and backup
- Excludes system databases (template0, template1, postgres)
- Daily scheduled backups at 01:00 via systemd timer
- Integrated NixOS module with options
- Compressed custom format backups (pg_dump -Fc -Z 9)
- No-owner, no-privileges dumps for portability

**Used By**: Hosts running PostgreSQL in Docker containers

**Dependencies**: docker, gawk, coreutils

**NixOS Usage**:
```nix
ruinous.postgres.docker.backup.enable = true;
```

---

### [docker-mcp-gateway](docker-mcp-gateway/README.md)

Docker CLI plugin for MCP (Model Context Protocol) gateway.

**Purpose**: Enables integration between Docker and the Model Context Protocol, allowing AI assistants and tools to interact with Docker environments.

**Key Features**:
- Docker CLI plugin integration
- MCP protocol support for Docker operations
- Secure, controlled access to Docker functionality
- Compatible with Docker Desktop's MCP Toolkit

**Used By**: Development systems requiring AI-assisted Docker operations

**Dependencies**: Docker

**Version**: 0.28.0

---

### [forgejo-shell](forgejo-shell/README.md)

SSH shell wrapper for Forgejo Git hosting in Docker.

**Purpose**: Bridges SSH connections to a Forgejo Docker container, enabling Git operations over SSH.

**Key Features**:
- Executes commands inside the `forgejo` Docker container as the `git` user
- Passes SSH commands via `SSH_ORIGINAL_COMMAND` environment variable
- Minimal wrapper script for seamless Git hosting

**Used By**: monolith (for Git hosting services)

**Dependencies**: Docker

---

### [messy-restricted-shell](messy-restricted-shell/README.md)

Restricted shell with whitelisted commands for limited SSH access.

**Purpose**: Provides a secure, limited-access shell environment that only allows specific read-only commands.

**Key Features**:
- Validates all commands before execution
- Whitelisted commands:
  - `ls` with common flags
  - `docker ps`, `docker images`, `docker logs`
- Prevents command injection and unauthorized access
- All validation errors logged to stderr

**Used By**: Systems requiring restricted user access

**Dependencies**: bash, docker

---

### [nelko-pl70ebt](nelko-pl70ebt/README.md)

CUPS printer driver for the Nelko PL70e-BT Bluetooth label printer.

**Purpose**: Enables printing to Nelko PL70e-BT label printers on NixOS systems.

**Key Features**:
- Extracts driver from vendor .deb package
- Installs PPD files for PL70e-BT and PL420 models
- Includes `rastertolabel` CUPS filter
- Full CUPS integration

**Used By**: monolith, framework, obelisk (systems with printing enabled)

**Dependencies**: CUPS

**Version**: 3.0.1.407

---

### [ssh-agent-check](ssh-agent-check/README.md)

Fast, cached SSH agent availability checker.

**Purpose**: Checks if the SSH agent is available and responding, with intelligent caching to avoid repeated ssh-add calls.

**Key Features**:
- Caches results based on SSH_AUTH_SOCK value
- Only re-checks when SSH_AUTH_SOCK changes
- Near-instant response for repeated checks
- Shell-agnostic (works in bash, fish, zsh, etc.)
- Simple exit codes: 0 = working, 1 = not responding

**Used By**:
- `modules/home/default/fish.nix` - Shell startup warning
- `modules/home/default/starship.nix` - Prompt indicator

**Dependencies**: openssh

**Performance**: <1ms for cached checks, ~10-50ms for fresh checks

---

### [pinentry-1password](pinentry-1password/README.md)

Pinentry-compatible program using 1Password CLI for passphrase retrieval.

**Purpose**: Allows programs like `rage`, `gpg-agent`, and other pinentry-compatible tools to retrieve secrets from 1Password.

**Key Features**:
- Implements standard pinentry protocol
- Retrieves secrets from 1Password using `op` CLI
- Works with age/rage, GPG, and other pinentry-compatible programs
- Automatic integration with agenix-helper
- No secrets stored on disk

**Used By**: Development systems with 1Password CLI integration

**Dependencies**: 1Password CLI (`op`), coreutils

**Version**: 0.1.0

---

## Usage

These packages are automatically available to all hosts in this flake. To use them in a host configuration:

```nix
environment.systemPackages = with pkgs; [
  agenix-helper
  backup-docker-mariadb
  backup-docker-postgres
  docker-mcp-gateway
  forgejo-shell
  messy-restricted-shell
  nelko-pl70ebt
  pinentry-1password
  ssh-agent-check
];
```

Or for specific use cases:

### As NixOS Modules with Systemd Services

```nix
# Enable automated database backups
ruinous.postgres.docker.backup.enable = true;
ruinous.mariadb.docker.backup.enable = true;

# Customize with EnvironmentFile for secure credentials
systemd.services.mariadb-backup.serviceConfig.EnvironmentFile = "/run/secrets/mariadb-env";
```

### As a Login Shell
```nix
users.users.git = {
  shell = pkgs.forgejo-shell;
  # ...
};
```

### For Printing
```nix
services.printing = {
  enable = true;
  drivers = [ pkgs.nelko-pl70ebt ];
};
```

## Package Structure

Each package follows the standard Nix package structure:

```
packages/<package-name>/
├── default.nix          # Nix package derivation
├── README.md           # Package documentation
└── [source files]      # Additional package-specific files
```

## Adding a New Package

1. Create a new directory under `packages/` with your package name
2. Add a `default.nix` file with the package derivation
3. Create a `README.md` documenting the package's purpose and usage
4. The Blueprint system will automatically discover and expose it
5. Reference it in host configurations as needed

Example minimal `default.nix`:

```nix
{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "my-package";
  version = "1.0.0";

  # Package definition...

  meta = {
    description = "My custom package";
    platforms = ["x86_64-linux"];
  };
}
```
