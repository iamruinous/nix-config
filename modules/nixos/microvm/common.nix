{flake, ...}: {
  # microvm defaults
  imports = [
    flake.inputs.microvm.nixosModules.microvm
    flake.inputs.impermanence.nixosModules.impermanence

    flake.nixosModules.common
  ];
}
