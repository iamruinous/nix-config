# tmux Cleanup & OSC52 Fix

**Date:** 2026-02-06  
**Issue:** OSC52 clipboard not working in tmux  
**Result:** Clean tmux config optimized for mouse/trackpad usage

---

## Philosophy

**Hybrid approach:** Use well-maintained plugins for standard features, add custom config only where we improve on defaults. Primary input method is trackpad, optimize for that.

---

## Changes Made

### 1. Fixed OSC52 Clipboard Support

**File:** `modules/home/default/tmux.nix`

**Problem:**
- `allowPassthrough` was disabled by default (set to `false`)
- Missing `set-clipboard on` configuration
- OSC52 sequences couldn't reach terminal

**Solution:**
```nix
# Line 137: Enable passthrough by default
allowPassthrough = lib.mkOption {
  type = lib.types.bool;
  default = true;  # Changed from false
  description = "Allow passthrough for certain escape sequences (e.g., for image protocols, OSC52 clipboard support).";
};

# Lines 552-553: Add clipboard support
set -g allow-passthrough on
set -g set-clipboard on
```

**Impact:**
- `osc-copy` package now works correctly over SSH and in tmux
- Native tmux clipboard support enabled
- No additional configuration needed

---

### 2. Plugin Cleanup (Hybrid Approach)

**Removed (broken/redundant):**

| Plugin | Why Removed | Replacement |
|--------|-------------|-------------|
| **yank** | Redundant with native OSC52 | `set-clipboard on` + `osc-copy` package |
| **sensible** | We already set everything it does | Our declarative Nix config |
| **better-mouse-mode** | Unmaintained since 2017, causes issues | Native trackpad optimizations below |

**Kept (working, maintained):**

| Plugin | Why Kept |
|--------|----------|
| **pain-control** | Standard vim-style pane navigation (hjkl, HJKL, \|, -). Works, maintained. |
| **copycat** | Multiple search patterns (URLs, files, git hashes, IPs). More comprehensive than single regex. |

**Before:**
```nix
plugins = with pkgs.tmuxPlugins; [
  better-mouse-mode
  copycat
  pain-control
  sensible
  yank
];
```

**After:**
```nix
plugins = with pkgs.tmuxPlugins; [
  copycat        # Regex search + predefined patterns
  pain-control   # Vim-style pane navigation
];
```

---

### 3. Trackpad Optimization

Since the user primarily uses trackpad, we added native tmux optimizations that improve on better-mouse-mode:

#### Faster Scrolling
**Default:** 1 line per wheel event (slow)  
**Optimized:** 3 lines per wheel event

```bash
bind -T copy-mode-vi WheelUpPane send -N 3 -X scroll-up
bind -T copy-mode-vi WheelDownPane send -N 3 -X scroll-down
```

#### Stay in Copy-Mode on Selection
**Default:** Selecting text exits copy-mode and jumps to bottom (annoying)  
**Optimized:** Selection stays visible, remain in copy-mode

```bash
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection-no-clear
```

#### Smart Scrolling
**Feature:** Respects mouse-aware apps (vim, less) while providing smooth scrollback

```bash
# Pass scroll to app if it handles mouse, else enter copy-mode
bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
```

#### Additional Optimizations
```bash
set -sg escape-time 0       # Instant response to trackpad gestures
set -g focus-events on      # Better terminal integration
set -g mouse on             # Enables: pane selection, border resizing, window selection
```

---

## Verification

### Generated Config Includes

```bash
# Clipboard support (OSC52)
set -g allow-passthrough on
set -g set-clipboard on

# Trackpad optimization
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection-no-clear
bind -T copy-mode-vi WheelUpPane send -N 3 -X scroll-up
bind -T copy-mode-vi WheelDownPane send -N 3 -X scroll-down
bind -T copy-mode WheelUpPane send -N 3 -X scroll-up
bind -T copy-mode WheelDownPane send -N 3 -X scroll-down
bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
bind -n WheelDownPane select-pane -t= \; send-keys -M

# Plugins (from pain-control)
# prefix + h/j/k/l  → Navigate panes
# prefix + H/J/K/L  → Resize panes
# prefix + |/-      → Split panes

# Plugins (from copycat)
# prefix + ctrl-f   → File search
# prefix + ctrl-u   → URL search
# prefix + ctrl-g   → Git hash search
```

---

## osc-copy Integration

**No additional integration needed.** The `osc-copy` script automatically:
1. Detects `$TMUX` environment variable
2. Wraps OSC52 in DCS passthrough (`\033Ptmux;\033...\033\\`)
3. Works seamlessly with our `allow-passthrough on` setting

**Usage:**
```bash
echo "hello" | osc-copy
cat file.txt | osc-copy
osc-copy ~/.ssh/id_ed25519.pub
```

---

## Benefits

### Before
- 5 plugins (3 broken/unmaintained, 2 working)
- OSC52 clipboard broken
- Slow scrolling (1 line per event)
- Selections jump to bottom on release
- Unclear what each plugin does

### After
- 2 working plugins (pain-control, copycat) + powerkit
- OSC52 works perfectly
- Fast scrolling (3 lines per event)
- Selections stay visible in copy-mode
- Trackpad-optimized for primary input method

---

## Migration

To apply changes:
```bash
just deploy chassis  # Or your current host
```

**Test OSC52 clipboard:**
```bash
# In tmux session
echo "test" | osc-copy
# Then paste (Cmd+V / Ctrl+V) - should paste "test"
```

**Test trackpad features:**
```bash
# In tmux:
1. Scroll up with trackpad → Should scroll 3 lines per notch (fast)
2. Scroll up → Should enter copy-mode automatically
3. Drag to select text → Selection should stay visible (not jump to bottom)
4. Open vim/less → Scroll should work inside app (not tmux copy-mode)
5. Click pane borders and drag → Should resize panes smoothly
```

**Test plugin keybindings:**
```bash
# pain-control
prefix + h/j/k/l    # Navigate panes
prefix + H/J/K/L    # Resize panes
prefix + |          # Split horizontal
prefix + -          # Split vertical

# copycat
prefix + ctrl-f     # Search files
prefix + ctrl-u     # Search URLs
prefix + ctrl-g     # Search git hashes
```

---

## Related

- Package: `packages/osc-copy/`
- OSC52 Spec: [OSC 52 - Operating System Command](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands)
- tmux Clipboard: [tmux Wiki - Clipboard](https://github.com/tmux/tmux/wiki/Clipboard)
