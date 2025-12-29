{
  description = "Blueprint-driven NixOS config and dotfiles";

  inputs = {
    # Nixpkgs
    # <https://search.nixos.org/packages>
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Map folder structure to flake outputs
    # <https://github.com/numtide/blueprint>
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    # <https://mipmip.github.io/home-manager-option-search>
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # System manager
    # <https://github.com/numtide/system-manager>
    system-manager.url = "github:numtide/system-manager";
    system-manager.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS profiles to optimize settings for different hardware
    # <https://github.com/NixOS/nixos-hardware>
    hardware.url = "github:nixos/nixos-hardware";

    # Nix Darwin (for MacOS machines)
    # <https://github.com/nix-darwin/nix-darwin>
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Homebrew
    # <https://github.com/zhaofengli/nix-homebrew>
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Nix Flake Registry
    # <https://github.com/nixos/flake-registry>
    flake-registry.url = "github:NixOS/flake-registry";
    flake-registry.flake = false;

    # Fenix for rust
    # <https://github.com/nix-community/fenix>
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    # Secureboot
    # <https://github.com/nix-community/lanzaboote>
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.2";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    # Wezterm
    # <https://github.com/wez/wezterm?dir=nix>
    wezterm.url = "github:wez/wezterm?dir=nix";

    # Hyprland
    # <https://github.com/h3rmt/hyprshell>
    hyprshell.url = "github:H3rmt/hyprswitch?ref=hyprshell";
    hyprland-qtutils.url = "github:hyprwm/hyprland-qtutils";
    walker.url = "github:abenz1267/walker";

    # Agenix for secrets
    # <https://github.com/ryantm/agenix>
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    # Agenix-rekey for improved secret management
    # <https://github.com/oddlama/agenix-rekey>
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";

    # Flatpak
    # <https://github.com/gmodena/nix-flatpak>
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # Disko
    # <https://github.com/nix-community/disko>
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Plasma Manager
    # <https://github.com/nix-community/plasma-manager>
    plasma-manager.url = "github:nix-community/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";

    # MicroVM
    # <https://github.com.astro/microvm>
    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";

    # # nixos-lima VM builders
    # # <https://github.com/ciderale/nixos-lima>
    # nixos-lima.url = "github:ciderale/nixos-lima";
    # nixos-lima.inputs.nixpkgs.follows = "nixpkgs";

    # nixos-anywhere
    # <https://github.com/nix-community/nixos-anywhere>
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    nixos-anywhere.inputs.nixpkgs.follows = "nixpkgs";

    # impermanence
    # <https://github.com/nix-community/impermanence>
    impermanence.url = "github:nix-community/impermanence";

    # claude-code-nix
    # <https://github.com/sadjow/claude-code-nix/>
    claude-code.url = "github:sadjow/claude-code-nix";

    # gemini-cli-nix
    # <https://github.com/iamruinous/gemini-cli-nix/>
    gemini-cli.url = "github:iamruinous/gemini-cli-nix";

    # nixos-raspberrypi
    # <https://https://github.com/nvmd/nixos-raspberrypi>
    # Note: Do NOT follow nixpkgs - nixos-raspberrypi has its own pinned nixpkgs
    # that's compatible with its boot.loader.raspberryPi options
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    # Nix User Repository
    # <https://nur.nix-community.org>
    # nur.url = "github:nix-community/NUR";
  };

  # Load the blueprint
  # outputs = inputs: inputs.blueprint {inherit inputs;};
  outputs = inputs: let
    blueprintOutputs = inputs.blueprint {
      inherit inputs;
      nixpkgs.config.allowUnfree = true;
    };

    # Raspberry Pi hosts (using nixos-raspberrypi's nixosSystem for proper kernel/bootloader support)
    # See hosts/README.md for naming conventions and documentation
    piHosts = let
      # Common specialArgs for all Pi hosts
      mkPiSpecialArgs = {
        inherit inputs;
        flake = inputs.self;
        nixos-raspberrypi = inputs.nixos-raspberrypi;
        perSystem = {
          self = blueprintOutputs.packages.aarch64-linux;
        };
      };

      # Common modules for all Pi hosts
      piCommonModules = [
        inputs.self.nixosModules.default
        inputs.self.nixosModules.server
        inputs.self.nixosModules.pi
        inputs.home-manager.nixosModules.home-manager
      ];

      # Discover home-manager users from host directory
      # Returns an attrset of user configs with proper defaults
      discoverUsers = hostDir: let
        usersDir = hostDir + "/users";
        userDirs =
          if builtins.pathExists usersDir
          then builtins.attrNames (builtins.readDir usersDir)
          else [];
        hasHomeConfig = name:
          builtins.pathExists (usersDir + "/${name}/home-configuration.nix");
        validUsers = builtins.filter hasHomeConfig userDirs;
        # Create user config with required defaults
        mkUserConfig = name: {pkgs, ...}: {
          imports = [
            (import (usersDir + "/${name}/home-configuration.nix"))
          ];
          home = {
            username = name;
            homeDirectory = "/home/${name}";
            stateVersion = "25.11";
          };
        };
      in
        builtins.listToAttrs (map (name: {
            inherit name;
            value = mkUserConfig name;
          })
          validUsers);

      # Home-manager configuration module for a Pi host
      mkHomeManagerConfig = hostDir: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = mkPiSpecialArgs;
          users = discoverUsers hostDir;
        };
      };

      # Helper to create a Pi 5 host
      mkPi5Host = hostDir:
        inputs.nixos-raspberrypi.lib.nixosSystem {
          specialArgs = mkPiSpecialArgs;
          modules =
            piCommonModules
            ++ [
              inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
              inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
              inputs.nixos-raspberrypi.nixosModules.sd-image
              (hostDir + "/configuration.nix")
              (mkHomeManagerConfig hostDir)
            ];
        };

      # Helper to create a Pi 4 host
      mkPi4Host = hostDir:
        inputs.nixos-raspberrypi.lib.nixosSystem {
          specialArgs = mkPiSpecialArgs;
          modules =
            piCommonModules
            ++ [
              inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.base
              inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.display-vc4
              inputs.nixos-raspberrypi.nixosModules.sd-image
              (hostDir + "/configuration.nix")
              (mkHomeManagerConfig hostDir)
            ];
        };
    in {
      # Legacy standalone Pi
      rp500 = mkPi5Host ./hosts/rp500;

      # RPC (Raspberry Pi Cluster) members
      # Naming: rpc-<model>-<name> (e.g., rpc-5-alpha = Pi 5, member "alpha")
      # Uses NATO phonetic alphabet: alpha, bravo, charlie, delta, echo, foxtrot...
      rpc-5-alpha = mkPi5Host ./hosts/rpc-5-alpha;
      rpc-4-echo = mkPi4Host ./hosts/rpc-4-echo;
    };
  in
    blueprintOutputs
    // {
      # Expose shared modules (cross-platform) from blueprint
      # Blueprint auto-discovers modules/shared/ and creates modules.shared
      sharedModules = blueprintOutputs.modules.shared or {};

      # Expose desktop environment modules manually
      # Blueprint creates flat module outputs, so we expose subdirectories here
      desktopModules = {
        kde = ./modules/nixos/desktop/kde;
        gnome = ./modules/nixos/desktop/gnome;
        hyprland = ./modules/nixos/desktop/hyprland;
        lxqt = ./modules/nixos/desktop/lxqt;
        xfce = ./modules/nixos/desktop/xfce;
      };

      # Merge Pi hosts with blueprint nixosConfigurations
      nixosConfigurations = blueprintOutputs.nixosConfigurations // piHosts;

      # packages = pkgs.perSystem.default;
      caches = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "wezterm.cachix.org-1:kAbhjYUC9qvblTE+s7S+kl5XM1zVa4skO+E/1IDWdH0="
        "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
        "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
        "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
        "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        "gemini-cli.cachix.org-1:UgcVYrQrbEktUBlGpoEmTLqZ05LK9xhRfkzzTgli1rM="
      ];

      # Expose agenix-rekey configuration
      # Usage: nix run .#agenix-rekey -- edit <secret>
      #        nix run .#agenix-rekey -- rekey --all
      agenix-rekey = inputs.agenix-rekey.configure {
        userFlake = inputs.self;
        nixosConfigurations = blueprintOutputs.nixosConfigurations // piHosts;
        homeConfigurations = blueprintOutputs.homeConfigurations or {};
      };
    };
}
