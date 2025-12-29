{
  pkgs,
  lib,
  flake,
  ...
}: let
  inherit (lib) mapAttrs imap1;

  # Convert cache public key to substituter URL
  # e.g., "nix-community.cachix.org-1:..." -> "https://nix-community.cachix.org?priority=1"
  cacheUrl = index: pubKey: let
    beforeColon = builtins.head (lib.splitString ":" pubKey);
    name = lib.concatStringsSep "-" (lib.init (lib.splitString "-" beforeColon));
  in "https://${name}?priority=${toString index}";
in {
  # Nix Settings
  nix.settings = {
    # Enable flakes and pipes
    experimental-features =
      [
        "nix-command"
        "flakes"
        "pipe-operators"
      ]
      ++ (pkgs.lib.optionals pkgs.stdenv.isDarwin [
        "external-builders"
      ]);

    # 500MB buffer
    download-buffer-size = 500000000;

    # Deduplicate and optimize nix store
    auto-optimise-store = lib.mkDefault true;

    # Root and sudo users
    trusted-users = ["root" "@wheel"];

    # Supress annoying warning
    warn-dirty = false;

    # https://discourse.nixos.org/t/how-to-prevent-flake-from-downloading-registry-at-every-flake-command/32003/3
    flake-registry = "${flake.inputs.flake-registry}/flake-registry.json";

    # Speed up remote builds
    builders-use-substitutes = true;

    # Binary caches
    substituters = imap1 (index: key: cacheUrl index key) flake.caches;
    trusted-public-keys = flake.caches;
  };

  # Automatic garbage collection
  nix.gc =
    {
      automatic = pkgs.stdenv.isLinux;

      options = "--delete-older-than 30d";
    }
    // (
      if pkgs.stdenv.isDarwin
      then {
        # Add Darwin-specific attributes to the user
        interval = {
          Weekday = 0;
          Hour = 0;
          Minute = 0;
        };
      }
      else {
        dates = "weekly";
      }
    );

  # Add each flake input as a registry
  # To make nix3 commands consistent with the flake
  # Use mkDefault to allow overriding (e.g., when using nixos-raspberrypi's separate nixpkgs)
  nix.registry = mapAttrs (_: value: {flake = lib.mkDefault value;}) flake.inputs;

  # Map registries to channels
  nix.nixPath = ["repl=${flake}/repl.nix" "nixpkgs=${flake.inputs.nixpkgs}"];
}
