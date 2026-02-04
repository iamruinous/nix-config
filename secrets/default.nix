{
  flake,
  config,
  lib,
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
    # For home-manager, use XDG state directory since config.home.uid
    # can be null in standalone home-manager mode
    secretsDir =
      if builtins.hasAttr "home" config
      then "${config.home.homeDirectory}/.local/state/agenix"
      else "/run/agenix";

    # https://github.com/oddlama/agenix-rekey
    rekey = let
      # Hostname resolution priority:
      # 1. hostName from _module.args (set by our flake.nix override for standalone home-manager)
      # 2. config.networking.hostName (available when run via nixos-rebuild)
      # 3. "standalone" fallback for standalone home-manager without hostName arg
      moduleHostName = config._module.args.hostName or null;
      networkingHostName = config.networking.hostName or "unknown";
      rawHostName =
        if moduleHostName != null
        then moduleHostName
        else networkingHostName;
      resolvedHostName =
        if rawHostName == "unknown" || rawHostName == null
        then "standalone"
        else rawHostName;
      username = config.home.username or "";
      target =
        if builtins.hasAttr "home" config
        then "home/${resolvedHostName}-${username}"
        else "nixos/${resolvedHostName}";
    in {
      # Master identities for agenix-rekey operations (static /tmp paths)
      # agenix-rekey evaluates ALL hosts, so we use /tmp symlinks created by agenix-helper
      # Run `agenix-helper unlock` before rekeying operations
      # Includes both host identity (secrets/id_age.age) and user identity (users/$USER/id_age.age)
      masterIdentities = ["/tmp/host_id_age" "/tmp/host_id_age_" "/tmp/user_id_age"];

      # Public ssh host key derived from 32-byte hex
      # > nixos generate
      hostPubkey = let
        inherit (builtins) pathExists readFile;
        sshPub = flake + /hosts/${resolvedHostName}/ssh_host_ed25519_key.pub;
        agePub = flake + /users/${username}/id_age.pub;
      in
        if pathExists agePub
        then readFile agePub
        else if pathExists sshPub
        then readFile sshPub
        else readFile (flake + /secrets/id_age.pub);

      storageMode = "local";
      # Rekeyed secrets (host-key encrypted) - hash-prefixed files
      localStorageDir = flake + /secrets/${target};
      # Generated secrets (master-key encrypted) - source files from generators
      # MUST be different from localStorageDir to avoid orphan cleanup conflicts
      generatedSecretsDir = flake + /secrets/generated/${target};
    };
  };
}
