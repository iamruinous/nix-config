{lib, ...}: {
  # direnv integration
  programs.direnv = {
    enable = lib.mkDefault true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
