{lib, ...}: let
  usersDir = ../users;
  # Get subdirectory names (excluding hidden dirs)
  userDirs = builtins.attrNames (
    lib.filterAttrs (n: v: v == "directory" && !lib.hasPrefix "." n)
      (builtins.readDir usersDir)
  );
in
  lib.genAttrs userDirs (
    dir: let
      user = import (usersDir + "/${dir}");
      isRoot = dir == "root";

      # Common openssh handling for all users
      openssh = {
        authorizedKeys = user.openssh.authorizedKeys or {};
        authorizedPrincipals = user.openssh.authorizedPrincipals or [];
      };
    in
      user
      // {inherit openssh;}
      // (
        if isRoot
        then {
          name = "root";
          uid = 0;
          description = "System administrator";
          isSystemUser = true;
          isNormalUser = false;
          linger = false;
        }
        else rec {
          name = user.name or dir;
          uid = user.uid or null;
          description = user.description or name;
          isSystemUser = user.isSystemUser or false;
          isNormalUser = !isSystemUser;
          useDefaultShell = user.useDefaultShell or true;
          linger = user.linger or true;
        }
      )
  )
