# Monolith Caddy configuration using docker-caddy module
#
# Routes migrated from Caddyfile.age
# See files/caddy/README.md for route documentation
{config, ...}: {
  services.docker-caddy = {
    enable = true;
    secretsFile = config.age.secrets.monolith_caddy_secrets.path;
    email = "admin@meskill.network";

    # Simple reverse proxy routes
    routes = {
      # Database admin UI
      "adminer.meskill.farm" = {
        upstream = "adminer:8080";
        description = "Database admin UI";
      };

      # Notification service
      "apprise.meskill.farm" = {
        upstream = "apprise:8000";
        description = "Notification service";
      };

      # Torrent automation
      "autobrr.meskill.farm" = {
        upstream = "autobrr:7474";
        description = "Torrent automation";
      };

      # Subtitle management
      "bazarr.meskill.farm" = {
        upstream = "bazarr:6767";
        description = "Subtitle management";
      };

      # Kavita book server
      "books.meskill.farm" = {
        upstream = "kavita:5000";
        description = "Kavita book server";
      };

      # Step CA certificate authority
      "ca.meskill.farm" = {
        upstream = "stepca:9000";
        description = "Step CA certificate authority";
      };

      # Calibre desktop
      "calibre-dt.meskill.farm" = {
        upstream = "calibre:8080";
        description = "Calibre desktop";
      };

      # Calibre automated
      "calibre.meskill.farm" = {
        upstream = "calibre-automated:8083";
        description = "Calibre automated";
      };

      # Calibre download (via VPN)
      "calibre-dl.meskill.farm" = {
        upstream = "gluetun:8085";
        description = "Calibre download (via VPN)";
      };

      # Change detection service
      "changes.meskill.farm" = {
        upstream = "changedetection:5000";
        description = "Change detection service";
      };

      # Deluge torrent (via VPN)
      "deluge.meskill.farm" = {
        upstream = "gluetun:8112";
        description = "Deluge torrent (via VPN)";
      };

      # ErsatzTV IPTV server
      "etv.meskill.farm" = {
        upstream = "ersatztv:8409";
        description = "ErsatzTV IPTV server";
      };

      # Frigate NVR
      "frigate.meskill.farm" = {
        upstream = "frigate:5000";
        description = "Frigate NVR";
      };

      # Forgejo git server
      "forge.meskill.farm" = {
        upstream = "forgejo:3000";
        description = "Forgejo git server";
      };

      # Glance dashboard
      "glance.meskill.farm" = {
        upstream = "glance:8080";
        description = "Glance dashboard";
      };

      # Grafana monitoring
      "grafana.meskill.farm" = {
        upstream = "grafana:3000";
        description = "Grafana monitoring";
      };

      # PDF generation service
      "gotenberg.meskill.farm" = {
        upstream = "gotenberg:3000";
        description = "PDF generation service";
      };

      # Kavita book server (alt)
      "kavita.meskill.farm" = {
        upstream = "kavita:5000";
        description = "Kavita book server";
      };

      # LDAP admin UI
      "ldap.meskill.farm" = {
        upstream = "phpldapadmin:80";
        description = "LDAP admin UI";
      };

      # Loki log aggregation
      "loki.meskill.farm" = {
        upstream = "loki:3100";
        description = "Loki log aggregation";
      };

      # MQTT Explorer
      "mqtt-explorer.meskill.farm" = {
        upstream = "mqtt-explorer:4000";
        description = "MQTT Explorer";
      };

      # NocoDB database UI
      "nocodb.meskill.farm" = {
        upstream = "nocodb:8080";
        description = "NocoDB database UI";
      };

      # n8n workflow automation
      "n8n.meskill.farm" = {
        upstream = "n8n:5678";
        description = "n8n workflow automation";
      };

      # Pinchflat media downloader
      "pinchflat.meskill.farm" = {
        upstream = "pinchflat:8945";
        description = "Pinchflat media downloader";
      };

      # TubeSync YouTube downloader
      "tubesync.meskill.farm" = {
        upstream = "tubesync:4848";
        description = "TubeSync YouTube downloader";
      };

      # Paperless-ngx documents
      "paperless.meskill.farm" = {
        upstream = "paperless-ngx:8000";
        description = "Paperless-ngx documents";
      };

      # Paperless AI assistant
      "paperless-ai.meskill.farm" = {
        upstream = "paperless-ai:3000";
        description = "Paperless AI assistant";
      };

      # Prometheus metrics
      "prometheus.meskill.farm" = {
        upstream = "prometheus:9090";
        description = "Prometheus metrics";
      };

      # Prowlarr indexer manager
      "prowlarr.meskill.farm" = {
        upstream = "prowlarr:9696";
        description = "Prowlarr indexer manager";
      };

      # Radarr movie manager
      "radarr.meskill.farm" = {
        upstream = "radarr:7878";
        description = "Radarr movie manager";
      };

      # Readarr book manager
      "readarr.meskill.farm" = {
        upstream = "readarr:8787";
        description = "Readarr book manager";
      };

      # ROM manager
      "romm.meskill.farm" = {
        upstream = "romm:8080";
        description = "ROM manager";
      };

      # RTL-SDR 433MHz receiver
      "rtl433.meskill.farm" = {
        upstream = "10.55.20.24:8433";
        description = "RTL-SDR 433MHz receiver";
      };

      # RTL-SDR 915MHz receiver
      "rtl915.meskill.farm" = {
        upstream = "10.55.20.24:8915";
        description = "RTL-SDR 915MHz receiver";
      };

      # SABnzbd (via VPN)
      "sabnzbd.meskill.farm" = {
        upstream = "gluetun:8080";
        description = "SABnzbd (via VPN)";
      };

      # Jellyseerr media requests
      "seerr.meskill.farm" = {
        upstream = "jellyseerr:5055";
        description = "Jellyseerr media requests";
      };

      # Sonarr TV manager
      "sonarr.meskill.farm" = {
        upstream = "sonarr:8989";
        description = "Sonarr TV manager";
      };

      # TaskTrove task manager
      "tasks.meskill.farm" = {
        upstream = "tasktrove:3000";
        description = "TaskTrove task manager";
      };

      # Gatus uptime monitoring
      "uptime.meskill.farm" = {
        upstream = "gatus:8080";
        description = "Gatus uptime monitoring";
      };

      # Weaviate vector database
      "weaviate.meskill.farm" = {
        upstream = "weaviate:8080";
        description = "Weaviate vector database";
      };

      # Zigbee2MQTT
      "zigbee.meskill.farm" = {
        upstream = "zigbee2mqtt:8080";
        description = "Zigbee2MQTT";
      };

      # Obsidian web UI (n8n REST API integration)
      "obsidian.meskill.farm" = {
        upstream = "obsidian:3000";
        description = "Obsidian web UI";
      };
    };

    # Complex routes with raw Caddy config
    rawRoutes = {
      # MQTT broker (websocket)
      "mqtt.meskill.farm" = {
        description = "MQTT broker (websocket)";
        config = ''
          reverse_proxy mosquitto:9001
        '';
      };

      # n8n webhooks only (restricted)
      "n8h.meskill.farm" = {
        description = "n8n webhooks only (restricted)";
        config = ''
          handle /webhook/* {
            reverse_proxy n8n:5678
          }
          handle /mcp/* {
            reverse_proxy n8n:5678
          }
          handle {
            abort
          }
        '';
      };
    };
  };

  # Caddy secrets (global config with ACME credentials)
  age.secrets.monolith_caddy_secrets = {
    rekeyFile = ./files/caddy/secrets.age;
    mode = "600";
  };
}
