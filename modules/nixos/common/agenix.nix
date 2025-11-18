{
  flake,
  pkgs,
  ...
}: {
  imports = [
    flake.inputs.agenix.nixosModules.default
    flake.inputs.agenix-rekey.nixosModules.default
    (flake + /secrets)
  ];

  nixpkgs.overlays = [flake.inputs.agenix-rekey.overlays.default];

  environment.systemPackages = with pkgs; [
    age
    agenix-rekey
    rage
  ];
}
