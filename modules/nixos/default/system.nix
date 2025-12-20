{
  pkgs,
  flake,
  lib,
  ...
}: {
  imports = [
    flake.nixosModules.common
  ];

  # set default, agenix-rekey freaks out without this
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Set your time zone.
  time.timeZone = lib.mkDefault "America/Phoenix";
  # time.hardwareClockInLocalTime = true;

  # PATH configuration
  environment.localBinInPath = true;

  # Additional services
  services.locate.enable = true;

  # Networking
  networking.networkmanager.enable = lib.mkDefault true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = lib.mkDefault false;

  environment.systemPackages = with pkgs; [
    btop
    pciutils
    usbutils
    isd
  ];
}
