{
  lib,
  osConfig,
  config,
  ...
}: {
  options = {
    home.uid = lib.mkOption {
      type = with lib.types; nullOr int;
      default = osConfig.users.users.${config.home.username}.uid or null;
      description = ''
        Lookup uid from flake.users.<name>.uid and assign to config.home.uid
      '';
    };
  };
}
