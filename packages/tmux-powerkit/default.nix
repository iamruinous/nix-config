{pkgs, ...}: let
  # Platform-specific dependencies
  # procps (ps, free, top) is Linux-only; Darwin has these in system
  linuxDeps = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    pkgs.procps   # for ps, top, free on Linux
    pkgs.hostname # hostname on Linux
  ];

  darwinDeps = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    # Darwin has ps/top in system, but we need to ensure /usr/bin is in PATH
    # for system commands like sw_vers, system_profiler, etc.
  ];

  runtimeDeps = [
    pkgs.bash
    pkgs.coreutils
    pkgs.findutils
    pkgs.gawk
    pkgs.gnugrep
    pkgs.gnused
    pkgs.jq
    pkgs.bc
    pkgs.tmux
  ] ++ linuxDeps ++ darwinDeps;

  # On Darwin, include /usr/bin for system commands (ps, top, sw_vers, etc.)
  darwinSystemPath = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ":/usr/bin:/bin";
  runtimePath = (pkgs.lib.makeBinPath runtimeDeps) + darwinSystemPath;
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
      # Fix shebangs in all scripts to use Nix bash
      for script in $(find $out/share/tmux-plugins/tmux-powerkit -name "*.sh" -o -name "*.tmux"); do
        if [ -f "$script" ]; then
          sed -i 's|#!/usr/bin/env bash|#!${pkgs.bash}/bin/bash|g' "$script"
          sed -i 's|#!/bin/bash|#!${pkgs.bash}/bin/bash|g' "$script"
        fi
      done

      # Only wrap the entry points - NOT every sourced script
      # The wrapper sets PATH once, and sourced scripts inherit it
      wrapProgram $out/share/tmux-plugins/tmux-powerkit/tmux-powerkit.tmux \
        --set PATH ${runtimePath}

      # Wrap bin scripts (these are called directly by tmux)
      for script in $out/share/tmux-plugins/tmux-powerkit/bin/*; do
        if [ -f "$script" ] && [ -x "$script" ] && [[ ! "$script" =~ -wrapped$ ]]; then
          wrapProgram "$script" \
            --set PATH ${runtimePath}
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
