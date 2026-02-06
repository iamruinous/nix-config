# N0FRILLS Terminal Theme Gaps and Improvements

Date: 2026-02-06

## Current State (From Repo)
Source of truth today:
- Shared palette and colorways live in `modules/home/default/starship.nix`.
- Tmux N0FRILLS themes live in `packages/tmux-powerkit/default.nix`.

Shared colors:
- `white #eeeeee`, `gray #8a8a8a`, `muted #626262`, `dim #4e4e4e`, `border #3a3a3a`, `bg #1c1c1c`.

Colorways (starship):
- `ruin`: primary `#d75fd7`, accent `#ffafd7`, hotAccent `#ff5faf`, highlight `#5fd7d7`.
- `siege`: primary `#875fd7`, accent `#af87ff`, hotAccent `#5f5fff`, highlight `#00afaf`.
- `ghost`: primary `#eeeeee`, accent `#bcbcbc`, hotAccent `#eeeeee`, highlight `#ffaf00`.

Tmux themes add UI roles using the same palette, including `ok-base`, `good-base`, `warning-base`, and `error-base`, but those are all mapped to shared or accent colors rather than a full semantic spectrum.

## Gaps for a Terminal Color Scheme
Terminal theming requires a full ANSI 16-color palette plus UI surfaces. The current N0FRILLS colorway system lacks the following explicit definitions:

- ANSI base and bright colors (indices 0-15): no canonical mapping for black/red/green/yellow/blue/magenta/cyan/white and their bright variants.
- Success and warning hues: no dedicated green/yellow equivalents. This creates ambiguity for apps that assume ANSI color semantics (diffs, `ls`, `git`, compilers).
- Cursor and selection colors: not yet defined per colorway.
- Tab bar and window chrome colors: required to align WezTerm UI surfaces with N0FRILLS.
- Copy-mode and quick-select highlight colors: needed for WezTerm’s auxiliary UIs.
- Consistency rule: `classic` still uses named/ANSI colors while other colorways are hex. This conflicts with the N0FRILLS “hex-only” principle documented in `docs/plans/starship-n0frills-theme.md`.

## Recommendations
1. Define a canonical N0FRILLS terminal palette contract.
- Add explicit keys for `background`, `foreground`, `cursor`, `selection`, and the 16 ANSI colors.
- Keep `shared` for neutrals, but add `success`, `warning`, `error`, and `info` per colorway.
- Use hex everywhere, including `classic`, to maintain consistency.

2. Build ANSI mappings per colorway.
- `ansi[0]` (black): `bg`.
- `ansi[7]` (white): `white`.
- `ansi[1]` (red): `hotAccent`.
- `ansi[4]` (blue): `primary` or a desaturated variant if primary is magenta/purple.
- `ansi[6]` (cyan): `highlight` when it is cyan/teal.
- `ansi[5]` (magenta): `primary` for ruin/siege, `accent` for ghost.
- `ansi[2]` (green) and `ansi[3]` (yellow): **new colors required** to avoid semantic collisions.

3. Add a minimal “signal pair” for green/yellow.
- Create two new tokens per colorway: `success` and `warning`.
- If you want to keep the palette tight, derive these from `highlight` and `accent` using perceptual shifts (HSL with controlled luminance).

4. Standardize UI surfaces for WezTerm.
- Cursor: `cursor_bg` = `white` or `primary`, `cursor_fg` = `bg`, `cursor_border` = `cursor_bg`.
- Selection: `selection_bg` = `border` or `dim`, `selection_fg` = `white`.
- Tab bar: `tab_bar.background` = `bg`, inactive tabs = `dim`/`muted`, active tabs = `primary` with `bg` fg.
- Copy mode and quick select: use `highlight` for active labels, `accent` for matches.

## Suggested Next Steps
1. Create a `themes/n0frills-terminal.nix` palette module that exports all terminal-required keys, including ANSI 16 colors and UI surfaces.
2. Generate WezTerm TOML schemes from that palette for `ruin`, `siege`, and `ghost`.
3. Update `modules/home/default/wezterm.nix` to point `color_scheme` to the selected N0FRILLS variant.
4. Add a verification checklist: ANSI color swatches, `ls` colors, `git diff`, and WezTerm tab bar visual check.
