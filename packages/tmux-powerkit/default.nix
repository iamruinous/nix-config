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

  # On Darwin, include /usr/bin, /usr/sbin, /bin, /sbin for system commands
  # (ps, top, sw_vers, sysctl, etc.)
  darwinSystemPath = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ":/usr/bin:/usr/sbin:/bin:/sbin";
  runtimePath = (pkgs.lib.makeBinPath runtimeDeps) + darwinSystemPath;
in
  pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-powerkit";
    version = "unstable-2026-01-11";

    src = pkgs.fetchFromGitHub {
      owner = "fabioluciano";
      repo = "tmux-powerkit";
      rev = "200ba5846ebf43b93bb8abc4de4b4d13f70b6825"; # main branch as of 2026-01-11
      sha256 = "sha256-R7FpIoaqvqE3ATSaq7yT2ZnME+KJPJ8IrpGNGV9cmNM=";
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

      # Create symlink for mkTmuxPlugin convention (converts hyphens to underscores)
      ln -sf tmux-powerkit.tmux $out/share/tmux-plugins/tmux-powerkit/tmux_powerkit.tmux

      # Wrap bin scripts (these are called directly by tmux)
      for script in $out/share/tmux-plugins/tmux-powerkit/bin/*; do
        if [ -f "$script" ] && [ -x "$script" ] && [[ ! "$script" =~ -wrapped$ ]]; then
          wrapProgram "$script" \
            --set PATH ${runtimePath}
        fi
      done

      # Add N0FRILLS custom themes
      # https://forge.meskill.farm/RUiNAGE/N0FRILLS
      mkdir -p $out/share/tmux-plugins/tmux-powerkit/src/themes/n0frills
      
      cat > $out/share/tmux-plugins/tmux-powerkit/src/themes/n0frills/ruin.sh << 'EOF'
#!${pkgs.bash}/bin/bash
# RUiN - Warm magenta primary with cyan highlight (default)
declare -gA THEME_COLORS=(
    [background]="#1c1c1c"
    [statusbar-bg]="#1c1c1c"
    [statusbar-fg]="#eeeeee"
    [session-bg]="#d75fd7"
    [session-fg]="#1c1c1c"
    [session-prefix-bg]="#ff5faf"
    [session-copy-bg]="#ffafd7"
    [session-search-bg]="#d75fd7"
    [session-command-bg]="#ff5faf"
    [window-active-base]="#d75fd7"
    [window-active-style]="bold"
    [window-inactive-base]="#4e4e4e"
    [window-inactive-style]="none"
    [window-activity-base]="#5fd7d7"
    [window-activity-style]="italics"
    [window-bell-base]="#ff5faf"
    [window-bell-style]="bold"
    [window-zoomed-bg]="#ffafd7"
    [pane-border-active]="#d75fd7"
    [pane-border-inactive]="#4e4e4e"
    [ok-base]="#626262"
    [good-base]="#d75fd7"
    [info-base]="#ffafd7"
    [warning-base]="#ff5faf"
    [error-base]="#ff5faf"
    [disabled-base]="#4e4e4e"
    [message-bg]="#1c1c1c"
    [message-fg]="#eeeeee"
    [popup-bg]="#1c1c1c"
    [popup-fg]="#eeeeee"
    [popup-border]="#d75fd7"
    [menu-bg]="#1c1c1c"
    [menu-fg]="#eeeeee"
    [menu-selected-bg]="#d75fd7"
    [menu-selected-fg]="#1c1c1c"
    [menu-border]="#d75fd7"
)
EOF

      cat > $out/share/tmux-plugins/tmux-powerkit/src/themes/n0frills/siege.sh << 'EOF'
#!${pkgs.bash}/bin/bash
# SIEGE - Cool violet primary with teal highlight
declare -gA THEME_COLORS=(
    [background]="#1c1c1c"
    [statusbar-bg]="#1c1c1c"
    [statusbar-fg]="#eeeeee"
    [session-bg]="#875fd7"
    [session-fg]="#1c1c1c"
    [session-prefix-bg]="#5f5fff"
    [session-copy-bg]="#af87ff"
    [session-search-bg]="#875fd7"
    [session-command-bg]="#5f5fff"
    [window-active-base]="#875fd7"
    [window-active-style]="bold"
    [window-inactive-base]="#4e4e4e"
    [window-inactive-style]="none"
    [window-activity-base]="#00afaf"
    [window-activity-style]="italics"
    [window-bell-base]="#5f5fff"
    [window-bell-style]="bold"
    [window-zoomed-bg]="#af87ff"
    [pane-border-active]="#875fd7"
    [pane-border-inactive]="#4e4e4e"
    [ok-base]="#626262"
    [good-base]="#875fd7"
    [info-base]="#af87ff"
    [warning-base]="#5f5fff"
    [error-base]="#5f5fff"
    [disabled-base]="#4e4e4e"
    [message-bg]="#1c1c1c"
    [message-fg]="#eeeeee"
    [popup-bg]="#1c1c1c"
    [popup-fg]="#eeeeee"
    [popup-border]="#875fd7"
    [menu-bg]="#1c1c1c"
    [menu-fg]="#eeeeee"
    [menu-selected-bg]="#875fd7"
    [menu-selected-fg]="#1c1c1c"
    [menu-border]="#875fd7"
)
EOF

      cat > $out/share/tmux-plugins/tmux-powerkit/src/themes/n0frills/ghost.sh << 'EOF'
#!${pkgs.bash}/bin/bash
# GHOST - Monochrome with amber highlight
declare -gA THEME_COLORS=(
    [background]="#1c1c1c"
    [statusbar-bg]="#1c1c1c"
    [statusbar-fg]="#eeeeee"
    [session-bg]="#eeeeee"
    [session-fg]="#1c1c1c"
    [session-prefix-bg]="#bcbcbc"
    [session-copy-bg]="#bcbcbc"
    [session-search-bg]="#eeeeee"
    [session-command-bg]="#bcbcbc"
    [window-active-base]="#eeeeee"
    [window-active-style]="bold"
    [window-inactive-base]="#4e4e4e"
    [window-inactive-style]="none"
    [window-activity-base]="#ffaf00"
    [window-activity-style]="italics"
    [window-bell-base]="#eeeeee"
    [window-bell-style]="bold"
    [window-zoomed-bg]="#bcbcbc"
    [pane-border-active]="#eeeeee"
    [pane-border-inactive]="#4e4e4e"
    [ok-base]="#626262"
    [good-base]="#eeeeee"
    [info-base]="#bcbcbc"
    [warning-base]="#8a8a8a"
    [error-base]="#8a8a8a"
    [disabled-base]="#4e4e4e"
    [message-bg]="#1c1c1c"
    [message-fg]="#eeeeee"
    [popup-bg]="#1c1c1c"
    [popup-fg]="#eeeeee"
    [popup-border]="#eeeeee"
    [menu-bg]="#1c1c1c"
    [menu-fg]="#eeeeee"
    [menu-selected-bg]="#eeeeee"
    [menu-selected-fg]="#1c1c1c"
    [menu-border]="#eeeeee"
)
EOF
    '';

  meta = {
    description = "The Ultimate tmux Status Bar Framework - 42 plugins, 32 themes";
    homepage = "https://github.com/fabioluciano/tmux-powerkit";
    license = pkgs.lib.licenses.mit;
    platforms = pkgs.lib.platforms.unix;
    maintainers = [];
  };
}
