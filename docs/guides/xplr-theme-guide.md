# xplr Theme Implementation Guide (N0FRILLS)

Date: 2026-02-06

This guide explains how to implement the **N0FRILLS** design system in the **xplr** file manager.

## N0FRILLS Philosophy in Navigation
- **No Waste:** Minimalist layouts, removal of non-essential columns (permissions/owners).
- **Visual Stability:** Seamless panels without heavy borders.
- **Direct Voice:** Clear indicators for directories and focus.
- **Hex-Only:** Explicit hex codes for all UI elements.

## Colorway Variants

### ruin (Default)
The signature RUiNAGE palette featuring magenta and cyan.
- **Primary:** `#d75fd7` (Magenta)
- **Highlight:** `#5fd7d7` (Cyan)
- **Accent:** `#ffafd7` (Light Pink)
- **HotAccent:** `#ff5faf` (Hot Pink)

### siege
A cooler variant using purple and teal.
- **Primary:** `#875fd7` (Purple)
- **Highlight:** `#00afaf` (Teal)
- **Accent:** `#af87ff` (Light Purple)
- **HotAccent:** `#5f5fff` (Blue-Purple)

### ghost
A stark, high-contrast monochrome variant with amber highlights.
- **Primary:** `#eeeeee` (White)
- **Highlight:** `#ffaf00` (Amber)
- **Accent:** `#bcbcbc` (Light Gray)
- **HotAccent:** `#eeeeee` (White)

---

## Implementation

Add the following to your `~/.config/xplr/init.lua`.

### 1. Define the Palette
Select one colorway block:

```lua
-- N0FRILLS Palette (ruin)
local c = {
    bg        = "#1c1c1c",
    white     = "#eeeeee",
    gray      = "#8a8a8a",
    muted     = "#626262",
    primary   = "#d75fd7",
    highlight = "#5fd7d7",
    accent    = "#ffafd7",
    hotAccent = "#ff5faf",
}
```

### 2. Apply Styles
```lua
-- General UI
xplr.config.general.style.default = { fg = c.white, bg = c.bg }

-- Focused Item (Cursor)
xplr.config.general.style.focused = { fg = c.bg, bg = c.highlight, add_modifiers = { "Bold" } }

-- Selected Items (Multi-select)
xplr.config.general.style.selected = { fg = c.accent, add_modifiers = { "Italic" } }

-- Node Types
xplr.config.node_types.directory.style = { fg = c.primary, add_modifiers = { "Bold" } }
xplr.config.node_types.file.style      = { fg = c.white }
xplr.config.node_types.symlink.style   = { fg = c.highlight, add_modifiers = { "Italic" } }
xplr.config.node_types.executable.style = { fg = c.hotAccent }

-- Table Header
xplr.config.general.table.header.style = { fg = c.muted }

-- Status Bar
xplr.config.general.status_bar.style = { fg = c.gray, bg = c.bg }
```

### 3. Layout: N0FRILLS "Seamless" Layout
To achieve the N0FRILLS "Brutalist" look, we remove borders and simplify the table columns.

```lua
-- Remove Borders for a seamless data stream
xplr.config.layouts.builtin.default = {
    "Table",
    "HelpMenu",
}

-- Simplify Columns: Name and Size only
xplr.config.general.table.columns = {
    { name = " ", field = "icon", width = 2 },
    { name = "Name", field = "name", width = 50 },
    { name = "Size", field = "size", width = 10 },
}
```

---

## Integration into nix-config
This configuration is typically managed in `modules/home/default/xplr.nix` (if exists) or via `home.file.".config/xplr/init.lua".text`.

1. **Variant Injection:** Use Nix to inject the correct palette based on `ruinous.themeVariant`.
2. **Style Selection:** Toggle between `basic` (Table only) and `advanced` (Table + Logs/Help) styles.

---

## Validation Checklist
- [ ] **Contrast:** Focused item (`highlight`) is clearly legible against its background.
- [ ] **Distinction:** Directories (`primary`) are easily distinguished from files.
- [ ] **Borders:** Panels flow together without jarring line-drawing characters.
- [ ] **Consistency:** Colors match `tmux`, `starship`, and `wezterm` on the same host.
