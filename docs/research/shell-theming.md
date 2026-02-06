
# N0H Design System: Minimal Aesthetic

> [!SUMMARY] Summary
> A design system for terminal theming focusing on minimalism, functionality and efficient navigation.

# Cinematic Infrastructure: A Design System for High-Definition Documentary Interfaces

## 1. Introduction: The Intersection of DevOps and Cinematography

In the production of high-definition documentaries focusing on technology, cyber-warfare, or open-source intelligence, the terminal interface ceases to be merely a utility for the operator; it transforms into a primary character. It becomes the stage upon which the narrative plays out, a "set piece" that must communicate complex technical concepts to a lay audience without breaking immersion or resorting to the clichéd, cascading green text of 1990s "hacker" cinema. This report outlines the architecture and implementation of the "N0* Design System" (pronounced "N-Star"), a unified aesthetic protocol designed to harmonize disparate command-line tools—Bash, Fish, Zsh, Starship, Tmux, OpenCode, and various TUI frameworks—into a cohesive "Cinematic Operating System."

The requirement for a "minimal/scifi" aesthetic recorded in high definition imposes strict constraints that standard software configurations rarely satisfy. When a 4K or 8K camera sensor captures a screen, artifacts such as sub-pixel aliasing, inconsistent padding, jarring color shifts, and rapid refresh rates can destroy the visual fidelity of the shot.[1] Furthermore, a documentary environment requires a "consistent world." Whether the operator is monitoring system resources in `btop`, editing code in `opencode`, or navigating files in `xplr`, the viewer must perceive these activities as occurring within a single, unified computational environment—a "Ship OS" or "Mainframe" interface. Achieving this requires dismantling the default configurations of over ten distinct CLI tools and rebuilding them around a central design token system.

This report is structured as a comprehensive technical manual for production designers and systems architects. It moves from the theoretical foundations of the "N0* System"—defining the "Void" palette and "Signal" typography—through the granular configuration of shell environments and multiplexers, to the development of custom "hero props" using modern TUI libraries like Bubbletea, Textual, and Ratatui.

---

## 2. The N0* Design System: Theoretical Framework

### 2.1 The Philosophy of Negative Space in FUI
Fictional User Interfaces (FUI) in cinema often prioritize motion over function. However, for a documentary rooted in reality, the interface must be functional code that *looks* cinematic. The core tenet of the N0* System is the "Void Canvas." Unlike standard terminal themes which often use a dark grey background (e.g., `#1E1E2E`), high-end cinematic recording benefits from true black or near-black (`#09090B`). This "Void" background serves two purposes: it reduces the "light bleed" that can wash out a camera sensor in a darkened room, and it provides maximum contrast for the data, which is the "hero" of the shot.

We enforce a strict "Signal Color" policy. A single high-intensity hue (e.g., Cyan `#00D4FF` or Amber `#FFB800`) is used to indicate active focus or critical data. All other information is relegated to a "Context Palette" of desaturated greys and blues. This directs the viewer's eye immediately to the relevant action, a critical requirement when a shot may only last three seconds on screen.

### 2.2 Token Architecture and Inheritance
To maintain consistency across tools written in Rust (Ratatui, Starship), Go (Bubbletea, OpenCode), Python (Textual), and C++ (Btop), we cannot rely on manual color picking. We must establish a "Token Inheritance Map." This abstract definition serves as the single source of truth, from which all specific configuration files are derived.

http://googleusercontent.com/assisted_ui_content/1 



The diagram above illustrates the flow of design tokens. The "Void" token (`#09090B`) propagates to `statusbar-bg` in Tmux-Powerkit [2], `main_bg` in Btop [3], and `background` in OpenCode.[4] Any deviation in this inheritance creates a "seam" in the visual fabric, breaking the illusion of a unified OS.

### 2.3 Typography and Readability on Sensor
Standard coding fonts like "Source Code Pro" or "Fira Code" are optimized for LCD monitors viewed by human eyes at a distance of 20 inches. They are *not* optimized for camera sensors. Fine hairlines in fonts can cause moiré patterns or aliasing when filmed, especially if the focus plane is shallow—a common stylistic choice in modern documentaries.

For the N0* System, we mandate **JetBrains Mono** or **Berkeley Mono** in a **Medium** or **Bold** weight. The additional stroke width ensures that characters remain legible even if they fall slightly out of focus or if the footage is compressed for streaming. Furthermore, we rely heavily on **Nerd Fonts** symbols. In a cinematic context, a folder icon (``) is recognized faster than the word "Directory." Symbols transcend language barriers, making the footage more accessible to international audiences.

---

## 3. Layer 1: The Shell Environment (Bash, Fish, Zsh)

The shell is the foundational layer of our "Ship OS." While the viewer may not distinguish between Bash and Zsh, the behavior of the shell—autocompletion, syntax highlighting, and prompt rendering—creates the "texture" of the interaction.

### 3.1 Unifying the Triumvirate: Bash, Fish, Zsh
The N0* System must function identically regardless of the underlying shell. This requires abstracting the visual components away from the shell logic.

**Fish (Friendly Interactive Shell):** Recommended for "hero" shots involving typing. Fish's autosuggestion engine (the "ghost text" that appears as you type) is a powerful visual trope in sci-fi. It suggests that the computer is anticipating the user's intent.[5]
*   *Config:* We must force the suggestion color to a strict dark grey (`#333333`) to prevent it from competing with the active text.
*   *Suppression:* We must suppress the default welcome message ("Welcome to fish...") which breaks immersion.

**Zsh:** If Zsh is required for compatibility, we utilize `zsh-autosuggestions` and `zsh-syntax-highlighting` to replicate the Fish aesthetic.

**Bash:** Bash is the most restrictive but often necessary. Here, we rely entirely on the Starship prompt to provide visual interest, as Bash lacks the native "ghost text" capabilities of Fish.

### 3.2 The Zero-Latency HUD: Starship Configuration
**Starship** serves as the unifying visual layer. Written in Rust, it is fast enough to render instantly, avoiding the "pop-in" lag that can look like a glitch on camera. The default Starship configuration is too colorful ("rainbow") and cluttered for our minimal aesthetic. We strip it down to a "Zero-Latency HUD."

#### The "Enclosure" Concept
To give the prompt a "military/industrial" feel common in sci-fi (reminiscent of interfaces in *Andor* or *The Expanse*), we utilize Unicode box-drawing characters to create a physical "enclosure" for the command. This subtly suggests that the user is operating within a secured, structural system rather than a floating void.

#### Configuration: `starship.toml`
The following configuration enforces the N0* aesthetic: High contrast, sparse data, and structural delimiters.

```toml
# ~/.config/starship.toml

# Global: Disable the "package" and "language" clutter unless explicitly active
add_newline = true
command_timeout = 1000

# The Aesthetic: Flat, High-Contrast, Spaced
# We use a custom format string to manually place the box-drawing characters.
format = """
[╭─](bold #575B5F)\
$directory\
$git_branch\
$git_status\
$character\
"""

# Second line for input (splits the visual weight, common in tactical displays)
right_format = """$cmd_duration"""

[directory]
style = "bold #00D4FF"  # The "Signal" Color (Cyan)
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = " "
style = "bold #575B5F"
format = "[$symbol$branch]($style) "

[git_status]
style = "bold #FF0055" # Error color for dirty state
format = "[$all_status$ahead_behind]($style) "

[character]
# The interaction point. Changes color on error.
success_symbol = "[╰─λ](bold #00D4FF)"
error_symbol = "[╰─×](bold #FF0055)"

[cmd_duration]
min_time = 2000
format = "[$duration](italic #575B5F)"
```

**Contextual Analysis:**
*   **Structure:** The `╭─` and `╰─` characters frame the command. The prompt starts on one line and the input happens on the next. This "two-line" prompt is superior for filming because it guarantees that the user's typing always starts at the same horizontal coordinate, regardless of how long the directory path is. This consistency aids in framing the shot.
*   **Signal Color:** The `directory` is colored with the Signal Token (`#00D4FF`). This establishes location as the primary context.
*   **Error State:** If the previous command fails, the prompt character changes to a red `×` (`#FF0055`). This provides immediate, non-verbal feedback to the audience that "something went wrong," a critical narrative device.

---

## 4. Layer 2: The Structural Frame (Tmux & Tmux-Powerkit)

In a documentary setting, a single full-screen terminal window is rarely visually arresting. **Tmux** (Terminal Multiplexer) allows us to subdivide the screen into complex grids—running code on the left, monitoring systems on the right, and a log stream at the bottom. This "Command Center" layout is the hallmark of cinematic hacking.[6]

### 4.1 The "Floating" Layout Philosophy
Standard tiling window managers often fill the screen completely. For the N0* System, we employ a "Floating" layout philosophy. By setting the Tmux status bar background to match the "Void" background of the terminal (`#09090B`), the status bar appears to float in space rather than cutting the screen in half. This reduces visual weight and emphasizes the content panes.

### 4.2 Tmux-Powerkit: Modular Status Architecture
We select **Tmux-Powerkit** [2, 7] over standard `tmux-powerline` or `oh-my-tmux` because of its strict "contract-based" architecture. Powerkit separates the *theme* (palette) from the *renderer* (layout). This allows us to inject our N0* colors without rewriting the rendering logic.

#### Creating the N0* Theme
Powerkit themes are Bash scripts that define an associative array of colors.[2] We must author a custom theme file that strictly adheres to our Token Inheritance Map.

**File:** `~/.config/tmux-powerkit/themes/n-star.sh`

```bash
#!/usr/bin/env bash
# N0* System Theme for Tmux-Powerkit

declare -A THEME_COLORS=(
    # The "Void" Background - Matches the terminal bg for seamless blending
    [statusbar-bg]="#09090B"
    [statusbar-fg]="#575B5F"

    # Active Window - The "Signal" Color (Cyan)
    [window-active-base]="#00D4FF"
    [window-active-fg]="#000000"

    # Inactive Window - Receded into the background
    [window-inactive-base]="#1A1B26"
    [window-inactive-fg]="#575B5F"

    # Session Indicator - The "Anchor"
    [session-bg]="#00D4FF"
    [session-fg]="#000000"

    # Health States for Plugins (CPU, Mem) - Mapped to our palette
    [ok-base]="#00D4FF"       # Nominal
    [info-base]="#575B5F"     # Context
    [warning-base]="#FFB800"  # Caution
    [error-base]="#FF0055"    # Critical
)
```

**Implementation Detail:** Note the high contrast between `window-active` and `window-inactive`. The active window uses black text on a cyan background, while the inactive window uses grey text on a dark grey background. This extreme contrast ensures that the viewer instantly knows which pane is "live," preventing confusion in complex split-screen shots.

### 4.3 Pane Management: Borders as Narrative Cues
The borders between panes are not just dividers; they are focus indicators. Standard tmux borders are often thin, single-pixel lines. We require heavy, bold borders to define the grid.

**Configuration (`.tmux.conf`):**
```tmux
# Status Bar Position: Top (HUD style)
set-option -g status-position top

# Pane Borders
# Inactive panes fade into the void (#1A1B26 is barely visible against #09090B)
set -g pane-border-style fg="#1A1B26"
# Active pane glows with the Signal Color
set -g pane-active-border-style fg="#00D4FF"

# Popup Style (for Gum/Huh scripts)
set -g popup-border-style fg="#575B5F"
set -g popup-border-lines rounded
```

**Third-Order Insight:** The decision to place the status bar at the **top** (`status-position top`) rather than the bottom is significant. In cinema, "Head-Up Displays" (HUDs) typically have data at the top (e.g., fighter jet interfaces). Bottom bars are associated with standard consumer desktop OSs (Windows Taskbar, macOS Dock). Moving the bar to the top instantly signals "tactical interface" rather than "desktop workspace."

### 4.4 Configuring Plugins for Narrative Relevance
A documentary audience does not care about the date or the user's battery life. They care about "System Load" and "Network Traffic" because these metrics imply activity and stress. Therefore, we strip the status bar of non-diegetic information.

**Selected Plugins:**
1.  **CPU:** Indicates "thinking" or processing load.
2.  **Memory:** Indicates capacity.
3.  **Net Speed:** Indicates communication/data transfer.
4.  **Git:** Indicates the state of the project.

We explicitly exclude `datetime` and `battery` from the `tmux-powerkit` configuration to maintain the timeless, powered-in aesthetic of a mainframe.

---

## 5. Layer 3: System Vitality (Btop & Eza)

Even when the user is not actively typing, the screen must feel "alive." System monitors provide this ambient motion, serving as the "heartbeat" of the machine.

### 5.1 Btop: The Medical Monitor for Machines
**Btop** [3, 8] is the premier choice for cinematic system monitoring due to its high-resolution graphs and fluid animation. However, its default themes are often multicolored "rainbows" which read as "gaming PC" rather than "cyber-warfare workstation."

#### The Monochromatic Gradient Strategy
To align Btop with the N0* System, we employ a "Monochromatic Gradient" strategy. Instead of different colors for different cores, we use a single hue (Cyan) that varies in brightness to indicate intensity. This unifies the visual language.

**Theme File Analysis (`~/.config/btop/themes/n-star.theme`):**
Btop theme files use a specific key-value syntax.[9]

```bash
# Main Background (Matches Terminal Void)
theme[main_bg]="#09090B"

# Main Text
theme[main_fg]="#FFFFFF"

# Title (The "Label" of the box)
theme[title]="#575B5F"

# Highlight (The selected item)
theme[hi_fg]="#00D4FF"

# Graphs - The Gradient Strategy
# We use a shift from Dark Blue to Bright Cyan to show intensity
# This creates a "glowing" effect on the peaks of the graph
theme[cpu_start]="#0E2F44"
theme[cpu_mid]="#007799"
theme[cpu_end]="#00D4FF"

# Net Box (Traffic) - Use Amber to differentiate "Comms" from "Compute"
theme[net_box]="#575B5F"
theme[download_start]="#331A00"
theme[download_end]="#FFB800"
theme[upload_start]="#330000"
theme[upload_end]="#FF0055"
```

**Visual Logic:** By separating CPU (Cyan) and Network (Amber/Red) colors, we allow the audience to distinguish between "Thinking" (CPU) and "Communicating" (Network) purely through color code, even without reading the text labels. This is essential for visual storytelling where the viewer cannot read small text.

### 5.2 Eza: Structured Listings for the Camera
**Eza** (a modern replacement for `ls`) allows for extensive coloring of file listings.[10] The default colors often clash with dark backgrounds (e.g., dark blue on black). We must override `EZA_COLORS` or `LS_COLORS` to ensure legibility on camera.

**Mapping Strategy:**
*   **Directories:** **Bold Blue** (`#00D4FF`) - Represents structure.
*   **Executables:** **Bright GreeN0** (`#00FF00`) - Represents action/danger.
*   **Media/Data:** **Dimmed Grey** (`#575B5F`) - Passive data, receded.
*   **Symlinks:** **CyaN0** (`#00FFFF`) - Connections.

**Configuration:**
```bash
# Set in.bashrc /.zshrc / config.fish
export EZA_COLORS="di=1;34:ex=1;32:fi=37:ln=36:da=90:sn=90:sb=90:ur=90:gr=90:tr=90"
```
*   `di=1;34`: Directory, Bold, Blue.
*   `da=90`: Date column, Dark Grey.
*   `sn=90`: Size column, Dark Grey.

**Insight:** By setting the metadata columns (date, size, user, group) to Dark Grey (`90`), we visually suppress them. This ensures that the **Filename** is the hero of the list. On a cluttered screen, this hierarchy guides the viewer's eye to the relevant information (the file name) while keeping the technical details available but unobtrusive (the metadata).

---

## 6. Layer 4: The Intelligence (OpenCode)

**OpenCode** [11, 12] represents the AI agent in the documentary. Since "AI Assistants" are often anthropomorphized in modern sci-fi (e.g., JARVIS, HAL), this interface must look distinct from the "dumb" shell tools. It represents a higher order of intelligence.

### 6.1 Theming the Agent
OpenCode supports JSON-based theming.[4] We must override the default theme to remove "friendly" consumer colors and replace them with our "Systems" palette.

**File:** `~/.config/opencode/themes/n-star.json`
```json
{
  "colors": {
    "primary": "#00D4FF",
    "secondary": "#575B5F",
    "background": "#09090B",
    "surface": "#1A1B26",
    "error": "#FF0055",
    "success": "#00D4FF",
    "warning": "#FFB800"
  },
  "syntax": {
    "keyword": "#575B5F",
    "string": "#00D4FF",
    "comment": "#333333",
    "function": "#FFFFFF",
    "variable": "#E0E0E0"
  },
  "ui": {
    "border": "rounded",
    "padding": 
  }
}
```

### 6.2 Interaction Dynamics for Film
OpenCode allows for different agent modes, notably "Plan" and "Build".[13]
*   **The "Plan" Agent:** This read-only mode is ideal for exposition scenes. If the user asks, "Analyze this vulnerability," the Plan agent can output a text analysis without modifying files. This is safer for recording as it prevents accidental scrolling or file changes during a take.
*   **Visual Rhythm:** OpenCode supports Markdown rendering in the terminal. We can leverage this to create visual rhythm. When the AI responds, it formats its output with headers, bullet points, and code blocks.
    *   *N0* System Effect:* The AI's response streams in. Text appears in cyan. Code blocks appear in dark grey boxes (`#1A1B26`) with bright white text. This high contrast implies a "secure transmission" or a "data packet" being received, differentiating the AI's "voice" from the user's shell commands.

---

## 7. Layer 5: Navigation (Xplr)

**Xplr** [14] is a hackable, keyboard-centric file explorer configured via Lua. Standard file managers are often visually dense grids. For the N0* System, we transform Xplr into a "Miller Column" browser that mimics the flow of data streams.

### 7.1 Lua Configuration for Aesthetics
The default Xplr interface includes borders around every panel and detailed columns for permissions. We remove these to create a cleaner, more modern look.

**File:** `~/.config/xplr/init.lua`

```lua
version = '0.21.0'
local xplr = xplr

-- The Palette Table (Lua Version of N0* Token)
local c = {
    void = { fg = "Reset", bg = "Reset" },
    signal = { fg = "#00D4FF", bg = "Reset", add_modifiers = {"Bold"} },
    muted = { fg = "#575B5F", bg = "Reset" },
    error = { fg = "#FF0055", bg = "Reset" }
}

-- Layout: Remove borders to create a seamless flow
-- We override the builtin layout to remove the "Border" widgets
xplr.config.layouts.builtin.default = {
    "Table",
    "Log"
}

-- Node Styling
xplr.config.node_types.directory.style = c.signal
xplr.config.node_types.file.style = c.void
xplr.config.node_types.symlink.style = { fg = "#00D4FF", add_modifiers = {"Italic"} }

-- Minimalist Columns: Name and Size only.
-- Hiding Permissions/User/Group is a key "Cinema vs. Reality" decision.
xplr.config.general.table.header.style = c.muted
xplr.config.general.table.row.style = c.void

-- Define columns explicitly to exclude Permissions
xplr.config.general.table.columns = {
    { name = "icon", field = "icon", width = 2 },
    { name = "name", field = "name", width = 60 },
    { name = "size", field = "size", width = 10 },
}
```

**Reasoning:** In a documentary, seeing `-rwxr-xr-x` adds visual noise that often confuses lay audiences. Seeing just `Filename` and `Size` tells the story of "Data" without technical jargon. The removal of borders between the columns makes the interface look like a continuous stream of information rather than a spreadsheet.

---

## 8. Layer 6: The Props (Custom TUI Frameworks)

For specific narrative beats—such as "Decrypting File," "Establishing Connection," or "System Purge"—standard tools are insufficient. They are too generic. We must build custom "hero props" using modern TUI libraries. These are small, single-purpose programs that look like part of the OS but perform specific, scripted visual feats.

http://googleusercontent.com/assisted_ui_content/3 



### 8.1 Bubbletea & Lipgloss (Go): The "Hero" Modal
**Lipgloss** [15] is the style engine for Bubbletea. It excels at creating "physical" looking interfaces with thick borders, shadows, and distinct padding.
**Use Case:** A "Connection Established" or "Access Granted" modal dialog that pops up over the terminal.

**Design Rule:** Use `lipgloss.NewStyle().Border(lipgloss.ThickBorder())` to create a heavy, authoritative card look.
**Gradient Text:** Recent updates to Lipgloss allow for gradient text.[16] We can create a "scanning" effect where text shifts from Grey to White to Cyan, mimicking a biometric scan.

**Implementation Concept (Go):**
```go
var borderStyle = lipgloss.NewStyle().
    BorderStyle(lipgloss.RoundedBorder()).
    BorderForeground(lipgloss.Color("#00D4FF")). // Signal Color
    Padding(1, 2).
    Margin(1)

var textStyle = lipgloss.NewStyle().
    Foreground(lipgloss.Color("#FFFFFF")).
    Bold(true)

// Render
fmt.Println(borderStyle.Render(textStyle.Render("SECURE UPLINK ESTABLISHED")))
```

### 8.2 Textual (Python): The "Mainframe" Form
**Textual** [17, 18] brings CSS-like styling to the terminal. It is unique in supporting **CSS transitions** and animations natively.
**Use Case:** A complex data entry form or a database search interface.
**Animation:** We can animate the `opacity` of a panel from 0% to 100% on load. This mimics the "screen warm-up" effect of old CRT monitors, a beloved sci-fi trope that adds texture to the visuals.

**CSS Configuration:**
```css
/* textual.css */
Screen {
    background: #09090B;
}

#login-panel {
    border: heavy #00D4FF; /* Signal Color Border */
    background: #1A1B26;
    transition: opacity 1s out-cubic; /* CRT Fade In Effect */
    opacity: 0%; 
}

#login-panel.visible {
    opacity: 100%;
}
```

### 8.3 Ratatui (Rust): The Signal Analyzer
**Ratatui** [19, 20] provides the highest performance for data visualization.
**Use Case:** A real-time waveform, spectrogram, or histogram showing signal frequency.
**Gradient Blocks:** Using the `tui-gradient-block` extension [20], we can render bar charts that fade from blue to purple. This is visually distinct from the sharp, solid lines of Btop, offering a more "organic" look suitable for representing "raw data" or "voice patterns."

**Implementation Concept (Rust):**
```rust
// Concept Code for a Gradient Block in Ratatui
let block = GradientBlock::new()
   .top_gradient(LinearGradient::new(BLUE, CYAN))
   .borders(Borders::ALL)
   .title("SIGNAL FREQUENCY ANALYSIS");
```

### 8.4 Gum & Huh (Shell): The Quick Fix
**Gum** [21, 22] is a tool for "glue" scripts. It allows shell scripts to prompt for input with the aesthetics of Bubbletea.
**Use Case:** A simple confirmation script ("Delete Database? Y/N") or a spinner while a command runs.
**Theming:** Gum accepts configuration via flags. To avoid repeating flags, we create alias wrappers that enforce the N0* theme.

**Wrapper Script:**
```bash
# Define standard Gum styling variables
export GUM_CONFIRM_PROMPT_FOREGROUND="#00D4FF"
export GUM_CONFIRM_SELECTED_BACKGROUND="#00D4FF"
export GUM_CONFIRM_SELECTED_FOREGROUND="#000000"

# Usage in script
gum confirm "PURGE ALL LOGS?" && echo "Logs Purged"
```
This allows the production crew to generate interactive, themed prompts on the fly during a shoot without needing a compiled language like Go or Rust.

---

## 9. Layout and Composition Strategy

A coherent visual experience relies not just on the tools, but on how they are arranged on the screen. We adhere to a "Standard Hero Layout" optimized for 16:9 recording.

### 9.1 The "Golden Ratio" Split
We typically split the screen using Tmux into two primary zones based on the Golden Ratio (approx. 62% / 38%).
*   **Zone A (Left, 62%):** The "Active Workspace." This contains the editor (OpenCode) or the primary shell. This is where the human (or AI) action happens.
*   **Zone B (Right, 38%):** The "Passive Monitor." This contains `btop` or a scrolling log file. This provides constant, low-level motion (graphs updating, text scrolling) that keeps the shot visually interesting even if the operator pauses typing.
*   **Zone C (Top):** The Status Bar (Tmux-Powerkit). This frames the content and provides the HUD context.

### 9.2 Monochromatic Gradient & Glow Effects
As referenced in our Btop configuration, we utilize a specific coloring strategy for data density.
*   **Low Values:** Dark Blue (`#0E2F44`).
*   **Mid Values:** Medium Cyan (`#007799`).
*   **High Values / Peaks:** Bright Cyan (`#00D4FF`).

This creates a pseudo-"glow" effect. On a high-contrast OLED screen, the bright cyan peaks will appear to bloom slightly, reinforcing the sci-fi aesthetic without requiring post-production VFX.

---

## 10. Production Workflow & Deployment

To ensure consistency across multiple machines, shooting days, or retakes, the N0* System must be deployable as code.

### 10.1 The "Reset" Protocol
In documentary filmmaking, continuity is paramount. If a scene needs to be re-shot, the terminal state must be reset to *exactly* how it was at the start of the take. We implement a `reset_world.sh` script.

**Script Logic:**
1.  **Kill Sessions:** Terminate all existing `tmux` sessions.
2.  **Clean History:** Wipe `.bash_history` and `.zsh_history` to remove commands from the previous take.
3.  **Reset AI:** Clear `opencode` session cache to ensure the AI "types" the response again from scratch.
4.  **Launch Layout:** Start a new `tmux` session, split the windows according to the Golden Ratio, and launch `opencode` in the left pane and `btop` in the right pane automatically.

### 10.2 Hardware Considerations for Filming
*   **Contrast Check:** Before recording, view the screen through the camera monitor. Ensure the `#575B5F` (Grey) context text separates clearly from the `#09090B` (Black) background. If the camera's dynamic range crushes the blacks, bump the grey to `#777777`.
*   **Refresh Rate:** Set the monitor refresh rate to a multiple of the camera's shutter angle (e.g., 60Hz monitor for 30fps/60fps recording) to avoid flickering or "rolling bars."
*   **Cursor Blink:** **Disable it.** A blinking cursor creates editing nightmares. If you cut between two shots, and the cursor is "on" in one and "off" in the other, it creates a jump cut.
    *   *Fix:* `set -g cursor-style steady-block` in Tmux.

---

## 11. Conclusion

The N0* Design System transforms the terminal from a chaotic utility into a disciplined cinematic stage. By enforcing a strict "Void" palette, leveraging the modularity of Tmux-Powerkit and Starship, and utilizing the advanced rendering of Ratatui and Lipgloss for hero props, we create a digital world that feels authentic, high-tech, and consistent. The result is an interface that supports the narrative without distracting from it—the ultimate goal of documentary design.

## Related Concepts
- [[ASCII art]]
- [[Unicode box-drawing characters]]
- [[RoundedBorder() function from lipgloss package]]

