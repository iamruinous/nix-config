# Common settings for desktops
{flake, ...}: {
  # include nixos.common by default
  imports = [
    flake.nixosModules.common
  ];
}
