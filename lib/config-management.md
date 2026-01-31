# Config Management Library

> Reusable abstraction for runtime-writable configuration files while maintaining Nix-declared defaults.

## Problem

AI assistants and other tools need to write to configuration files at runtime, but Nix-managed files are typically:
- Immutable symlinks to `/nix/store`
- Read-only when using `home.file`
- Cause "read-only file system" errors when tools try to modify them

## Solution

This library provides functions that generate `home.activation` scripts which:
1. ✅ Copy Nix-defined content to writable user directories
2. ✅ Track last-deployed version in `.nix-deployed` backup files
3. ✅ Detect runtime changes via `diff` and warn with colored output
4. ✅ Always overwrite with Nix content on rebuild (declarative management)
5. ✅ Allow runtime modifications between rebuilds

## Usage

### Import the Library

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  configMgmt = import ../../lib/config-management.nix { inherit lib pkgs config; };
in {
  # ... use configMgmt functions
}
```

### Example: JSON Configuration

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  configMgmt = import ../../lib/config-management.nix { inherit lib pkgs config; };
  
  myAppSettings = {
    model = "claude-opus-4";
    plugins = ["plugin-a" "plugin-b"];
    apiKey = null;  # Runtime-configured
  };
in {
  # Generate activation script for JSON config
  home.activation.manage-myapp-settings = configMgmt.manageJsonFile {
    name = "myapp-settings";
    configDir = "${config.home.homeDirectory}/.config/myapp";
    configFile = "settings.json";
    content = myAppSettings;
  };
}
```

**Result**:
- Creates `~/.config/myapp/settings.json` with JSON content
- Creates `~/.config/myapp/settings.json.nix-deployed` backup
- File is writable by the application
- On next rebuild, warns if runtime changes detected

### Example: YAML Configuration

```nix
{
  configMgmt = import ../../lib/config-management.nix { inherit lib pkgs config; };

  teaConfig = {
    logins = [{
      name = "forge.meskill.farm";
      url = "https://forge.meskill.farm";
      token = "";  # Injected via environment variable
      default = true;
    }];
  };
in {
  home.activation.manage-tea-config = configMgmt.manageYamlFile {
    name = "tea-config";
    configDir = "${config.home.homeDirectory}/.config/tea";
    configFile = "config.yml";
    content = teaConfig;
  };
}
```

### Example: Plain Text Configuration

```nix
{
  configMgmt = import ../../lib/config-management.nix { inherit lib pkgs config; };

  envContent = ''
    export MODEL="claude-opus-4"
    export OPENCODE_PORT=9500
  '';
in {
  home.activation.manage-env = configMgmt.manageTextFile {
    name = "app-env";
    configDir = "${config.home.homeDirectory}/.config/myapp";
    configFile = ".env";
    content = envContent;
  };
}
```

### Example: From Template File

```nix
{
  configMgmt = import ../../lib/config-management.nix { inherit lib pkgs config; };
  flake = ...;
in {
  home.activation.manage-from-template = configMgmt.manageFromTemplate {
    name = "app-config";
    configDir = "${config.home.homeDirectory}/.config/myapp";
    configFile = "config.toml";
    templateFile = "${flake}/files/configs/myapp/config.toml";
  };
}
```

## API Reference

### `manageJsonFile`

Generate activation script for a JSON configuration file.

**Parameters**:
| Name | Type | Description |
|------|------|-------------|
| `name` | string | Unique identifier for the activation script |
| `configDir` | string | Directory path (e.g., `"${config.home.homeDirectory}/.config/app"`) |
| `configFile` | string | Filename (e.g., `"settings.json"`) |
| `content` | attrset | Nix attribute set to convert to JSON |

**Returns**: `lib.hm.dag.entryAfter` activation script

### `manageYamlFile`

Generate activation script for a YAML configuration file.

**Parameters**:
| Name | Type | Description |
|------|------|-------------|
| `name` | string | Unique identifier for the activation script |
| `configDir` | string | Directory path |
| `configFile` | string | Filename (e.g., `"config.yml"`) |
| `content` | attrset | Nix attribute set to convert to YAML |

**Returns**: `lib.hm.dag.entryAfter` activation script

### `manageTextFile`

Generate activation script for a plain text configuration file.

**Parameters**:
| Name | Type | Description |
|------|------|-------------|
| `name` | string | Unique identifier for the activation script |
| `configDir` | string | Directory path |
| `configFile` | string | Filename |
| `content` | string | Text content to write |

**Returns**: `lib.hm.dag.entryAfter` activation script

### `manageFromTemplate`

Generate activation script from a template file in the Nix store.

**Parameters**:
| Name | Type | Description |
|------|------|-------------|
| `name` | string | Unique identifier for the activation script |
| `configDir` | string | Directory path |
| `configFile` | string | Filename |
| `templateFile` | path | Path to template file in Nix store |

**Returns**: `lib.hm.dag.entryAfter` activation script

## Runtime Behavior

### First Activation (New File)

```bash
$ home-manager switch
# Creates ~/.config/myapp/settings.json
# Creates ~/.config/myapp/settings.json.nix-deployed (backup)
```

### Second Activation (No Changes)

```bash
$ home-manager switch
# No warnings - files match backup
```

### Activation After Runtime Edits

```bash
# User manually edits ~/.config/myapp/settings.json
$ vim ~/.config/myapp/settings.json

# Next rebuild:
$ home-manager switch

------------------------------------------------------------------------
⚠️  WARNING: Runtime changes detected in /home/user/.config/myapp/settings.json
------------------------------------------------------------------------
Nix is overwriting the file with its configured version.
To preserve your changes, add them to your Nix configuration.
Diff:
--- /home/user/.config/myapp/settings.json.nix-deployed
+++ /home/user/.config/myapp/settings.json
@@ -1,4 +1,4 @@
 {
-  "model": "claude-opus-4",
+  "model": "gpt-4",  # <- Runtime change detected
   "plugins": ["plugin-a", "plugin-b"]
 }
------------------------------------------------------------------------
```

**File is overwritten with Nix content**, preserving declarative management.

## Migration Guide

### Before (Inline Activation Script)

```nix
home.activation.manage-gemini-settings = lib.hm.dag.entryAfter ["writeBoundary"] ''
  CONFIG_DIR="${config.home.homeDirectory}/.gemini"
  CONFIG_FILE="$CONFIG_DIR/settings.json"
  BACKUP_FILE="$CONFIG_FILE.nix-deployed"
  NIX_CONTENT='${builtins.toJSON globalSettings}'

  $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"

  if [ -f "$CONFIG_FILE" ] && [ -f "$BACKUP_FILE" ] && ! diff -q "$BACKUP_FILE" <(echo "$NIX_CONTENT") > /dev/null 2>&1; then
    echo " "
    echo "⚠️  WARNING: Runtime changes detected..."
    # ... long warning block ...
  fi

  echo "$NIX_CONTENT" > "$CONFIG_FILE"
  echo "$NIX_CONTENT" > "$BACKUP_FILE"
'';
```

### After (Using Library)

```nix
let
  configMgmt = import ../../lib/config-management.nix { inherit lib pkgs config; };
in {
  home.activation.manage-gemini-settings = configMgmt.manageJsonFile {
    name = "gemini-settings";
    configDir = "${config.home.homeDirectory}/.gemini";
    configFile = "settings.json";
    content = globalSettings;
  };
}
```

**Benefits**:
- ✅ 15 lines → 6 lines
- ✅ No shell script maintenance
- ✅ Consistent behavior across all configs
- ✅ Type-safe content conversion (JSON/YAML)
- ✅ Easier to read and understand

## Design Decisions

### Why Not Use `home.file`?

`home.file` creates symlinks or copies, but doesn't support:
- Change detection
- Warning messages
- Backup tracking
- Declarative overwrites with warnings

### Why Always Overwrite?

The pattern enforces **Nix as the source of truth**:
- Runtime changes are temporary (valid use case)
- Nix configuration is the canonical source
- Warnings guide users to propagate important changes back to Nix
- Prevents configuration drift

### Why `.nix-deployed` Backups?

Tracking the last deployed state enables:
- Detecting what changed at runtime (vs. what Nix changed)
- Showing meaningful diffs
- Avoiding false warnings when Nix config changes

## Real-World Examples

This pattern is used in:
- `modules/home/default/ruinage/assistants/gemini.nix` - `settings.json`
- `modules/home/default/ruinage/assistants/opencode.nix` - `oh-my-opencode.json`
- `modules/home/default/tea.nix` - `config.yml`

## Related

- [docs/config-writable-pattern.md](../docs/config-writable-pattern.md) - Original research notes
- [AGENTS.md](../AGENTS.md) - Project context
