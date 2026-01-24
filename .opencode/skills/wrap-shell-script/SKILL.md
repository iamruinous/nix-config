---
name: wrap-shell-script
description: Convert a shell script into a reproducible Nix package
compatibility: Requires nix
metadata:
  author: ruinous.ai
  version: "1.1"
  domain: packaging
parameters:
  script_name:
    type: string
    description: Name for the wrapped script package
    required: true
    placeholder: "my-script"
  script_path:
    type: string
    description: Path to existing script file (or "inline" to create new)
    required: true
    placeholder: "./scripts/backup.sh"
---

# Wrap Shell Script

Convert a shell script into a reproducible Nix package with proper dependency management.

## Parameter Handling

**If parameters are missing from `$ARGUMENTS`, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "What should the packaged script be named?",
      header: "Name",
      options: [
        { label: "Enter name...", description: "e.g., my-script (will be the command name)" }
      ]
    },
    {
      question: "Where is the script located?",
      header: "Script Path",
      options: [
        { label: "Enter path...", description: "e.g., ./scripts/backup.sh" },
        { label: "Create inline", description: "I'll provide the script content" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `<script_name> <script_path>`
- Example: `backup-script ./scripts/backup.sh`
- Example: `my-tool inline` (then provide content)

## Steps

### 1. Create package directory
```bash
mkdir -p packages/<script-name>
```

### 2. Copy or create the script
```bash
cp /path/to/script.sh packages/<script-name>/script.sh
```

### 3. Create default.nix

```nix
{ lib, stdenv, makeWrapper, bash, coreutils, jq, curl }:

stdenv.mkDerivation rec {
  pname = "script-name";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ bash ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp script.sh $out/bin/${pname}
    chmod +x $out/bin/${pname}

    # Wrap with runtime dependencies
    wrapProgram $out/bin/${pname} \
      --prefix PATH : ${lib.makeBinPath [ coreutils jq curl ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Description of what the script does";
    homepage = "https://github.com/user/repo";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "script-name";
  };
}
```

### 4. Build and test
```bash
nix build .#<script-name>
./result/bin/<script-name> --help
```

## Key Concepts

### Dependencies

| Type | Purpose | Example |
|------|---------|---------|
| `nativeBuildInputs` | Build-time tools | `makeWrapper` |
| `buildInputs` | Compile-time libs | `bash` |
| Runtime (via wrap) | PATH dependencies | `coreutils`, `jq`, `curl` |

### wrapProgram Options

```nix
wrapProgram $out/bin/${pname} \
  --prefix PATH : ${lib.makeBinPath [ dep1 dep2 ]} \
  --set ENV_VAR "value" \
  --suffix PATH : "/additional/path"
```

### Shebang Patching

If script has hardcoded paths:
```nix
patchPhase = ''
  patchShebangs .
'';
```

## Alternative: writeShellApplication

For simpler scripts, use `writeShellApplication`:

```nix
{ writeShellApplication, coreutils, jq }:

writeShellApplication {
  name = "my-script";
  runtimeInputs = [ coreutils jq ];
  text = ''
    echo "Hello, $1!"
    jq --version
  '';
}
```

## Common Dependencies

| Need | Package |
|------|---------|
| Basic utils | `coreutils` |
| JSON processing | `jq` |
| HTTP requests | `curl`, `wget` |
| Text processing | `gnused`, `gawk`, `gnugrep` |
| Archive handling | `gzip`, `unzip`, `p7zip` |
| Git operations | `git` |
| SSH | `openssh` |

## Example

```bash
/wrap-shell-script backup-script ./scripts/backup.sh
```

## Verification

```bash
# Build
nix build .#<script-name>

# Test execution
./result/bin/<script-name>

# Check dependencies are found
ldd ./result/bin/<script-name>  # (if binary wrapper)
```
