import os
import shutil
import json
import re
import urllib.request
import urllib.error
import datetime
import sys
import argparse

# Configuration
OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "phi3:mini"


def call_ollama(prompt):
    payload = {"model": MODEL, "prompt": prompt, "stream": False, "format": "json"}
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        OLLAMA_URL, data=data, headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode("utf-8"))
            return result.get("response", "")
    except urllib.error.URLError as e:
        print(f"  [ERROR] Ollama call failed: {e}")
        return None


def generate_full_metadata(content):
    truncated = content[:8000]
    prompt = f"""
    You are an Obsidian Markdown expert. Analyze this chat log.
    Provide ONLY a JSON object with:
    1. "title": Concise title (5-7 words).
    2. "summary": 1-2 sentence summary.
    3. "tags": List of 3-5 tags (lowercase, kebab-case).
    4. "key_concepts": List of 3-5 concepts for Wiki Links (e.g. "NixOS", "LLM").

    Content:
    {truncated}
    """
    return call_ollama(prompt)


def to_kebab_case(text):
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    text = re.sub(r"-+", "-", text)
    return text.strip("-")


def manual_yaml_dump(data):
    lines = []
    for key, value in data.items():
        if isinstance(value, list):
            lines.append(f"{key}:")
            for item in value:
                lines.append(f"  - {item}")
        else:
            clean_value = (
                str(value)
                .replace("\\", "\\\\")
                .replace('"', '\\"')
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t")
            )
            lines.append(f'{key}: "{clean_value}"')
    return "\n".join(lines)


def extract_frontmatter(content):
    match = re.match(r"^---\n(.*?)\n---\n(.*)", content, re.DOTALL)
    if match:
        return match.group(1), match.group(2)
    return None, content


def parse_frontmatter_to_dict(fm_str):
    data = {}
    lines = fm_str.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]
        if ":" in line and not line.startswith(" "):
            key, _, value_part = line.partition(":")
            key = key.strip()
            value_part = value_part.strip()

            if value_part.startswith('"') and value_part.endswith('"'):
                data[key] = value_part[1:-1]
            elif not value_part:
                list_items = []
                i += 1
                while i < len(lines) and lines[i].startswith("  - "):
                    list_items.append(lines[i][4:].strip())
                    i += 1
                data[key] = list_items
                continue
            else:
                data[key] = value_part
        i += 1
    return data


def rebuild_frontmatter_with_escaping(fm_str):
    parsed = parse_frontmatter_to_dict(fm_str)
    return manual_yaml_dump(parsed)


def update_frontmatter_block(fm_str, new_data):
    # robustly appends missing keys to the frontmatter string
    updated_fm = fm_str

    for key, value in new_data.items():
        # Simple regex check to see if key exists at start of line
        if not re.search(f"^{key}:", updated_fm, re.MULTILINE):
            # Append it
            if isinstance(value, list):
                block = f"\n{key}:"
                for item in value:
                    block += f"\n  - {item}"
                updated_fm += block
            else:
                updated_fm += f'\n{key}: "{value}"'

    # Update 'updated' field if it exists, or add it
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    if re.search(r"^updated:", updated_fm, re.MULTILINE):
        # Use simple string concatenation or carefully constructed regex replacement
        # The previous error was likely due to string literal handling in the previous write
        replacement = f'updated: "{now}"'
        updated_fm = re.sub(
            r"^updated:.*\n", replacement + "\n", updated_fm, flags=re.MULTILINE
        )
    else:
        updated_fm += f'\nupdated: "{now}"'

    return updated_fm


def process_file(filepath, incremental=False):
    filename = os.path.basename(filepath)
    # Ignore hidden files, readme, and this script
    if (
        filename.startswith(".")
        or not filename.endswith(".md")
        or filename.lower() == "readme.md"
        or filename == "organize_chats.py"
    ):
        return

    # print(f"Scanning: {filename}")

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        print(f"  [ERROR] Read failed: {e}")
        return

    fm_str, body = extract_frontmatter(content)

    # DECISION LOGIC
    needs_processing = False
    is_update = False

    if not fm_str:
        print(f"Processing New: {filename}")
        needs_processing = True
    elif incremental:
        # Check for missing crucial fields
        missing_concepts = "key_concepts:" not in fm_str
        missing_agent = "agent:" not in fm_str
        missing_aliases = "aliases:" not in fm_str

        # Check filename convention
        # Regex for YYYY-MM-DD-something
        is_standard_name = re.match(r"^\d{4}-\d{2}-\d{2}-.*", filename)

        if missing_concepts or missing_agent or missing_aliases or not is_standard_name:
            print(f"Updating: {filename}")
            needs_processing = True
            is_update = True
        else:
            return
    else:
        # Frontmatter exists and not incremental
        return

    # METADATA GENERATION
    if needs_processing:
        # Create Timestamped Backup
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = f"{filepath}.{timestamp}.bak"

        try:
            shutil.copy2(filepath, backup_path)
            # print(f"  [BACKUP] Created {os.path.basename(backup_path)}")
        except OSError as e:
            print(f"  [ERROR] Backup failed: {e}")
            return  # Stop processing if backup fails

        stat = os.stat(filepath)
        created_date = datetime.datetime.fromtimestamp(stat.st_ctime).strftime(
            "%Y-%m-%d %H:%M"
        )

        # Infer Agent
        parent_dir = os.path.basename(os.path.dirname(filepath))
        # Logic: If parent is the root dir, assume "Unknown", else use parent folder name
        agent_name = (
            parent_dir
            if parent_dir not in ["Agent Chats", "Obsidian Vaults", "src", "bin"]
            else "Unknown"
        )

        if is_update and fm_str:
            needs_llm = "key_concepts:" not in fm_str or "tags:" not in fm_str

            if needs_llm:
                json_str = generate_full_metadata(body)
                if not json_str:
                    return
                try:
                    metadata = json.loads(json_str)
                except json.JSONDecodeError:
                    print(f"  [ERROR] Failed to parse LLM response for {filename}")
                    return

                updates = {}
                if "key_concepts:" not in fm_str:
                    updates["key_concepts"] = metadata.get("key_concepts", [])
                if "tags:" not in fm_str:
                    updates["tags"] = metadata.get("tags", [])
                if "agent:" not in fm_str:
                    updates["agent"] = agent_name
                if "aliases:" not in fm_str:
                    updates["aliases"] = [metadata.get("title")]

                new_fm_str = update_frontmatter_block(fm_str, updates)

                new_content = f"---\n{new_fm_str}\n---\n{body}"

                if "## Related Concepts" not in body and metadata.get("key_concepts"):
                    footer = "\n\n## Related Concepts\n"
                    for concept in metadata.get("key_concepts"):
                        footer += f"- [[{concept}]]\n"
                    new_content += footer
            else:
                parsed = parse_frontmatter_to_dict(fm_str)
                if "agent" not in parsed:
                    parsed["agent"] = agent_name
                new_fm_str = manual_yaml_dump(parsed)
                print("  [FIX] Re-escaped frontmatter YAML")

                new_content = f"---\n{new_fm_str}\n---\n{body}"

                if "## Related Concepts" not in body and parsed.get("key_concepts"):
                    footer = "\n\n## Related Concepts\n"
                    for concept in parsed.get("key_concepts", []):
                        footer += f"- [[{concept}]]\n"
                    new_content += footer

        else:
            json_str = generate_full_metadata(content)
            if not json_str:
                return
            try:
                metadata = json.loads(json_str)
            except json.JSONDecodeError:
                print(f"  [ERROR] Failed to parse LLM response for {filename}")
                return

            original_title = os.path.splitext(filename)[0]
            frontmatter_data = {
                "title": metadata.get("title", "Untitled Chat"),
                "aliases": [original_title],
                "summary": metadata.get("summary", ""),
                "tags": metadata.get("tags", []),
                "key_concepts": metadata.get("key_concepts", []),
                "created": created_date,
                "updated": created_date,
                "agent": agent_name,
                "type": "chat-log",
            }

            fm_str = manual_yaml_dump(frontmatter_data)
            obsidian_header = f"# {metadata.get('title')}\n\n"
            obsidian_callout = f"> [!SUMMARY] Summary\n> {metadata.get('summary')}\n\n"

            footer = ""
            if metadata.get("key_concepts"):
                footer = "\n\n## Related Concepts\n"
                for concept in metadata.get("key_concepts"):
                    footer += f"- [[{concept}]]\n"

            new_content = f"---\n{fm_str}\n---\n\n{obsidian_header}{obsidian_callout}{content}{footer}"

        with open(filepath, "w", encoding="utf-8") as f:
            f.write(new_content)
        print("  [WRITE] Updated content.")

        target_title = ""
        t_match = re.search(r'^title: "(.*?)"', new_content, re.MULTILINE)
        if t_match:
            target_title = t_match.group(1)

        if target_title:
            kebab_title = to_kebab_case(target_title)
            # Use file creation date for prefix
            date_prefix = datetime.datetime.fromtimestamp(stat.st_ctime).strftime(
                "%Y-%m-%d"
            )
            new_filename = f"{date_prefix}-{kebab_title}.md"
            new_filepath = os.path.join(os.path.dirname(filepath), new_filename)

            if new_filename != filename:
                if not os.path.exists(new_filepath):
                    try:
                        os.rename(filepath, new_filepath)
                        print(f"  [RENAME] -> {new_filename}")
                    except OSError as e:
                        print(f"  [ERROR] Rename failed: {e}")
                else:
                    print(f"  [WARN] Name exists: {new_filename}")


def main():
    parser = argparse.ArgumentParser(description="Organize chat logs for Obsidian.")
    parser.add_argument(
        "directory", nargs="?", default=os.getcwd(), help="Target directory"
    )
    parser.add_argument(
        "-r", "--recursive", action="store_true", help="Recursively scan"
    )
    parser.add_argument(
        "-i",
        "--incremental",
        action="store_true",
        help="Scan files WITH frontmatter and improve them (add missing fields, fix names)",
    )

    args = parser.parse_args()
    target_dir = os.path.abspath(args.directory)

    # Verify Ollama
    try:
        req = urllib.request.Request(OLLAMA_URL.replace("/api/generate", "/api/tags"))
        with urllib.request.urlopen(req) as _:
            pass
    except Exception as e:
        print(f"CRITICAL: Cannot connect to Ollama at {OLLAMA_URL}: {e}")
        sys.exit(1)

    print(f"Scanning: {target_dir} (Incremental: {args.incremental})")

    files_to_process = []
    if args.recursive:
        for root, dirs, files in os.walk(target_dir):
            for file in files:
                if not file.startswith("."):  # Ignore hidden files
                    files_to_process.append(os.path.join(root, file))
    else:
        for f in os.listdir(target_dir):
            if not f.startswith("."):
                files_to_process.append(os.path.join(target_dir, f))

    count = 0
    for f in files_to_process:
        if os.path.isfile(f) and f.endswith(".md") and not f.endswith(".bak"):
            process_file(f, incremental=args.incremental)
            count += 1

    if count == 0:
        print("No markdown files found.")


if __name__ == "__main__":
    main()
