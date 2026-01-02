#!/usr/bin/env bash
# scripts/bootstrap-context.sh
set -e

# Configuration
DELIMITER="<!-- CONTEXT_BOOTSTRAP_START - DO NOT EDIT BELOW THIS LINE -->"
FILES=("GEMINI.md" "CLAUDE.md")

# Function to generate the immutable context
generate_context() {
    local agent_name=$1
    local repo_url="https://github.com/iamruinous/nix-config"
    
    cat <<'EOF' | sed "s/{{AGENT_NAME}}/${agent_name}/g" | sed "s|{{REPO_URL}}|${repo_url}|g"
# {{AGENT_NAME}} CLI Context (Bootstrapped)

## ⚠️ Primary Context Source
**STOP:** You must initialize your context before proceeding.
Run `make context-check` (or read **[.context/index.md](.context/index.md)** directly) to load the Single Source of Truth.

*   **Standards & Protocols:** `.context/global/`
*   **Project Specifics:** `.context/project/`

## Project Overview
This is a NixOS configuration repository using `blueprint` for structure. It manages NixOS and Darwin hosts.
*   **Switch:** `nixos-rebuild switch --flake .#<host>`
*   **Remote:** `make remote-rebuild remotehost=<host>`

## AI Agent Workflow
You are an intelligent coding assistant. Your primary goal is to help the user safely and efficiently.

### 1. Plan & Orchestrate
*   **Check Context:** Always reference `.context/` files.
*   **Create Plan:** Use the TodoWrite tool (or similar) to outline your steps.
*   **Confirm:** Get user approval before executing complex changes.

### 2. Specialized Agents
This project defines specialized agent personas. When dealing with specific domains, delegate (mentally) to the instructions found in `.context/project/agents/`:
*   **`agenix`**: Secrets management (`.age` files).
*   **`cfnix`**: Cloudflare DNS & Tunnels.
*   **`containnix`**: Docker/OCI container deployment.
*   **`nix-packager`**: Nix package creation.

### 3. Git Workflow
*   **Branch:** Always work on a feature branch (`feat/`, `fix/`).
*   **Draft PR:** Create a draft PR early to track progress.
*   **Verify:** Run `make remote-dry-build remotehost=<host>` before committing.
*   **Sign:** GPG sign all commits.
*   **Global Improvements:** If you improve the Global Standards (`.context/global/`), you MUST contribute these back to the source of truth. Create a PR at [{{REPO_URL}}]({{REPO_URL}}).

## Secrets Management
**CRITICAL:** Never commit unencrypted secrets.
*   Use `agenix` for all secrets.
*   See `.context/project/agents/agenix.md` for detailed workflows.

## Common Recipes
*   **Create Database:** See `.context/project/recipes/create-db.md`
*   **Create Pi Host:** See `.context/project/recipes/create-pi-host.md`
EOF
}

echo "🔄 Bootstrapping Agent Context..."

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   Processing $file..."
        
        # Determine Agent Name
        if [[ "$file" == "GEMINI.md" ]]; then
            NAME="Gemini"
        elif [[ "$file" == "CLAUDE.md" ]]; then
            NAME="Claude"
        else
            NAME="Agent"
        fi

        # 1. Read existing content
        CONTENT=$(cat "$file")
        
        # 2. Split at delimiter
        # Uses awk to grab everything BEFORE the delimiter line.
        # If delimiter not found, keeps everything (assuming it's all memory).
        MEMORY=$(echo "$CONTENT" | awk -v delim="$DELIMITER" '\
$0 == delim { exit }
{ print }
')
        
        # 3. Trim trailing newlines from memory to avoid stacking gaps
        MEMORY=$(echo "$MEMORY" | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba')
        
        # 4. If empty/missing memory header, inject default
        if [[ -z "$MEMORY" ]] || [[ "$MEMORY" == *"$DELIMITER"* ]]; then
             MEMORY="# $NAME Memory & Scratchpad\n\n## 🧠 Active Context\n*   **Role:** Orchestrator (Hub)\n\n## 📝 Memories\n*   (No active memories)"
        fi

        # 5. Write back
        # Use a temporary file to ensure atomic write
        TMP_FILE="${file}.tmp"
        
        echo -e "$MEMORY" > "$TMP_FILE"
        echo "" >> "$TMP_FILE" # Ensure one blank line
        echo "$DELIMITER" >> "$TMP_FILE"
        generate_context "$NAME" >> "$TMP_FILE"
        
        mv "$TMP_FILE" "$file"
        echo "   ✓ Updated $file"
    else
        echo "   ⚠️  $file not found, skipping."
    fi
done

echo "✅ Context Bootstrap Complete."
