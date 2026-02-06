# WezTerm Theming Research

Date: 2026-02-06

## Executive Summary
WezTerm theming is split between a named color scheme (`color_scheme`), ad-hoc overrides via `colors`, and scheme discovery from TOML files via `color_scheme_dirs`. Schemes are defined by the same keys used in `colors`, so a theme can cover the full 16-color ANSI palette plus UI surfaces like tab bars, selection, cursor, copy-mode highlights, and quick-select labels.

Key sources:
- WezTerm Appearance and Themes: https://wezfurlong.org/wezterm/config/appearance.html
- WezTerm Colors Config: https://wezfurlong.org/wezterm/config/lua/config/colors.html

## Theme Entry Points
- `config.color_scheme`: selects a built-in or custom scheme by name.
- `config.color_schemes`: inline Lua table of scheme definitions.
- `config.color_scheme_dirs`: directories containing TOML files with `[colors]` and optional `[metadata]`.
- `config.colors`: direct override table for colors, used when you want to change a subset or bypass schemes.

## Colors Schema (Fields Worth Covering)
These keys show up in the WezTerm `colors` reference and should be included in a complete scheme definition.

Palette and core surfaces:
- `foreground`, `background`
- `ansi`: list of 8 colors (standard ANSI indices 0-7)
- `brights`: list of 8 colors (bright ANSI indices 8-15)
- `indexed`: extra color overrides by numeric index

Cursor and selection:
- `cursor_bg`, `cursor_fg`, `cursor_border`
- `selection_bg`, `selection_fg`

Structural UI:
- `scrollbar_thumb`
- `split`

Tab bar and window chrome:
- `tab_bar`:
- `tab_bar.background`
- `tab_bar.inactive_tab.bg_color` and `tab_bar.inactive_tab.fg_color`
- `tab_bar.active_tab.bg_color` and `tab_bar.active_tab.fg_color`
- `tab_bar.inactive_tab_hover.bg_color` and `tab_bar.inactive_tab_hover.fg_color`
- `tab_bar.new_tab.bg_color` and `tab_bar.new_tab.fg_color`
- `tab_bar.new_tab_hover.bg_color` and `tab_bar.new_tab_hover.fg_color`
- `window_frame.active_titlebar_bg`, `window_frame.inactive_titlebar_bg` (macOS titlebar colors)

Mode and selection UIs:
- `copy_mode_active_highlight_bg`, `copy_mode_active_highlight_fg`
- `copy_mode_inactive_highlight_bg`, `copy_mode_inactive_highlight_fg`
- `quick_select_label_bg`, `quick_select_label_fg`
- `quick_select_match_bg`, `quick_select_match_fg`

## TOML Scheme Format
WezTerm loads schemes from TOML with a `[colors]` table. The schema matches the `colors` Lua table. Minimal schemes define `background`, `foreground`, `ansi`, and `brights`; full schemes add UI surfaces. The example below mirrors the docs.

```toml
# ~/.config/wezterm/colors/N0FRILLS-ruin.toml
[colors]
background = "#1c1c1c"
foreground = "#eeeeee"
ansi = ["#1c1c1c", "#ff5faf", "#5fd7d7", "#ffafd7", "#875fd7", "#d75fd7", "#00afaf", "#bcbcbc"]
brights = ["#4e4e4e", "#ff5faf", "#5fd7d7", "#ffafd7", "#af87ff", "#d75fd7", "#00afaf", "#eeeeee"]
```

## Practical Implications for N0FRILLS
- WezTerm supports a complete theme surface area: not just terminal text colors, but the tab bar, selection, cursor, and utility UIs.
- Because schemes reuse the `colors` schema, a single canonical N0FRILLS palette can drive `color_schemes`, TOML, and `config.colors` without format translation.
- For consistency, it is best to define a stable 16-color ANSI mapping per colorway and then layer UI surfaces (cursor, selection, tab bar) using the same shared tokens.
