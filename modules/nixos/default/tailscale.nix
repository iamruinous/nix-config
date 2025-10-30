{lib, ...}: {
  # Enable tailscale
  services.tailscale.enable = lib.mkDefault true;
}
