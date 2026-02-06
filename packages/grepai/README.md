# grepai

AI-powered semantic code search tool.

**Purpose**: Search code by meaning, not just text patterns. Understands synonyms, related terms, and conceptual similarity. Integrates with Claude Code, Cursor, Windsurf, and other AI tools via MCP.

**Key Features**:
- Semantic code search with natural language queries
- Call graph tracing (find callers/callees of functions)
- File watcher for live index updates
- MCP server for AI agent integration
- Workspace management for multi-repo searches
- Local-first with Ollama support (uses nomic-embed-text)

**Used By**: Development systems with Ollama for AI-assisted code search.

**Dependencies**: Ollama with nomic-embed-text model for embeddings

**Version**: 0.27.0

**Upstream**: https://github.com/yoanbernabeu/grepai

## Quick Start

```bash
# Initialize in your project
cd your-project && grepai init

# Start indexing daemon
grepai watch

# Search with natural language
grepai search "user authentication flow"

# Trace function calls
grepai trace callers "Login"
grepai trace callees "handleAuth"
```

## MCP Server

Start the MCP server for AI agent integration:

```bash
grepai mcp-serve
```

Configure in Claude Desktop or OpenCode MCP settings.

## Configuration

Create `.grepai/config.yaml` in your project:

```yaml
embedder:
  provider: ollama
  model: nomic-embed-text
```
