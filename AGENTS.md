# AI Agent Development Guidelines

This document provides build/lint/test commands and code style guidelines for AI agents working in this NixOS configuration repository.

## Build Commands

### Core Commands
```bash
# Update flake inputs
make update-flake

# Build configurations (dry-run for testing)
nix build .#<hostname>  # Build specific host config
nix build .#<package>    # Build specific package

# Deploy to systems
nixos-rebuild switch --flake .#<hostname>    # NixOS hosts
darwin-rebuild switch --flake .#<hostname>   # macOS hosts
make remote-rebuild remotehost=<hostname>    # Remote deployment

# Testing/verification
make remote-dry-build remotehost=<hostname> # Test build without deploying
make check                     # Comprehensive CI-style check
```

### Package Development
```bash
# Build package in devshell
nix develop .#<devshell-name>   # Enter appropriate devshell
nix build .#<package-name>      # Build package
alejandra .                     # Format Nix code
```

### Development Shells
Available devshells in `devshells/`:
- `default`: General development
- `python313`: Python 3.13 development
- `nodejs`, `bun`: JavaScript/Node.js development
- `n8n-node-dev`: n8n node development
- `pdftools`: PDF manipulation tools

## Code Style Guidelines

### Nix Formatting
- **Formatter**: `alejandra` (auto-formats Nix files)
- **Style**: Follow alejandra's default formatting
- **File organization**: Group related configurations together

### Package Structure Template
```nix
{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "package-name";
  version = "x.x.x";
  
  src = pkgs.lib.cleanSource ./.;
  
  buildInputs = [ pkgs.dependency1 ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  
  dontUnpack = true;  # For script-only packages
  
  buildPhase = ''
    # Build commands
  '';
  
  installPhase = ''
    # Installation commands
    mkdir -p $out/bin
    cp script.sh $out/bin/
    chmod +x $out/bin/script.sh
    
    # Wrap runtime dependencies if needed
    wrapProgram $out/bin/script.sh \
      --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.dependency1]}
  '';
  
  meta = with pkgs.lib; {
    description = "Brief description of the package";
    homepage = "https://github.com/iamruinous/nix-config";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "executable-name";
    platforms = platforms.unix;
  };
}
```

### Import Ordering
```nix
# In flake.nix - inputs section
{
  # Core inputs first
  nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  home-manager.url = "github:nix-community/home-manager";
  
  # Automation/framework
  blueprint.url = "github:numtide/blueprint";
  
  # Specialized inputs (alphabetical)
  agenix.url = "github:ryantm/agenix";
  disko.url = "github:nix-community/disko/latest";
}

# In host configurations
{
  imports = [
    ./hardware-configuration.nix          # Core first
    ../../modules/nixos/common            # Shared modules
    ../../modules/nixos/server            
    ./containers.nix                      # Host-specific
  ];
}
```

### Naming Conventions
- **Files**: kebab-case (`containers.nix`, `cloudflared.nix`)
- **Packages**: kebab-case (`docker-image-updater`)
- **Hosts**: lowercase, hyphenated (`framework`, `monolith`)
- **Secrets**: `<hostname>_<purpose>_<service>` (e.g., `monolith_docker_env_n8n`)
- **Attributes**: camelCase for Nix attributes (`system.configuration`)

### Error Handling
- **Shell scripts**: Always use `set -euo pipefail`
- **Nix packages**: Include proper `buildInputs` and `nativeBuildInputs`
- **Dependencies**: Use `wrapProgram` for runtime dependencies

## Testing Strategy

### Before Committing
1. **Verify builds**: Always test before committing
   ```bash
   make remote-dry-build remotehost=<affected-host>
   nix build .#<affected-package>
   ```

2. **Format code**: Run formatter on all changes
   ```bash
   alejandra .
   ```

3. **Check SSH agent**: Ensure responsive for commits
   ```bash
   ssh-agent-check
   ```

### Single Package Testing
```bash
# Build only your package
nix build .#docker-image-updater

# Test with specific devshell
nix develop .#default
nix build .#your-package
```

## Repository Conventions

### Blueprint Integration
This project uses Blueprint for automatic discovery:
- `hosts/` → Auto-discovered host configurations
- `modules/` → Auto-discovered modules
- `packages/` → Auto-discovered packages (available as overlay)
- `devshells/` → Auto-discovered development shells

### Git Workflow
- **Protected main**: All changes via pull requests
- **Conventional commits**: Use `feat:`, `fix:`, `docs:`, `chore:`
- **Signed commits**: All commits must be GPG signed
- **Feature branches**: Use `feat/`, `fix/`, `docs/` prefixes

### Platform Detection
```nix
lib.mkIf pkgs.stdenv.isLinux [ ... ]
lib.mkIf pkgs.stdenv.isDarwin [ ... ]
```

## Special Considerations

### Secrets Management
- **Never commit unencrypted secrets**
- **Use agenix**: All `.age` files are encrypted
- **Templates**: Create `.env.template` files for Docker environment variables

### Container Patterns
- **Networks**: Use `servicenet`, `datanet`, or `proxynet` appropriately
- **Naming**: Container names become hostnames on their networks
- **Environment**: Store secrets in encrypted `.env.age` files

### Module Structure
- **Modular**: Reusable components in `modules/`
- **Platform-specific**: Separate directories for `nixos`, `darwin`, `home`
- **Shared**: Common utilities in `modules/shared/`

## Quality Gates

### Pre-commit Checklist
- [ ] Code formatted with `alejandra`
- [ ] Build passes with `make check` or `nix build`
- [ ] SSH agent responsive
- [ ] Conventional commit message
- [ ] No unencrypted secrets in changes
- [ ] Documentation updated for significant changes

### CI Validation
The GitHub workflow validates:
- Flake syntax
- Representative host builds (framework, monolith, jbookpro, rp500, rpc-4-echo)
- Cross-platform compatibility

When in doubt, build locally before committing. The `make check` command replicates the CI pipeline.