# mkdocs.nix
# MkDocs documentation development environment with zensical support
#
# Two modes of operation:
# 1. Development: Uses zensical (installed via uv/pip) for hot reload
# 2. Production/CI: Uses mkdocs from nixpkgs for reproducible builds
#
# Usage:
#   nix develop .#mkdocs
#   # or with direnv: use flake path/to/nix-config#mkdocs
#
{pkgs, ...}:
pkgs.mkShell {
  packages = with pkgs; [
    # Python 3.13 with MkDocs and Material theme
    # This is used for `nix build` and CI - provides reproducible builds
    (python313.withPackages (ps:
      with ps; [
        # Core MkDocs
        mkdocs
        mkdocs-material
        mkdocs-material-extensions

        # Extensions commonly used with Material theme
        pymdown-extensions

        # Package management for zensical installation
        pip
        virtualenv
      ]))

    # Modern Python package management (for zensical)
    uv

    # Common documentation tools
    just # Task runner
    git # Version control

    # Optional: for packaging dist artifacts
    zip
  ];

  shellHook = ''
    # Auto-create venv with zensical if it doesn't exist
    # zensical is a fork of mkdocs with enhanced features
    # Not yet in nixpkgs, so we install via uv/pip
    if [ ! -d .venv ]; then
      echo "Creating Python venv with zensical..."
      uv venv .venv --quiet
      uv pip install --quiet zensical
    fi

    # Activate venv if it exists
    if [ -d .venv ]; then
      source .venv/bin/activate
    fi

    echo ""
    echo "MkDocs development environment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "mkdocs (nixpkgs): $(mkdocs --version 2>/dev/null | head -1)"
    if command -v zensical &>/dev/null; then
      echo "zensical (venv):  $(zensical --version 2>/dev/null | head -1)"
    fi
    echo ""
    echo "Commands:"
    echo "  mkdocs serve     - Start dev server (hot reload)"
    echo "  mkdocs build     - Build static site"
    echo "  zensical serve   - Start dev server (zensical)"
    echo "  just             - Show project tasks"
    echo ""
  '';
}
