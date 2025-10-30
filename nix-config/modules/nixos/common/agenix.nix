{
  flake,
  perSystem,
  ...
}: {
  imports = [
    flake.inputs.agenix.nixosModules.default
  ];

  environment.systemPackages = [
    perSystem.agenix.default
  ];
}
