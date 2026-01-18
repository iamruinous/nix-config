# Documentation

> Infrastructure documentation for nix-config. Built with Material for MkDocs.

## Contents

| Document | Purpose |
|----------|---------|
| [NETWORKS.md](NETWORKS.md) | VLANs, DNS domains, network topology |

## Format

All documentation uses **Material for MkDocs** conventions:
- Markdown with admonitions, tabs, and code blocks
- Tables for structured data
- Mermaid diagrams where helpful

## Building Docs

If MkDocs is configured:

```bash
# Local preview
mkdocs serve

# Build static site
mkdocs build
```

## Related

- [AGENTS.md](../AGENTS.md) - Agent context entry point
- [llms.txt](../llms.txt) - LLM-friendly index
- [hosts/README.md](../hosts/README.md) - Host specifications
