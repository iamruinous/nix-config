{pkgs, ...}: let
  runtimeDeps = [
    pkgs.bash
    pkgs.coreutils
    pkgs.findutils
    pkgs.gawk
    pkgs.gnugrep
    pkgs.gnused
    pkgs.hostname
    pkgs.jq
    pkgs.bc
    pkgs.procps # for ps, top, free
    pkgs.tmux
  ];
  runtimePath = pkgs.lib.makeBinPath runtimeDeps;
in
  pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-powerkit";
    version = "unstable-2026-01-11";

    src = pkgs.fetchFromGitHub {
      owner = "fabioluciano";
      repo = "tmux-powerkit";
      rev = "a3bf1a951b297adab8d1e6225cff5987fe6bd5e8"; # main branch as of 2026-01-11
      sha256 = "0ip4xwcxk4fxw7r8mvymyay5wvszkvb9wacsrfa1r1fa9g37jkzp";
    };

    # Powerkit requires bash 5.0+, bc, jq, and other utilities
    nativeBuildInputs = [pkgs.makeWrapper];

    postInstall = ''
      # Patch all shell scripts to use proper shebang and have PATH set
      for script in $(find $out/share/tmux-plugins/tmux-powerkit -name "*.sh" -o -name "*.tmux"); do
        if [ -f "$script" ]; then
          # Replace /usr/bin/env bash with direct bash path
          sed -i 's|#!/usr/bin/env bash|#!${pkgs.bash}/bin/bash|g' "$script"
          # Add PATH export after shebang for sourced scripts
          if grep -q "^#!.*bash" "$script"; then
            sed -i '2i export PATH="${runtimePath}:$PATH"' "$script"
          fi
        fi
      done

      # Wrap the main entry point script
      wrapProgram $out/share/tmux-plugins/tmux-powerkit/tmux-powerkit.tmux \
        --prefix PATH : ${runtimePath}

      # Wrap bin scripts
      for script in $out/share/tmux-plugins/tmux-powerkit/bin/*; do
        if [ -f "$script" ] && [ -x "$script" ] && [[ ! "$script" =~ -wrapped$ ]]; then
          wrapProgram "$script" \
            --prefix PATH : ${runtimePath}
        fi
      done
    '';

  meta = {
    description = "The Ultimate tmux Status Bar Framework - 42 plugins, 32 themes";
    homepage = "https://github.com/fabioluciano/tmux-powerkit";
    license = pkgs.lib.licenses.mit;
    platforms = pkgs.lib.platforms.unix;
    maintainers = [];
  };
}
