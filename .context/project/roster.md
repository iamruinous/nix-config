# Agent Roster & Delegation (Project Specific)

## Available Specialists
Defined in `.context/project/agents/`.

*   **`agenix`**: Secrets management expert.
*   **`cfnix`**: Cloudflare & Networking expert.
*   **`containnix`**: Container orchestration expert.
*   **`nix-packager`**: Nix packaging expert.
*   **`codebase_investigator`** (Tool): Deep architectural analysis.

## Task Delegation Matrix

| Task Category | Primary Agent | Secondary/Support |
| :--- | :--- | :--- |
| **Secrets Management** | | |
| Encrypt/Edit `.age` files | `agenix` | |
| Rekey secrets | `agenix` | |
| Create Docker env files | `agenix` | `containnix` (for context) |
| **Infrastructure** | | |
| Deploy new container | `containnix` | `agenix` (secrets), `cfnix` (DNS) |
| Update Caddy config | `containnix` | `agenix` (if encrypted), `cfnix` (DNS) |
| Create DB | `containnix` (via recipes) | |
| **Networking** | | |
| Manage DNS records | `cfnix` | |
| Create Cloudflare Tunnels | `cfnix` | `agenix` (creds), `containnix` (service) |
| **Development** | | |
| Create new package | `nix-packager` | |
| Fix build errors | `nix-packager` | `codebase_investigator` |
| **Architecture** | | |
| Refactor modules | Orchestrator | `codebase_investigator` |
| Analyze dependencies | `codebase_investigator` | |
