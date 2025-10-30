{
  config,
  lib,
  ...
}: let
  cfg = config.programs.ssh-interactive;
in {
  options.programs.ssh-interactive.enable = lib.options.mkEnableOption "ssh-interactive";

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
