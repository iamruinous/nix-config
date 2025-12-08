{
  osConfig,
  config,
  lib,
  ...
}: {
  home.uid = lib.mkDefault osConfig.users.users.${config.home.username}.uid;
}
