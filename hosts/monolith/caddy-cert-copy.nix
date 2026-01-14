{pkgs, ...}: {
  systemd.timers.caddy-cert-copy = {
    description = "Copy Caddy certs to Mosquitto";
    wantedBy = ["timers.target"];
    timerConfig = {
      Unit = "caddy-cert-copy.service";
      OnCalendar = "*-*-* 02:00:00";
      Persistent = true;
    };
  };

  systemd.services.caddy-cert-copy = {
    description = "Copy Caddy certs to Mosquitto and restart";
    path = with pkgs; [coreutils bash docker];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "caddy-cert-copy" ''
        set -euo pipefail

        SRC="/data/docker/caddy/data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mqtt.meskill.farm"
        DEST="/data/docker/mosquitto/config/cert"

        # Verify source exists
        if [[ ! -d "$SRC" ]]; then
          echo "ERROR: Source directory $SRC does not exist"
          exit 1
        fi

        # Copy certs preserving attributes
        cp -rfp "$SRC"/* "$DEST"/

        # Set ownership and permissions
        chown -R 1883:1883 "$DEST"
        chmod 700 "$DEST"
        chmod 600 "$DEST"/*

        # Restart mosquitto to pick up new certs
        docker restart mosquitto || true

        echo "Certificates copied and mosquitto restarted"
      '';
    };
  };
}
