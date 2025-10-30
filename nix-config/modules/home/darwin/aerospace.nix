{lib, ...}: {
  home.activation.aerospace = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo -e "\033[0;34mReloading aerospace config"
    echo -e "\033[0;34m=================="
    /opt/homebrew/bin/aerospace reload-config && echo "Success"
    echo -e "\033[0;34m=================="
  '';
}
