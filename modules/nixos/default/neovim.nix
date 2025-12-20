{
  lib,
  pkgs,
  ...
}: {
  # Neovim text editor configuration
  programs.neovim = {
    enable = lib.mkDefault true;
    package = pkgs.neovim-unwrapped;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
