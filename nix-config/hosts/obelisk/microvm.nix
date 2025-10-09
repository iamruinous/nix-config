{
  flake,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    flake.inputs.microvm.nixosModules.host
  ];

  networking.firewall.allowedTCPPorts = [2222];
  # networking.macvlans.mv-eth0-host = {
  #   interface = "enp2s0";
  #   mode = "bridge";
  # };

  microvm.autostart = ["messytty"];
  microvm.vms = {
    messytty.config = import ./microvms/messytty.nix {inherit inputs pkgs;};
    # messytty = tracedAttrset.config;
  };
}
