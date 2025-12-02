# Development Shells

This directory contains development shell environments that provide project-specific tooling and dependencies. These shells can be activated manually with `nix develop` or automatically using [direnv](https://direnv.net/).

## Available Devshells

### default

The default development shell loaded when entering this repository.

**Activation**:
```bash
nix develop
# or with direnv
use flake
```

**Packages**:
- Currently minimal (placeholder for project-specific tools)

**Use Cases**:
- General repository development
- Building and testing configurations
- Managing flake operations

---

### pdftools

Comprehensive PDF manipulation and document processing environment.

**Activation**:
```bash
nix develop .#pdftools
# or with direnv
use flake .#pdftools
```

**Packages**:
- **ghostscript** - PostScript and PDF processor
- **paperjam** - PDF page manipulation tool
- **poppler-utils** - PDF rendering library utilities (pdfinfo, pdftotext, etc.)
- **Python 3.13** with document processing packages:
  - gotenberg-client - API client for Gotenberg document conversion
  - python-docx - Microsoft Word document creation/manipulation
  - python-pptx - PowerPoint presentation creation/manipulation
  - md2pdf - Markdown to PDF conversion
  - pdftotext - PDF text extraction
  - rmrl - Remove restrictions from PDF files

**Use Cases**:
- PDF manipulation and conversion
- Document generation from various formats
- Automated document processing workflows
- Batch PDF operations

---

### python313

Clean Python 3.13 development environment.

**Activation**:
```bash
nix develop .#python313
# or with direnv
use flake .#python313
```

**Packages**:
- **Python 3.13** - Latest Python interpreter
- **pip** - Python package installer
- **virtualenv** - Virtual environment creation

**Shell Hook**:
- Displays "Entering Python 3.13 devshell" message on activation

**Use Cases**:
- Python 3.13 development
- Testing Python scripts with latest interpreter
- Creating isolated Python environments

---

### n8n-node-dev

Development environment for creating custom n8n nodes.

**Activation**:
```bash
nix develop .#n8n-node-dev
# or with direnv
use flake .#n8n-node-dev
```

**Packages**:
- **Node.js 22** - JavaScript runtime
- **npm** and **pnpm** - Package managers
- **TypeScript** - Type-safe JavaScript
- **typescript-language-server** - IDE support
- **ESLint** and **Prettier** - Linting and formatting
- **Turbo** - Build system
- **@n8n/node-cli** - Official n8n node development CLI (auto-installed)

**Shell Hook**:
- Displays environment info (Node, npm, pnpm, TypeScript versions)
- Auto-installs `@n8n/node-cli` globally
- Shows available commands

**Use Cases**:
- Creating custom n8n community nodes
- Developing n8n integrations
- Building and testing n8n node packages

**Commands** (available after entering shell):
```bash
n8n-node new <name>   # Create a new node project
n8n-node dev          # Run n8n with your node (hot reload)
n8n-node build        # Build your node
```

## Using Development Shells

### Manual Activation

Enter a development shell directly:

```bash
# Default shell
nix develop

# Specific shell
nix develop .#pdftools
nix develop .#python313
nix develop .#n8n-node-dev
```

Exit the shell with `exit` or `Ctrl+D`.

### Automatic Activation with direnv

Development shells can be automatically loaded when entering a directory using direnv.

#### Setup

1. **Install direnv** (if not already available via home-manager):
   ```bash
   # direnv is typically included in home-manager configurations
   ```

2. **Create an `.envrc` file** in your project directory:

   ```bash
   # For default shell
   use flake

   # For specific shell (e.g., pdftools)
   use flake ~/Projects/github/iamruinous/nix-config#pdftools
   ```

3. **Allow direnv** to load the configuration:
   ```bash
   direnv allow
   ```

4. **Automatic loading** - The shell environment will now activate automatically when you `cd` into the directory.

#### .envrc Examples

**Using the default devshell**:
```bash
#!/usr/bin/env bash
source_up

# Load default devshell
use flake

# Load local overrides if present
source_env_if_exists .envrc.local
```

**Using pdftools for document processing projects**:
```bash
#!/usr/bin/env bash
# PDF manipulation project
use flake ~/Projects/github/iamruinous/nix-config#pdftools

# Watch the devshell file for changes
watch_file ~/Projects/github/iamruinous/nix-config/devshells/pdftools.nix
```

**Using python313 for Python projects**:
```bash
#!/usr/bin/env bash
# Python 3.13 project
use flake ~/Projects/github/iamruinous/nix-config#python313

# Set project-specific environment variables
export PYTHONPATH="$PWD/src:$PYTHONPATH"
```

### Best Practices

#### Environment Variables

Export project-specific variables in your `.envrc`:
```bash
use flake .#python313
export DATABASE_URL="postgresql://localhost/mydb"
export DEBUG=true
```

#### Watch Files

Automatically reload when devshell definitions change:
```bash
use flake .#pdftools
watch_file devshells/pdftools.nix
```

#### Local Overrides

Create `.envrc.local` (git-ignored) for personal settings:
```bash
# .envrc
use flake
source_env_if_exists .envrc.local

# .envrc.local (not tracked in git)
export MY_PERSONAL_API_KEY="secret"
```

## Creating a New Devshell

1. **Create a new file** in this directory (e.g., `nodejs.nix`):

   ```nix
   {pkgs, ...}:
   pkgs.mkShell {
     packages = with pkgs; [
       nodejs_22
       nodePackages.npm
       nodePackages.pnpm
       nodePackages.typescript
     ];

     shellHook = ''
       echo "Node.js development environment"
       node --version
     '';
   }
   ```

2. **Blueprint auto-discovery** - The flake system automatically discovers the new shell.

3. **Use the new shell**:
   ```bash
   nix develop .#nodejs
   ```

4. **Create an `.envrc` for automatic loading**:
   ```bash
   use flake ~/Projects/github/iamruinous/nix-config#nodejs
   ```

## Shell Structure

Each devshell file follows this structure:

```nix
{pkgs, ...}:
pkgs.mkShell {
  # Required packages
  packages = with pkgs; [
    # List packages here
  ];

  # Optional: Environment variables
  env = {
    MY_VAR = "value";
  };

  # Optional: Run when entering shell
  shellHook = ''
    echo "Welcome to my devshell"
  '';
}
```

## Common Patterns

### Language-Specific Shells

Create focused environments for different languages:
- `python313.nix` - Python development
- `nodejs.nix` - JavaScript/TypeScript development
- `rust.nix` - Rust development with cargo
- `go.nix` - Go development

### Tool-Specific Shells

Create environments for specific tools or workflows:
- `pdftools.nix` - Document processing
- `cloud.nix` - Cloud CLI tools (aws, gcloud, azure)
- `k8s.nix` - Kubernetes tools (kubectl, helm, k9s)

### Project Templates

Create templates that combine multiple tools:
- `web-dev.nix` - Web development (node, python, docker)
- `data-science.nix` - Data analysis (python, R, jupyter)

## Integration with System Configuration

Devshells are independent from system configurations and can be used on any machine with Nix installed. They provide reproducible development environments without modifying system packages.

## Troubleshooting

### Shell not found
If `nix develop .#shellname` fails, ensure:
- The file exists in `devshells/`
- The file has a `.nix` extension
- The flake has been updated: `nix flake update`

### direnv not loading
If direnv doesn't activate:
- Run `direnv allow` in the directory
- Check `.envrc` syntax
- Verify direnv is installed and hooked into your shell
