# opencode-anthropic-auth-patch

Patched version of [opencode-anthropic-auth](https://github.com/anomalyco/opencode-anthropic-auth) with tool renaming to bypass Claude OAuth restrictions.

## Overview

This package provides a patched version of the `opencode-anthropic-auth` plugin that renames tools using the `oc_` prefix to work around Claude API restrictions. The solution:

- **Prefixes tool names with `oc_`** in outgoing requests to Anthropic API
- **Strips `oc_` prefix from tool names** in streaming responses back from Anthropic

This allows OpenCode to use Claude OAuth credentials with MCP tools, bypassing the "This credential is only authorized for use with Claude Code" restriction.

## Why This Is Needed

When using Claude OAuth credentials with MCP tools, Anthropic's API rejects requests because the tool names don't match Claude Code's expected format. By prefixing tools with `oc_` (representing "OpenCode") and then stripping the prefix on the response, we can use OAuth credentials while appearing to be Claude Code.

## Usage

This package is automatically installed when you enable the OpenCode module. The patched plugin is automatically configured and available for use.

### Installation

The plugin is automatically integrated into your OpenCode configuration by the Nix module. No manual installation is required.

Simply enable OpenCode in your host configuration:

```nix
ruinous.ai-cli.opencode.enable = true;
```

## How It Works

1. **Outgoing Requests**: When OpenCode sends a request with tools, the plugin intercepts it and renames each tool by prefixing with `oc_`:
   - `bash` → `oc_bash`
   - `read_file` → `oc_read_file`

2. **Incoming Responses**: When Anthropic returns tool calls in the streaming response, the plugin strips the `oc_` prefix:
   - `oc_bash` → `bash`
   - `oc_read_file` → `read_file`

3. **End Result**: OpenCode sees the original tool names, but Anthropic sees the prefixed names that are valid for OAuth credentials.

## Version

Based on PR #10: [fix: claude oauth by renaming tools on in/out](https://github.com/anomalyco/opencode-anthropic-auth/pull/10)

- Source: https://github.com/ashley-bytespell/opencode-anthropic-auth/tree/fix/claude-oauth-tools
- Commit: 12dbe9295408aad09b919ea8ed05bfc6b7bc6029

## License

MIT (inherited from original opencode-anthropic-auth package)
