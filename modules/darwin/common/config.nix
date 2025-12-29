{
  lib,
  pkgs,
  flake,
  ...
}: {
  imports = [
    # Import shared cross-platform modules
    flake.sharedModules.universal
    flake.sharedModules.console
  ];

  nix.package = pkgs.nix;

  # disable for Determinate Nix
  nix.enable = false;

  nix.settings.trusted-users = ["root" "@admin" "jmeskill"];
  nix.settings.experimental-features = ["external-builders"];
  nix.settings.external-builders = [
    {
      "systems" = ["aarch64-linux" "x86_64-linux"];
      "program" = "/usr/local/bin/determinate-nixd";
      "args" = ["builder"];
    }
  ];

  # Add ability to use TouchID for sudo
  security.pam.services.sudo_local.touchIdAuth = lib.mkDefault true;

  # default system packages
  environment.systemPackages = with pkgs; [
    jankyborders
    pinentry-1password
  ];
}
