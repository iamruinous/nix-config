---
name: update-package
description: Update a local Nix package to a new version with automatic hash resolution
compatibility: Requires nix
metadata:
  author: ruinous.ai
  version: "1.1"
  domain: packaging
parameters:
  package_name:
    type: string
    description: Name of existing package in packages/ directory
    required: true
    placeholder: "forgejo-mcp"
  new_version:
    type: string
    description: New version or tag to update to
    required: true
    placeholder: "2.6.0"
---

# Update Package

Update a local Nix package in `packages/` to a new version, automatically resolving the new hash.

## Parameter Handling

**If parameters are missing from `$ARGUMENTS`, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "Which package do you want to update?",
      header: "Package",
      options: [
        { label: "Enter package name...", description: "e.g., forgejo-mcp, weaviate-cli" }
      ]
    },
    {
      question: "What version should it be updated to?",
      header: "Version",
      options: [
        { label: "Enter version...", description: "e.g., 2.6.0, v3.3.0" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `<package_name> <new_version>`
- Example: `forgejo-mcp 2.6.0`
- Example: `weaviate-cli v3.3.0`

## Steps

### 1. Read the current package definition

```bash
cat packages/<package-name>/default.nix
```

Identify:
- Current `version` value
- Hash field location (`hash`, `sha256`, `vendorHash`, `cargoHash`)
- Fetch method (`fetchFromGitHub`, `fetchurl`, `fetchzip`, `fetchgit`)

### 2. Update the version

Edit `packages/<package-name>/default.nix`:
- Update `version = "X.Y.Z";` to the new version
- If version has `v` prefix in tag but not in version string, strip it

### 3. Replace hash(es) with placeholder

Replace the existing hash with `lib.fakeHash` or the placeholder string:

```nix
# For sha256/hash fields:
hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

# Or use lib.fakeHash:
hash = pkgs.lib.fakeHash;
```

**Common hash fields to update:**
- `hash` or `sha256` - Source archive hash
- `vendorHash` - Go module dependencies (buildGoModule)
- `cargoHash` - Rust dependencies (buildRustPackage)

### 4. Run test build to get correct hash

```bash
nix build .#<package-name> 2>&1 | grep -E "(got:|hash mismatch)" | head -5
```

The output will contain the correct hash:
```
error: hash mismatch in fixed-output derivation
  got:    sha256-CORRECT_HASH_HERE=
```

### 5. Update with correct hash

Replace the placeholder with the actual hash from the error output.

### 6. Handle vendorHash/cargoHash (if applicable)

For Go packages (`buildGoModule`):
```bash
# After fixing source hash, build again to get vendorHash
nix build .#<package-name> 2>&1 | grep "got:"
```

For Rust packages (`buildRustPackage`):
```bash
# After fixing source hash, build again to get cargoHash
nix build .#<package-name> 2>&1 | grep "got:"
```

### 7. Final verification build

```bash
nix build .#<package-name>
```

Ensure build completes successfully.

### 8. Test the built package

```bash
./result/bin/<program> --version
# or
./result/bin/<program> --help
```

## Hash Placeholder Reference

| Hash Type | Placeholder |
|-----------|-------------|
| SRI format | `sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=` |
| lib.fakeHash | `pkgs.lib.fakeHash` |
| Old base32 | `0000000000000000000000000000000000000000000000000000` |

## Example: Updating forgejo-mcp

```bash
/update-package forgejo-mcp 2.6.0
```

**Before:**
```nix
version = "2.5.0";
src = pkgs.fetchurl {
  url = "https://codeberg.org/goern/forgejo-mcp/archive/v${version}.tar.gz";
  hash = "sha256-oT2AYvMv0L6CBRNYi0ph6NaQQOMsROqQ8BPTDL8okcI=";
};
vendorHash = "sha256-tOTRbc735TrIZ7fL9EywKLLlePKWMMCeuhbQJGHUuk4=";
```

**Step 1 - Update version and placeholder:**
```nix
version = "2.6.0";
src = pkgs.fetchurl {
  url = "https://codeberg.org/goern/forgejo-mcp/archive/v${version}.tar.gz";
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
};
vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

**Step 2 - Build, extract source hash:**
```bash
nix build .#forgejo-mcp 2>&1 | grep "got:"
# got: sha256-NEW_SOURCE_HASH=
```

**Step 3 - Update source hash, build again for vendorHash:**
```bash
nix build .#forgejo-mcp 2>&1 | grep "got:"
# got: sha256-NEW_VENDOR_HASH=
```

**Step 4 - Update vendorHash, final build:**
```bash
nix build .#forgejo-mcp
./result/bin/forgejo-mcp --version
```

## Example: Updating Python package

```bash
/update-package weaviate-cli 3.3.0
```

Python packages typically only have one hash (source):
```nix
version = "3.3.0";
src = pkgs.fetchFromGitHub {
  owner = "weaviate";
  repo = "weaviate-cli";
  rev = "v${version}";
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
};
```

## Common Fetch Methods

| Method | URL Pattern | Hash Field |
|--------|-------------|------------|
| `fetchFromGitHub` | GitHub repos | `hash` |
| `fetchurl` | Direct URL | `hash` or `sha256` |
| `fetchzip` | Release archives | `sha256` |
| `fetchgit` | Git repos | `hash` |

## Troubleshooting

### Build fails after hash update
- Check if version tag format changed (e.g., `v2.0.0` vs `2.0.0`)
- Verify URL is still valid for new version
- Check if build system changed (e.g., switched to pyproject.toml)

### Multiple hash errors
- Update hashes one at a time
- Source hash first, then vendorHash/cargoHash

### Package renamed or moved
- Check upstream for new URL patterns
- Update `owner`, `repo`, or URL template as needed

## Post-Update Checklist

- [ ] Version updated in default.nix
- [ ] All hashes updated (source, vendor/cargo if applicable)
- [ ] Final build succeeds: `nix build .#<package>`
- [ ] Binary/program works: `./result/bin/<program> --version`
- [ ] Update README.md if version is mentioned
- [ ] Update packages/README.md if needed
