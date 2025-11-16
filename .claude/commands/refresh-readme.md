---
description: Show README.md changes from this session and git, then refresh
---

Analyze changes to README.md from multiple sources and provide a helpful summary:

1. **Review this Claude Code chat session context** to identify what changes were made to README.md during our conversation

2. **Check git for additional changes** made outside this session (e.g., with neovim):
   - Run `git diff HEAD README.md` to see uncommitted changes
   - Run `git diff HEAD` to see uncommitted changes for the rest of the repo
   - Run `git diff origin/main HEAD -- README.md` to see committed but unpushed changes
   - Run `git log --oneline -10 -- README.md` to see recent commit history
   - Run `git log --oneline -10` to see recent commit history for the rest of the repo

3. **Provide a clear summary** that includes:
   - Changes made in this Claude Code session (from chat context)
   - Changes made outside this session (from git diff/log)
   - When the README was last modified (git log timestamp)
   - Current state: uncommitted changes, committed but unpushed, or in sync with remote

4. **Then ask the user** which action they want to take:
   - Keep current changes (do nothing)
   - Restore from current commit (discard uncommitted changes) - `git restore README.md`
   - Pull latest from remote origin/main - `git fetch origin && git checkout origin/main -- README.md`
   - Show full diff for review

Execute the chosen git command if applicable.
