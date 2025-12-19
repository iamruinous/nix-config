# Extend nixpkgs' genAttrs to first convert provided paths or attrs to a list
{lib, ...}: x: fn: let
  # Ensure string and strip .nix suffix from any entries
  fromList = list: map (name: lib.removeSuffix ".nix" (toString name)) list;

  # List of subdirectory names in given path (excludes hidden dirs)
  fromPath = path: let
    contents = builtins.readDir path;
    dirs = lib.filterAttrs (n: v: v == "directory" && !lib.hasPrefix "." n) contents;
  in
    builtins.attrNames dirs;

  # List of attribute names in given attr set
  fromAttrs = attrs: fromList (builtins.attrNames attrs);

  inherit (builtins) isAttrs isPath isList;
  list =
    if isPath x
    then fromPath x
    else if isList x
    then fromList x
    else if isAttrs x
    then fromAttrs x
    else [];
in
  lib.genAttrs list fn
