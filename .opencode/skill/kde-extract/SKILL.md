---
name: kde-extract
description: Extract KDE settings and convert to plasma-manager Nix configuration
compatibility: Requires KDE/Plasma desktop environment
metadata:
  author: ruinous.ai
  version: "1.0"
---

# KDE Extract

Extract current KDE/Plasma settings from config files and convert them to declarative plasma-manager Nix configuration.

**Arguments:** `$ARGUMENTS` should contain one of:
- A config file name (e.g., "kwinrc", "kdeglobals", "kglobalshortcutsrc")
- A section name to filter (e.g., "TabBox", "Desktops", "Windows")
- "all" to show all available config files
- Empty to interactively choose

## Steps

1. **Parse arguments** from `$ARGUMENTS`

2. **If "all" or empty**, list available KDE config files:
   ```bash
   ls -1 ~/.config/k* ~/.config/plasma* 2>/dev/null | grep -v '.lock' | head -30
   ```
   Then ask user which file(s) to extract.

3. **Read the specified config file(s)**:
   ```bash
   cat ~/.config/<filename>
   ```

4. **Parse the INI format** and convert to plasma-manager `configFile` format:
   
   KDE INI format:
   ```ini
   [Section]
   Key=Value
   
   [Section][Subsection]
   Key=Value
   ```
   
   Converts to Nix:
   ```nix
   configFile = {
     "<filename>"."Section"."Key" = <value>;
     "<filename>"."Section][Subsection"."Key" = <value>;
   };
   ```

5. **Handle value types**:
   - `true`/`false` -> Nix booleans
   - Numbers -> Nix integers/floats
   - Everything else -> Nix strings

6. **Output the Nix configuration** in a format ready to paste into `programs.plasma.configFile`:

   ```nix
   # Add to programs.plasma in your home-configuration.nix
   configFile = {
     # <filename> settings
     "<filename>"."Section"."Key" = value;
   };
   ```

7. **If a specific section was requested**, filter output to only that section.

## Common Config Files

| File | Contains |
|------|----------|
| `kwinrc` | Window manager (tiling, TabBox, effects, desktops) |
| `kdeglobals` | Global KDE settings (theme, fonts, colors) |
| `kglobalshortcutsrc` | Keyboard shortcuts |
| `plasmarc` | Plasma shell settings |
| `plasma-org.kde.plasma.desktop-appletsrc` | Panel and widget config |
| `kscreenlockerrc` | Lock screen settings |
| `kcminputrc` | Input device settings |
| `ksmserverrc` | Session manager settings |

## Example Usage

```
/kde-extract kwinrc
```
Extracts all kwinrc settings as Nix config.

```
/kde-extract kwinrc TabBox
```
Extracts only the TabBox section from kwinrc.

```
/kde-extract all
```
Lists all KDE config files and prompts for selection.

## Example Output

Input (`~/.config/kwinrc`):
```ini
[TabBox]
ApplicationsMode=1
HighlightWindows=false

[Windows]
FocusPolicy=FocusFollowsMouse
```

Output:
```nix
# Add to programs.plasma in your home-configuration.nix
configFile = {
  # kwinrc - Window Manager settings
  "kwinrc"."TabBox"."ApplicationsMode" = 1;
  "kwinrc"."TabBox"."HighlightWindows" = false;
  "kwinrc"."Windows"."FocusPolicy" = "FocusFollowsMouse";
};
```

## Notes

- Settings managed by plasma-manager's native options (like `kwin.virtualDesktops`) may conflict with `configFile` entries
- Some settings require logout/login or `kwin_wayland --replace` to take effect
- Use `qdbus` to query current runtime values if config file doesn't reflect actual state
