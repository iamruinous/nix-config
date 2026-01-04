# docker-image-updater

A beautiful interactive TUI tool for checking and updating Docker image versions in NixOS container configurations.

## Overview

This tool scans your `hosts/**/containers.nix` files, extracts Docker image references, checks for available updates using container registries, and provides an interactive interface to selectively apply updates.

Written in Go using [Bubbletea](https://github.com/charmbracelet/bubbletea) for the terminal UI.

## Features

- **Automatic Discovery**: Scans all `containers.nix` files under `hosts/` directory
- **Multi-Registry Support**: Works with Docker Hub, GitHub Container Registry (ghcr.io), and other OCI-compliant registries
- **Version Detection**: Intelligently detects versioned tags and finds newer versions using semantic versioning
- **Version Pinning**: Pin images to major/minor versions using Cargo-style constraints
- **Floating Tag Detection**: Identifies when floating tags (like `latest`) have new digests available
- **Interactive TUI**: Beautiful Bubbletea-powered interface for selecting which images to update
- **Flexible Update Options**:
  - Update all images at once
  - Update all images for a specific host
  - Select individual images to update
  - Generate update commands without applying

## Installation

This package is automatically available in the nix-config flake. To use it:

```nix
environment.systemPackages = with pkgs; [
  docker-image-updater
];
```

Or run it directly:

```bash
nix run .#docker-image-updater
```

## Usage

### Basic Usage

Run from your nix-config directory:

```bash
docker-image-updater
```

### Specify Config Path

```bash
docker-image-updater --path /path/to/nix-config
```

Or use the environment variable:

```bash
NIX_CONFIG_PATH=/path/to/nix-config docker-image-updater
```

### Filter by Host

Only check containers for a specific host:

```bash
docker-image-updater --host monolith
```

### Limit Number of Containers

Limit the number of containers to check (useful for testing or when rate-limited):

```bash
docker-image-updater --limit 10
docker-image-updater --host monolith --limit 5
```

### Dry-Run Mode

Only scan and list containers without checking for updates:

```bash
docker-image-updater --dry-run
docker-image-updater --dry-run --host monolith
```

### Non-Interactive Mode

For CI/CD or scripting, use non-interactive mode to just display available updates:

```bash
docker-image-updater --non-interactive
```

### Command Line Options

| Option | Description |
|--------|-------------|
| `-p, --path PATH` | Path to nix-config directory (default: current directory) |
| `-H, --host HOST` | Only check containers for a specific host |
| `-c, --containers LIST` | Only check specific containers (comma-separated) |
| `-l, --limit N` | Limit the number of containers to check |
| `-t, --max-tags N` | Max tags to fetch per image (default 50, 0 for all) |
| `-i, --check-image IMG` | Check a single Docker image for updates |
| `--dry-run` | Only scan containers, skip checking for updates |
| `--non-interactive` | Run without interactive prompts |
| `--apply-all` | Apply all available updates (implies --non-interactive) |
| `--clear-cache` | Clear the cache before running |
| `--no-cache` | Disable caching for this run |
| `-v, --version` | Show version |
| `-h, --help` | Show help message |

## Interactive Menu

When updates are found, you'll be presented with options:

1. **All images** - Update all discovered images with available updates
2. **All images for a specific host** - Select a host and update all its containers
3. **Individual images** - Multi-select specific containers to update
4. **Show update commands only** - Display the changes without applying them
5. **Exit** - Exit without making changes

### Keyboard Navigation

- `↑/↓` or `j/k` - Navigate up/down
- `Enter` - Select option
- `Space` - Toggle selection (in multi-select mode)
- `q` or `Ctrl+C` - Quit
- `Esc` - Go back

## How It Works

### Image Discovery

The tool parses Nix files looking for the `virtualisation.oci-containers.containers` structure and extracts `image` attributes.

### Version Checking

For each discovered image:

1. **Versioned tags** (e.g., `v1.2.3`, `2.10.0`): Lists all tags from the registry and finds the latest version using semantic versioning
2. **Floating tags** (e.g., `latest`, `stable`): Compares digests to detect if newer content is available

### Version Pinning

You can pin images to specific version ranges using the `# IMAGECHECK: pin <constraint>` directive. This uses Cargo-style version requirements to limit which updates are considered.

#### Constraint Syntax

| Constraint | Meaning | Example |
|------------|---------|---------|
| `~X` | Same major version | `~4` allows 4.0.0 to 4.99.99 |
| `~X.Y` | Same major.minor | `~4.0` allows 4.0.0 to 4.0.99 |
| `~X.Y.Z` | Patch updates only | `~4.0.16` allows 4.0.16 to 4.0.99 |
| `^X.Y.Z` | SemVer compatible | `^1.2.3` allows 1.2.3 to 1.99.99 |
| `^0.Y.Z` | Minor locked for 0.x | `^0.2.3` allows 0.2.3 to 0.2.99 |
| `X.*` | Wildcard major | `1.*` allows 1.0.0 to 1.99.99 |
| `X.Y.*` | Wildcard minor | `1.2.*` allows 1.2.0 to 1.2.99 |
| `=X.Y.Z` | Exact version | `=1.2.3` only allows 1.2.3 |
| `>=X.Y.Z` | Greater or equal | `>=1.0.0` allows 1.0.0 and above |
| `>X.Y.Z` | Greater than | `>1.0.0` allows 1.0.1 and above |
| `<X.Y.Z` | Less than | `<2.0.0` allows up to 1.99.99 |
| `<=X.Y.Z` | Less or equal | `<=2.0.0` allows up to 2.0.0 |
| `>=X,<Y` | Range | `>=1.0,<2.0` allows 1.0.0 to 1.99.99 |

#### Usage Examples

```nix
containers = {
  # Pin to major version 4 - allows 4.0.0 through 4.99.99
  sonarr = {
    # IMAGECHECK: pin ~4
    image = "lscr.io/linuxserver/sonarr:4.0.16";
  };

  # Pin to same line
  postgres = {
    image = "postgres:17.1"; # IMAGECHECK: pin ^17
  };

  # Pin to minor version - allows 1.27.x only
  nginx = {
    # IMAGECHECK: pin ~1.27
    image = "nginx:1.27.0";
  };

  # Exact version - no updates
  legacy = {
    # IMAGECHECK: pin =1.0.0
    image = "legacy-app:1.0.0";
  };

  # Version range
  redis = {
    # IMAGECHECK: pin >=7.0,<8.0
    image = "redis:7.2.0";
  };
};
```

### Registry Normalization

Images are automatically normalized to their full registry paths:
- `nginx` → `docker.io/library/nginx`
- `username/image` → `docker.io/username/image`
- `ghcr.io/org/image` → `ghcr.io/org/image` (unchanged)

## Examples

### Example Output (Non-Interactive)

```
=== Docker Image Updater ===
    for NixOS Configurations

Found 45 containers across 4 hosts

Checking for updates...
[45/45] Checking pilaster/authentik...
Found 3 available updates (checked 45 containers)

=== Available Updates ===

HOST            CONTAINER            CURRENT         LATEST
----            ---------            -------         ------
monolith        postgres             17              18
obelisk         ollama               0.12.5          0.12.6
pilaster        authentik            2025.10.2       2025.11.1

=== Update Commands ===

Host: monolith
Container: postgres
Current: postgres:17
New: postgres:18
File: /path/to/nix-config/hosts/monolith/containers.nix

To update manually:
  sed -i 's|postgres:17|postgres:18|g' /path/to/nix-config/hosts/monolith/containers.nix
```

## Performance

By default, the tool only fetches 50 tags per image, providing an order of magnitude speedup compared to fetching all tags. This is sufficient for detecting recent version increments.

- **Default behavior**: Fetch 50 most recent tags (~0.5-1s per image)
- **Thorough check**: Use `--max-tags 0` to fetch all tags (slower but comprehensive)
- **Fast check**: Use `--max-tags 25` for even faster checks on well-maintained images

The tool uses the [go-containerregistry](https://github.com/google/go-containerregistry) library for direct registry API access with pagination support.

## Dependencies

No external runtime dependencies. The tool uses a pure Go implementation for all registry operations.

## Limitations

- Only scans files named `containers.nix` under the `hosts/` directory
- Requires network access to query container registries
- Cannot automatically update floating tags (shows notification instead)
- Private registries use credentials from `~/.docker/config.json`

## Tips

### Before Running Updates

1. Ensure you're in a git repository so changes can be reviewed/reverted
2. Run `git status` to check for uncommitted changes
3. Consider running with `--non-interactive` first to preview changes

### After Applying Updates

1. Review changes with `git diff`
2. Test the build: `nixos-rebuild dry-build --flake .#<hostname>`
3. Commit changes if build succeeds

## Troubleshooting

### "No containers found"

Ensure you're running from the nix-config root directory or specify the path with `--path`.

### Rate limiting

Container registries may rate-limit unauthenticated requests. The `--max-tags` option helps reduce API calls. For heavy usage, authenticate with your registry.

### Private registry authentication

For private registries, configure credentials in `~/.docker/config.json`. The tool uses the standard Docker credential chain.

## Related Packages

- **backup-docker-postgres** - Automated PostgreSQL backups for Docker
- **backup-docker-mariadb** - Automated MariaDB backups for Docker

## Version History

### 2.4.0

- **Major performance improvement**: Tag fetching now uses pagination
- Added `--max-tags` flag to limit tags fetched per image (default: 50)
- Replaced skopeo with go-containerregistry library for direct registry access
- No external runtime dependencies required
- Order of magnitude speedup for images with many tags

### 2.0.0

- Complete rewrite in Go using Bubbletea TUI framework
- Improved version detection with semantic versioning
- Better terminal handling and keyboard navigation
- Simpler dependency footprint (only skopeo required at runtime)

### 1.0.0

- Initial release (shell script version)
- Interactive update selection with gum
- Multi-registry support via skopeo
- Host-level and individual container updates
- Non-interactive mode for scripting
