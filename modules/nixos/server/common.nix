# Common settings for servers
{flake, ...}: {
  # include nixos.common by default
  imports = [
    flake.nixosModules.common
    flake.nixosModules.console
  ];
}
