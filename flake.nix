{
  description = "Blueprint-driven NixOS config and dotfiles";

  inputs = {
    # Nixpkgs
    # <https://search.nixos.org/packages>
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    # nixpkgs master for bleeding-edge packages (ROCm 7.1.1 for Strix Halo)
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

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

    # llm-agents
    # <https://github.com/numtide/llm-agents.nix>
    llm-agents.url = "github:numtide/llm-agents.nix";

    # nixos-raspberrypi
    # <https://https://github.com/nvmd/nixos-raspberrypi>
    # Note: Do NOT follow nixpkgs - nixos-raspberrypi has its own pinned nixpkgs
    # that's compatible with its boot.loader.raspberryPi options
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    # budgey-assistant-ingest-tools - Multi-CLI session extraction and ingestion tools
    # <https://forge.meskill.farm/iamruinous/budgey-assistant-ingest-tools>
    # NOTE: Keep pinned to tagged version. Update with: /update-flake-input budgey-assistant-ingest-tools
    budgey-assistant-ingest-tools.url = "git+ssh://git@forge.meskill.farm/iamruinous/budgey-assistant-ingest-tools.git?ref=refs/tags/v0.18.3";
    budgey-assistant-ingest-tools.inputs.nixpkgs.follows = "nixpkgs";

    # budgey-assistant-dashboard - Analytics dashboard for budgey assistant
    # <https://forge.meskill.farm/iamruinous/budgey-assistant-dashboard>
    # NOTE: Keep pinned to tagged version. Update with: /update-flake-input budgey-assistant-dashboard
    budgey-assistant-dashboard.url = "git+ssh://git@forge.meskill.farm/iamruinous/budgey-assistant-dashboard.git?ref=refs/tags/v0.4.10";
    budgey-assistant-dashboard.inputs.nixpkgs.follows = "nixpkgs";

    # n8n-agent - n8n workflow automation agent
    # <https://forge.meskill.farm/iamruinous/n8n-agent>
    n8n-agent.url = "git+ssh://git@forge.meskill.farm/iamruinous/n8n-agent.git?ref=refs/tags/v0.2.0";
    n8n-agent.inputs.nixpkgs.follows = "nixpkgs";

    # messy-attributes-editor - CRUD webservice for messy_attribute table
    # <https://forge.meskill.farm/iamruinous/messy-attributes-editor>
    # NOTE: Keep pinned to tagged version. Update with: /update-flake-input messy-attributes-editor
    messy-attributes-editor.url = "git+ssh://git@forge.meskill.farm/iamruinous/messy-attributes-editor.git?ref=refs/tags/v0.3.0";
    messy-attributes-editor.inputs.nixpkgs.follows = "nixpkgs";

    # ruinagents - Agent definitions, docs, and skills
    # <https://forge.meskill.farm/iamruinous/ruinagents>
    # TODO: Pin to tagged version once v5 stabilizes
    ruinagents.url = "git+ssh://git@forge.meskill.farm/RUiNAGE/RUiNAGENTS.git";
    ruinagents.inputs.nixpkgs.follows = "nixpkgs";

    # N0P - Op management CLI for isolated development sessions
    # <https://forge.meskill.farm/RUiNAGE/n0p>
    # TODO: Pin to tagged version once v0.1.0 is released
    n0p.url = "git+ssh://git@forge.meskill.farm/RUiNAGE/N0P.git";
    n0p.inputs.nixpkgs.follows = "nixpkgs";

    # n0h - Host management CLI
    # <https://forge.meskill.farm/RUiNAGE/N0H>
    # TODO: Pin to tagged version once v0.1.0 is released
    n0h.url = "git+ssh://git@forge.meskill.farm/RUiNAGE/N0H.git";
    n0h.inputs.nixpkgs.follows = "nixpkgs";

    # n0s - Session management CLI
    # <https://forge.meskill.farm/RUiNAGE/N0S>
    # TODO: Pin to tagged version once v0.1.0 is released
    n0s.url = "git+ssh://git@forge.meskill.farm/RUiNAGE/N0S.git";
    n0s.inputs.nixpkgs.follows = "nixpkgs";

    # nix-openclaw - Openclaw personal AI assistant for Nix
    # <https://github.com/openclaw/nix-openclaw>
    nix-openclaw.url = "github:openclaw/nix-openclaw";
    nix-openclaw.inputs.nixpkgs.follows = "nixpkgs";

    # Nix User Repository
    # <https://nur.nix-community.org>
    # nur.url = "github:nix-community/NUR";
  };

  # Load the blueprint
  # outputs = inputs: inputs.blueprint {inherit inputs;};
  outputs = inputs: let
    # Custom library functions for this flake
    ruinousLib = import ./lib {inherit inputs;};

    blueprintOutputs = inputs.blueprint {
      inherit inputs;
      nixpkgs.config.allowUnfree = true;
    };

    # Raspberry Pi hosts (auto-discovered from hosts/ directory)
    # Pi hosts are identified by pi5-configuration.nix or pi4-configuration.nix files
    # See lib/pi.nix for implementation details
    piHosts = ruinousLib.pi.discoverPiHosts {
      hostsDir = ./hosts;
      inherit blueprintOutputs;
    };
  in
    blueprintOutputs
    // {
      # Expose shared modules (cross-platform) from blueprint
      # Blueprint auto-discovers modules/shared/ and creates modules.shared
      sharedModules = blueprintOutputs.modules.shared or {};

      # Merge Pi hosts with blueprint nixosConfigurations
      nixosConfigurations = blueprintOutputs.nixosConfigurations // piHosts;

      # add hashes for cachenix
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
      # Note: darwinConfigurations are merged into nixosConfigurations because
      # agenix-rekey doesn't have a dedicated darwinConfigurations parameter,
      # but darwin configs have the same home-manager structure for secret discovery.
      agenix-rekey = inputs.agenix-rekey.configure {
        userFlake = inputs.self;
        nixosConfigurations =
          blueprintOutputs.nixosConfigurations
          // piHosts
          // (blueprintOutputs.darwinConfigurations or {});
        homeConfigurations = blueprintOutputs.homeConfigurations or {};
      };

      checks = {
        ruinage-tests = let
          pkgs = import inputs.nixpkgs {system = "x86_64-linux";};
        in
          import ./tests/ruinage.test.nix {
            inherit (pkgs) lib pkgs;
          };

        # opencode-module-test = import ./tests/opencode.test.nix {
        #   inherit (blueprintOutputs.legacyPackages.x86_64-linux) lib pkgs;
        #   home-manager-lib = inputs.home-manager.lib;
        # };
      };
    };
}
