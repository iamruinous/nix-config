{
  description = "NixOS on Lima";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable-small";
    nixos-lima.url = "github:ciderale/nixos-lima";
    nixos-lima.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixos-lima,
    nixpkgs,
    ...
  }: {
    nixosConfigurations = {
      builder-x86_64 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          nixos-lima.nixosModules.lima
          nixos-lima.nixosModules.disk-default
          nixos-lima.nixosModules.impure-config
          nixos-lima.nixosModules.lima-container
          ./lima-settings.nix
          ./configuration.nix
        ];
      };

      builder-aarch64 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          nixos-lima.nixosModules.lima
          nixos-lima.nixosModules.disk-default
          nixos-lima.nixosModules.impure-config
          nixos-lima.nixosModules.lima-container
          ./lima-settings.nix
          ./configuration.nix
        ];
      };
    };
    devShells = nixos-lima.devShells;
    packages = nixos-lima.packages;
  };
}
