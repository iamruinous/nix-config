{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in rec {
  users = import ./users.nix {inherit lib;};

  # Extract URL from cache public key
  # e.g., "nix-community.cachix.org-1:..." -> "https://nix-community.cachix.org?priority=1"
  cacheUrl = index: pubKey: let
    beforeColon = builtins.head (lib.splitString ":" pubKey);
    parts = lib.splitString "-" beforeColon;
    name = lib.concatStringsSep "-" (lib.init parts);
  in "https://${name}?priority=${toString index}";
}
