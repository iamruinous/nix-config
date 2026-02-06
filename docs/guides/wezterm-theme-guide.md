# WezTerm Theme Implementation Guide

Date: 2026-02-06

This guide explains how to implement and apply a WezTerm color scheme, and how to integrate it into this repo’s Home Manager configuration.

## How WezTerm Loads Themes
WezTerm uses one of three mechanisms, and they can be combined:
- `config.color_scheme`: selects a named scheme.
- `config.color_schemes`: inline Lua table that defines schemes.
- `config.color_scheme_dirs`: directory of TOML files with `[colors]`.

If `config.colors` is set, it overrides specific keys regardless of the chosen scheme.

## Recommended Structure for N0FRILLS
- One scheme per colorway: `N0FRILLS-ruin`, `N0FRILLS-siege`, `N0FRILLS-ghost`.
- Each scheme defines `background`, `foreground`, `ansi`, `brights`, plus UI colors (cursor, selection, tab bar, copy mode, quick select).
- Keep all colors hex-based for consistency.

## Option A: TOML Scheme Files (Recommended)
1. Create a directory for schemes:
- `~/.config/wezterm/colors/`

2. Add a TOML scheme file:
```toml
# ~/.config/wezterm/colors/N0FRILLS-ruin.toml
[colors]
background = "#1c1c1c"
foreground = "#eeeeee"
ansi = ["#1c1c1c", "#ff5faf", "#00afaf", "#ffafd7", "#875fd7", "#d75fd7", "#5fd7d7", "#bcbcbc"]
brights = ["#4e4e4e", "#ff5faf", "#00afaf", "#ffafd7", "#af87ff", "#d75fd7", "#5fd7d7", "#eeeeee"]
cursor_bg = "#eeeeee"
cursor_fg = "#1c1c1c"
selection_bg = "#3a3a3a"
selection_fg = "#eeeeee"

[colors.tab_bar]
background = "#1c1c1c"
[colors.tab_bar.active_tab]
bg_color = "#d75fd7"
fg_color = "#1c1c1c"
[colors.tab_bar.inactive_tab]
bg_color = "#4e4e4e"
fg_color = "#eeeeee"
```

3. Point WezTerm to the directory and scheme:
```lua
config.color_scheme_dirs = { wezterm.home_dir .. '/.config/wezterm/colors' }
config.color_scheme = 'N0FRILLS-ruin'
```

## Option B: Inline Lua Scheme
```lua
config.color_schemes = {
  ['N0FRILLS-ruin'] = {
    foreground = '#eeeeee',
    background = '#1c1c1c',
    ansi = { '#1c1c1c', '#ff5faf', '#00afaf', '#ffafd7', '#875fd7', '#d75fd7', '#5fd7d7', '#bcbcbc' },
    brights = { '#4e4e4e', '#ff5faf', '#00afaf', '#ffafd7', '#af87ff', '#d75fd7', '#5fd7d7', '#eeeeee' },
    cursor_bg = '#eeeeee',
    cursor_fg = '#1c1c1c',
    selection_bg = '#3a3a3a',
    selection_fg = '#eeeeee',
  },
}
config.color_scheme = 'N0FRILLS-ruin'
```

## Integrate Into This Repo
WezTerm is configured in `modules/home/default/wezterm.nix` via `programs.wezterm.extraConfig`.

To adopt N0FRILLS:
1. Add `color_scheme_dirs` and point to a stable path for the TOML files.
2. Set `config.color_scheme` to the chosen N0FRILLS variant.
3. Keep the rest of the config intact to preserve fonts and keybindings.

## Validation Checklist
- ANSI swatches: run a 16-color test script to confirm `ansi` and `brights` mapping.
- `ls` and `git diff` readability: confirm success/error/warning visibility.
- WezTerm UI: tab bar, selection, and cursor all match the N0FRILLS palette.
