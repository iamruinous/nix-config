{
  flake,
  inputs,
  ...
}: let
  # Module args with lib included
  inherit (inputs.nixpkgs) lib;
  args = {inherit flake inputs lib;};
in rec {
  # List directories and files that can be imported by nix
  ls = import ./ls.nix args;
  users = import ./users.nix args;
  genAttrs = import ./genAttrs.nix args;

  # Extract URL from cache public key
  cacheUrl = index: pubKey: let
    name = lib.pipe pubKey [
      (x: lib.split ":" x)
      (x: builtins.elemAt x 0)
      (x: lib.split "-" x)
      (x: lib.flatten x)
      (x: lib.take (builtins.length x - 1) x)
      (x: lib.concatStringsSep "-" x)
    ];
  in "https://${name}?priority=${toString index}";
}
