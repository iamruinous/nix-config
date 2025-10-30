# services.xserver.enable = true;
{pkgs, ...}: {
  # Enable the X11 windowing system.
  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
    excludePackages = with pkgs; [xterm];
  };
}
