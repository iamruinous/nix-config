# devshell.nix
# Using mkShell from nixpkgs
{
  pkgs,
  perSystem,
  ...
}:
pkgs.mkShell {
  packages = with pkgs; [
    cloudflare-cli
    doggo # Modern DNS client for lookups
    pnpm # For running Node.js-based MCP servers
    uv # Provides uvx for running Python-based MCP servers
    # perSystem.nixos-lima.nixos-lima
  ];

  shellHook = ''
    # Alias dig to doggo for modern DNS lookups
    alias dig='doggo'

    # Show helpful message on shell startup if age identity is not unlocked
    if ! ${pkgs.coreutils}/bin/test -f /tmp/id_age 2>/dev/null; then
      echo ""
      echo "💡 Tip: Run 'agenix-helper unlock' to decrypt your age identity for agenix operations"
      echo "   Available commands: agenix-helper {unlock|lock|status}"
      echo ""
    fi
  '';
}
