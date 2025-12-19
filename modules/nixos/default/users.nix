{
  config,
  flake,
  pkgs,
  lib,
  ...
}: let
  # User names with home-manager config
  userNames = builtins.attrNames (config.home-manager.users or {});

  # Path to users directory in the flake
  usersDir = ../../../users;

  # Check if a user has a password.age file
  hasPasswordFile = name: builtins.pathExists (usersDir + "/${name}/password.age");

  # Get all user names (including root) that have password.age files
  allUserNames = userNames ++ ["root"];
  usersWithPasswords = builtins.filter hasPasswordFile allUserNames;
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
          if hasPasswordFile name
          then "/run/user/${u.name}"
          else null;
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
            if hasPasswordFile "root"
            then "/run/user/${u.name}"
            else null;
        };
    };
  in
    userAccounts // rootAccount;

  # Disallow modifying users outside of this config
  users.mutableUsers = false;
  users.defaultUserShell = pkgs.fish;

  # Define age secrets for each user's password.age file
  age.secrets = lib.genAttrs
    (map (name: "user_password_${name}") usersWithPasswords)
    (secretName: let
      # Extract username from secret name (remove "user_password_" prefix)
      userName = lib.removePrefix "user_password_" secretName;
    in {
      rekeyFile = usersDir + "/${userName}/password.age";
      mode = "600";
    });

  # Hook into agenixInstall to hash passwords immediately after secrets are decrypted
  # This runs as part of agenix's activation, ensuring passwords are available on boot
  system.activationScripts.agenixInstall.text = lib.mkIf (usersWithPasswords != []) (lib.mkAfter (let
    mkpasswd = "${pkgs.mkpasswd}/bin/mkpasswd";
    hashPassword = userName: ''
      # Create /run/user directory if it doesn't exist
      mkdir -p /run/user

      # Read plaintext password from agenix secret and hash it
      if [ -f "${config.age.secrets."user_password_${userName}".path}" ]; then
        ${mkpasswd} -m sha-512 "$(cat ${config.age.secrets."user_password_${userName}".path})" > /run/user/${userName}
        chmod 600 /run/user/${userName}
      fi
    '';
  in
    lib.concatMapStringsSep "\n" hashPassword usersWithPasswords));
}
