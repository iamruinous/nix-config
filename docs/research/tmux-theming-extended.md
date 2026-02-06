# Tmux Theming Research (Extended)

Date: 2026-02-06

## Scope
This extends the existing tmux theming research with UI surfaces beyond the status line and window list, focusing on command prompt, session chooser, menus, and popups.

## Command Prompt and Messages
Tmux renders both status messages and the command prompt using `message-style`. When vi-style command mode is active in the prompt, `message-command-style` applies. These are core surfaces for command entry and feedback. citeturn1search3

Related options:
- `message-style`
- `message-command-style`
- `status-keys` influences whether vi command mode is used in the prompt. citeturn1search5

## Copy and Choice Modes
Window modes use `mode-style` for selection visuals in copy mode and other modes. This is the primary control for the selection background during copy operations. citeturn0search4

## Menus
Tmux supports menus via `display-menu` and styles them using menu options. Styling keys include:
- `menu-style`
- `menu-selected-style`
- `menu-border-style`
These control the overall menu, selected entry, and border appearance. Menu placement is configurable with `display-menu` options like `-x`, `-y`, and `-T` for a title. citeturn0search3

## Popups
Popups are separate from menus and can be styled via:
- `popup-style`
- `popup-border-style`
- `popup-border-lines`
The `display-popup` command controls size, position, and title. The man page documents `-w`, `-h`, `-x`, `-y`, `-T`, and style flags. citeturn1search2turn1search6

## Session Chooser and Choose Tree
Session and window selection uses `choose-tree` and other choose modes. Formatting is driven by tmux format strings, and `choose-tree -F` controls how each line is rendered. This enables a custom session chooser layout that matches the theme’s information hierarchy. citeturn1search1

## Pane Numbers and Clock
Additional themable surfaces in the core tmux UI include:
- Pane number overlays via `display-panes-colour` and `display-panes-active-colour`. citeturn0search1
- Clock mode colors via `clock-mode-colour` and style via `clock-mode-style`. citeturn0search4turn0search7

## Style Syntax Reference
Style strings use `fg=`, `bg=`, and attributes such as `bold`, `italics`, and `dim`. Colors support named values, 256-color indices, or `#RRGGBB` hex. Embedded styles can be used inside formatted text with `#[...]`. citeturn0search5turn0search7
