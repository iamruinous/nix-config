# SSH Host Management Module
# Generates programs.ssh.matchBlocks from ruinous.ssh.hosts definitions
# Options defined in options.nix
{
  config,
  lib,
  ...
}: let
  cfg = config.ruinous.ssh;

  # Parse "user@hostname" string into {user, hostname}
  parseHostString = str: let
    parts = lib.splitString "@" str;
  in {
    user = builtins.elemAt parts 0;
    hostname = builtins.elemAt parts 1;
  };

  # Generate matchBlock from host config
  mkMatchBlock = name: hostCfg: let
    parsed = parseHostString hostCfg.host;
    aliasString =
      if hostCfg.aliases != []
      then "${name} ${lib.concatStringsSep " " hostCfg.aliases}"
      else name;
  in {
    "${aliasString}" =
      {
        hostname = parsed.hostname;
        user = parsed.user;
      }
      // lib.optionalAttrs (hostCfg.forwardAgent != null) {
        forwardAgent = hostCfg.forwardAgent;
      }
      // lib.optionalAttrs (hostCfg.addKeysToAgent != null) {
        addKeysToAgent = hostCfg.addKeysToAgent;
      }
      // lib.optionalAttrs (hostCfg.extraOptions != {}) {
        extraOptions = hostCfg.extraOptions;
      };
  };

  # Combine all host definitions into matchBlocks
  allMatchBlocks =
    lib.foldlAttrs
    (acc: name: hostCfg: acc // (mkMatchBlock name hostCfg))
    {}
    cfg.hosts;
in {
  config = lib.mkIf (cfg.hosts != {}) {
    programs.ssh.matchBlocks = allMatchBlocks;
  };
}
