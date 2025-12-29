# Raspberry Pi host discovery and configuration helpers
#
# This module provides functions to auto-discover and build Raspberry Pi hosts
# using the nixos-raspberrypi flake for proper kernel and bootloader support.
#
# Pi hosts are identified by the presence of:
#   - pi5-configuration.nix for Raspberry Pi 5 hosts
#   - pi4-configuration.nix for Raspberry Pi 4 hosts
#
# Each Pi configuration should explicitly import the modules it needs:
#   imports = [
#     flake.nixosModules.default
#     flake.nixosModules.server
#     flake.nixosModules.pi
#     ./hardware-configuration.nix
#   ];
{inputs}: let
  # Discover home-manager users from host directory
  # Returns an attrset of user configs with proper defaults
  discoverUsers = {
    hostDir,
    specialArgs,
  }: let
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

  # Create home-manager configuration module for a Pi host
  mkHomeManagerConfig = {
    hostDir,
    specialArgs,
  }: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = specialArgs;
      users = discoverUsers {inherit hostDir specialArgs;};
    };
  };

  # Create common specialArgs for Pi hosts
  mkPiSpecialArgs = {blueprintOutputs}: {
    inherit inputs;
    flake = inputs.self;
    nixos-raspberrypi = inputs.nixos-raspberrypi;
    perSystem = {
      self = blueprintOutputs.packages.aarch64-linux;
    };
  };

  # Build a Pi 5 host configuration
  mkPi5Host = {
    hostDir,
    blueprintOutputs,
  }: let
    specialArgs = mkPiSpecialArgs {inherit blueprintOutputs;};
  in
    inputs.nixos-raspberrypi.lib.nixosSystem {
      inherit specialArgs;
      modules = [
        inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
        inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
        inputs.nixos-raspberrypi.nixosModules.sd-image
        inputs.home-manager.nixosModules.home-manager
        (hostDir + "/pi5-configuration.nix")
        (mkHomeManagerConfig {inherit hostDir specialArgs;})
      ];
    };

  # Build a Pi 4 host configuration
  mkPi4Host = {
    hostDir,
    blueprintOutputs,
  }: let
    specialArgs = mkPiSpecialArgs {inherit blueprintOutputs;};
  in
    inputs.nixos-raspberrypi.lib.nixosSystem {
      inherit specialArgs;
      modules = [
        inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.base
        inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.display-vc4
        inputs.nixos-raspberrypi.nixosModules.sd-image
        inputs.home-manager.nixosModules.home-manager
        (hostDir + "/pi4-configuration.nix")
        (mkHomeManagerConfig {inherit hostDir specialArgs;})
      ];
    };

  # Scan a directory for Pi host configurations
  # Returns list of {name, model, hostDir} for each discovered Pi host
  scanForPiHosts = hostsDir: let
    hostDirs = builtins.attrNames (builtins.readDir hostsDir);

    # Check if a host directory contains a Pi configuration
    checkHost = hostname: let
      hostDir = hostsDir + "/${hostname}";
      hasPi5Config = builtins.pathExists (hostDir + "/pi5-configuration.nix");
      hasPi4Config = builtins.pathExists (hostDir + "/pi4-configuration.nix");
    in
      if hasPi5Config
      then {
        name = hostname;
        model = "pi5";
        inherit hostDir;
      }
      else if hasPi4Config
      then {
        name = hostname;
        model = "pi4";
        inherit hostDir;
      }
      else null;

    # Filter out non-Pi hosts
    piHostInfos = builtins.filter (x: x != null) (map checkHost hostDirs);
  in
    piHostInfos;
in {
  # Discover and build all Pi hosts from a hosts directory
  #
  # Usage:
  #   piHosts = ruinousLib.pi.discoverPiHosts {
  #     hostsDir = ./hosts;
  #     inherit blueprintOutputs;
  #   };
  #
  # Returns an attrset of hostname -> nixosConfiguration
  discoverPiHosts = {
    hostsDir,
    blueprintOutputs,
  }: let
    piHostInfos = scanForPiHosts hostsDir;

    # Build a Pi host based on its model
    buildPiHost = info:
      if info.model == "pi5"
      then mkPi5Host {inherit blueprintOutputs; hostDir = info.hostDir;}
      else mkPi4Host {inherit blueprintOutputs; hostDir = info.hostDir;};
  in
    builtins.listToAttrs (map (info: {
        name = info.name;
        value = buildPiHost info;
      })
      piHostInfos);

  # Export individual builders for advanced use cases
  inherit mkPi4Host mkPi5Host mkPiSpecialArgs discoverUsers mkHomeManagerConfig;
}
