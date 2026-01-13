# osc-copy

Copy to clipboard via OSC 52 escape sequence. Works over SSH and inside tmux.

## Overview

Uses the OSC 52 terminal escape sequence to copy text to your **local** system clipboard, even when running on a remote machine over SSH.

## Requirements

Your terminal must support OSC 52:
- **wezterm** ✓
- **kitty** ✓
- **iTerm2** ✓
- **alacritty** ✓
- **foot** ✓

## Usage

```bash
# Pipe output
echo "hello" | osc-copy
cat file.txt | osc-copy

# Copy a file
osc-copy file.txt

# Copy SSH public key
cat ~/.ssh/id_ed25519.pub | osc-copy
```

## How It Works

1. Encodes input as base64
2. Wraps in OSC 52 escape sequence: `\033]52;c;<base64>\a`
3. If inside tmux, wraps in DCS passthrough: `\033Ptmux;\033...\033\\`
4. Terminal interprets the sequence and copies to local clipboard

## tmux Support

The script automatically detects tmux and uses DCS passthrough to ensure the OSC 52 sequence reaches your terminal.

For best results, ensure tmux has clipboard support enabled:

```tmux
set -g set-clipboard on
```
