# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `messy-discord-bot`: Discord bot for Messy personal assistant
  - Forwards Discord messages to n8n webhook
  - Shows typing indicator while processing
  - Handles long message responses by splitting into chunks
  - Deployed as Docker container on monolith
- `docker-image-updater` v2.2.0: Added `--apply-all` flag for automated updates
  - New `--apply-all` flag automatically applies all available container image updates
  - Suitable for CI/CD and automated workflows
- GitHub Actions workflow for automated Docker image update checks
  - Runs weekly on Mondays at 9:00 UTC
  - Automatically creates PRs when container image updates are available
  - Can also be triggered manually via workflow_dispatch

### Changed
- Migrated session logging from `SESSION_LOG.md` to `CHANGELOG.md` following Keep a Changelog format

## [2025-11-25]

### Added
- `ssh-agent-check`: Added `--help` and `-h` flags with comprehensive usage documentation
- Stricter error handling (`set -euo pipefail`) for ssh-agent-check script

## [2025-11-24]

### Added
- **Supabase Full Stack Deployment** on pilaster host
  - 12 Supabase container definitions (studio, kong, auth, rest, realtime, storage, imgproxy, meta, functions, analytics, vector, pooler)
  - Kong API gateway configuration with declarative routing
  - Vector log aggregation configuration
  - Environment file templates for secure secret management
  - Comprehensive setup documentation (`hosts/pilaster/SUPABASE_SETUP.md`)
- `pinentry-1password`: New package for 1Password CLI integration with pinentry protocol
  - Compatible with rage, age, GPG, and other pinentry-aware programs
  - Proper Assuan protocol implementation
- Custom AI agent framework (`.claude/agents/`)
  - `nix-packager` agent for specialized NixOS packaging expertise

### Changed
- **Backup packages refactored** (`backup-docker-postgres`, `backup-docker-mariadb`)
  - Extracted shell scripts to separate `.sh` files for better maintainability
  - Converted from `writeShellApplication` to `stdenv.mkDerivation` with template substitution
  - Added 8 comprehensive NixOS module configuration options each
  - Enhanced documentation with complete usage examples
- `agenix-helper`: Switched from `age` to `rage` for better pinentry support
  - Automatic 1Password integration detection
  - Falls back to interactive prompt if 1Password unavailable
- Shell scripts extracted to separate files for all custom packages:
  - `agenix-helper.sh`, `ssh-agent-check.sh`, `forgejo-shell.sh`, `pinentry-1password.sh`

### Fixed
- `pinentry-1password`: Proper Assuan protocol implementation
  - Added initial greeting and comprehensive command support
  - Fixed GPG error codes and command parsing

## [2025-11-23]

### Added
- `ssh-agent-check` package with intelligent caching
  - Fast SSH agent availability checking (<1ms cached)
  - Shell-agnostic implementation (works in bash, fish, zsh)
  - Exit codes: 0 = agent working, 1 = not responding
- `agenix-helper` package for managing passphrase-protected age identities
  - unlock/lock/status commands
  - Quiet mode for direnv integration
  - One-time unlock per session
- Nutify container configuration on pilaster host
- Encrypted environment file support for containers via agenix
- SSH agent visual indicator in starship prompt (󰌆 symbol)
- Docker Caddy auto-restart on Caddyfile changes (4 hosts)
- `AGENTS.md` with comprehensive AI agent guidelines

### Changed
- Shell integration simplified to use `ssh-agent-check` package
- Starship configuration for real-time SSH agent validation
