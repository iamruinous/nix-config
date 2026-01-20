---
name: update-flake-input
description: Update a versioned flake input to the latest tagged version from its source repository
compatibility: Requires nix, curl, jq
metadata:
  author: ruinous.ai
  version: "1.0"
  domain: flake-management
parameters:
  input_name:
    type: select
    description: Name of the flake input to update
    required: true
    options:
      - label: "ruinagents"
        description: "Agent definitions, docs, and skills"
      - label: "budgey-extractor"
        description: "OpenCode session extractor for Postgres + Weaviate"
      - label: "budgey-dashboard"
        description: "Token usage analytics dashboard"
      - label: "all"
        description: "Update all versioned flake inputs"
---

# Update Flake Input

Update a versioned flake input in `flake.nix` to the latest tagged version from its source repository (Forgejo/GitHub).

## Parameter Handling

**If parameters are missing from `$ARGUMENTS`, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "Which flake input do you want to update?",
      header: "Input",
      options: [
        { label: "ruinagents", description: "Agent definitions, docs, and skills" },
        { label: "budgey-extractor", description: "OpenCode session extractor" },
        { label: "budgey-dashboard", description: "Token usage analytics dashboard" },
        { label: "all", description: "Update all versioned inputs" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `<input_name>`
- Example: `ruinagents`
- Example: `all`

## Versioned Flake Inputs Registry

These inputs are pinned to tagged versions and managed by this skill:

| Input | Source | URL Pattern |
|-------|--------|-------------|
| `ruinagents` | forge.meskill.farm | `git+ssh://git@forge.meskill.farm/iamruinous/ruinagents.git?ref=refs/tags/vX.Y.Z` |
| `budgey-extractor` | forge.meskill.farm | `git+ssh://git@forge.meskill.farm/iamruinous/budgey-extractor.git?ref=refs/tags/vX.Y.Z` |
| `budgey-dashboard` | forge.meskill.farm | `git+ssh://git@forge.meskill.farm/iamruinous/budgey-dashboard.git?ref=refs/tags/vX.Y.Z` |

## Steps

### 1. Query latest tag from source repository

**For Forgejo repositories (forge.meskill.farm):**

```bash
# Get latest tag (first in list is most recent)
curl -s "https://forge.meskill.farm/api/v1/repos/iamruinous/<repo>/tags?limit=1" | jq -r '.[0].name'
```

**For GitHub repositories:**

```bash
# Get latest release tag
gh api repos/<owner>/<repo>/releases/latest --jq '.tag_name'

# Or get latest tag if no releases
gh api repos/<owner>/<repo>/tags --jq '.[0].name'
```

### 2. Compare with current version

Read `flake.nix` and extract the current version:

```bash
grep '<input_name>.url' flake.nix
# Look for: ?ref=refs/tags/vX.Y.Z
```

If the latest tag matches the current version, report "Already up to date" and stop.

### 3. Update flake.nix

Edit `flake.nix` to update the version tag:

**Before:**
```nix
ruinagents.url = "git+ssh://git@forge.meskill.farm/iamruinous/ruinagents.git?ref=refs/tags/v0.8.11";
```

**After:**
```nix
ruinagents.url = "git+ssh://git@forge.meskill.farm/iamruinous/ruinagents.git?ref=refs/tags/v0.8.12";
```

### 4. Update flake.lock

```bash
nix flake update <input_name>
```

This updates only the specified input in `flake.lock`.

### 5. Verify the build

```bash
# Dry build a representative host to verify
just remote-dry-build chassis
```

### 6. Report changes

Summarize what was updated:
- Input name
- Previous version
- New version
- Any build issues

## Updating All Inputs

When `$ARGUMENTS` is `all`:

1. Query latest tags for ALL versioned inputs
2. Compare each with current versions
3. Update only those that have newer versions
4. Run single `nix flake update ruinagents budgey-extractor budgey-dashboard` for efficiency
5. Verify build once after all updates

## Input Registry Details

### ruinagents

- **Repository:** `iamruinous/ruinagents`
- **API:** `https://forge.meskill.farm/api/v1/repos/iamruinous/ruinagents/tags?limit=1`
- **Provides:** `ruinagents-docs`, `ruinagents-global` packages
- **Used by:** chassis (home-manager), monolith (caddy sites)

### budgey-extractor

- **Repository:** `iamruinous/budgey-extractor`
- **API:** `https://forge.meskill.farm/api/v1/repos/iamruinous/budgey-extractor/tags?limit=1`
- **Provides:** `budgey-extractor` package, NixOS/home-manager modules
- **Used by:** chassis (home-manager service)

### budgey-dashboard

- **Repository:** `iamruinous/budgey-dashboard`
- **API:** `https://forge.meskill.farm/api/v1/repos/iamruinous/budgey-dashboard/tags?limit=1`
- **Provides:** `budgey-dashboard` package, NixOS module
- **Used by:** chassis (NixOS service)

## Example Workflow

```bash
# Update single input
/update-flake-input ruinagents

# Update all versioned inputs
/update-flake-input all
```

### Single Input Update Example

```
$ /update-flake-input ruinagents

Checking latest version for ruinagents...
  Current: v0.8.11
  Latest:  v0.8.12

Updating flake.nix...
Running: nix flake update ruinagents
Verifying build...

Updated ruinagents: v0.8.11 -> v0.8.12
```

### All Inputs Update Example

```
$ /update-flake-input all

Checking versions...
  ruinagents:       v0.8.11 -> v0.8.12 (update available)
  budgey-extractor: v0.7.0  -> v0.7.0  (up to date)
  budgey-dashboard: v0.6.0  -> v0.7.0  (update available)

Updating flake.nix...
Running: nix flake update ruinagents budgey-dashboard
Verifying build...

Summary:
  - ruinagents: v0.8.11 -> v0.8.12
  - budgey-dashboard: v0.6.0 -> v0.7.0
  - budgey-extractor: (no update needed)
```

## Adding New Versioned Inputs

To add a new input to this skill's registry:

1. Add the input to `flake.nix` with `?ref=refs/tags/vX.Y.Z` suffix
2. Add a comment: `# NOTE: Keep pinned to tagged version. Update with: /update-flake-input <name>`
3. Update the "Versioned Flake Inputs Registry" table in this skill
4. Add input details section with API URL and usage info

## Troubleshooting

### API returns empty or error

```bash
# Check if repo exists and has tags
curl -s "https://forge.meskill.farm/api/v1/repos/iamruinous/<repo>/tags" | jq
```

### Build fails after update

- Check if the new version has breaking changes
- Review the changelog in the source repository
- Consider pinning to a specific working version

### Lock file conflicts

```bash
# Force update the lock file
nix flake update <input_name> --recreate-lock-file
```

## Post-Update Checklist

- [ ] Latest tag queried from source repository
- [ ] Version in flake.nix updated
- [ ] `nix flake update <input>` completed
- [ ] Build verification passed: `just remote-dry-build chassis`
- [ ] Changes ready to commit (do NOT commit automatically)
