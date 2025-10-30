{pkgs, ...}: {
  config = {
    nixpkgs.hostPlatform = "aarch64-linux";

    environment = {
      systemPackages = [
        pkgs.ripgrep
        pkgs.fd
      ];
    };
  };
}
