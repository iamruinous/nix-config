{
  flake,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    flake.inputs.microvm.nixosModules.host
    flake.inputs.impermanence.nixosModules.impermanence
  ];

  # networking.firewall.allowedTCPPorts = [2222 2223];

  # microvm.autostart = ["messytty" "ruinous-tty"];
  microvm.vms = {
    # messytty.config = import ./microvms/messytty.nix {inherit inputs pkgs;};
    # ruinitty = {
    #   inherit flake;
    #   updateFlake = "git+file:///home/jmeskill/Projects/github/iamruinous/nix-config#ruinitty";
    # };
    ruinous-tty = {
      inherit flake;
      updateFlake = "git+file:///home/jmeskill/Projects/github/iamruinous/nix-config";
    };
  };
}
