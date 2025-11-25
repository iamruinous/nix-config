# Git Behavior Guidelines for AI Agents

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

# 5. Create commit with detailed message
git commit -m "type(scope): short description" -m "
Detailed explanation of what changed and why.

- Bullet points for key changes
- Context about the motivation
- Any breaking changes or notes

Fixes #123
"

# 6. Verify commit
git log -1 --stat
```

## Special Considerations

1. **Don't commit without testing**: Always verify builds/tests succeed first
2. **One feature per commit**: Keep commits focused and atomic
3. **Update documentation**: Include doc updates in the same commit as code changes
4. **Secrets**: Never commit unencrypted secrets
5. **Large changes**: Consider breaking into multiple commits with clear progression
6. **Rebase, don't merge**: Keep history linear when possible

## Handling Commit Failures

### GPG Signing Issues

If commits require GPG signing and it fails:

1. **Keep the files staged** (they should already be staged from the failed commit attempt)

2. **Save the commit message to a temporary file**:
   ```bash
   cat > COMMIT_MSG.txt << 'EOF'
   type(scope): short description

   Detailed explanation of what changed and why.

   - Bullet points for key changes
   - Context about the motivation
   - Any breaking changes or notes
   EOF
   ```

3. **Notify the user** to commit manually:
   ```
   Unable to create signed commit (GPG signing failed).

   Changes are staged and commit message saved to COMMIT_MSG.txt

   To create the signed commit:
     git commit -F COMMIT_MSG.txt && rm COMMIT_MSG.txt
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

For complex commit messages, use HEREDOC to ensure proper formatting:

```bash
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
