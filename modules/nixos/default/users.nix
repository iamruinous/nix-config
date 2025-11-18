{
  config,
  flake,
  pkgs,
  lib,
  ...
}: let
  # User names with home-manager config
  userNames = builtins.attrNames (config.home-manager.users or {});
in {
  # Update users with details found in flake.users
  users.users = let
    # Filter list of groups to only those which exist
    ifTheyExist = groups:
      builtins.filter
      (group: builtins.hasAttr group config.users.groups)
      groups;

    # Get a user by name from the flake
    flakeUser = name: rec {
      inherit name;
      user = flake.users."${name}" or {};
      openssh = user.openssh or {};
      extraGroups = (user.extraGroups or []) ++ ifTheyExist ["media" "photos"];
    };

    # Each user account found in flake.users
    userAccounts = lib.genAttrs userNames (name: let
      u = flakeUser name;
    in
      u.user
      // {
        inherit (u) extraGroups openssh;
        hashedPasswordFile =
          if config.users.users."${u.name}".password == null
          then "/run/user/${u.name}"
          else null; # generated in activation script
      });

    # Special case for flake.users.root
    rootAccount = let
      u = flakeUser "root";
    in {
      "${u.name}" =
        u.user
        // {
          inherit (u) openssh;
          hashedPasswordFile =
            if config.users.users."${u.name}".password == null
            then "/run/user/${u.name}"
            else null; # generated in activation script
        };
    };
  in
    userAccounts // rootAccount;

  # Disallow modifying users outside of this config
  users.mutableUsers = false;
  users.defaultUserShell = pkgs.fish;
}
