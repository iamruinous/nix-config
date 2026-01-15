# codey-docs

Nix package for the Codey documentation site.

## Overview

This package fetches the codey-docs repository from Forgejo, builds it with MkDocs Material, and outputs the static site to the Nix store.

## Usage

```bash
# Build the package
nix build .#codey-docs

# View output
ls -la result/

# Test locally
python -m http.server --directory result/ 8000
```

## Deployment

The package is deployed to chassis via Caddy configuration in `hosts/chassis/caddy.nix`.

## Updating

When a new version is released in codey-docs:

1. Update `version = "X.Y.Z";` in `default.nix`
2. Update `rev = "vX.Y.Z";`
3. Clear hash: `hash = "";`
4. Run `nix build .#codey-docs` (will fail with correct hash)
5. Copy hash from error and update `hash = "sha256-...";`
6. Commit: `git commit -S -m "feat(codey-docs): update to vX.Y.Z"`
7. Deploy: `just linux-rebuild` (on chassis) or `just remote-rebuild chassis`

## Hash Prefetch

Alternatively, use nix-prefetch-url:

```bash
nix-prefetch-url --unpack \
  "https://forge.meskill.farm/iamruinous/codey-docs/archive/v0.1.0.tar.gz"
```

## Dependencies

- `python3`
- `python3Packages.mkdocs-material`

## Build Process

1. Fetch source from Forgejo using `fetchFromGitea`
2. Run `mkdocs build --strict`
3. Copy `site/*` to `$out`

## Verification

```bash
# Check package builds
nix build .#codey-docs

# Verify content
ls result/
# Should contain: index.html, protocols/, capabilities/, etc.

# Test serving
python -m http.server --directory result/ 8000
# Open http://localhost:8000
```
