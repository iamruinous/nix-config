# Neovim + AstroNvim Theme Implementation Guide

Date: 2026-02-06

This guide focuses on AstroNvim v5, which is the setup used in `files/configs/nvim/`.

## Current Repo State
- `files/configs/nvim/lua/plugins/astroui.lua` sets `colorscheme = "tokyonight-night"`.
- `files/configs/nvim/lua/community.lua` imports `astrocommunity.colorscheme.tokyonight-nvim`.
- `files/configs/nvim/lua/user.lua` also sets `colorscheme tokyonight-night` via `vim.cmd`.

Recommendation: use AstroUI as the single source of truth for the colorscheme and remove redundant `vim.cmd` overrides.

## Strategy Options
1. **Custom N0FRILLS colorscheme** (recommended): implement a standalone colorscheme that defines highlight groups and terminal colors.
2. **AstroTheme fork**: reuse AstroTheme’s structure and plugin integration, swap palettes for N0FRILLS.

## Option 1: Custom Colorscheme (Recommended)
### Step 1: Create the colorscheme file
Add a colorscheme in `files/configs/nvim/colors/n0frills.lua`:

```lua
local n0 = {
  bg = "#1c1c1c",
  fg = "#eeeeee",
  primary = "#d75fd7",
  accent = "#5fd7d7",
  muted = "#626262",
  border = "#3a3a3a",
}

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.g.colors_name = "n0frills"

local set = vim.api.nvim_set_hl
set(0, "Normal", { fg = n0.fg, bg = n0.bg })
set(0, "NormalFloat", { fg = n0.fg, bg = n0.bg })
set(0, "LineNr", { fg = n0.muted, bg = n0.bg })
set(0, "CursorLine", { bg = n0.border })
set(0, "CursorLineNr", { fg = n0.primary, bg = n0.border, bold = true })
set(0, "StatusLine", { fg = n0.fg, bg = n0.border })
set(0, "StatusLineNC", { fg = n0.muted, bg = n0.border })
set(0, "VertSplit", { fg = n0.border, bg = n0.bg })
set(0, "Visual", { bg = n0.border })
set(0, "ErrorMsg", { fg = "#ff5faf", bg = n0.bg, bold = true })
```

### Step 2: Register the colorscheme with AstroNvim
Update `files/configs/nvim/lua/plugins/astroui.lua`:

```lua
return {
  "AstroNvim/astroui",
  opts = {
    colorscheme = "n0frills",
  },
}
```

### Step 3: Remove redundant overrides
If `vim.cmd [[colorscheme ...]]` exists in `files/configs/nvim/lua/user.lua`, remove it so AstroUI controls the scheme.

## Option 2: AstroTheme Fork
1. Fork `AstroNvim/astrotheme` and replace its palettes with N0FRILLS.
2. Add the fork as a plugin in `files/configs/nvim/lua/plugins/`.
3. Set `colorscheme = "astrotheme"` in AstroUI (or your fork’s scheme name).

This gives you broader plugin support out of the box but requires maintaining the fork.

## Add N0FRILLS Highlight Overrides
Use AstroUI’s highlight override hook to enforce key N0FRILLS tokens.

Example in `files/configs/nvim/lua/plugins/astroui.lua`:
```lua
return {
  "AstroNvim/astroui",
  opts = {
    colorscheme = "n0frills",
    highlights = {
      init = function()
        return {
          CursorLine = { bg = "#3a3a3a" },
          CursorLineNr = { fg = "#d75fd7", bold = true },
          Visual = { bg = "#3a3a3a" },
        }
      end,
    },
  },
}
```

## Validation Checklist
- `:colorscheme n0frills` loads without errors.
- LSP diagnostics are readable (Error/Warn/Info/Hint).
- Telescope, statusline, and float windows are legible.
- Git signs and diff highlights are distinct but not noisy.

## Future Exploration
- Treesitter-specific highlight groups for richer syntax control.
- GitSigns highlight overrides to align add/change/delete colors with N0FRILLS.
- LSP inlay hints (virtual text) to ensure legibility on the dark background.

## References
- https://docs.astronvim.com/Recipes/colorscheme
- https://docs.astronvim.com/configuration/core_plugins/
- https://neovim.io/doc/user/syntax.html
- https://github.com/AstroNvim/astrotheme
