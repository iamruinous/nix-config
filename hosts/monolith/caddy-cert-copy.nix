{pkgs, ...}: {
  systemd.timers.caddy-cert-copy = {
    description = "caddy cert copier timer";
    wantedBy = ["timers.target"]; # Ensures the timer starts with the system
    timerConfig = {
      Unit = "caddy-cert-copy.service"; # Links to the service defined above
      OnCalendar = "*-*-* 02:00:00"; # Example: run daily at midnight
      Persistent = true; # Ensures the timer runs even if the system was off during a scheduled run
    };
  };
  systemd.services.caddy-cert-copy = {
    description = "caddy cert copier";
    path = with pkgs; [
      coreutils
      bash
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c \"cp -rfp /data/docker/caddy/data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mqtt.meskill.farm/* /data/docker/mosquitto/config/cert; chown 1883:1883 /data/docker/mosquitto/config/cert/*\"";
    };
  };
}
