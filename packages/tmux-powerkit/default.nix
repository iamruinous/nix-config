{
  lib,
  fetchFromGitHub,
  pkgs,
  bash,
  coreutils,
  gawk,
  gnused,
  jq,
  bc,
  playerctl,
  ...
}:
pkgs.tmuxPlugins.mkTmuxPlugin {
  pluginName = "powerkit";
  version = "unstable-2025-01-10";

  src = fetchFromGitHub {
    owner = "fabioluciano";
    repo = "tmux-powerkit";
    rev = "c1aa0a3c94ef2f1ac8ba4e5def8e23ef1c5ac47c"; # main branch as of 2025-01-10
    sha256 = "sha256-3OzO3pQ/8kK/J+2c+h2LF/5LH/3T7UMPTqUwn63IZxo=";
  };

  # Powerkit requires bash 5.0+, bc, jq, and other utilities
  nativeBuildInputs = [pkgs.makeWrapper];

  postInstall = ''
    # Wrap the main script to ensure required utilities are in PATH
    wrapProgram $out/share/tmux-plugins/powerkit/tmux-powerkit.tmux \
      --prefix PATH : ${lib.makeBinPath [
      bash
      coreutils
      gawk
      gnused
      jq
      bc
    ]}

    # Also wrap bin scripts
    for script in $out/share/tmux-plugins/powerkit/bin/*; do
      if [ -f "$script" ] && [ -x "$script" ]; then
        wrapProgram "$script" \
          --prefix PATH : ${lib.makeBinPath [
      bash
      coreutils
      gawk
      gnused
      jq
      bc
    ]}
      fi
    done
  '';

  meta = {
    description = "The Ultimate tmux Status Bar Framework - 42 plugins, 32 themes";
    homepage = "https://github.com/fabioluciano/tmux-powerkit";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    maintainers = [];
  };
}
