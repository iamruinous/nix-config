---
name: pr
description: Branch, commit, and create PR without auto-merge. Use when you want to create a pull request for review before merging.
compatibility: Requires git, gh (GitHub CLI) or tea (Forgejo CLI)
metadata:
  author: ruinous.ai
  version: "1.0"
---

# Create PR

Automate git workflow up to PR creation: create branch, commit changes, create PR, but DO NOT merge.

## Steps

1. **Detect CLI tool**:
   - Run `git remote get-url origin` to get the remote URL
   - If URL contains `github.com` → use `gh` (GitHub CLI)
   - Otherwise → use `tea` (Forgejo CLI)

2. **Check prerequisites**:
   - Run `git status` to verify there are changes to commit
   - Run `git branch --show-current` to get current branch
   - If on `main`:
     - Run `git checkout main && git pull origin main`
     - Create a new branch
   - If already on a feature branch, use it

3. **Create branch** (if on main):
   - Generate branch name using format: `<type>/<short-description>`
   - Types: `feat/`, `fix/`, `docs/`, `refactor/`, `test/`, `chore/`
   - Example: `feat/add-apprise-notifier`
   - Run `git checkout -b <branch-name>`

4. **Stage and commit**:
   - Run `git add -A` to stage all changes
   - Run `git diff --cached --stat` to review what will be committed
   - Generate commit message following Conventional Commits with emoji:
     - ✨ `feat`: New feature
     - 🐛 `fix`: Bug fix
     - 📝 `docs`: Documentation
     - ♻️ `refactor`: Refactoring
     - ⚙️ `chore`: Maintenance
   - Include body explaining why/what
   - MUST include footer: `🤖 Generated with [ruinous.ai](https://agents.ruinous.ai) 🦾✨`
   - Use HEREDOC format:
     ```bash
     git commit -S -m "$(cat <<'EOF'
     ✨ feat(scope): short description

     Detailed explanation of what changed and why.

     - Key change 1
     - Key change 2

     🤖 Generated with [ruinous.ai](https://agents.ruinous.ai) 🦾✨
     EOF
     )"
     ```

5. **Push and create PR**:
   - Run `git push -u origin <branch-name>`
   - Generate PR title using conventional commit format
   - Generate PR body with Summary section
   - For GitHub:
     ```bash
     gh pr create --title "<title>" --body "$(cat <<'EOF'
     ## Summary
     <bullet points>
     EOF
     )"
     ```
   - For Forgejo:
     ```bash
     tea pr create --title "<title>" --description "$(cat <<'EOF'
     ## Summary
     <bullet points>
     EOF
     )"
     ```

6. **STOP - Do NOT merge**:
   - Return the PR URL to the user
   - Stay on the feature branch
   - Inform user: "PR created. Ready for review. Merge manually when ready."

## Rules

- Never force push
- Commit messages MUST have body (not just one-line)
- All commits MUST be signed (`-S` flag)
- All commits MUST include the AI footer
- Branch names MUST use type prefix
