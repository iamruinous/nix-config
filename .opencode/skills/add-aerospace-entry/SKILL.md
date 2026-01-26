---
name: add-aerospace-entry
description: Add an AeroSpace window rule to assign an app/window to a workspace (macOS only)
compatibility: macOS with AeroSpace window manager
metadata:
  author: ruinous.ai
  version: "1.0"
parameters:
  mode:
    type: select
    description: How to identify the target
    required: true
    options:
      - label: "Interactive (Recommended)"
        description: "List running apps/windows and select interactively"
      - label: "By app-id"
        description: "Provide the bundle ID directly (e.g., com.spotify.client)"
      - label: "By window title"
        description: "Match windows by title regex"
  workspace:
    type: string
    description: Target workspace (A-Z, 1-9)
    required: true
    placeholder: "S"
  layout:
    type: select
    description: Window layout mode
    required: false
    options:
      - label: "Tiled (default)"
        description: "Window participates in tiling layout"
      - label: "Floating"
        description: "Window floats above tiled windows"
---

# Add AeroSpace Entry

Add a window detection rule to AeroSpace configuration for automatic workspace assignment on macOS.

## Platform Check

**This skill is macOS only.** Before proceeding:
```bash
uname -s  # Must return "Darwin"
```

If not Darwin, inform user: "AeroSpace is macOS-only. This skill cannot run on Linux/NixOS."

## Parameter Handling

**If parameters are missing from `$ARGUMENTS`, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "How do you want to identify the target window/app?",
      header: "Selection Mode",
      options: [
        { label: "Interactive (Recommended)", description: "List running apps and select" },
        { label: "By app-id", description: "I know the bundle ID" },
        { label: "By window title", description: "Match by window title regex" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `[app-id|window-title] <workspace> [floating]`
- Example: `com.spotify.client S` (assign Spotify to workspace S)
- Example: `"- Jade (Work)$" B` (assign Chrome Work profile to workspace B)
- Example: `com.apple.finder floating` (make Finder windows float)

## Discovery Commands

### List All Running Apps
```bash
aerospace list-apps --json
```

Output format:
```json
[
  {
    "app-bundle-id": "com.spotify.client",
    "app-name": "Spotify",
    "app-pid": 12345
  }
]
```

### List All Windows
```bash
aerospace list-windows --all --json
```

Output format:
```json
[
  {
    "app-name": "Google Chrome",
    "window-id": 55,
    "window-title": "GitHub - Google Chrome - Jade (Work)"
  }
]
```

## Configuration File Location

For `jbookpro` host:
```
hosts/jbookpro/users/jmeskill/aerospace.toml
```

## TOML Entry Patterns

### Basic App Assignment (by app-id)
```toml
[[on-window-detected]]
if.app-id = 'com.spotify.client'
run = 'move-node-to-workspace S'
```

### Window Title Matching (for apps with multiple windows/profiles)
```toml
[[on-window-detected]]
if.app-id = 'com.google.Chrome'
if.window-title-regex-substring = '- Jade (Work)$'
run = 'move-node-to-workspace B'
```

### Floating Window
```toml
[[on-window-detected]]
if.app-id = 'com.apple.finder'
run = 'layout floating'
check-further-callbacks = true
```

### Combined: Float + Move to Workspace
```toml
[[on-window-detected]]
if.app-id = 'tv.plex.desktop'
run = 'layout floating'
check-further-callbacks = true

[[on-window-detected]]
if.app-id = 'tv.plex.desktop'
run = 'move-node-to-workspace P'
```

## Steps

### 1. Interactive Mode (Recommended)

1. **Run discovery commands:**
   ```bash
   aerospace list-apps --json
   aerospace list-windows --all --json
   ```

2. **Present options to user:**
   ```
   mcp_question({
     questions: [
       {
         question: "Which app do you want to configure?",
         header: "Select App",
         multiple: false,
         options: [
           // Generated from aerospace list-apps output
           { label: "Spotify", description: "com.spotify.client" },
           { label: "Discord", description: "com.hnc.Discord" },
           // ... etc
         ]
       }
     ]
   })
   ```

3. **If app has multiple windows (like Chrome), ask about title matching:**
   ```
   mcp_question({
     questions: [
       {
         question: "This app has multiple windows. Match by title?",
         header: "Title Filter",
         options: [
           { label: "All windows", description: "Any window from this app" },
           { label: "By title pattern", description: "Match specific window titles" }
         ]
       }
     ]
   })
   ```

4. **Ask for workspace:**
   ```
   mcp_question({
     questions: [
       {
         question: "Which workspace should this app/window go to?",
         header: "Workspace",
         options: [
           { label: "A", description: "AI Space" },
           { label: "B", description: "Browser (Work)" },
           { label: "C", description: "Chat Space" },
           { label: "E", description: "Element" },
           { label: "F", description: "Fantastical" },
           { label: "G", description: "Glance" },
           { label: "M", description: "Mail" },
           { label: "N", description: "Claude" },
           { label: "O", description: "Obsidian" },
           { label: "S", description: "Spotify" },
           { label: "T", description: "Todoist" },
           { label: "W", description: "WezTerm" },
           { label: "X", description: "Telegram/Discord" },
           { label: "Y", description: "Available" },
           { label: "1", description: "Messages" },
           { label: "2", description: "Personal Browser" }
         ]
       }
     ]
   })
   ```

5. **Ask about floating:**
   ```
   mcp_question({
     questions: [
       {
         question: "Should this window float or tile?",
         header: "Layout",
         options: [
           { label: "Tiled (default)", description: "Participate in tiling layout" },
           { label: "Floating", description: "Float above tiled windows" }
         ]
       }
     ]
   })
   ```

### 2. Read Current Config

```bash
cat hosts/jbookpro/users/jmeskill/aerospace.toml
```

Identify the appropriate section for the new entry:
- Floating windows section (after line ~203)
- Chrome-related section (around line ~227)
- Full Screen apps section (around line ~255)
- Or create a new section with a comment

### 3. Generate TOML Entry

Based on user selections, generate the appropriate `[[on-window-detected]]` block.

### 4. Insert Entry

Use `mcp_edit` to add the entry in the appropriate location:
- Group with similar apps (Chrome entries together, etc.)
- Add a comment if it's a new category
- Maintain consistent formatting

### 5. Validate & Reload

```bash
# Validate TOML syntax
aerospace reload-config 2>&1
```

If reload fails, show the error and offer to revert.

### 6. Verify

```bash
# List current workspace assignments
aerospace list-workspaces --all --json
```

## Existing Workspace Assignments (for reference)

| Workspace | Current Apps |
|-----------|--------------|
| 1 | Messages |
| 2 | Chrome (Personal - "- Jade$") |
| A | Gemini AI apps |
| B | Chrome (Work - "- Jade (Work)$") |
| C | Chat (Google Chat) |
| E | Element |
| F | Fantastical |
| G | Glance |
| M | Mimestream (Mail) |
| N | Claude Desktop |
| O | Obsidian |
| S | Spotify |
| T | Todoist |
| W | WezTerm |
| X | Telegram, Discord |

## Floating Apps (for reference)

- Finder
- Plex
- 1Password
- LuLu Alert windows
- Chrome Picture-in-Picture

## Example Workflow

```
User: /add-aerospace-entry

Agent: [Runs aerospace list-apps --json]
Agent: "Which app do you want to configure?"
  - Antigravity (com.google.antigravity)
  - Spotify (com.spotify.client)
  - Discord (com.hnc.Discord)
  - [Enter other...]

User: Selects "Antigravity"

Agent: "Which workspace should this app go to?"
  - A (AI Space)
  - Y (Available)
  - [Enter other...]

User: Selects "Y"

Agent: "Should this window float or tile?"
  - Tiled (default)
  - Floating

User: Selects "Tiled (default)"

Agent: 
1. Adds to aerospace.toml:
   ```toml
   # Y - Antigravity Space
   
   [[on-window-detected]]
   if.app-id = 'com.google.antigravity'
   run = 'move-node-to-workspace Y'
   ```

2. Also enables the workspace keybinding if not already active:
   - Uncomments `alt-y = 'workspace Y'`
   - Uncomments `alt-shift-y = 'move-node-to-workspace Y'`

3. Runs `aerospace reload-config`

Agent: "Added Antigravity to workspace Y. Reload successful."
```

## Post-Completion Checklist

- [ ] App/window identified correctly
- [ ] TOML entry syntax is valid
- [ ] Entry placed in appropriate section
- [ ] Workspace keybinding enabled (if using new workspace)
- [ ] `aerospace reload-config` succeeds
- [ ] Window moves to correct workspace on next launch
