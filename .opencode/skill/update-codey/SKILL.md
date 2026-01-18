---
name: update-codey
description: Update codey-agent-system to a new version
compatibility: Requires nix, webfetch
metadata:
  author: ruinous.ai
  version: "1.0"
---

# Update Codey

Update the codey-agent-system version in the opencode module.

**Required arguments:** `$ARGUMENTS` should contain the version tag (e.g., "v0.7.0")

## Steps

1. **Parse the version** from `$ARGUMENTS`
   - If no version provided, ask the user for it
   - Version should include the "v" prefix (e.g., "v0.7.0")
   - If user provides version without "v" prefix, add it automatically

2. **Fetch the release page** to extract the sha256:
   - URL: `https://forge.meskill.farm/iamruinous/codey-agent-system/releases/tag/{VERSION}`
   - Use the WebFetch tool to retrieve the page content
   - Look for the sha256 hash in the fetchgit code block, formatted as:
     ```
     sha256 = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=";
     ```
   - Extract just the hash value (e.g., `sha256-BBdr9kHDPq1SH36iv1xcMaL/n9ZEEJ8+yOZExqw0YC0=`)

3. **Verify the release exists:**
   - If the release page returns a 404 or doesn't contain the expected sha256, inform the user
   - Show available releases if possible

4. **Update the Nix module** at `modules/home/default/ai-cli/opencode.nix`:
   - Find the `codeyAgentSystem.rev` default value and update it to the new version
   - Find the `codeyAgentSystem.sha256` default value and update it to the new sha256
   
   The relevant section looks like:
   ```nix
   rev = mkOption {
     type = types.str;
     default = "v0.5.3";  # <-- Update this
     ...
   };

   sha256 = mkOption {
     type = types.str;
     default = "sha256-BBdr9kHDPq1SH36iv1xcMaL/n9ZEEJ8+yOZExqw0YC0=";  # <-- Update this
     ...
   };
   ```

5. **Show the user a summary:**
   ```
   Updated codey-agent-system:
     Previous version: v0.5.3
     New version:      v0.7.0
     New sha256:       sha256-XXXXX...
   
   File modified: modules/home/default/ai-cli/opencode.nix
   ```

6. **Offer next steps:**
   - Test with `make dry-build` to verify the configuration builds
   - Commit and apply with `/automerge` or `/pr`

## Example Usage

```
/update-codey v0.7.0
```

Updates:
- `codeyAgentSystem.rev` default to `"v0.7.0"`
- `codeyAgentSystem.sha256` default to the hash from the release page

## Notes

- The sha256 hash is published on each release page in the "Installation" section
- The hash is for `pkgs.fetchgit` and uses the SRI format (sha256-XXX=)
- Release page format: `https://forge.meskill.farm/iamruinous/codey-agent-system/releases/tag/vX.Y.Z`
