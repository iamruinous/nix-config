# Chat Organizer

A Python tool generalized from a local script to organize LLM chat logs into an Obsidian-friendly format using local LLM inference.

**Purpose**: Scans a directory of Markdown chat logs, uses a local Ollama model (phi3:mini) to generate metadata (titles, summaries, tags, key concepts), and restructures the files with YAML frontmatter, Obsidian callouts, and wiki-links.

## Key Features

- **Local LLM Inference**: Uses `ollama` (default: `phi3:mini`) for privacy and cost-efficiency.
- **Obsidian Optimization**:
  - Adds `> [!SUMMARY]` callouts.
  - Generates `[[Key Concept]]` wiki-links in a footer.
  - Adds `aliases` to preserve original filenames.
  - Adds `agent` field based on directory structure.
- **Incremental Updates**: Can run on already-processed files to add missing fields (e.g. `key_concepts`) or fix filenames without overwriting manual edits.
- **Safe Backups**: Creates timestamped backups (e.g. `file.md.20260131_120000.bak`) before modification.
- **Unix-Friendly**: Renames files to `YYYY-MM-DD-kebab-case-title.md`.

## Usage

### As a Package
This package provides the `chat-organizer` binary.

```bash
# Scan current directory
chat-organizer

# Recursive scan of a specific directory
chat-organizer ~/Documents/Chats -r

# Incremental update (fix missing fields/filenames in existing notes)
chat-organizer ~/Documents/Chats -r --incremental
```

### Requirements

- **Ollama**: Must be running (`systemctl start ollama` or `ollama serve`).
- **Model**: Must have the model pulled (`ollama pull phi3:mini` or configured model).

## Configuration

The script currently defaults to `http://localhost:11434` and `phi3:mini`. These are defined in the source script.
