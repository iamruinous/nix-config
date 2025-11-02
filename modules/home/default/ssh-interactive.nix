# ruinous.openssh.remote.forwarding = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.ruinous.openssh.remote.forwarding;
in {
  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enableDefaultConfig = lib.mkDefault false;
      matchBlocks = {
        "*" = {
          forwardAgent = true;
          addKeysToAgent = "yes";
        };
      };
      extraConfig = ''
        IgnoreUnknown AddKeysToAgent,UseKeychain
        StrictHostKeyChecking no
        UseKeychain yes
      '';
    };
  };
}
