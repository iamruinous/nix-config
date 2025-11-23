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
    # Age identity management aliases
    alias age-unlock='${pkgs.bash}/bin/bash .scripts/agenix-unlock.sh unlock'
    alias age-lock='${pkgs.bash}/bin/bash .scripts/agenix-unlock.sh lock'
    alias age-status='${pkgs.bash}/bin/bash .scripts/agenix-unlock.sh status'

    # Show helpful message on shell startup
    if [[ ! -f /tmp/id_age ]]; then
      echo ""
      echo "💡 Tip: Run 'age-unlock' to decrypt your age identity for agenix operations"
      echo "   Run 'age-lock' when done to remove the decrypted key"
      echo ""
    fi
  '';
}

