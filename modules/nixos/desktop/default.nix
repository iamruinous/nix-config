{lib, ...}: let
  # Only import .nix files directly in this directory, NOT subdirectories
  # Desktop environment subdirectories (kde/, gnome/, hyprland/, etc.) are
  # imported explicitly by hosts to avoid conflicts between DEs
  entries = builtins.readDir ./.;
  nixFiles = lib.filterAttrs (name: type:
    type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
  ) entries;
in {
  imports = map (name: ./. + "/${name}") (builtins.attrNames nixFiles);
}
