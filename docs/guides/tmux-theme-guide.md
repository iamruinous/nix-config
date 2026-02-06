# Tmux Theme Implementation Guide

Date: 2026-02-06

This guide focuses on theming tmux beyond the status bar, using the existing N0FRILLS colorways (ruin, siege, ghost) already implemented in tmux-powerkit.

## Current Repo State
- N0FRILLS tmux-powerkit themes live in `packages/tmux-powerkit/default.nix`.
- The tmux module is in `modules/home/default/tmux.nix` and can override core tmux options directly.

## Core Theming Surface Areas
These options cover the major UI surfaces:
- Messages and command prompt: `message-style`, `message-command-style`. citeturn1search3
- Copy and choice modes: `mode-style`, `copy-mode-match-style`, `copy-mode-current-match-style`. citeturn0search4
- Menus: `menu-style`, `menu-selected-style`, `menu-border-style`, plus `display-menu`. citeturn0search3
- Popups: `popup-style`, `popup-border-style`, `popup-border-lines`, plus `display-popup`. citeturn1search2turn1search6
- Pane numbers: `display-panes-colour`, `display-panes-active-colour`. citeturn0search1
- Clock mode: `clock-mode-colour`, `clock-mode-style`. citeturn0search4turn0search7

## Suggested N0FRILLS Mapping
Use the same shared tokens used in tmux-powerkit:
- `bg`: `#1c1c1c`
- `fg`: `#eeeeee`
- `border`: `#3a3a3a`
- `muted`: `#626262`
- `dim`: `#4e4e4e`
- `primary`, `accent`, `hotAccent`, `highlight`: per colorway

Suggested styles:
- `message-style`: `fg=<fg>,bg=<bg>`
- `message-command-style`: `fg=<primary>,bg=<bg>,bold`
- `mode-style`: `fg=<bg>,bg=<primary>,bold`
- `copy-mode-match-style`: `fg=<bg>,bg=<accent>`
- `copy-mode-current-match-style`: `fg=<bg>,bg=<hotAccent>,bold`
- `menu-style`: `fg=<fg>,bg=<bg>`
- `menu-selected-style`: `fg=<bg>,bg=<primary>,bold`
- `menu-border-style`: `fg=<border>,bg=<bg>`
- `popup-style`: `fg=<fg>,bg=<bg>`
- `popup-border-style`: `fg=<primary>,bg=<bg>`
- `display-panes-colour`: `<muted>`
- `display-panes-active-colour`: `<primary>`
- `clock-mode-colour`: `<primary>`

## Example tmux Options (Generic)
```tmux
set -g message-style "fg=#eeeeee,bg=#1c1c1c"
set -g message-command-style "fg=#d75fd7,bg=#1c1c1c,bold"

set -g mode-style "fg=#1c1c1c,bg=#d75fd7,bold"
set -g copy-mode-match-style "fg=#1c1c1c,bg=#5fd7d7"
set -g copy-mode-current-match-style "fg=#1c1c1c,bg=#ff5faf,bold"

set -g menu-style "fg=#eeeeee,bg=#1c1c1c"
set -g menu-selected-style "fg=#1c1c1c,bg=#d75fd7,bold"
set -g menu-border-style "fg=#3a3a3a,bg=#1c1c1c"

set -g popup-style "fg=#eeeeee,bg=#1c1c1c"
set -g popup-border-style "fg=#d75fd7,bg=#1c1c1c"
set -g popup-border-lines "rounded"

set -g display-panes-colour "#626262"
set -g display-panes-active-colour "#d75fd7"

set -g clock-mode-colour "#d75fd7"
set -g clock-mode-style 24
```

## Session Chooser (choose-tree)
The session chooser is built on `choose-tree`. You can customize its content with format strings using the `-F` flag, and bind it to a key for consistent access. citeturn1search1

Example:
```tmux
bind-key s choose-tree -Z -F "#[fg=#d75fd7]#S #[fg=#8a8a8a]#W" -O name
```

## Integration Options in This Repo
1. Add a N0FRILLS theme block to `modules/home/default/tmux.nix` using these options.
2. Keep the tmux-powerkit theme for status bar and pane styles, and use the tmux options above for menus, popups, messages, and copy mode.
3. If you want dynamic switching, store palette tokens as `@` variables and reference them in styles.

## Validation Checklist
- Command prompt is legible in both normal and command mode.
- Copy mode selection and search matches are high contrast.
- Menu and popup borders are visible on the background.
- Session chooser formatting is readable and minimal.
