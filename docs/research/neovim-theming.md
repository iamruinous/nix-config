# Neovim + AstroNvim Theming Research

Date: 2026-02-06

## Sources
- https://docs.astronvim.com/Recipes/colorscheme
- https://docs.astronvim.com/reference/default_plugins/
- https://docs.astronvim.com/v4/configuration/core_plugins/
- https://neovim.io/doc/user/syntax.html
- https://github.com/AstroNvim/astrotheme

## AstroNvim Theme Architecture (v5)
AstroNvim ships core UI/theming plugins, including AstroUI and AstroTheme. AstroUI provides UI configuration and highlight group control, while AstroTheme is the default colorscheme with broad plugin support.

## How AstroNvim Sets Colorschemes
AstroNvim’s recommended flow is:
1. Install a colorscheme plugin (or import one from AstroCommunity).
2. Set the `colorscheme` option via the AstroUI plugin configuration.

## Neovim Colorscheme Mechanics
The `:colorscheme {name}` command loads `colors/{name}.vim` or `colors/{name}.lua` from the `runtimepath`. This is the core mechanism used by any custom theme in Neovim.

## AstroTheme as a Reference Implementation
AstroTheme exposes an API for palettes, highlight overrides, and terminal colors. Its structure is a useful reference when building a full-surface theme for AstroNvim.
