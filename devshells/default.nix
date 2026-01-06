# devshell.nix
# Using mkShell from nixpkgs
{pkgs, ...}:
pkgs.mkShell {
  packages = with pkgs;
    [
      cloudflared
      cloudflare-cli
      commitlint # Git commit message linter (for pre-commit hook)
      doggo # Modern DNS client for lookups
      gitleaks # Secret scanner (for pre-commit hook)
      go # Go compiler for building/testing Go packages
      gum # Pretty TUI for Makefile commands
      pnpm # For running Node.js-based MCP servers
      uv # Provides uvx for running Python-based MCP servers
      postgresql # cli for postgres
      prek
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
      bmaptool # Fast SD card flashing with block map support
    ];

  shellHook = ''
    # Set GOPATH to avoid "relative path" errors when running Go tools
    export GOPATH="$HOME/go"

    # Alias dig to doggo for modern DNS lookups
    alias dig='doggo'

    # Auto-install git hooks using prek
    if [ -d .git ]; then
      prek install --hook-types pre-commit commit-msg >/dev/null 2>&1
    fi

    # Show helpful message on shell startup if age identity is not unlocked
    if ! ${pkgs.coreutils}/bin/test -f /tmp/id_age 2>/dev/null; then
      echo ""
      echo "💡 Tip: Run 'agenix-helper unlock' to decrypt your age identity for agenix operations"
      echo "   Available commands: agenix-helper {unlock|lock|status}"
      echo ""
    fi
  '';
}
