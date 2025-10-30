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
}

