{
  config,
  flake,
  pkgs,
  ...
}: let
  # User names with home-manager config
  userNames = builtins.attrNames (config.home-manager.users or {});
in {
  users.defaultUserShell = pkgs.fish;

  # Update users with details found in flake.users
  users.users.jmeskill = flake.lib.users.jmeskill;

  # users.users = lib.genAttrs userNames (name: let
  #   u = flake.lib.users."${name}";
  # in
  #   u.user);

  # let
  #   # Get a user by name from the flake
  #   flakeUser = name: rec {
  #     inherit name;
  #     user = flake.users."${name}" or {};
  #   };
  #
  #   # Each user account found in flake.users
  #   userAccounts = lib.genAttrs userNames (name: let
  #     u = flakeUser name;
  #   in
  #     u.user);
  # in
  #   userAccounts;
}
