{
  flake,
  config,
  ...
}: {
  # https://github.com/ryantm/agenix
  age = {
    # List of recipient keys (age or ssh) used to decrypt secrets
    identityPaths =
      if builtins.hasAttr "home" config
      then ["${config.home.homeDirectory}/.config/age/user_id_age"]
      else ["/etc/ssh/ssh_host_ed25519_key"];

    # Directory where secrets are symlinked to by default
    secretsDir =
      if builtins.hasAttr "home" config
      then "/run/user/${toString config.home.uid}/agenix"
      else "/run/agenix";

    # https://github.com/oddlama/agenix-rekey
    rekey = let
      inherit (config.networking) hostName;
      username = config.home.username or "";
      target =
        if builtins.hasAttr "home" config
        then "home/${hostName}-${username}"
        else "nixos/${hostName}";
    in {
      # Master identities for agenix-rekey operations (always in /tmp for consistent rekey)
      # Run `agenix-helper unlock` before rekeying operations
      # The agenix-helper creates symlinks: /tmp/host_id_age -> ~/.local/state/agenix-helper/host_id_age
      masterIdentities = ["/tmp/host_id_age" "/tmp/host_id_age_"];

      # Public ssh host key derived from 32-byte hex
      # > nixos generate
      hostPubkey = let
        inherit (builtins) pathExists readFile;
        sshPub = flake + /hosts/${hostName}/ssh_host_ed25519_key.pub;
        agePub = flake + /users/${username}/id_age.pub;
      in
        if pathExists agePub
        then readFile agePub
        else if pathExists sshPub
        then readFile sshPub
        else readFile (flake + /secrets/id_age.pub);

      storageMode = "local";
      localStorageDir = flake + /secrets/${target};
      generatedSecretsDir = flake + /secrets/${target};
    };
  };
}
