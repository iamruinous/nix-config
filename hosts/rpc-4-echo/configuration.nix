{...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "rpc-4-echo";

  system.stateVersion = "25.11";
}
