# Add Package

Analyze a project from a URL or local directory and create a Nix package with auto-detected build system.

## Parameter Handling

**If parameters are missing from `$ARGUMENTS`, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "What is the source location? (GitHub URL, git URL, or local path)",
      header: "Source",
      options: [
        { label: "Enter URL or path...", description: "e.g., https://github.com/user/repo or ~/Projects/myapp" }
      ]
    },
    {
      question: "What should the package be named? (leave blank to auto-detect)",
      header: "Name",
      options: [
        { label: "Auto-detect (Recommended)", description: "Derive from repository/directory name" },
        { label: "Enter name...", description: "Custom package name (lowercase, hyphens OK)" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `<source_url_or_path> [package_name]`
- Example: `https://github.com/user/myapp`
- Example: `~/Projects/myapp my-custom-name`
- Example: `https://forge.meskill.farm/iamruinous/project`

## Detection Strategy

### Step 1: Fetch/Access Source

**For URLs:**
- GitHub: Use `mcp_github_get_file_contents` to read project files
- Forgejo/Gitea: Use web fetch or clone
- Direct archives: Note the URL for `fetchurl`

**For Local Paths:**
- Use `mcp_read` and `mcp_glob` to analyze the directory

### Step 2: Detect Project Type

Check for these files in priority order:

| File | Type | Build System |
|------|------|--------------|
| `go.mod` | Go | `buildGoModule` |
| `Cargo.toml` | Rust | `rustPlatform.buildRustPackage` |
| `pyproject.toml` | Python | `python3Packages.buildPythonPackage` |
| `setup.py` | Python (legacy) | `python3Packages.buildPythonPackage` |
| `package.json` | Node.js | `buildNpmPackage` or shell wrapper |
| `CMakeLists.txt` | C/C++ | `stdenv.mkDerivation` with cmake |
| `Makefile` | C/C++ | `stdenv.mkDerivation` |
| `mkdocs.yml` | Docs (MkDocs) | `stdenv.mkDerivation` with mkdocs |
| `*.sh` only | Shell script | `stdenv.mkDerivation` wrapper |
| `*.deb` | Binary | `stdenv.mkDerivation` extract |

### Step 3: Extract Metadata

From detected project files, extract:
- **Name**: From `go.mod`, `Cargo.toml`, `pyproject.toml`, `package.json`, or directory name
- **Version**: From tags, version files, or `0.1.0` as default
- **Description**: From README.md first paragraph or project file metadata
- **License**: From LICENSE file or project metadata
- **Dependencies**: From lock files or dependency declarations

## Templates by Type

### Go Module (go.mod detected)

```nix
{pkgs, ...}:
pkgs.buildGoModule rec {
  pname = "<package-name>";
  version = "<version>";

  src = pkgs.fetchFromGitHub {
    owner = "<owner>";
    repo = "<repo>";
    rev = "v${version}";
    hash = "sha256-AAAA...";
  };

  vendorHash = "sha256-BBBB...";

  meta = with pkgs.lib; {
    description = "<description>";
    homepage = "<url>";
    license = licenses.<license>;
    mainProgram = "<binary-name>";
    platforms = platforms.unix;
  };
}
```

**For Forgejo/Gitea sources, use `fetchgit`:**
```nix
  src = pkgs.fetchgit {
    url = "<git-url>";
    rev = "v${version}";
    hash = "sha256-AAAA...";
  };
```

### Rust Package (Cargo.toml detected)

```nix
{pkgs, ...}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "<package-name>";
  version = "<version>";

  src = pkgs.fetchFromGitHub {
    owner = "<owner>";
    repo = "<repo>";
    rev = "v${version}";
    hash = "sha256-AAAA...";
  };

  cargoHash = "sha256-BBBB...";

  meta = with pkgs.lib; {
    description = "<description>";
    homepage = "<url>";
    license = licenses.<license>;
    mainProgram = "<binary-name>";
  };
}
```

### Python Package (pyproject.toml detected)

```nix
{pkgs, ...}:
pkgs.python3Packages.buildPythonApplication rec {
  pname = "<package-name>";
  version = "<version>";
  format = "pyproject";

  src = pkgs.fetchFromGitHub {
    owner = "<owner>";
    repo = "<repo>";
    rev = "v${version}";
    hash = "sha256-AAAA...";
  };

  nativeBuildInputs = with pkgs.python3Packages; [
    setuptools
    setuptools-scm
    wheel
  ];

  propagatedBuildInputs = with pkgs.python3Packages; [
    # Add dependencies from pyproject.toml
  ];

  pythonImportsCheck = ["<module_name>"];

  meta = with pkgs.lib; {
    description = "<description>";
    homepage = "<url>";
    license = licenses.<license>;
    mainProgram = "<binary-name>";
  };
}
```

### Node.js Package (package.json detected)

For CLI tools, prefer shell wrapper with bundled JS:

```nix
{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "<package-name>";
  version = "<version>";
  dontUnpack = true;

  propagatedBuildInputs = with pkgs; [
    nodejs
  ];

  buildPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/<package-name>

    # Copy source files
    cp -r ${./src}/* $out/share/<package-name>/

    # Create wrapper script
    cat > $out/bin/<package-name> << 'EOF'
    #!/usr/bin/env bash
    exec ${pkgs.nodejs}/bin/node $out/share/<package-name>/index.js "$@"
    EOF
    chmod +x $out/bin/<package-name>
  '';

  installPhase = "true";

  meta = with pkgs.lib; {
    description = "<description>";
    homepage = "<url>";
    license = licenses.<license>;
    mainProgram = "<package-name>";
    platforms = platforms.unix;
  };
}
```

### MkDocs Documentation (mkdocs.yml detected)

```nix
{pkgs, ...}:
pkgs.stdenv.mkDerivation rec {
  pname = "<package-name>";
  version = "<version>";

  src = pkgs.fetchzip {
    url = "<release-url>";
    sha256 = "sha256-AAAA...";
  };

  # Or for pre-built docs:
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r * $out/
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "<description>";
    homepage = "<url>";
    license = licenses.<license>;
    platforms = platforms.linux;
  };
}
```

### Shell Script

```nix
{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "<package-name>";
  version = "<version>";
  dontUnpack = true;

  propagatedBuildInputs = with pkgs; [
    bash
    coreutils
    # Add detected dependencies
  ];

  passthru.shellPath = "/bin/<package-name>";
  outputs = ["out"];

  buildPhase = ''
    mkdir -p $out/bin

    substitute ${./<script>.sh} $out/bin/<package-name> \
      --replace '@bash@' '${pkgs.bash}/bin/bash' \
      --replace '@coreutils@' '${pkgs.coreutils}'

    chmod +x $out/bin/<package-name>
  '';

  installPhase = "true";

  meta = with pkgs.lib; {
    description = "<description>";
    homepage = "<url>";
    license = licenses.<license>;
    mainProgram = "<package-name>";
    platforms = platforms.unix;
  };
}
```

## Steps

### 1. Analyze Source

```
# For GitHub URL
Parse owner/repo from URL
Use mcp_github_get_file_contents to check for:
- go.mod, Cargo.toml, pyproject.toml, package.json, mkdocs.yml

# For Forgejo/Gitea URL  
Use mcp_webfetch or clone to analyze

# For local path
Use mcp_glob to find project files
Use mcp_read to analyze content
```

### 2. Determine Package Details

- Extract name from project file or derive from repo/directory
- Find latest version from tags or releases
- Parse description from README.md or project metadata
- Identify license from LICENSE file or project metadata
- List dependencies for propagatedBuildInputs

### 3. Create Package Directory

```bash
mkdir -p packages/<package-name>
```

### 4. Generate default.nix

Use the appropriate template based on detected type.

### 5. Create README.md

```markdown
# <package-name>

<description>

## Overview

<brief explanation of purpose>

## Features

- Feature 1
- Feature 2

## Usage

```nix
environment.systemPackages = with pkgs; [
  <package-name>
];
```

## Version

<version>

## Upstream

<homepage-url>
```

### 6. Build and Test

```bash
# First build (will fail with correct hash)
nix build .#<package-name>

# Copy hash from error output
# Update default.nix with correct hash

# Build again
nix build .#<package-name>

# Test
./result/bin/<package-name> --help
```

### 7. Update packages/README.md

Add entry to the packages README following the existing format.

## Hash Resolution

For the first build, use placeholder hashes:

```nix
hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

Then extract correct hashes from build errors:

```bash
nix build .#<package-name> 2>&1 | grep "got:" | awk '{print $2}'
```

Or use prefetch tools:

```bash
# For GitHub
nix-prefetch-github <owner> <repo> --rev v<version>

# For URLs
nix-prefetch-url --unpack <url>

# For git repos
nix-prefetch-git <git-url> --rev v<version>
```

## Example Workflow

```bash
# User provides GitHub URL
/add-package https://github.com/docker/mcp-gateway

# Agent analyzes:
# - Detects go.mod -> Go project
# - Extracts name: mcp-gateway
# - Finds version from releases: 0.28.0
# - Reads description from README
# - Identifies Apache 2.0 license

# Creates packages/docker-mcp-gateway/default.nix
# Creates packages/docker-mcp-gateway/README.md
# Runs nix build, extracts hashes
# Updates packages/README.md
```

## Post-Completion Checklist

- [ ] Package type correctly detected
- [ ] default.nix uses appropriate builder
- [ ] Hashes resolved (not placeholders)
- [ ] README.md created with usage instructions
- [ ] `nix build .#<package-name>` succeeds
- [ ] Binary/output works as expected
- [ ] packages/README.md updated with new entry
