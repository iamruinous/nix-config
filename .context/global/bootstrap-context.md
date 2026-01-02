# Bootstrap Context Command

## Purpose
Refreshes the immutable context section of beacon files (`GEMINI.md`, `CLAUDE.md`) with the latest protocols and project specifics from the Single Source of Truth (`.context/`).

## Usage
Run this command when:
1.  You have updated global standards or project docs in `.context/`.
2.  The beacon files seem out of sync or missing critical info.
3.  Initializing a new agent environment.

## Command
```bash
make bootstrap-context
```

## Behavior
1.  Reads `GEMINI.md` and `CLAUDE.md`.
2.  Preserves the top "Memory & Scratchpad" section (user data).
3.  Injects the latest "Bootstrapped Context" below the delimiter.
4.  Ensures consistent structure across agent files.
