# Ruinous Starship Theme Plan

> Design document for implementing the Ruinous theme system in Starship

## Overview

Create a unified themeable Starship configuration:

```nix
ruinous.starship = {
  theme = "ruinous";           # Theme system (future: could add others)
  themeVariant = "classic";    # Colorway: classic | ruin | siege | ghost
  themeStyle = "handcrafted";  # Style: basic | advanced | handcrafted
};
```

### Theme Matrix

| Variant | Style | Description |
|---------|-------|-------------|
| **classic** | handcrafted | Original prompt with current colors (default) |
| **classic** | basic | Original colors, brutalist layout |
| **classic** | advanced | Original colors, structured N0FRILLS layout |
| **ruin** | basic | N0FRILLS magenta/cyan, brutalist |
| **ruin** | advanced | N0FRILLS magenta/cyan, structured layout |
| **ruin** | handcrafted | N0FRILLS magenta/cyan, artisanal box-drawing |
| **siege** | basic | N0FRILLS purple/teal, brutalist |
| **siege** | advanced | N0FRILLS purple/teal, structured layout |
| **siege** | handcrafted | N0FRILLS purple/teal, artisanal box-drawing |
| **ghost** | basic | N0FRILLS white/amber, brutalist |
| **ghost** | advanced | N0FRILLS white/amber, structured layout |
| **ghost** | handcrafted | N0FRILLS white/amber, artisanal box-drawing |

**Colorways:** **classic**, **ruin**, **siege**, **ghost**
**Styles:**
- **basic** - Brutalist, minimal decoration (pure N0FRILLS philosophy)
- **advanced** - Structured layout with functional grouping (tech-forward)
- **handcrafted** - Artisanal box-drawing with gradient borders (original)

---

## Colorway: classic (Preserved Original)

The original Starship color palette, preserved exactly as-is.

### Visual Design (handcrafted style)

```
┍━━━━━┫user󰁥hostname󰌆┣━━━━╾╶ ~/Projects/nix-config          ─╼━┫main:origin/main┣━╾─ M
┕━❯ λ                                                                              12.5s 󰁹
```

### Characteristics

- **Two-line prompt** with box-drawing frame (`┍━┫...┣━┕`)
- **Gradient borders** using ANSI 236-254 grayscale
- **Unicode separators** between username/hostname (`󰁥`)
- **Git branch** framed with decorative borders
- **Git status** with emoji indicators (😵😰 for diverged/behind)
- **Lambda (λ)** success symbol, cross (✗) for errors
- **Right-aligned** command duration and battery

### Color Palette (Hardcoded)

| Element | Color | Value |
|---------|-------|-------|
| Box drawing | ANSI gradient | 236-250 |
| Username | gray | 252 |
| Hostname | purple | named |
| Git branch | blue bold | named |
| Git status | muted purple | 140 |
| Package/Rust | orange | 208 |
| Golang | cyan bold | named |
| Lua | aquamarine | `#7FFFD4` |
| Duration | yellow bold | named |
| Success λ | near-white | 254 |
| Error ✗ | red bold | named |

### Why Keep as Default

- Distinctive visual identity established over time
- Complex color gradients that work well with current terminals
- Default for backward compatibility
- Allows gradual migration to N0FRILLS colorways

---

## Design System Reference

### N0FRILLS Color Palette

#### Shared Colors (All Colorways)
```nix
colors = {
  white  = "#eeeeee";  # Primary text, content
  gray   = "#8a8a8a";  # Secondary text, labels, brackets
  muted  = "#626262";  # Tertiary text, help hints
  dim    = "#4e4e4e";  # Inactive items, placeholders
  border = "#3a3a3a";  # Frame borders, dividers
  bg     = "#1c1c1c";  # Backgrounds for panels
};
```

#### Colorway Definitions
```nix
colorways = {
  # Original colors (preserved from current config)
  classic = {
    primary   = "purple";   # Hostname, active elements (named color)
    accent    = "208";      # Package, rust (ANSI 208 = orange)
    hotAccent = "red";      # Errors, alerts
    highlight = "bold blue"; # Git branch
    # Uses ANSI gradient for borders: 236-254
    # Git status: 140, username: 252, etc.
  };
  
  # N0FRILLS colorways
  ruin = {
    primary   = "#d75fd7";  # Magenta - active elements
    accent    = "#ffafd7";  # Lt Pink - secondary highlights
    hotAccent = "#ff5faf";  # Hot Pink - alerts, errors
    highlight = "#5fd7d7";  # Cyan - complementary pop
  };
  siege = {
    primary   = "#875fd7";  # Purple - active elements
    accent    = "#af87ff";  # Lt Purple - secondary highlights
    hotAccent = "#5f5fff";  # Blue-Purple - alerts, errors
    highlight = "#00afaf";  # Teal - complementary pop
  };
  ghost = {
    primary   = "#eeeeee";  # White - active elements
    accent    = "#bcbcbc";  # Lt Gray - secondary highlights
    hotAccent = "#eeeeee";  # White - alerts (use gray bg)
    highlight = "#ffaf00";  # Amber - complementary pop
  };
};
```

### N0FRILLS Design Principles

| Principle | Application to Starship |
|-----------|------------------------|
| **No Waste** | Remove purely decorative elements unless they serve navigation |
| **Visual Stability** | Consistent element positioning regardless of content length |
| **Direct Voice** | Icons over emoji, uppercase labels, terse output |
| **Absolute Consistency** | One colorway active at a time, hex codes not ANSI names |

---

## Style 1: BASIC (Brutalist)

Pure N0FRILLS aesthetic. Strips away all decorations, raw information only.

### Format Design

```
USERNAME@HOSTNAME DIRECTORY BRANCH
> _
```

**Right side:** `duration`

No brackets, no separators - just the data.

### Color Mapping

| Element | Color Token | Rationale |
|---------|-------------|-----------|
| Username | `gray` | Secondary info |
| `@` separator | `muted` | Tertiary |
| Hostname | `primary` | Identity anchor |
| Directory | `highlight` | Current context (N0FRILLS "signal" color) |
| Git branch | `primary` | Active work context |
| Git dirty | `hotAccent` | Attention needed |
| Git clean | `accent` | Positive state |
| Prompt `>` | `gray` | Structural |
| Success λ | `primary` | Ready state |
| Error ✗ | `hotAccent` | Alert |
| Duration | `muted` | Non-critical info |

### Starship Format String (BASIC)

```toml
format = """
$username[@](muted)$hostname \
$directory \
$git_branch\
$git_status\
$line_break\
$character"""

right_format = "$cmd_duration"
```

No brackets, no decorative elements - pure data.

### Module Configurations (BASIC)

```nix
# BASIC Style - Example for RUiN colorway
settings = {
  format = lib.concatStrings [
    "$username"
    "[@](${colors.muted})"
    "$hostname"
    " "
    "$directory"
    " "
    "$git_branch"
    "$git_status"
    "$line_break"
    "$character"
  ];
  
  right_format = "$cmd_duration";

  username = {
    format = "[$user]($style)";
    style_user = colors.gray;
    style_root = colorway.hotAccent;
    disabled = false;
  };

  hostname = {
    format = "[$hostname]($style)";
    style = "bold ${colorway.primary}";
    ssh_only = false;
    disabled = false;
  };

  directory = {
    format = "[$path]($style)";
    style = colorway.highlight;
    truncation_length = 3;
    truncation_symbol = ".../";
  };

  git_branch = {
    format = "[$symbol$branch]($style) ";
    style = colorway.primary;
    symbol = "";
  };

  git_status = {
    format = "[$all_status$ahead_behind]($style)";
    style = colorway.accent;
    conflicted = "!";
    ahead = "+$count";
    behind = "-$count";
    diverged = "~";
    untracked = "?";
    stashed = "S";
    modified = "M";
    staged = "A";
    renamed = "R";
    deleted = "D";
  };

  character = {
    success_symbol = "[>](${colorway.primary})";
    error_symbol = "[>](bold ${colorway.hotAccent})";
  };

  cmd_duration = {
    format = "[$duration]($style)";
    style = colors.muted;
    min_time = 2000;
  };
};
```

---

---

## Style 2: ADVANCED (Structured Tech-Forward)

N0FRILLS aesthetic with functional decorators. Uses the signature `[>]` `[+]` `[!]` bracket notation.
Takes full advantage of left/right justification for information density.

### Format Design

```
LEFT: Active context (what you're doing)
RIGHT: Ambient context (environment info)

[~] ~/Projects/nix-config [>] main [+2][~1]          rust 1.75  go 1.21 [@] user@host 12.5s
[>] _
```

### Information Hierarchy

| Side | Purpose | Content |
|------|---------|---------|
| **Left** | Active work context | Directory, git branch, git status |
| **Right** | Ambient environment | Languages, docker, user@host, duration |

Uses N0FRILLS bracket notation for semantic meaning:
- `[~]` directory/modified context
- `[>]` action/navigation point  
- `[@]` identity anchor
- `[+]` additions/success
- `[!]` warnings/conflicts

### Starship Format String (ADVANCED)

```toml
format = """
[\\[~\\]](gray) $directory \
[\\[>\\]](gray) $git_branch\
$git_status\
$fill\
$line_break\
$character"""

right_format = """
$golang\
$rust\
$nodejs\
$python\
$docker_context\
[\\[@\\]](muted) $username$hostname \
$cmd_duration\
$battery"""
```

### Module Configurations (ADVANCED)

```nix
# ADVANCED Style - Example for RUiN colorway
settings = {
  format = lib.concatStrings [
    "[\\[~\\]](${colors.gray})"
    " "
    "$directory"
    " "
    "[\\[>\\]](${colors.gray})"
    " "
    "$git_branch"
    "$git_status"
    "$fill"
    "$line_break"
    "$character"
  ];
  
  right_format = lib.concatStrings [
    "$golang"
    "$rust"
    "$nodejs"
    "$python"
    "$docker_context"
    "[\\[@\\]](${colors.muted})"
    " "
    "$username"
    "$hostname"
    " "
    "$cmd_duration"
    "$battery"
  ];

  fill = {
    symbol = " ";
  };

  username = {
    format = "[$user](${colors.gray})[@](${colors.muted})";
    style_root = colorway.hotAccent;
    disabled = false;
  };

  hostname = {
    format = "[$hostname]($style)";
    style = colorway.primary;
    ssh_only = false;
    disabled = false;
  };

  directory = {
    format = "[$path]($style)";
    style = "bold ${colorway.highlight}";
    truncation_length = 4;
    truncation_symbol = ".../";
  };

  git_branch = {
    format = "[$branch]($style) ";
    style = "bold ${colorway.primary}";
    symbol = "";
  };

  git_status = {
    format = "[$all_status$ahead_behind]($style)";
    style = colorway.accent;
    # N0FRILLS bracket notation
    conflicted = "[\\[!\\]](${colorway.hotAccent})";
    ahead = "[+$count]";
    behind = "[-$count]";
    diverged = "[!]";
    untracked = "[?]";
    stashed = "[S]";
    modified = "[~]";
    staged = "[+]";
    renamed = "[>]";
    deleted = "[x]";
  };

  # Language indicators - compact, right-aligned
  golang = {
    format = "[$symbol$version]($style) ";
    symbol = "go ";
    style = colors.muted;
  };

  rust = {
    format = "[$symbol$version]($style) ";
    symbol = "rs ";
    style = colors.muted;
  };

  nodejs = {
    format = "[$symbol$version]($style) ";
    symbol = "node ";
    style = colors.muted;
  };

  python = {
    format = "[$symbol$version]($style) ";
    symbol = "py ";
    style = colors.muted;
  };

  docker_context = {
    format = "[\\[docker\\]](${colors.gray}) [$context](${colorway.accent}) ";
    disabled = false;
  };

  character = {
    # N0FRILLS action prompt
    success_symbol = "[\\[>\\]](${colorway.highlight})";
    error_symbol = "[\\[!\\]](bold ${colorway.hotAccent})";
  };

  cmd_duration = {
    format = "[$duration]($style) ";
    style = colors.muted;
    min_time = 2000;
  };

  battery = {
    format = "[$symbol$percentage]($style)";
    # Uses colorway.highlight for normal, colorway.hotAccent for low
  };
};
```

### Design Rationale

- **Bracket notation** (`[>]` `[~]` `[@]`) - N0FRILLS signature style from justfile helpers
- **Left/Right split** - active context left, ambient environment right
- **Language versions** - compact `go 1.21` `rs 1.75` format, muted color (not distracting)
- **Docker context** - `[docker] context-name` when active
- **Identity anchor** - `[@]` marks user@host section on right
- **Duration last** - timing info at far right, least important
- **Battery** - only shows when relevant (on laptops with battery enabled)

---

## Style 3: HANDCRAFTED (Artisanal Box-Drawing)

Preserves the original distinctive box-drawing aesthetic with colorway applied.

### Format Design

```
[┍][━━━━━][┫] user@hostname ssh [┣][━━━━][╾][╶] directory ... [┫]branch[┣] status
[┕][━][❯] λ                                                           duration
```

### Color Mapping for HANDCRAFTED

| Element | Current | N0FRILLS Token |
|---------|---------|----------------|
| Box corners `┍┕┫┣` | Gradient 241-250 | `gray` |
| Box lines `━` | Gradient 241-250 | `muted` → `dim` gradient |
| Username | 252 | `gray` |
| Hostname | purple | `primary` bold |
| SSH indicator | 250 | `accent` |
| SSH agent warning | bold red | `hotAccent` bold |
| Directory | - | `highlight` |
| Git branch | blue bold | `primary` bold |
| Git status | 140 | `accent` / `hotAccent` for dirty |
| Package | 208 | `accent` |
| Languages (go/rust/etc) | various | `primary` |
| Success λ | 254 | `primary` |
| Error ✗ | bold red | `hotAccent` bold |
| Duration | bold yellow | `muted` |
| Battery | gradient | `highlight` / `hotAccent` |

### Starship Format String (HANDCRAFTED)

```nix
# HANDCRAFTED Style - maintains box-drawing structure
format = lib.concatStrings [
  "$line_break"
  "[┍](${colors.gray})[━](${colors.muted})[━](${colors.muted})[━](${colors.muted})[━](${colors.muted})[━](${colors.muted})[┫](${colors.gray})"
  "$username"
  "$hostname"
  "\${custom.ssh_auth_sock}"
  "[┣](${colors.gray})[━](${colors.muted})[━](${colors.muted})[━](${colors.muted})[━](${colors.muted})[╾](${colors.dim})[╶](${colors.dim})"
  " "
  "$directory"
  "$fill"
  "$docker_context"
  "$package"
  "$golang"
  "$rust"
  "$git_branch"
  " "
  "$git_status"
  "\${custom.ssh}"
  "$line_break"
  "[┕](${colors.gray})[━](${colors.muted})[❯](${colors.gray})"
  " "
  "$jobs"
  "$character"
];
```

---

## Implementation Plan

### Phase 1: Module Options

Add theme configuration to `modules/home/default/options.nix`:

```nix
ruinous.starship = {
  battery.enable = lib.mkEnableOption "battery display";
  
  theme = lib.mkOption {
    type = lib.types.enum ["ruinous"];
    default = "ruinous";
    description = "Starship theme system. Currently only 'ruinous' is supported.";
  };
  
  themeVariant = lib.mkOption {
    type = lib.types.enum ["classic" "ruin" "siege" "ghost"];
    default = "classic";
    description = ''
      Colorway variant:
      - 'classic': Original colors (ANSI gradients, purple/blue accents)
      - 'ruin': N0FRILLS magenta primary, cyan highlight
      - 'siege': N0FRILLS purple primary, teal highlight
      - 'ghost': N0FRILLS white primary, amber highlight
    '';
  };
  
  themeStyle = lib.mkOption {
    type = lib.types.enum ["basic" "advanced" "handcrafted"];
    default = "handcrafted";
    description = ''
      Visual style:
      - 'basic': Brutalist, minimal decoration (pure N0FRILLS philosophy)
      - 'advanced': Structured layout with functional grouping (tech-forward)
      - 'handcrafted': Artisanal box-drawing with gradient borders (original)
    '';
  };
};
```

### Phase 2: Color Definitions

Create `modules/home/default/themes/n0frills.nix`:

```nix
{
  # Shared colors across all colorways
  shared = {
    white  = "#eeeeee";
    gray   = "#8a8a8a";
    muted  = "#626262";
    dim    = "#4e4e4e";
    border = "#3a3a3a";
    bg     = "#1c1c1c";
  };

  # Colorway definitions
  colorways = {
    ruin = {
      primary   = "#d75fd7";
      accent    = "#ffafd7";
      hotAccent = "#ff5faf";
      highlight = "#5fd7d7";
    };
    siege = {
      primary   = "#875fd7";
      accent    = "#af87ff";
      hotAccent = "#5f5fff";
      highlight = "#00afaf";
    };
    ghost = {
      primary   = "#eeeeee";
      accent    = "#bcbcbc";
      hotAccent = "#eeeeee";
      highlight = "#ffaf00";
    };
  };
}
```

### Phase 3: Refactor starship.nix

Restructure `modules/home/default/starship.nix`:

1. **Define colorways** in `themes/ruinous-colors.nix`
   - `classic`: Current hardcoded colors extracted
   - `ruin`, `siege`, `ghost`: N0FRILLS palettes

2. **Define styles** in `themes/ruinous-styles.nix`
   - `basic`: Brutalist format string + module configs
   - `advanced`: Structured format string + module configs
   - `handcrafted`: Artisanal box-drawing format string + module configs

3. **Main starship.nix becomes a compositor**:
   ```nix
   let
     colors = import ./themes/ruinous-colors.nix;
     styles = import ./themes/ruinous-styles.nix;
     
     # Select colorway
     palette = colors.${cfg.themeVariant};
     
     # Select style and inject colors
     settings = styles.${cfg.themeStyle} { inherit lib palette cfg; };
   in {
     programs.starship.settings = settings;
   }
   ```

4. **Color injection pattern**:
   - Styles reference semantic color names (`palette.primary`, `palette.highlight`)
   - Colorway provides the actual hex values
   - Same style works with any colorway

### Phase 4: Host Configuration

Default behavior unchanged - `classic` + `handcrafted` is the default:

```nix
# Default (no config needed) - uses classic handcrafted
ruinous.starship.battery.enable = true;  # Just enable battery if needed

# Explicit default (same as above)
ruinous.starship = {
  theme = "ruinous";
  themeVariant = "classic";
  themeStyle = "handcrafted";
};
```

To switch to N0FRILLS colorway (matching tmux theme):

```nix
# hosts/chassis/users/jmeskill/home-configuration.nix
ruinous.starship = {
  theme = "ruinous";
  themeVariant = "ruin";       # Match tmux.powerkit.themeVariant
  themeStyle = "advanced";     # Tech-forward structured layout
};
```

Try the pure brutalist look:

```nix
ruinous.starship = {
  themeVariant = "ghost";
  themeStyle = "basic";        # Pure N0FRILLS philosophy
};
```

Keep artisanal box-drawing with N0FRILLS colors:

```nix
ruinous.starship = {
  themeVariant = "ruin";
  themeStyle = "handcrafted";  # Original structure, new colors
};
```

---

## Visual Comparison

### classic + handcrafted (default)

```
┍━━━━━┫jmeskill󰁥chassis󰌆┣━━━━╾╶ ~/Projects/nix-config ─╼━┫main:origin/main┣━╾─ M
┕━❯ λ                                                                      12.5s
```

Colors: ANSI gradient box (236-254), `purple` hostname, `blue` git, `208` package

### ruin + handcrafted

```
┍━━━━━┫jmeskill󰁥chassis󰌆┣━━━━╾╶ ~/Projects/nix-config ─╼━┫main┣━╾─ M
┕━❯ λ                                                            12.5s
```

Colors: `gray`/`muted` box, `#d75fd7` magenta hostname, `#5fd7d7` cyan directory

### ruin + advanced

```
[~] ~/Projects/nix-config [>] main [+2][~1]        rs 1.75 go 1.21 [@] jmeskill@chassis 12.5s
[>] λ
```

Left: `[~]` gray, directory `#5fd7d7` cyan, `[>]` gray, branch `#d75fd7` magenta, status `#ffafd7` accent
Right: languages `#626262` muted, `[@]` muted, hostname `#d75fd7`, duration muted

Full information density with semantic bracket notation.

### ruin + basic

```
jmeskill@chassis ~/Projects/nix-config main
> λ
```

Colors: `gray`@`#d75fd7` `#5fd7d7` `#d75fd7`
Brutalist: no brackets, no separators, pure information

### ghost + basic

```
jmeskill@chassis ~/Projects/nix-config main
> λ
```

Colors: `gray`@`#eeeeee` `#ffaf00` `#eeeeee` - stark, monochrome with amber pop

### ghost + advanced

```
[~] ~/Projects/nix-config [>] main [~1]              py 3.12 [@] jmeskill@chassis 3.2s
[>] λ
```

Left: `[~]` gray, directory `#ffaf00` amber, `[>]` gray, branch `#eeeeee` white
Right: languages muted, `[@]` muted, hostname `#eeeeee` white

Stark monochrome with amber highlight for navigation context.

### ghost + handcrafted

```
┍━━━━━┫jmeskill󰁥chassis┣━━━━╾╶ ~/Projects/nix-config ─╼━┫main┣━╾─
┕━❯ λ
```

Colors: `gray`/`muted` box, `#eeeeee` white hostname, `#ffaf00` amber directory

---

## Alignment with Tmux

Ensures visual consistency across shell layers:

| Tool | Theme Setting |
|------|--------------|
| tmux-powerkit | `theme = "n0frills"; themeVariant = "ruin";` |
| starship | `theme = "ruinous"; themeVariant = "ruin"; themeStyle = "advanced";` |

When both use the same colorway (e.g., `ruin`), the prompt and status bar share:
- Same `#d75fd7` magenta for active elements
- Same `#5fd7d7` cyan for highlights
- Same `#1c1c1c` background integration

**Note:** tmux uses `theme = "n0frills"` while starship uses `theme = "ruinous"` - the colorway variants (`ruin`, `siege`, `ghost`) are shared between both.

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `modules/home/default/themes/` | **CREATE** - Directory for theme definitions |
| `modules/home/default/themes/ruinous-colors.nix` | **CREATE** - All colorway palettes (classic, ruin, siege, ghost) |
| `modules/home/default/themes/ruinous-styles.nix` | **CREATE** - Style definitions (minimal, decorated) |
| `modules/home/default/options.nix` | **MODIFY** - Add theme/variant/style options |
| `modules/home/default/starship.nix` | **REFACTOR** - Compositor (combine colorway + style) |
| `hosts/chassis/users/jmeskill/home-configuration.nix` | **OPTIONAL** - Switch to ruin colorway |

---

## Next Steps

1. [ ] Create `modules/home/default/themes/` directory
2. [ ] Create `themes/ruinous-colors.nix` with all colorway palettes
3. [ ] Create `themes/ruinous-styles.nix` with minimal + decorated styles
4. [ ] Add options to `options.nix` (theme, themeVariant, themeStyle)
5. [ ] Refactor `starship.nix` to be a compositor
6. [ ] Test all 12 combinations:
   - `classic` × `handcrafted` (default, unchanged behavior)
   - `classic` × `basic`
   - `classic` × `advanced`
   - `ruin` × `basic`
   - `ruin` × `advanced`
   - `ruin` × `handcrafted`
   - `siege` × `basic`
   - `siege` × `advanced`
   - `siege` × `handcrafted`
   - `ghost` × `basic`
   - `ghost` × `advanced`
   - `ghost` × `handcrafted`
7. [ ] Verify alignment with tmux-powerkit themes (same colorway = visual match)
