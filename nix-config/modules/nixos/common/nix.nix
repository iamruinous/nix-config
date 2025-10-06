{
  hostName,
  pkgs,
  lib,
  flake,
  ...
}: let
  inherit (lib) mapAttrs imap1;
  inherit (flake.lib) cacheUrl;
in {
  # Nix Settings
  nix.settings = {
    # Enable flakes and pipes
    experimental-features = ["nix-command" "flakes" "pipe-operators"];

    # 500MB buffer
    download-buffer-size = 500000000;

    # Deduplicate and optimize nix store
    auto-optimise-store = true;

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

  # nix.sshServe = {
  #   enable = true;
  #   keys = let
  #     userKeys = ls {
  #       path = flake + /users;
  #       dirsWith = ["id_ed25519.pub"];
  #     };
  #   in
  #     map (key: builtins.readFile key) userKeys;
  # };

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
  nix.registry = mapAttrs (_: value: {flake = value;}) flake.inputs;

  # Map registries to channels
  nix.nixPath = ["repl=${flake}/repl.nix" "nixpkgs=${flake.inputs.nixpkgs}"];

  # Nixpkgs configuration
  nixpkgs.config = {
    allowUnfree = true;
  };

  # # Automatically upgrade this system while I sleep
  # system.autoUpgrade = {
  #   enable = false;
  #   dates = "04:00";
  #   flake = "/etc/nixos#${hostName}";
  #   flags = [
  #     # "--update-input" "nixpkgs"
  #     # "--update-input" "unstable"
  #     # "--update-input" "nur"
  #     # "--update-input" "home-manager"
  #     # "--update-input" "agenix"
  #     # "--update-input" "impermanence"
  #     # "--commit-lock-file"
  #   ];
  #   allowReboot = true;
  # };
}
