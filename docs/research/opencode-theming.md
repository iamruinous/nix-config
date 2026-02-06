# OpenCode Theming Research

Date: 2026-02-06

## Sources
- https://open-code.ai/en/docs/themes
- https://opencode.ai/docs/config/

## Theme System Overview
OpenCode supports JSON-based themes. Themes can be selected in config or via the theme selector command in the TUI. The default theme is `opencode`, and several built-in themes are available.

## Theme Loading and Placement
Themes are loaded from multiple directories with later paths overriding earlier ones:
1. Built-in themes
2. `~/.config/opencode/themes/*.json` (or `$XDG_CONFIG_HOME/opencode/themes/*.json`)
3. `<project-root>/.opencode/themes/*.json`
4. `./.opencode/themes/*.json`

## Theme JSON Format
The public docs show a minimal theme format using `defs` plus a `theme` object. Required keys are:
- `primary`
- `secondary`
- `accent`
- `text`
- `background`

## Color Value Formats
Theme values can be:
- Hex colors (e.g., `"#ffffff"`)
- ANSI codes (0-255)
- Color references (e.g., `"primary"` or a `defs` key)
- Dark/light variants via objects
- `"none"` to inherit the terminal’s default colors

## Config Integration
The OpenCode config file (`opencode.json` or `opencode.jsonc`) supports a `theme` field to select a theme by name. The global config lives at `~/.config/opencode/opencode.json`.
