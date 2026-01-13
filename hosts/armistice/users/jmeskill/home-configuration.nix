{
  flake,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.default
  ];

  ruinous.rust-motd.enable = true;
  ruinous.loginHub.enable = true;

  # systemd.user.tmpfiles.rules = [
  #   "L+    /home/jmeskill/.local/bin/op-ssh-sign -    -    -     - ${pkgs.openssh}/bin/ssh-keygen"
  # ];

  home.stateVersion = "26.05";
}
