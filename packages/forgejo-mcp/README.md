# forgejo-mcp

MCP (Model Context Protocol) server for interacting with Forgejo/Gitea REST API.

## Overview

This package provides a local MCP server that enables AI assistants to interact with Forgejo instances (including Codeberg.org) through the Model Context Protocol. It supports operations like managing repositories, issues, pull requests, and more.

## Purpose

Connects AI assistants to Forgejo/Gitea instances, enabling:
- Repository management (list, create, fork, search)
- Branch operations (list, create, delete)
- File operations (read, create, update, delete)
- Issue management (list, create, update, comment)
- Pull request workflows (list, create, update, review)
- Organization and user operations

## Installation

This package is available to all hosts in this flake:

```nix
environment.systemPackages = with pkgs; [
  forgejo-mcp
];
```

## Usage

### As a Standalone Server

```sh
# Start in stdio mode (for MCP clients)
forgejo-mcp --transport stdio --url https://codeberg.org --token $FORGEJO_ACCESS_TOKEN

# Start in SSE mode (HTTP-based)
forgejo-mcp --transport sse --url https://codeberg.org --token $FORGEJO_ACCESS_TOKEN --sse-port 8080
```

### With OpenCode

The OpenCode module can configure this automatically. See `modules/home/default/ai-cli/opencode.nix` for integration details.

### Environment Variables

- `FORGEJO_ACCESS_TOKEN` - Your personal access token (required)
- `FORGEJO_URL` - Your Forgejo instance URL (optional, used by wrapper scripts)

## Getting an Access Token

1. Log into your Forgejo instance (e.g., codeberg.org)
2. Go to **Settings** > **Applications** > **Access Tokens**
3. Create a new token with required permissions:
   - `repo` - Repository access
   - `issue` - Issue management
   - `admin:org` - Organization access (optional)

## Available Tools

| Category | Tools |
|----------|-------|
| **User** | `get_my_user_info`, `search_users` |
| **Repositories** | `list_my_repos`, `create_repo`, `fork_repo`, `search_repos` |
| **Branches** | `list_branches`, `create_branch`, `delete_branch` |
| **Files** | `get_file_content`, `create_file`, `update_file`, `delete_file` |
| **Commits** | `list_repo_commits` |
| **Issues** | `list_repo_issues`, `get_issue_by_index`, `create_issue`, `update_issue`, `add_issue_labels`, `issue_state_change` |
| **Comments** | `list_issue_comments`, `get_issue_comment`, `create_issue_comment`, `edit_issue_comment`, `delete_issue_comment` |
| **Pull Requests** | `list_repo_pull_requests`, `get_pull_request_by_index`, `create_pull_request`, `update_pull_request`, `list_pull_reviews`, `get_pull_review`, `list_pull_review_comments` |
| **Organizations** | `search_org_teams` |

## Technical Details

- **Language**: Go
- **Version**: 2.5.0
- **Build**: Static binary with CGO disabled
- **Transport**: stdio (default) or SSE (HTTP)
- **Platform Support**: Linux, macOS

## Upstream

- **Repository**: https://codeberg.org/goern/forgejo-mcp
- **License**: Apache 2.0
- **Documentation**: https://codeberg.org/goern/forgejo-mcp/src/branch/main/README.md
