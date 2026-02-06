# OpenCode Theme Implementation Guide

Date: 2026-02-06

This guide explains how to build and install a custom OpenCode theme, and how to integrate it into this repo’s configuration.

## Theme Files and Discovery
OpenCode loads JSON theme files from multiple locations. Custom themes should live in one of the user or project directories.

Recommended placement for this repo:
- `files/configs/opencode/themes/` in the repo
- Mapped to `~/.config/opencode/themes/` via Home Manager

Discovery order (later overrides earlier):
1. Built-in themes
2. `~/.config/opencode/themes/*.json` or `$XDG_CONFIG_HOME/opencode/themes/*.json`
3. `<project>/.opencode/themes/*.json`
4. `./.opencode/themes/*.json`

## Minimal Theme Skeleton
A valid theme requires the fields below. All values can be hex, ANSI 0-255, a named reference, or `none`.

```json
{
  "$schema": "https://opencode.ai/theme.json",
  "theme": {
    "primary": "#d75fd7",
    "secondary": "#8a8a8a",
    "accent": "#5fd7d7",
    "text": "#eeeeee",
    "background": "#1c1c1c"
  }
}
```

## Extended Keys (If Supported)
The public docs only show the minimal keys above. If additional theme keys are supported in your OpenCode version, map them using the same N0FRILLS palette tokens.

## Suggested N0FRILLS Mapping
Use the existing palette from `modules/home/default/starship.nix` as a baseline:
- `background`: `bg`
- `text`: `white`
- `textMuted`: `muted`
- `primary`: colorway `primary`
- `accent`: colorway `highlight`
- `secondary`: `gray`
- `error`: `hotAccent`
- `warning`: `accent`
- `success`: `highlight`

Then apply tokens to the OpenCode-specific slots:
- `backgroundPanel`: `bg`
- `backgroundElement`: `border`
- `border`: `border`
- `borderActive`: `primary`
- `diffAdded`: `highlight`
- `diffRemoved`: `hotAccent`
- `markdownHeading`: `primary`
- `markdownCode`: `accent`
- `syntaxKeyword`: `primary`
- `syntaxString`: `accent`
- `syntaxComment`: `muted`

## Configure Theme in OpenCode
OpenCode themes can be selected via config or the theme picker. The config field is `theme`.

Example config snippet:
```json
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "n0frills-ruin"
}
```

## Wire It Into This Repo
1. Add themes to `files/configs/opencode/themes/`.
2. Update the Home Manager module that provisions OpenCode config to include the theme directory.
3. Set `theme` in `files/configs/opencode/opencode.json`.

Relevant files:
- `files/configs/opencode/opencode.json`
- `modules/home/default/ruinage/assistants/opencode.nix`

## Validation Checklist
- `opencode` loads the theme without errors.
- Markdown rendering is readable (headings, code blocks, lists).
- Diff colors clearly separate added and removed lines.
- Syntax colors are distinct but not noisy.
