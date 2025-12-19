{
  config,
  pkgs,
  lib,
  ...
}: let
  # Path to users directory
  usersDir = ../../../users;

  # User names with home-manager config
  userNames = builtins.attrNames (config.home-manager.users or {});

  # Check if a user has a password.age file
  hasPasswordFile = name: builtins.pathExists (usersDir + "/${name}/password.age");

  # Get all user names (including root) that have password.age files
  allUserNames = userNames ++ ["root"];
  usersWithPasswords = builtins.filter hasPasswordFile allUserNames;

  # Filter list of groups to only those which exist
  ifTheyExist = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;

  # Import and normalize a user config from users/<name>/default.nix
  mkUser = name: let
    userPath = usersDir + "/${name}";
    raw = import (userPath + "/default.nix");
    hasPassword = hasPasswordFile name;
  in
    raw
    // {
      inherit name;
      isNormalUser = !(raw.isSystemUser or false);
      extraGroups = (raw.extraGroups or []) ++ ifTheyExist ["media" "photos" "dialout"];
      openssh = {
        authorizedKeys = raw.openssh.authorizedKeys or {};
        authorizedPrincipals = raw.openssh.authorizedPrincipals or [];
      };
      hashedPasswordFile =
        if hasPassword
        then "/run/user/${name}"
        else null;
    };

  # Root account (if users/root exists)
  mkRoot = let
    rootPath = usersDir + "/root";
    hasRoot = builtins.pathExists (rootPath + "/default.nix");
    raw =
      if hasRoot
      then import (rootPath + "/default.nix")
      else {};
    hasPassword = hasPasswordFile "root";
  in {
    root =
      raw
      // {
        openssh = {
          authorizedKeys = raw.openssh.authorizedKeys or {};
          authorizedPrincipals = raw.openssh.authorizedPrincipals or [];
        };
        hashedPasswordFile =
          if hasPassword
          then "/run/user/root"
          else null;
      };
  };
in {
  users.users = lib.genAttrs userNames mkUser // mkRoot;

  # Disallow modifying users outside of this config
  users.mutableUsers = false;
  users.defaultUserShell = pkgs.fish;

  # Define age secrets for each user's password.age file
  age.secrets =
    lib.genAttrs
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
