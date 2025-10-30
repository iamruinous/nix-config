{pkgs, ...}: {
  xdg.configFile."borders/bordersrc".text = ''
    #!/bin/bash
    # vi: ft=bash

    options=(
    	style=round
    	width=6.0
    	hidpi=on
    	active_color=0xff813999
    	inactive_color=0xff19003f
    )

    ${pkgs.jankyborders}/bin/borders "''${options[@]}"
  '';
}
