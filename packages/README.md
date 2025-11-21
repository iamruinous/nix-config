# Custom Packages

This directory contains custom Nix packages developed specifically for this infrastructure. These packages are not available in the standard nixpkgs repository and provide specialized functionality for various hosts.

## Available Packages

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

## Usage

These packages are automatically available to all hosts in this flake. To use them in a host configuration:

```nix
environment.systemPackages = with pkgs; [
  docker-mcp-gateway
  forgejo-shell
  messy-restricted-shell
  nelko-pl70ebt
];
```

Or for specific use cases:

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
