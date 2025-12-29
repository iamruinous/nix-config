{
  lib,
  flake,
  ...
}: {
  imports =
    [
      # Import shared cross-platform modules
      flake.sharedModules.universal
      flake.sharedModules.console
    ]
    ++ builtins.filter
      (f: lib.hasSuffix ".nix" (toString f) && baseNameOf f != "default.nix")
      (lib.filesystem.listFilesRecursive ./.);
}
