# xplr File Manager Theming Research

Date: 2026-02-06
Status: Research Complete

## Overview
`xplr` is a terminal-based file explorer written in Rust, configured via Lua. Its design is highly modular, allowing for fine-grained control over layout, colors, and behavior.

## Styling System
`xplr` uses a styling system based on Lua tables that define `fg`, `bg`, and `add_modifiers`.

### Core Styling Keys
Styling is primarily handled under `xplr.config.general.style`.

- `xplr.config.general.style.default`: Base foreground/background.
- `xplr.config.general.style.focused`: The item under the cursor.
- `xplr.config.general.style.selected`: Multi-selected items.
- `xplr.config.general.style.current_directory`: Style for the path display.
- `xplr.config.general.style.symlink`: Symlink styling.

### Node Type Styling
Specific file types can be styled individually:
- `xplr.config.node_types.directory.style`
- `xplr.config.node_types.file.style`
- `xplr.config.node_types.executable.style`
- `xplr.config.node_types.symlink.style`

### Layout & Panels
`xplr` layouts are built from "Widgets" and "Panels". Borders are widgets that can be removed for a "No Waste" N0FRILLS look.
- Layouts are defined in `xplr.config.layouts`.
- Default columns are in `xplr.config.general.table.columns`.

### Status Bar & Help
The status line is configured per mode:
- `xplr.config.modes.builtin.<mode>.status_line`: Defines left, center, and right sections.

## N0FRILLS Mapping Strategy

| N0FRILLS Token | Role in xplr |
|----------------|--------------|
| `bg` | `Background` for all styles |
| `white` | `Foreground` for normal files, primary text |
| `gray` | `Foreground` for secondary text, headers |
| `muted` | `Foreground` for hidden files, log timestamps |
| `primary` | `Foreground` for directories, active mode indicator |
| `highlight` | `Foreground` or `Background` for focused items |
| `hotAccent` | `Foreground` for errors, dangerous operations |

## Design Constraints
- **Transparency:** If `bg` is set to `"Reset"`, `xplr` will use the terminal's background. N0FRILLS typically prefers `#1c1c1c` for visual stability across hosts.
- **Borders:** N0FRILLS "Brutalist" style suggests removing borders between panels to create a seamless data stream.
- **Information Density:** Columns like permissions and owner are often hidden in N0FRILLS to reduce visual noise.

## References
- [xplr Documentation](https://xplr.dev/docs/)
- [xplr Built-in Configuration](https://github.com/sayanarijit/xplr/blob/main/src/init.lua)
