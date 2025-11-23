# devshell.nix
# Using mkShell from nixpkgs
{ pkgs,
  perSystem,
  ...
}:
pkgs.mkShell {
  packages = [
    # perSystem.nixos-lima.nixos-lima
  ];

  shellHook = ''
    # Show helpful message on shell startup if age identity is not unlocked
    if ! ${pkgs.coreutils}/bin/test -f /tmp/id_age 2>/dev/null; then
      echo ""
      echo "💡 Tip: Run 'agenix-helper unlock' to decrypt your age identity for agenix operations"
      echo "   Available commands: agenix-helper {unlock|lock|status}"
      echo ""
    fi
  '';
}

