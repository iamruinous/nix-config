# Gemini CLI Theme Implementation Guide (N0FRILLS)

Date: 2026-02-06

This guide explains how to implement the **N0FRILLS** design system in the Gemini CLI. N0FRILLS focuses on "No Waste," "Visual Stability," and "Absolute Consistency" across the RUiNAGE infrastructure.

## N0FRILLS Philosophy
- **No Waste:** Remove purely decorative elements.
- **Visual Stability:** Consistent positioning and color roles.
- **Direct Voice:** Terse output, functional markers over emojis.
- **Hex-Only:** All colors are defined by hex codes, not ANSI names.

## Shared Color Palette
These colors are consistent across all N0FRILLS colorways:

| Token | Hex | Role |
|-------|-----|------|
| `bg` | `#1c1c1c` | UI Backgrounds |
| `white` | `#eeeeee` | Primary text, Foreground |
| `gray` | `#8a8a8a` | Secondary text, labels |
| `muted` | `#626262` | Comments, help hints |
| `dim` | `#4e4e4e` | Inactive items |
| `border` | `#3a3a3a` | Dividers, frame borders |

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

## Implementation in Gemini CLI

Gemini CLI supports custom themes via the `ui.customThemes` object in `settings.json`.

### 1. Locate Configuration
The configuration file is typically located at:
- Linux/macOS: `~/.config/gemini/settings.json` (or as managed in this repo: `files/configs/gemini/settings.json`)

### 2. Define N0FRILLS Themes
Add the following `customThemes` block to your `settings.json`. 

#### N0FRILLS-ruin
```json
{
  "ui": {
    "customThemes": {
      "N0FRILLS-ruin": {
        "name": "N0FRILLS-ruin",
        "type": "custom",
        "Background": "#1c1c1c",
        "Foreground": "#eeeeee",
        "Gray": "#8a8a8a",
        "Comment": "#626262",
        "AccentPurple": "#d75fd7",
        "AccentCyan": "#5fd7d7",
        "AccentRed": "#ff5faf",
        "AccentBlue": "#5fd7d7",
        "AccentGreen": "#ffafd7",
        "AccentYellow": "#ffafd7",
        "LightBlue": "#5fd7d7",
        "text": {
          "primary": "#eeeeee",
          "response": "#d75fd7",
          "accent": "#5fd7d7",
          "link": "#5fd7d7"
        }
      }
    },
    "theme": "N0FRILLS-ruin"
  }
}
```

#### N0FRILLS-siege
```json
{
  "ui": {
    "customThemes": {
      "N0FRILLS-siege": {
        "name": "N0FRILLS-siege",
        "type": "custom",
        "Background": "#1c1c1c",
        "Foreground": "#eeeeee",
        "Gray": "#8a8a8a",
        "Comment": "#626262",
        "AccentPurple": "#875fd7",
        "AccentCyan": "#00afaf",
        "AccentRed": "#5f5fff",
        "AccentBlue": "#00afaf",
        "AccentGreen": "#af87ff",
        "AccentYellow": "#af87ff",
        "LightBlue": "#00afaf",
        "text": {
          "primary": "#eeeeee",
          "response": "#875fd7",
          "accent": "#00afaf",
          "link": "#00afaf"
        }
      }
    }
  }
}
```

#### N0FRILLS-ghost
```json
{
  "ui": {
    "customThemes": {
      "N0FRILLS-ghost": {
        "name": "N0FRILLS-ghost",
        "type": "custom",
        "Background": "#1c1c1c",
        "Foreground": "#eeeeee",
        "Gray": "#8a8a8a",
        "Comment": "#626262",
        "AccentPurple": "#eeeeee",
        "AccentCyan": "#ffaf00",
        "AccentRed": "#eeeeee",
        "AccentBlue": "#ffaf00",
        "AccentGreen": "#bcbcbc",
        "AccentYellow": "#bcbcbc",
        "LightBlue": "#ffaf00",
        "text": {
          "primary": "#eeeeee",
          "response": "#eeeeee",
          "accent": "#ffaf00",
          "link": "#ffaf00"
        }
      }
    }
  }
}
```

### 3. Apply the Theme
You can apply a theme by setting the `ui.theme` key in `settings.json` to the name of your custom theme (e.g., `"N0FRILLS-ruin"`).

Alternatively, use the in-CLI command:
1. Type `/theme`
2. Select your N0FRILLS theme from the list.

*Note: Ensure you remove any existing `"theme"` key from `settings.json` if you wish to use the `/theme` command interactively, as the file setting takes precedence.*

## Integration into nix-config
To maintain consistency across the fleet, these theme definitions should be managed via Home Manager.

1. **Host-level selection:** Define `ruinous.gemini.themeVariant` (e.g., in `hosts/chassis/users/jmeskill/home-configuration.nix`).
2. **Module implementation:** The `gemini` module should inject the appropriate `customThemes` block and `theme` selection into the generated `settings.json`.

---

## Validation Checklist
- [ ] **Contrast:** Check readability of model responses (Foreground) against the Background.
- [ ] **Syntax:** Verify code block highlighting using `AccentCyan` (Highlight) and `AccentPurple` (Primary).
- [ ] **UI Markers:** Ensure tool calls and status messages are clearly visible using `AccentRed` (HotAccent).
- [ ] **Alignment:** Confirm visual matching with `tmux` and `starship` when using the same colorway.
