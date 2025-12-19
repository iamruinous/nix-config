{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  users = import ./users.nix {inherit lib;};
}
