# Git Behavior Guidelines for AI Agents

> **⚠️ CRITICAL: The main branch is protected and does not accept direct commits.**
>
> You MUST use feature branches and pull requests for ALL changes. Direct commits to main will be rejected. See the [Branching Strategy](#branching-strategy) section for required workflow.

## Pre-Change Checklist

**Before making ANY code changes, verify:**

1. [ ] **Am I on a feature branch?** Run `git branch --show-current`
   - If on `main` → create a feature branch first
   - If on a feature branch → proceed

2. [ ] **Does a draft PR exist for this branch?**
   - If no → create one after your first commit with `gh pr create --draft`
   - If yes → continue working

3. [ ] **Is the PR task list up to date?**
   - Mark completed tasks with `[x]`
   - Add new tasks discovered during implementation
   - Use `gh pr edit --body "..."` to update

**Quick start for new work:**
```bash
git checkout main && git pull origin main
git checkout -b feat/my-feature
# make changes, then:
git add <files> && git commit -m "feat: initial work"
git push -u origin feat/my-feature
gh pr create --draft --title "feat: my feature" --body "## Tasks
- [ ] First task
- [ ] Second task"
```

---

This document provides comprehensive guidance for AI coding assistants on how to handle git commits, following the [Conventional Commits](https://www.conventionalcommits.org/) specification.

## Commit Message Format

Each commit message consists of a **header**, a **body**, and a **footer**.

```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

### Types

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools and libraries

### Scope (Optional)

Provides additional contextual information contained within parentheses:
- `feat(parser): add ability to parse arrays`
- `fix(auth): correct token refresh logic`

### Description

A short, imperative-tense description of the change.

## When to Commit

Create commits at logical breakpoints during feature development:

1. **Per-Feature Commits**: Create a commit for each complete, self-contained feature or fix
2. **After Testing**: Only commit after verifying the change builds/tests successfully
3. **Before Major Changes**: Commit working code before starting significant refactoring
4. **Logical Groupings**: Group related changes together (e.g., implementation + tests + docs)

## Commit Along the Way

**IMPORTANT**: Don't wait until the end of a session to commit. Create commits progressively as you complete features.

### Progressive Commit Strategy

```bash
# Example session workflow:

# 1. Add feature A
# ... make changes ...
# Test the changes
git add src/feature-a/
git commit -m "feat(feature-a): add X functionality"

# 2. Add feature B
# ... make changes ...
# Test the changes
git add src/feature-b/
git commit -m "feat(feature-b): integrate with Y system"

# 3. Add documentation
# ... make changes ...
git add docs/
git commit -m "docs: document feature-a and feature-b usage"

# 4. Add configuration
# ... make changes ...
# Test the changes
git add config/
git commit -m "feat(config): enable new features in production"
```

### Benefits of Committing Along the Way

1. **Rollback Safety**: Easy to revert a specific change if something breaks
2. **Clear History**: Easier to understand what changed and when
3. **Reduced Cognitive Load**: Don't have to remember everything at the end
4. **Better Commit Messages**: Write while context is fresh
5. **Incremental Progress**: Show progress even if session is interrupted
6. **Easier Debugging**: Bisect to find which commit introduced an issue

## When to Group vs. Split Commits

### Group into one commit:
- Feature + its documentation (the feature isn't complete without docs)
- Config file + its corresponding secrets (they work together)
- Refactor that touches multiple files but is one logical change

### Split into separate commits:
- Different features (even if worked on in same session)
- Bugfix + new feature (separate concerns)
- Code changes + documentation updates (if substantial)
- Rename + new functionality

## Red Flags (Don't Do This)

**One giant commit at end of session**
```bash
# Bad: Everything in one commit
git add .
git commit -m "add lots of stuff"
```

**Committing broken code**
```bash
# Bad: Commit before testing
git add .
git commit -m "add feature (not tested)"
```

**Vague commit messages**
```bash
# Bad: No detail
git commit -m "fix stuff"
git commit -m "wip"
git commit -m "updates"
```

**Good Practice**
```bash
# Good: Specific, tested, detailed
git add src/auth/
git commit -m "feat(auth): add OAuth2 token refresh mechanism" -m "
Implements automatic token refresh when access tokens expire.
Refresh occurs 5 minutes before expiration to prevent
interrupted requests.

Key features:
- Automatic background refresh
- Retry logic with exponential backoff
- Graceful degradation on refresh failure
"
```

## Detailed Commit Message Structure

### Header (Required)
- Use present tense, imperative mood: "add" not "added" or "adds"
- Keep under 72 characters
- Be specific about what changed

### Body (Recommended for non-trivial changes)
- Explain **what** and **why**, not **how**
- Wrap at 72 characters
- Separate from header with a blank line
- Include:
  - Motivation for the change
  - How it differs from previous behavior
  - Any breaking changes or migration notes
  - Related issue numbers or documentation

### Footer (Optional)
- Reference issues: `Closes #123` or `Fixes #456`
- Note breaking changes: `BREAKING CHANGE: <description>`
- Add co-authors: `Co-authored-by: Name <email>`

## Commit Message Examples

### Adding a New Feature
```
feat(auth): add OAuth2 authentication support

Add OAuth2 authentication flow with support for multiple providers.
This allows users to sign in with Google, GitHub, or Microsoft accounts.

Key features:
- Provider-agnostic authentication flow
- Automatic token refresh
- Secure token storage
- Session management

The implementation follows OAuth2 best practices and includes
PKCE for enhanced security.
```

### Fixing a Bug
```
fix(api): correct rate limiting calculation

The rate limiter was counting requests per minute instead of per second,
allowing 60x more requests than intended. Fixed the time unit conversion
in the sliding window calculation.

Changes:
- Fix time unit from minutes to seconds
- Add unit tests for rate limiting
- Update documentation with correct limits
```

### Refactoring
```
refactor(database): extract connection pooling into separate module

Extract database connection pooling logic into a dedicated module
to improve testability and allow reuse across services.

Changes:
- Move pooling logic from db/client.ts to db/pool.ts
- Add configuration options for pool size and timeout
- Update all imports to use new module location
- Add unit tests for pool management

This is a non-breaking change; the public API remains unchanged.
```

### Documentation
```
docs(api): add comprehensive endpoint documentation

Add detailed documentation for all REST API endpoints including:
- Request/response schemas
- Authentication requirements
- Rate limiting information
- Example requests and responses
- Error codes and handling

Also updated:
- README.md: Added API documentation link
- CONTRIBUTING.md: Added docs update requirements
```

### Multiple Related Changes
```
feat(notifications): add email notification system

Implement email notification system with template support and
delivery tracking.

Changes:
1. Email service (src/services/email.ts):
   - Add SendGrid integration
   - Implement template rendering
   - Add delivery status tracking

2. Templates (src/templates/):
   - Add welcome email template
   - Add password reset template
   - Add notification preferences template

3. Database migrations:
   - Add email_logs table for tracking
   - Add user notification preferences

4. Configuration:
   - Add SendGrid API key to secrets
   - Add email configuration options

This enables the application to send transactional emails
with full delivery tracking and user preference management.
```

## Branching Strategy

> **⚠️ MANDATORY: The main branch is protected. Direct commits will be rejected.**

All changes MUST go through the following workflow:
1. Create a feature branch from main
2. Make commits on the feature branch
3. Push the branch and create a pull request
4. Merge via the pull request after review

There are NO exceptions to this rule. Do not attempt to commit directly to main.

### Branch Naming Conventions

Use descriptive branch names with a type prefix:

```
<type>/<short-description>
```

**Types:**
- `feat/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions or fixes
- `chore/` - Maintenance tasks

**Examples:**
```
feat/oauth-authentication
fix/rate-limiter-calculation
docs/api-endpoint-documentation
refactor/database-connection-pooling
```

### Feature Branch Workflow

**IMPORTANT:** Create a draft pull request early in your workflow. This provides visibility into work in progress and ensures all changes go through the PR process.

1. **Check current branch and ensure you're not on main:**
   ```bash
   git branch --show-current
   # If on main, proceed to step 2. If already on a feature branch, skip to step 4.
   ```

2. **Update main and create a new feature branch:**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feat/my-new-feature
   ```

3. **Make your first commit on the feature branch:**
   ```bash
   git add <files>
   git commit -m "feat(scope): initial implementation"
   ```

4. **Push and create a DRAFT pull request with a task list:**
   ```bash
   git push -u origin feat/my-new-feature
   gh pr create --draft --title "feat(scope): description" --body "$(cat <<'EOF'
   ## Summary
   Brief description of what this PR accomplishes.

   ## Tasks
   - [ ] Task 1
   - [ ] Task 2
   - [ ] Task 3
   EOF
   )"
   ```

   > **Why draft PRs?** They signal work is in progress, enable early feedback, and ensure the PR process is followed from the start.

5. **Continue making commits on the feature branch** following the commit guidelines above

6. **Update the PR task list as you work:**
   - Mark tasks complete as you finish them
   - Add new tasks discovered during implementation
   ```bash
   gh pr edit --body "$(cat <<'EOF'
   ## Summary
   Brief description of what this PR accomplishes.

   ## Tasks
   - [x] Task 1 (completed)
   - [x] Task 2 (completed)
   - [ ] Task 3
   - [ ] New task discovered during implementation
   EOF
   )"
   ```

7. **When work is complete, mark the PR ready for review:**
   ```bash
   gh pr ready
   ```

8. **After PR is merged**, clean up:
   ```bash
   git checkout main
   git pull origin main
   git branch -d feat/my-new-feature
   ```

### Pull Request Workflow

Always create pull requests for code review before merging to main. The process differs slightly between GitHub and Forgejo.

#### Detecting the Git Platform

Check the git remote URL to determine the platform:

```bash
git remote -v
```

- **GitHub**: URL contains `github.com`
- **Forgejo/Gitea**: URL contains your self-hosted domain (e.g., `forge.meskill.farm`) or uses `/git/` path pattern

#### GitHub Pull Requests

Use the GitHub CLI (`gh`) for pull request operations:

```bash
# Create a pull request
gh pr create --title "feat: add OAuth authentication" --body "$(cat <<'EOF'
## Summary
- Add OAuth2 authentication flow
- Support Google, GitHub, Microsoft providers
- Implement automatic token refresh

## Test Plan
- [ ] Test OAuth flow with each provider
- [ ] Verify token refresh works correctly
- [ ] Check session management
EOF
)"

# List open pull requests
gh pr list

# View pull request details
gh pr view <number>

# Check out a pull request locally
gh pr checkout <number>

# Merge a pull request (if you have permission)
gh pr merge <number>
```

**Note:** If `gh` is not available, create the PR through the GitHub web interface.

#### Forgejo/Gitea Pull Requests

Forgejo uses the same API as Gitea. You can use either:

1. **Web Interface** (recommended for most cases):
   - Push your branch
   - Navigate to the repository in your browser
   - Click "New Pull Request"
   - Select your feature branch as the source
   - Fill in title and description

2. **API via curl** (for automation):
   ```bash
   # Create a pull request via API
   curl -X POST "https://forge.meskill.farm/api/v1/repos/OWNER/REPO/pulls" \
     -H "Authorization: token $FORGEJO_API_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "title": "feat: add OAuth authentication",
       "body": "## Summary\n- Add OAuth2 flow\n- Support multiple providers",
       "head": "feat/oauth-authentication",
       "base": "main"
     }'
   ```

3. **Tea CLI** (if installed):
   ```bash
   # Create a pull request
   tea pr create --title "feat: add OAuth authentication" --description "Add OAuth2 flow"

   # List pull requests
   tea pr list
   ```

### Pull Request Best Practices

1. **Title**: Use conventional commit format for the PR title
   - `feat: add OAuth authentication`
   - `fix: correct rate limiting calculation`

2. **Description**: Include:
   - Summary of changes (what and why)
   - Test plan or checklist
   - Breaking changes or migration notes
   - Related issues (e.g., `Closes #123`)

3. **Size**: Keep PRs focused and reviewable
   - Prefer smaller, incremental PRs over large monolithic ones
   - Split unrelated changes into separate PRs

4. **Review**:
   - Request review from appropriate team members
   - Address review feedback with additional commits
   - Don't force-push after review has started (unless requested)

5. **Merge Strategy**:
   - Prefer "Squash and merge" for feature branches (cleaner history)
   - Use "Merge commit" for long-running branches with meaningful commit history
   - Never use "Rebase and merge" without understanding the implications

### When NOT to Create a PR

**With protected branches, there are NO cases where direct commits to main are acceptable.**

The main branch is protected and will reject all direct commits. Even for:
- Emergency hotfixes → create a `fix/` branch and expedited PR
- Trivial typo fixes → still requires a branch and PR
- Initial repository setup → only applies to new repos before protection is enabled

**All changes require PRs** - they provide documentation, enable review, and create a clear audit trail.

## Git Commands Workflow

When making commits, use this workflow:

```bash
# 1. Check current status
git status

# 2. Review changes
git diff

# 3. Stage specific files (preferred over `git add .`)
git add <file1> <file2> <file3>

# 4. Verify staged changes
git diff --cached

# 5. Check SSH agent and signing capability BEFORE committing
ssh-agent-check

# 6. Create commit with detailed message (only if ssh-agent-check passes)
git commit -m "type(scope): short description" -m "
Detailed explanation of what changed and why.

- Bullet points for key changes
- Context about the motivation
- Any breaking changes or notes

Fixes #123
"

# 7. Verify commit
git log -1 --stat
```

### Pre-Commit Signing Check

**IMPORTANT**: Before attempting any commit, always run `ssh-agent-check` to verify that SSH/GPG signing will succeed.

```bash
# Run the signing check
ssh-agent-check
```

- **If the check passes**: Proceed with the commit normally
- **If the check fails**: Do NOT attempt to commit. Instead, follow the "SSH/GPG Signing Failure" procedure below to save the commit message and instruct the user to commit manually

## Special Considerations

1. **Don't commit without testing**: Always verify builds/tests succeed first
2. **One feature per commit**: Keep commits focused and atomic
3. **Update documentation**: Include doc updates in the same commit as code changes
4. **Secrets**: Never commit unencrypted secrets
5. **Large changes**: Consider breaking into multiple commits with clear progression
6. **Rebase, don't merge**: Keep history linear when possible

## Handling Commit Failures

### SSH/GPG Signing Failure

If `ssh-agent-check` fails or commits require signing and signing fails:

1. **Do NOT attempt to commit** if `ssh-agent-check` fails

2. **Keep the files staged** (stage them if not already staged)

3. **Generate a random hex suffix** for the commit message file:
   ```bash
   COMMIT_FILE="COMMIT_MSG_$(openssl rand -hex 4).txt"
   ```

4. **Save the commit message to the temporary file**:
   ```bash
   cat > "$COMMIT_FILE" << 'EOF'
   type(scope): short description

   Detailed explanation of what changed and why.

   - Bullet points for key changes
   - Context about the motivation
   - Any breaking changes or notes
   EOF
   ```

5. **Notify the user** to commit manually:
   ```
   Unable to create signed commit (ssh-agent-check failed or signing unavailable).

   Changes are staged and commit message saved to COMMIT_MSG_<hex>.txt

   To create the signed commit:
     git commit -F COMMIT_MSG_<hex>.txt && rm COMMIT_MSG_<hex>.txt
   ```

**Example workflow when ssh-agent-check fails:**
```bash
# 1. Stage the files
git add src/feature.ts

# 2. Run ssh-agent-check
ssh-agent-check
# Output: FAIL - SSH agent not available

# 3. Generate unique filename and save commit message
COMMIT_FILE="COMMIT_MSG_$(openssl rand -hex 4).txt"
cat > "$COMMIT_FILE" << 'EOF'
feat(feature): add new capability

Implements the new feature with full test coverage.

Key changes:
- Add feature implementation
- Add unit tests
- Update documentation
EOF

# 4. Inform user
echo "Changes staged. Commit message saved to $COMMIT_FILE"
echo "Run: git commit -F $COMMIT_FILE && rm $COMMIT_FILE"
```

### Other Common Issues

**Pre-commit hooks fail:**
- Fix the issues identified by the hooks
- Re-run the commit after fixes
- Don't use `--no-verify` unless explicitly instructed

**Empty commits:**
- Ensure files are actually changed
- Verify files are staged with `git status`
- Check `git diff --cached` to see staged changes

**Merge conflicts:**
- Resolve conflicts first
- Stage resolved files
- Then commit

**Invalid commit message format:**
- Follow conventional commits specification
- Use proper type, scope, and description
- Include detailed body for non-trivial changes

## Commit Frequency Guidelines

- **Too frequent**: Don't commit every single file change
- **Too infrequent**: Don't bundle multiple unrelated features
- **Just right**: Commit when a feature is complete and tested

## When NOT to Commit

- Build/tests are failing
- Temporary/debugging code is present
- Secrets are exposed
- Work is incomplete and non-functional
- Code doesn't compile/parse

## HEREDOC Format for Complex Messages

For complex commit messages, use HEREDOC to ensure proper formatting.

**Remember**: Always run `ssh-agent-check` before attempting the commit. If it fails, save the message to `COMMIT_MSG_<hex>.txt` instead. 

**Never allow unsigned commits.**
 
```bash
# First, verify signing will work
ssh-agent-check

# If ssh-agent-check passes, proceed with commit
git commit -m "$(cat <<'EOF'
feat(component): add new feature

Detailed description of the feature.

Key changes:
- Change 1
- Change 2
- Change 3

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```
