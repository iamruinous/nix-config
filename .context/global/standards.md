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

## Security
*   **Secrets:** **NEVER** commit unencrypted secrets. Use the project's secret management tool.
*   **gitleaks:** **MANDATORY**. Must be integrated into Git hooks (`pre-commit`) to prevent accidental leaks. See [Git Workflow](./git.md) for installation.
*   **Access:** Respect least-privilege principles.