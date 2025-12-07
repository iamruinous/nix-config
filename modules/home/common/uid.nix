{
  osConfig,
  config,
  ...
}: {
  home.uid = osConfig.users.users.${config.home.username}.uid;
}
