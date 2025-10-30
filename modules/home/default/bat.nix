{lib, ...}: {
  # Install bat via home-manager module
  programs.bat = {
    enable = lib.mkDefault true;
  };
}
