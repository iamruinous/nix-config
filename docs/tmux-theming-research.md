# Tmux Theming Research

Research conducted 2026-01-07 for improving tmux theme configuration.

## Current State

Current theme is Tokyo Night with hardcoded hex colors in `modules/home/default/tmux.nix`.

### Missing Theme Elements

The current config doesn't theme:
- Messages/command prompt (`message-style`, `message-command-style`)
- Copy mode selection (`mode-style`, `copy-mode-match-style`)
- Menus (`menu-style`, `menu-selected-style`, `menu-border-style`)
- Popups (`popup-style`, `popup-border-style`)
- Display panes numbers (`display-panes-colour`, `display-panes-active-colour`)
- Clock (`clock-mode-colour`)

## All Themeable Tmux UI Elements

### Status Bar
| Element | Option Name | Description |
|---------|-------------|-------------|
| Status bar style | `status-style` | Overall status bar background/foreground |
| Status bar left section | `status-left-style` | Style for left part of status bar |
| Status bar right section | `status-right-style` | Style for right part of status bar |
| Status bar position | `status-position` | `top` or `bottom` |

### Windows (Status Bar Window List)
| Element | Option Name | Description |
|---------|-------------|-------------|
| Window status (inactive) | `window-status-style` | Default window appearance |
| Window status (current/active) | `window-status-current-style` | Active window appearance |
| Window status (last) | `window-status-last-style` | Last active window |
| Window status (activity) | `window-status-activity-style` | Window with activity/silence |
| Window status (bell) | `window-status-bell-style` | Window with bell triggered |
| Window status format | `window-status-format` | Format string for inactive windows |
| Window status current format | `window-status-current-format` | Format string for active window |
| Window status separator | `window-status-separator` | Separator between windows |

### Panes
| Element | Option Name | Description |
|---------|-------------|-------------|
| Pane border (inactive) | `pane-border-style` | Inactive pane border color/style |
| Pane border (active) | `pane-active-border-style` | Active pane border color/style |
| Pane border status | `pane-border-status` | `off`, `top`, or `bottom` |
| Pane border format | `pane-border-format` | Format string for pane border text |
| Window style (inactive) | `window-style` | Background for inactive panes |
| Window active style | `window-active-style` | Background for active pane |

### Messages & Command Prompt
| Element | Option Name | Description |
|---------|-------------|-------------|
| Message style | `message-style` | Messages and command prompt (insert mode) |
| Message command style | `message-command-style` | Command prompt in vi command mode |

### Copy Mode
| Element | Option Name | Description |
|---------|-------------|-------------|
| Copy mode style | `mode-style` | Visual selection background in copy mode |
| Copy mode match style | `copy-mode-match-style` | Search match highlighting (tmux 3.2+) |
| Copy mode current match | `copy-mode-current-match-style` | Current search match (tmux 3.2+) |

### Menus (tmux 3.4+)
| Element | Option Name | Description |
|---------|-------------|-------------|
| Menu style | `menu-style` | Default menu appearance |
| Menu selected style | `menu-selected-style` | Selected menu item |
| Menu border style | `menu-border-style` | Menu border appearance |

### Popups (tmux 3.2+)
| Element | Option Name | Description |
|---------|-------------|-------------|
| Popup style | `popup-style` | Popup window background/foreground |
| Popup border style | `popup-border-style` | Popup border color/style |
| Popup border lines | `popup-border-lines` | Border line type (`single`, `double`, `heavy`, `simple`, `rounded`, `padded`, `none`) |

### Display Panes (Pane Numbers)
| Element | Option Name | Description |
|---------|-------------|-------------|
| Display panes color | `display-panes-colour` | Inactive pane number color |
| Display panes active color | `display-panes-active-colour` | Active pane number color |

### Clock Mode
| Element | Option Name | Description |
|---------|-------------|-------------|
| Clock mode color | `clock-mode-colour` | Clock color when displayed |
| Clock mode style | `clock-mode-style` | `12` or `24` hour format |

## Comprehensive Theme Plugins Comparison

| Theme | Stars | Nix Package | Elements Themed | Unique Strengths |
|-------|-------|-------------|-----------------|------------------|
| **catppuccin** | 2,755 | `tmuxPlugins.catppuccin` | Status, panes, popups, menus, copy mode, messages | Best docs, modular, 4 flavors |
| **dracula** | 781 | `tmuxPlugins.dracula` | Status, panes, messages | Most plugins (spotify, kubernetes, weather, git) |
| **nord** | 1,160 | `tmuxPlugins.nord` | Status, panes, copy mode | Clean, uniform, good plugin support |
| **tmux-power** | 649 | `tmuxPlugins.power-theme` | Status, panes | 7 built-in themes, gradients, flexible colors |
| **tokyo-night** | 513 | `tmuxPlugins.tokyo-night-tmux` | Status, panes | Matches current aesthetic |
| **rose-pine** | 235 | `tmuxPlugins.rose-pine` | Status, panes, directory | 3 variants, transparency support |
| **gruvbox** | 647 | `tmuxPlugins.gruvbox` | Status, panes | Classic warm palette |
| **kanagawa** | - | `tmuxPlugins.kanagawa` | Status, panes | Japanese wave aesthetic |

## Theme Organization Patterns

### Variable-Based Pattern
```bash
# Define color palette as variables
white="#f8f8f2"
gray="#44475a"
blue="#89b4fa"

# Apply variables to tmux options
tmux set -g status-style "bg=${gray},fg=${white}"
tmux set -g pane-active-border-style "fg=${blue}"
```

### Tmux User Variables Pattern (Catppuccin)
```bash
# Define theme colors as tmux user variables
set -ogq @thm_bg "#1e1e2e"
set -ogq @thm_fg "#cdd6f4"
set -ogq @thm_blue "#89b4fa"

# Reference in style options
set -gF status-style "bg=#{@thm_bg},fg=#{@thm_fg}"
set -gF pane-active-border-style "fg=#{@thm_blue}"
```

### Conditional Logic (tmux 3.2+)
```bash
%if "#{>=:#{version},3.4}"
  set -gF menu-selected-style "..."
%endif
```

## Style Syntax Reference

**Format:**
```
fg=<color>,bg=<color>,<attributes>
```

**Colors:**
- Named: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`
- Bright: `brightred`, `brightgreen`, etc.
- 256-color: `colour0` to `colour255`
- RGB: `#RRGGBB`
- Special: `default`, `terminal`

**Attributes:**
- `bold`, `dim`, `underscore`, `blink`, `reverse`, `hidden`, `italics`, `strikethrough`

## Recommendations

1. **catppuccin** - Best overall for comprehensive theming including popups/menus
2. **tokyo-night-tmux** - Keep current look but properly themed via plugin
3. **dracula** - Best for status bar widgets (weather, git, spotify, etc.)

For popup/menu theming (tmux 3.2+ features), **catppuccin** is currently the most comprehensive.
