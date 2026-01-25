{lib, ...}: {
  imports =
    builtins.filter
    (f:
      lib.hasSuffix ".nix" (toString f)
      && baseNameOf f != "default.nix"
      # packages-overlay.nix is a function, not a module - exclude from auto-import
      && baseNameOf f != "packages-overlay.nix")
    (lib.filesystem.listFilesRecursive ./.);
}
