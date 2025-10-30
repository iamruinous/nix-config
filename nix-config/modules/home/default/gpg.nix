{lib, ...}: {
  # Install gpg via home-manager module
  programs.gpg = {
    enable = lib.mkDefault true;
  };
}
