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

    # NixOS profiles to optimize settings for different hardware
    # <https://github.com/NixOS/nixos-hardware>
    hardware.url = "github:nixos/nixos-hardware";

    # arion for docker
    # <https://github.com/hercules-ci/arion>
    arion.url = "github:hercules-ci/arion";

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

    # Declarative libvirt
    # <https://github.com/AshleyYakeley/NixVirt>
    NixVirt.url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
    NixVirt.inputs.nixpkgs.follows = "nixpkgs";

    # MicroVM
    # <https://github.com.astro/microvm>
    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";

    # ai coding agents
    # <https://github.com/numtide/nix-ai-tools>
    nix-ai-tools.url = "github:numtide/nix-ai-tools";

    # nixos-lima VM builders
    # <https://github.com/ciderale/nixos-lima>
    nixos-lima.url = "github:ciderale/nixos-lima";
    nixos-lima.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Load the blueprint
  # outputs = inputs: inputs.blueprint {inherit inputs;};
  outputs = inputs:
    inputs.blueprint {inherit inputs;}
    // {
      caches = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "wezterm.cachix.org-1:kAbhjYUC9qvblTE+s7S+kl5XM1zVa4skO+E/1IDWdH0="
        "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
        "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
      ];
    };
}
# Blueprint automatically maps: devshells, hosts, lib, modules, packages
# inherit
#   (inputs.blueprint {inherit inputs;})
#   checks
#   devShells
#   formatter
#   lib
#   nixosConfigurations
#   darwinConfigurations
#   packages
#   homeModules
#   networking
#   nixosModules
#   darwinModules
#   users
#   ;

