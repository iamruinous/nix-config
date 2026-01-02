# Global Coding & Operational Standards

## Code Style
*   **Consistency:** Follow the project's established linters and formatters.
*   **Idiomatic Code:** Adhere to language-specific best practices.
*   **Documentation:** Document complex logic.

## Git Workflow
For detailed guidelines, see **[Git Workflow](./git.md)**.

*   **Branching:**
    *   **Protected Main:** Direct commits to `main` are rejected.
    *   **Conventions:** Use `feat/`, `fix/`, `docs/`, `chore/` prefixes.
*   **Commits:**
    *   **Format:** Conventional Commits (`type(scope): description`).
    *   **Context:** **REQUIRED**. Provide a detailed body explaining *why* and *impact*. One-liners are insufficient.
    *   **Signing:** **MUST** be GPG signed. Ensure your GPG agent is configured.
    *   **Frequency:** Commit progressively.
*   **Pull Requests:**
    *   Create **Draft PRs** immediately.
    *   Maintain a task list.
    *   Review is required.

## Testing Strategy
*   **Verification:** Run project-specific build and test commands before committing.
*   **CI/CD:** Ensure local changes pass CI checks.

## Security & Integrity
*   **Secrets:** **NEVER** commit unencrypted secrets. Use the project's secret management tool.
*   **gitleaks:** **MANDATORY**. Must be integrated into Git hooks (`pre-commit`) to prevent accidental leaks. See [Git Workflow](./git.md) for installation.
*   **commitlint:** **MANDATORY**. Must be integrated into Git hooks (`commit-msg`) to enforce Conventional Commits. See [Git Workflow](./git.md) for installation.
*   **Signing:** **MANDATORY**. All commits MUST be GPG/SSH signed.
*   **Access:** Respect least-privilege principles.

## File System Practices

### Temporary Files
**Always use `<project-root>/tmp/` for temporary files** instead of `/tmp` or other system directories.

**Why:**
- Avoids permission issues when tools run in sandboxed environments
- Keeps temporary work visible and scoped to the project
- No risk of conflicts with other system processes
- Easier cleanup (just delete the directory)

**Usage:**
```bash
# Good - project-local tmp
mkdir -p tmp
echo "content" > tmp/scratch.txt

# Bad - system tmp (requires extra permissions)
echo "content" > /tmp/scratch.txt
```

**Safety:**
- The `tmp/` directory is already in `.gitignore`
- Never commit files from `tmp/` - if you need to keep something, move it to a proper location
- Clean up after yourself: `rm -rf tmp/*` when done with temporary work

**For AI Agents:**
When working with temporary files (e.g., decrypting secrets, staging edits), always use the project's `tmp/` directory. This ensures tools like `agenix` can access the files without requiring sandbox bypasses.