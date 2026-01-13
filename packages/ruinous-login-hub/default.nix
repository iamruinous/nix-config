{pkgs, ...}:
pkgs.buildGoModule {
  pname = "ruinous-login-hub";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-lKSr05aeK+HBxJKIbBPSesYpokf6D2Yol8p4OHHjNQ8=";

  meta = with pkgs.lib; {
    description = "SSH login hub with TUI menu for tmux/tmuxp sessions";
    homepage = "https://github.com/iamruinous/nix-config";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.linux;
  };
}
