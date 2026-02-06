# Starship Theme Implementation Guide (N0FRILLS)

Date: 2026-02-06

This guide explains how to implement and select **N0FRILLS** themes for the Starship prompt within the RUiNAGE infrastructure.

## N0FRILLS Philosophy in Prompts
- **No Waste:** Removal of purely decorative elements in "Basic" and "Advanced" styles.
- **Visual Stability:** Consistent element positioning for multi-line stability.
- **Direct Voice:** Functional bracket notation (`[>]`, `[~]`, `[@]`) over descriptive text.
- **Absolute Consistency:** Shared colorways (`ruin`, `siege`, `ghost`) across all CLI tools.

## Theme Matrix

The Starship theme is a combination of a **Colorway** (Palette) and a **Style** (Layout).

| Variant (Colorway) | Style | Description |
|--------------------|-------|-------------|
| `classic` | `handcrafted` | Original prompt with classic colors (Default) |
| `ruin` | `basic` | Magenta/Cyan palette, brutalist layout |
| `ruin` | `advanced` | Magenta/Cyan palette, structured bracket notation |
| `siege` | `advanced` | Purple/Teal palette, structured bracket notation |
| `ghost` | `basic` | White/Amber palette, brutalist layout |

---

## Style Definitions

### 1. Basic (Brutalist)
Pure N0FRILLS aesthetic. Strips away all decorations, raw information only.
- **Layout:** `USER@HOST DIR BRANCH >`
- **Use Case:** Minimalist environments, small terminal windows.

### 2. Advanced (Structured Tech-Forward)
Uses the signature N0FRILLS bracket notation for semantic meaning.
- **[~]** Directory / Context
- **[>]** Branch / Action Point
- **[@]** Identity Anchor
- **Layout:** Left-aligned active context, right-aligned environment (languages, duration).

### 3. Handcrafted (Artisanal)
Preserves the distinctive box-drawing aesthetic with modern colorways applied.
- **Layout:** Two-line prompt with `┍━┫` frames.
- **Use Case:** Main workstations, high-fidelity terminal setups.

---

## Configuration

In this repository, Starship is managed via Home Manager. You can select your theme in your host's `home-configuration.nix`.

### Selection Pattern
```nix
ruinous.starship = {
  themeVariant = "ruin";       # classic | ruin | siege | ghost
  themeStyle = "advanced";     # basic | advanced | handcrafted
  battery.enable = true;       # Optional: enable battery module
};
```

### Example: The "Mainframe" Look (Ghost Advanced)
```nix
ruinous.starship = {
  themeVariant = "ghost";
  themeStyle = "advanced";
};
```
*Result:* A stark monochrome prompt with amber highlights for the current directory.

---

## Colorway Reference

| Token | ruin (Magenta) | siege (Purple) | ghost (Stark) |
|-------|----------------|----------------|---------------|
| `primary` | `#d75fd7` | `#875fd7` | `#eeeeee` |
| `highlight` | `#5fd7d7` | `#00afaf` | `#ffaf00` |
| `accent` | `#ffafd7` | `#af87ff` | `#bcbcbc` |
| `hotAccent` | `#ff5faf` | `#5f5fff` | `#eeeeee` |
| `success` | `#afd787` | `#5faf87` | `#bcbcbc` |
| `warning` | `#ffd787` | `#afaf5f` | `#ffaf00` |
| `error` | `#ff5faf` | `#5f5fff` | `#eeeeee` |
| `info` | `#87afff` | `#5f87ff` | `#bcbcbc` |

**Note:** Starship now maps git status, prompt success/error, and battery thresholds to the semantic tokens (`success`, `warning`, `error`, `info`) for consistent meaning across colorways.

---

## Alignment with tmux
To ensure a "Unified Shell" experience, always match your Starship `themeVariant` with your `tmux.powerkit.themeVariant`.

| Tool | Recommended Setting |
|------|---------------------|
| **tmux** | `theme = "n0frills"; themeVariant = "ruin";` |
| **Starship** | `themeVariant = "ruin"; themeStyle = "advanced";` |

---

## Validation Checklist
- [ ] **Contrast:** Ensure the `highlight` color is readable against your terminal background.
- [ ] **Symbols:** Confirm that Nerd Fonts are correctly rendered for the `handcrafted` style.
- [ ] **Right Prompt:** Verify that the `advanced` style correctly right-aligns language versions and command duration.
