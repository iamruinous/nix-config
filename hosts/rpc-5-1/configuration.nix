{...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "rpc-5-1";

  system.stateVersion = "25.11";
}
