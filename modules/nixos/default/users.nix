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

  # Include all user password.age files as an agenix secret as user-password
  age.secrets =
    lib.genAttrs
    (map (userName: "${userName}-password") (builtins.attrNames flake.users))
    (secretName: let
      userName = lib.removeSuffix "-password" secretName;
    in {
      rekeyFile = flake + /users/${userName}/password.age;
    });

    # Write SSH keys to each ~/.ssh directory
    users.text = let
      perUser = userName: let
        inherit (builtins) dirOf;
        inherit (usermeta userName) user publicId publicKey password;
        sshDir = "${user.home}/.ssh";
        ageDir = "${user.home}/.config/age";
      in
        # bash
        ''
          # Copy public age id from this repo to ~/.config/age
          install -o ${user.name} -g ${user.group} -m 700 -d ${dirOf ageDir} ${ageDir}
          cat ${publicId} >${ageDir}/id_age.pub

          # Generate private age id derived from 32-byte hex
          # Delete if derived id doesn't verify with repo's public id
          if [[ -f ${hex} ]]; then
            derive hex ${userName}<${hex} |
            derive age >${ageDir}/id_age
            agenix verify ${ageDir} || rm -f ${ageDir}/id_age
          fi

          # Ensure proper permissions and ownership
          [[ -f ${ageDir}/id_age ]] && chmod 600 ${ageDir}/id_age
          [[ -f ${ageDir}/id_age.pub ]] && chmod 644 ${ageDir}/id_age.pub
          chown -R ${user.name}:${user.group} ${ageDir}

          # Copy public ssh user key from this repo to ~/.ssh
          install -o ${user.name} -g ${user.group} -m 700 -d ${sshDir}
          cat ${publicKey} >${sshDir}/id_ed25519.pub

          # Generate private ssh user key derived from 32-byte hex
          # Delete if derived private key doesn't verify with repo's public key
          if [[ -f ${hex} ]]; then
            derive hex ${userName}<${hex} |
            derive ssh >${sshDir}/id_ed25519
            sshed verify ${sshDir} || rm -f ${sshDir}/id_ed25519
          fi

          # If matching private key successfully derived, do it again
          # encrypted with passphrase matching user password into ~/.ssh
          if [[ -f ${hex} && -f ${sshDir}/id_ed25519 ]]; then
            derive hex ${userName}<${hex} |
            derive ssh "$(cat ${password})" \
            >${sshDir}/id_ed25519
          fi

          # Ensure proper permissions and ownership
          [[ -f ${sshDir}/id_ed25519 ]] && chmod 600 ${sshDir}/id_ed25519
          [[ -f ${sshDir}/id_ed25519.pub ]] && chmod 644 ${sshDir}/id_ed25519.pub
          chown -R ${user.name}:${user.group} ${sshDir}
        '';

      text = concatMapStrings perUser everyone;
      path = [perSystem.self.agenix perSystem.self.derive perSystem.self.sshed];
    in
      mkAfter "${mkScript {inherit text path;}}";
  };
}
