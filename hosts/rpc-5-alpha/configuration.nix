{...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "rpc-5-alpha";

  system.stateVersion = "25.11";
}
