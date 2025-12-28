{
  config,
  flake,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [80 443 1883 8083 8084 8883];
  networking.firewall.allowedUDPPorts = [443];

  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.autoPrune.enable = true;

  systemd.services.docker-servicenet-network = {
    description = "create docker servicenet network";
    wantedBy = ["multi-user.target"];
    after = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "create-servicenet-network" ''
        if ! ${pkgs.docker}/bin/docker network inspect servicenet >/dev/null 2>&1; then
          ${pkgs.docker}/bin/docker network create servicenet
        fi
      '';
    };
  };

  systemd.services.docker-proxynet-network = {
    description = "create docker proxynet network";
    wantedBy = ["multi-user.target"];
    after = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "create-proxynet-network" ''
        if ! ${pkgs.docker}/bin/docker network inspect proxynet >/dev/null 2>&1; then
          ${pkgs.docker}/bin/docker network create proxynet
        fi
      '';
    };
  };

  systemd.services.docker-datanet-network = {
    description = "create docker datanet network";
    wantedBy = ["multi-user.target"];
    after = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "create-datanet-network" ''
        if ! ${pkgs.docker}/bin/docker network inspect datanet >/dev/null 2>&1; then
          ${pkgs.docker}/bin/docker network create datanet --internal
        fi
      '';
    };
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      caddy = {
        image = "ghcr.io/caddybuilds/caddy-cloudflare:2.10.2";
        networks = [
          "proxynet"
          "servicenet"
        ];
        ports = [
          "80:80"
          "443:443"
          "443:443/udp"
          "2019:2019"
        ];
        capabilities = {
          "NET_ADMIN" = true;
        };
        # healthcheck = {
        #   test = [
        #     "CMD"
        #     "wget"
        #     "--no-verbose"
        #     "--tries=1"
        #     "--spider"
        #     "http://127.0.0.1:2019/metrics"
        #   ];
        #   start-period = "60s";
        #   interval = "60s";
        #   timeout = "5s";
        #   retries = 3;
        # };
        volumes = [
          "${config.age.secrets.monolith_caddy_caddyfile.path}:/etc/caddy/Caddyfile"
          "/data/docker/caddy/site:/srv"
          "/data/docker/caddy/data:/data"
          "/data/docker/caddy/config:/config"
          "/var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock"
        ];
      };
      mosquitto = {
        image = "docker.io/eclipse-mosquitto:2";
        networks = [
          "proxynet"
          "servicenet"
        ];
        ports = [
          "1883:1883"
          "8083:8083"
          "8084:8084"
          "8883:8883"
        ];
        cmd = ["/usr/sbin/mosquitto" "-c" "/config/mosquitto.conf"];
        volumes = [
          "${config.age.secrets.monolith_mosquitto_config.path}:/config/mosquitto.conf:ro"
          "${config.age.secrets.monolith_mosquitto_passwd.path}:/config/passwd:ro"
          # "/data/docker/caddy/data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mqtt.meskill.farm:/config/cert:ro"
          "/data/docker/mosquitto/config:/config"
          "/data/docker/mosquitto/data:/mosquitto/data"
          "/data/docker/mosquitto/log:/mosquitto/log"
        ];
      };
      mariadb = {
        image = "docker.io/mariadb:11";
        ports = ["3306:3306"];
        environmentFiles = [config.age.secrets.monolith_docker_env_mariadb.path];
        networks = [
          "datanet"
          "proxynet"
        ];
        # healthcheck = {
        #   test = [
        #     "CMD"
        #     "healthcheck.sh"
        #     "--connect"
        #     "--innodb_initialized"
        #   ];
        #   start-period = "10s";
        #   interval = "60s";
        #   timeout = "5s";
        #   retries = 3;
        # };
        volumes = [
          "/data/docker/mariadb/mysql:/var/lib/mysql"
          "/data/backup/mariadb:/backup"
        ];
      };
      openldap = {
        image = "docker.io/osixia/openldap:1.5.0";
        ports = ["389:389"];
        environment = {
          LDAP_TLS = "false";
          LDAP_OPENLDAP_UID = "351";
          LDAP_OPENLDAP_GID = "351";
          LDAP_ORGANISATION = "meskill-farmhouse";
          LDAP_DOMAIN = "meskill-farmhouse.lan";
        };
        networks = [
          "datanet"
          "proxynet"
        ];
        volumes = [
          "/data/docker/openldap/ldap:/var/lib/ldap"
          "/data/docker/openldap/slapd:/etc/ldap/slapd.d"
        ];
      };
      postgres = {
        image = "docker.io/postgres:17";
        ports = ["5432:5432"];
        environment = {
          PGDATA = "/var/lib/postgresql/17/docker";
        };
        environmentFiles = [config.age.secrets.monolith_docker_env_postgres.path];
        networks = [
          "datanet"
          "proxynet"
        ];
        # healthcheck = {
        #   test = [
        #     "CMD-SHELL"
        #     "pg_isready"
        #   ];
        #   start-period = "10s";
        #   interval = "60s";
        #   timeout = "5s";
        #   retries = 3;
        # };
        volumes = [
          "/data/docker/postgres/pgdata:/var/lib/postgresql/17/docker"
          "/data/backup/postgres:/backup"
        ];
      };
      prometheus = {
        image = "docker.io/prom/prometheus:v3.8.1";
        ports = ["9090:9090"];
        networks = [
          "datanet"
          "proxynet"
        ];
        volumes = [
          "/data/docker/prometheus/data:/prometheus"
          "${./files/prometheus/prometheus.yml}:/etc/prometheus/prometheus.yml"
          "${./files/prometheus/rules.yml}:/etc/prometheus/rules.yml"
        ];
      };
      gatus = {
        image = "docker.io/twinproduction/gatus:v5.17.0";
        environmentFiles = [config.age.secrets.monolith_docker_env_gatus.path];
        networks = ["servicenet"];
        volumes = [
          "${./files/gatus/config.yaml}:/config/config.yaml:ro"
          "/data/docker/gatus/data:/data"
        ];
      };
      redis = {
        image = "docker.io/redis:8-alpine";
        networks = ["datanet"];
        # healthcheck = {
        #   test = [
        #     "CMD"
        #     "redis-cli"
        #     "ping"
        #   ];
        #   start-period = "60s";
        #   interval = "60s";
        #   timeout = "5s";
        #   retries = 3;
        # };
        volumes = [
          "/data/docker/redis/data:/data"
        ];
      };
      acme-dns = {
        image = "docker.io/joohoi/acme-dns:v1.0";
        networks = ["servicenet"];
        volumes = [
          "/data/docker/acme-dns/config:/etc/acme-dns:ro"
          "/data/docker/acme-dns/data:/var/lib/acme-dns"
        ];
      };
      adminer = {
        image = "docker.io/adminer:5.4.1";
        environment = {
          TZ = "America/Phoenix";
        };
        networks = [
          "servicenet"
          "datanet"
        ];
        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };
      apprise = {
        image = "lscr.io/linuxserver/apprise-api:1.3.0";
        environment = {
          TZ = "America/Phoenix";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/apprise/config:/config"
        ];
      };
      autobrr = {
        image = "ghcr.io/autobrr/autobrr:v1.71.0";
        environment = {
          PUID = "4000";
          PGID = "4000";
          TZ = "America/Phoenix";
          AUTO_UPDATE = "false";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/autobrr/config:/config"
        ];
      };
      bazarr = {
        image = "lscr.io/linuxserver/bazarr:1.5.3";
        environment = {
          PUID = "4000";
          PGID = "4000";
          TZ = "America/Phoenix";
          AUTO_UPDATE = "false";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/bazarr/config:/config"
          "/nas/media/TV:/tv"
          "/nas/media/Kids/TV:/tv-kids"
          "/nas/media/Anime/TV:/tv-anime"
          "/nas/media/Movies:/movies"
          "/nas/media/Kids/Movies:/movies-kids"
          "/nas/media/Anime/Movies:/movies-anime"
          "/nas/media/Holidays:/movies-holidays"
        ];
      };
      calibre = {
        image = "lscr.io/linuxserver/calibre:8.16.2";
        environment = {
          PUID = "4000";
          PGID = "4000";
          TZ = "America/Phoenix";
          CALIBRE_TEMP_DIR = "/config/tmp";
          CALIBRE_CACHE_DIRECTORY = "/config/cache";
          AUTO_UPDATE = "false";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/calibre/config:/config"
          "/nas/media/Books:/mnt/calibre"
        ];
      };
      calibre-automated = {
        image = "ghcr.io/crocodilestick/calibre-web-automated:V3.1.4";
        environment = {
          PUID = "4000";
          PGID = "4000";
          TZ = "America/Phoenix";
          AUTO_UPDATE = "false";
          #DOCKER_MODS = "lscr.io/linuxserver/mods:universal-calibre-v7.16.0";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/calibre-automated/config:/config"
          "/nas/media/Books:/calibre-library"
          "/nas/media/xfer/ingest/calibre-automated:/cwa-book-ingest"
        ];
      };
      calibre-automated-dl = {
        # IMAGECHECK: disabled - no semver tags available
        image = "ghcr.io/calibrain/calibre-web-automated-book-downloader:latest";
        environment = {
          UID = "4000";
          GID = "4000";
          TZ = "America/Phoenix";
          FLASK_PORT = "8085";
          LOG_LEVEL = "info";
          BOOK_LANGUAGE = "en";
          USE_BOOK_TITLE = "true";
          APP_ENV = "prod";
          CWA_DB_PATH = "/auth/app.db";
        };
        extraOptions = [
          "--net=container:gluetun"
        ];
        dependsOn = ["gluetun"];
        volumes = [
          "/data/docker/calibre-automated/config/app.db:/auth/app.db:ro"
          #"/data/docker/calibre-automated/patch/book_manager.py:/app/book_manager.py:ro"
          "/nas/media/xfer/ingest/calibre-automated:/cwa-book-ingest"
        ];
      };
      changedetection = {
        image = "ghcr.io/dgtlmoon/changedetection.io:0.51.4";
        environment = {
          TZ = "America/Phoenix";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/changedetection/data:/datastore"
        ];
      };
      deluge = {
        image = "lscr.io/linuxserver/deluge:2.2.0";
        environment = {
          PUID = "4000";
          PGID = "4000";
          TZ = "America/Phoenix";
          AUTO_UPDATE = "false";
          DELUGE_LOGLEVEL = "error";
        };
        extraOptions = [
          "--net=container:gluetun"
        ];
        dependsOn = ["gluetun"];
        volumes = [
          "/data/docker/gluetun/shared:/pia:ro"
          "/data/docker/deluge/config:/config"
          "/nas/media/xfer:/data/xfer"
        ];
      };
      ersatztv = {
        image = "docker.io/jasongdove/ersatztv:v25.9.0";
        ports = ["8409:8409"];
        environment = {
          TZ = "America/Phoenix";
        };
        networks = [
          "proxynet"
          "servicenet"
        ];
        # healthcheck = {
        #   test = [
        #     "CMD"
        #     "curl"
        #     "--fail"
        #     "http://127.0.0.1:8409"
        #   ];
        #   start-period = "60s";
        #   interval = "60s";
        #   timeout = "5s";
        #   retries = 3;
        # };
        extraOptions = [
          "--tmpfs=/transcode:size=4g"
        ];
        volumes = [
          "/data/docker/ersatztv/config:/config"
          "/nas/media:/mnt/plex:ro"
        ];
        devices = [
          "/dev/dri/card0:/dev/dri/card0"
          "/dev/dri/renderD128:/dev/dri/renderD128"
        ];
      };
      flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:v3.4.6";
        environment = {
          PUID = "4000";
          PGID = "4000";
          TZ = "America/Phoenix";
          AUTO_UPDATE = "false";
        };
        extraOptions = [
          "--net=container:gluetun"
        ];
        dependsOn = ["gluetun"];
      };
      forgejo = {
        image = "codeberg.org/forgejo/forgejo:13";
        environment = {
          USER_UID = "2000";
          USER_GID = "2000";
        };
        networks = [
          "proxynet"
          "datanet"
          "servicenet"
        ];
        dependsOn = ["postgres"];
        ports = [
          "127.0.0.1:2222:22"
        ];
        volumes = [
          "/data/docker/forgejo/data:/data"
          "/home/git/.ssh:/data/git/.ssh"
          "${config.age.secrets.monolith_git_id_ed25519.path}:/data/git/.ssh/id_ed25519:ro"
          "${flake + /users/git/id_ed25519.pub}:/data/git/.ssh/id_ed25519.pub:ro"
          "/home/git/.gnupg:/data/git/.gnupg"
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };
      frigate = {
        image = "ghcr.io/blakeblackshear/frigate:0.16.3";
        networks = ["servicenet"];
        capabilities = {
          "CAP_PERFMON" = true;
        };
        extraOptions = [
          "--tmpfs=/tmp/cache:size=2g"
        ];
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/data/docker/frigate/config:/config"
          "/nas/media/xfer/frigate:/media/frigate"
        ];
        devices = [
          "/dev/apex_0:/dev/apex_0"
          "/dev/bus/usb:/dev/bus/usb"
          "/dev/dri/card0:/dev/dri/card0"
          "/dev/dri/renderD128:/dev/dri/renderD128"
        ];
      };
      glance = {
        image = "docker.io/glanceapp/glance:v0.8.4";
        environment = {
          TZ = "America/Phoenix";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/glance/config:/app/config"
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };
      grafana = {
        image = "docker.io/grafana/grafana-oss:12.3.1";
        networks = [
          "datanet"
          "servicenet"
        ];
        dependsOn = ["prometheus" "loki"];
        volumes = [
          "/data/docker/grafana/data:/var/lib/grafana"
          "${./files/grafana/datasources}:/etc/grafana/provisioning/datasources"
          "${./files/grafana/dashboards}:/etc/grafana/provisioning/dashboards"
        ];
      };
      "loki" = {
        image = "docker.io/grafana/loki:3.6.3";
        cmd = ["-config.file=/mnt/config/loki-config.yaml"];
        networks = [
          "datanet"
          "servicenet"
        ];
        volumes = [
          "/data/docker/loki/config:/mnt/config"
        ];
      };
      jellyseerr = {
        image = "docker.io/fallenbagel/jellyseerr:2";
        environment = {
          PUID = "4000";
          PGID = "4000";
          TZ = "America/Phoenix";
          AUTO_UPDATE = "false";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/jellyseerr/config:/app/config"
        ];
      };
      kavita = {
        image = "lscr.io/linuxserver/kavita:0.8.8";
        environment = {
          PUID = "4000";
          PGID = "4000";
          TZ = "America/Phoenix";
        };
        networks = ["servicenet"];
        # healthcheck = {
        #   test = [
        #     "CMD"
        #     "curl"
        #     "--fail"
        #     "http://127.0.0.1:5000"
        #   ];
        #   start-period = "60s";
        #   interval = "60s";
        #   timeout = "5s";
        #   retries = 3;
        # };
        volumes = [
          "/data/docker/kavita/config:/config"
          "/nas/media/Books:/mnt/books"
        ];
      };
      "mqtt-explorer" = {
        image = "docker.io/smeagolworms4/mqtt-explorer:browser-1.0.3";
        environment = {
          TZ = "America/Phoenix";
        };
        networks = ["servicenet"];
        volumes = [
          "${config.age.secrets.monolith_mqtt-explorer_settings.path}:/mqtt-explorer/config/settings.json:ro"
          "/data/docker/mqtt-explorer/config:/mqtt-explorer/config"
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };
      n8n = {
        image = "docker.io/n8nio/n8n:2.2.1";
        environment = {
          TZ = "America/Phoenix";
          GENERIC_TIMEZONE = "America/Phoenix";
          N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
          N8N_RUNNERS_ENABLED = "true";
          N8N_RUNNERS_MODE = "external";
          N8N_RUNNERS_BROKER_LISTEN_ADDRESS = "0.0.0.0";
          N8N_PROXY_HOPS = "1";
          DB_TYPE = "postgresdb";
          WEBHOOK_URL = "https://n8h.meskill.farm";
          N8N_EDITOR_BASE_URL = "https://n8n.meskill.farm";
          N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true";
          N8N_BLOCK_ENV_ACCESS_IN_NODE = "false";
          N8N_NATIVE_PYTHON_RUNNER = "true";
          WEVIATE_URL = "http://weaviate:8080";
        };
        environmentFiles = [config.age.secrets.monolith_docker_env_n8n.path];
        networks = [
          "servicenet"
          "datanet"
        ];
        dependsOn = ["postgres" "redis"];
        volumes = [
          "/data/docker/n8n/config:/home/node/.n8n"
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };
      n8n-runner = {
        image = "docker.io/n8nio/runners:2.2.1";
        environment = {
          TZ = "America/Phoenix";
          N8N_RUNNERS_TASK_BROKER_URI = "http://n8n:5679";
          N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT = "300";
          N8N_RUNNERS_TASK_TIMEOUT = "900";
          N8N_RUNNERS_MAX_CONCURRENCY = "10";
        };
        environmentFiles = [config.age.secrets.monolith_docker_env_n8n_runner.path];
        networks = ["servicenet"];
        dependsOn = ["n8n"];
      };
      # Vector database for n8n AI workflows and RAG
      weaviate = {
        image = "cr.weaviate.io/semitechnologies/weaviate:1.35.1";
        cmd = [
          "--host"
          "0.0.0.0"
          "--port"
          "8080"
          "--scheme"
          "http"
        ];
        environment = {
          QUERY_DEFAULTS_LIMIT = "25";
          AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED = "true";
          PERSISTENCE_DATA_PATH = "/var/lib/weaviate";
          CLUSTER_HOSTNAME = "weaviate";
          DEFAULT_VECTORIZER_MODULE = "none";
          ENABLE_API_BASED_MODULES = "true";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/weaviate/data:/var/lib/weaviate"
        ];
      };
      "paperless-ai" = {
        image = "docker.io/clusterzx/paperless-ai:3.0.9";
        environment = {
          PUID = "4000";
          PGUID = "4000";
          RAG_SERVICE_URL = "http://localhost:8000";
          RAG_SERVICE_ENABLED = "true";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/paperless-ai/data:/app/data"
        ];
      };
      "paperless-ngx" = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:2.20.3";
        environment = {
          PAPERLESS_REDIS = "redis://redis:6379";
          PAPERLESS_DBHOST = "postgres";
          PAPERLESS_TIKA_ENABLED = "1";
          PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://gotenberg:3000";
          PAPERLESS_TIKA_ENDPOINT = "http://tika:9998";
          PAPERLESS_URL = "https://paperless.meskill.farm";
          PAPERLESS_CSRF_TRUSTED_ORIGINS = "https://paperless.meskill.farm,https://paperless.svc.farmhouse.meskill.network";
          USERMAP_UID = "4000";
          USERMAP_GID = "4000";
          PAPERLESS_TIME_ZONE = "America/Phoenix";
        };
        environmentFiles = [config.age.secrets.monolith_docker_env_paperless_ngx.path];
        networks = [
          "servicenet"
          "datanet"
        ];
        dependsOn = ["postgres" "redis" "gotenberg" "tika"];
        volumes = [
          "/data/docker/paperless-ngx/data:/usr/src/paperless/data"
          "/nas/paperless/media:/usr/src/paperless/media"
          "/nas/paperless/consume:/usr/src/paperless/consume"
          "/nas/paperless/export:/usr/src/paperless/export"
        ];
      };
      "gotenberg" = {
        image = "docker.io/gotenberg/gotenberg:8.25.1";
        cmd = [
          "gotenberg"
          "--chromium-disable-javascript=true"
          "--chromium-allow-list=file:///tmp/.*"
        ];
        networks = ["servicenet"];
      };
      "tika" = {
        image = "docker.io/apache/tika:2.5.0";
        networks = ["servicenet"];
      };
      phpldapadmin = {
        image = "docker.io/phpldapadmin/phpldapadmin:2.3.7";
        environment = {
          PHPLDAPADMIN_HTTPS = "false";
          PHPLDAPADMIN_LDAP_HOSTS = "#PYTHON2BASH:[{'openldap': [{'server': [{'tls': False}]},{'login': [{'bind_id': 'cn=admin,dc=meskill-farmhouse,dc=lan'}]}]}]";
        };
        networks = [
          "datanet"
          "servicenet"
        ];
      };
      gluetun = {
        image = "docker.io/qmcgaw/gluetun:v3.40.3";
        environmentFiles = [config.age.secrets.monolith_docker_env_gluetun.path];
        ports = [
          "8080:8080"
          "8085:8085"
          "8112:8112"
          "8191:8191"
          "6789:6789"
          "9999:9999"
        ];
        capabilities = {
          "NET_ADMIN" = true;
        };
        devices = ["/dev/net/tun"];
        networks = ["proxynet"];
        volumes = [
          "/data/docker/gluetun/config:/gluetun"
          "/data/docker/gluetun/shared:/gluetun-shared"
        ];
      };
      # piavpn = {
      #   image = "docker.io/thrnz/docker-wireguard-pia";
      #   environmentFiles = [config.age.secrets.monolith_docker_env_piavpn.path];
      #   ports = [
      #     "8080:8080"
      #     "8084:8084"
      #     # "8112:8112"
      #     "8191:8191"
      #     "6789:6789"
      #     "9999:9999"
      #   ];
      #   capabilities = {
      #     "NET_ADMIN" = true;
      #     "NET_RAW" = true;
      #     "SYS_MODULE" = true;
      #   };
      #   extraOptions = [
      #     "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
      #     "--sysctl=net.ipv6.conf.default.disable_ipv6=1"
      #     "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
      #     "--sysctl=net.ipv6.conf.lo.disable_ipv6=1"
      #   ];
      #   networks = ["proxynet"];
      #   # healthcheck = {
      #   #   test = [
      #   #     "CMD"
      #   #     "ping"
      #   #     "-c 1"
      #   #     "www.google.com"
      #   #     "||"
      #   #     "exit 1"
      #   #   ];
      #   #   interval = "30s";
      #   #   timeout = "30s";
      #   #   retries = 3;
      #   # };
      #   volumes = [
      #     "/data/docker/piavpn/config:/config"
      #     "/data/docker/piavpn/shared:/pia-shared"
      #     "/lib/modules:/lib/modules"
      #   ];
      # };
      pinchflat = {
        image = "ghcr.io/kieraneglin/pinchflat:v2025.6.6";
        environment = {
          TZ = "America/Phoenix";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/pinchflat/config:/config"
          "/nas/media/YT:/downloads"
        ];
      };
      "alert-manager" = {
        image = "docker.io/prom/alertmanager:v0.30.0";
        networks = [
          "datanet"
          "servicenet"
        ];
        volumes = [
          "${./files/prometheus/alertmanager.yml}:/alertmanager/alertmanager.yml"
        ];
      };
      "graphite-exporter" = {
        image = "docker.io/prom/graphite-exporter:v0.16.0";
        networks = [
          "datanet"
          "servicenet"
          "proxynet"
        ];
        ports = [
          "9109:9109"
          "9109:9109/udp"
        ];
      };
      "node-exporter" = {
        image = "docker.io/prom/node-exporter:v1.10.2";
        networks = [
          "datanet"
          "servicenet"
        ];
      };
      "plex-exporter" = {
        # IMAGECHECK: disabled - no semver tags available
        image = "ghcr.io/timothystewart6/prometheus-plex-exporter:latest";
        networks = [
          "datanet"
          "servicenet"
        ];
        environmentFiles = [config.age.secrets.monolith_docker_env_prometheus_plex_exporter.path];
        environment = {
          TZ = "America/Phoenix";
        };
      };
      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:2.3.0";
        environment = {
          PUID = "4000";
          PGID = "4000";
          TZ = "America/Phoenix";
          AUTO_UPDATE = "false";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/prowlarr/config:/config"
        ];
      };
      radarr = {
        image = "lscr.io/linuxserver/radarr:6.0.4";
        environment = {
          PUID = "4000";
          PGID = "4000";
          TZ = "America/Phoenix";
          AUTO_UPDATE = "false";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/radarr/config:/config"
          "/nas/media/xfer/completed:/data/xfer/completed"
          "/nas/media/Movies:/mnt/movies"
          "/nas/media/Kids/Movies:/mnt/kids"
          "/nas/media/Anime/Movies:/mnt/anime"
          "/nas/media/Holidays:/mnt/holidays"
        ];
      };
      readarr = {
        image = "lscr.io/linuxserver/readarr:0.4.19-nightly";
        environment = {
          PUID = "4000";
          PGID = "4000";
          TZ = "America/Phoenix";
          AUTO_UPDATE = "false";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/readarr/config:/config"
          "/nas/media/Books:/books"
          "/nas/media/audiobooks:/audiobooks"
          "/nas/media/xfer/completed:/data/xfer/completed"
        ];
      };
      romm = {
        image = "docker.io/rommapp/romm:3";
        environmentFiles = [config.age.secrets.monolith_docker_env_romm.path];
        networks = [
          "servicenet"
          "datanet"
        ];
        # healthcheck = {
        #   test = [
        #     "CMD"
        #     "curl"
        #     "--fail"
        #     "http://127.0.0.1:8080"
        #   ];
        #   start-period = "60s";
        #   interval = "60s";
        #   timeout = "5s";
        #   retries = 3;
        # };
        volumes = [
          "/data/docker/romm/resources:/romm/resources"
          "/data/docker/romm/config:/romm/config"
          "/data/docker/romm/assets:/romm/assets"
          "/data/docker/romm/redis:/redis-data"
          "/nas/roms:/romm/library"
        ];
      };
      sabnzbd = {
        image = "lscr.io/linuxserver/sabnzbd:4.5.5";
        environment = {
          PUID = "4000";
          PGID = "4000";
          TZ = "America/Phoenix";
          AUTO_UPDATE = "false";
        };
        extraOptions = [
          "--net=container:gluetun"
        ];
        dependsOn = ["gluetun"];
        volumes = [
          "/data/docker/sabnzbd/config:/config"
          "/nas/media/xfer:/data/xfer"
        ];
      };
      sonarr = {
        image = "lscr.io/linuxserver/sonarr:4.0.16";
        environment = {
          PUID = "4000";
          PGID = "4000";
          TZ = "America/Phoenix";
          AUTO_UPDATE = "false";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/sonarr/config:/config"
          "/nas/media/xfer/completed:/data/xfer/completed"
          "/nas/media/TV:/mnt/tv"
          "/nas/media/Kids/TV:/mnt/kids"
          "/nas/media/Anime/TV:/mnt/anime"
        ];
      };
      stepca = {
        image = "docker.io/smallstep/step-ca:0.29.0";
        environmentFiles = [config.age.secrets.monolith_docker_env_stepca.path];
        networks = ["servicenet"];
        capabilities = {
          "NET_ADMIN" = true;
        };
        volumes = [
          "/data/docker/stepca/config:/home/step"
        ];
      };
      tasktrove = {
        image = "ghcr.io/dohsimpson/tasktrove:v0.11.1";
        networks = ["servicenet"];
        volumes = [
          "/data/docker/tasktrove/config:/app/data"
        ];
      };
      # weatherflow = {
      #   image = "docker.io/briis/weatherflow2mqtt:3.2.2";
      #   ports = ["50222:50222/udp"];
      #   environmentFiles = [config.age.secrets.monolith_docker_env_weatherflow.path];
      #   networks = ["proxynet"];
      #   volumes = [
      #     "/data/docker/weatherflow/config:/usr/local/config"
      #   ];
      # };
      zigbee2mqtt = {
        image = "ghcr.io/koenkk/zigbee2mqtt:2";
        environment = {
          TZ = "America/Phoenix";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/zigbee2mqtt/data:/app/data"
        ];
      };
      messy-discord-bot = {
        image = "forge.meskill.farm/iamruinous/n8n-messy-discord-bot:1.0.0";
        environmentFiles = [config.age.secrets.monolith_docker_env_messy_discord_bot.path];
        networks = ["servicenet"];
      };
    };
  };

  age.secrets.monolith_caddy_caddyfile = {
    rekeyFile = ./files/caddy/Caddyfile.age;
    mode = "600";
  };

  # Restart docker-caddy service when Caddyfile secret changes
  # Use rekeyFile (nix store path) instead of path (runtime path) so trigger fires on content change
  systemd.services.docker-caddy = {
    restartTriggers = [config.age.secrets.monolith_caddy_caddyfile.rekeyFile];
  };
  # Restart docker-n8n service when env secret changes
  systemd.services.docker-n8n = {
    restartTriggers = [config.age.secrets.monolith_docker_env_n8n.rekeyFile];
  };
  # Restart docker-gatus service when config or env changes
  systemd.services.docker-gatus = {
    restartTriggers = [
      ./files/gatus/config.yaml
      config.age.secrets.monolith_docker_env_gatus.rekeyFile
    ];
  };

  age.secrets.monolith_glance_config = {
    rekeyFile = ./files/glance/glance.yml.age;
    path = "/data/docker/glance/config/glance.yml";
    mode = "600";
    symlink = false;
  };
  # mosquitto container chowns the file
  age.secrets.monolith_mosquitto_config = {
    rekeyFile = ./files/mosquitto/mosquitto.conf.age;
    path = "/data/docker/mosquitto/config/mosquitto.conf";
    mode = "600";
    owner = "1883";
    group = "1883";
    symlink = false;
  };
  age.secrets.monolith_mosquitto_passwd = {
    rekeyFile = ./files/mosquitto/passwd.age;
    path = "/data/docker/mosquitto/config/passwd";
    mode = "400";
    owner = "1883";
    group = "1883";
    symlink = false;
  };
  age.secrets.monolith_mqtt-explorer_settings = {
    rekeyFile = ./files/mqtt-explorer/settings.json.age;
    mode = "644";
  };
  age.secrets.monolith_docker_env_mariadb = {
    rekeyFile = ./files/docker/env/mariadb.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_n8n = {
    rekeyFile = ./files/docker/env/n8n.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_n8n_runner = {
    rekeyFile = ./files/docker/env/n8n-runner.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_gluetun = {
    rekeyFile = ./files/docker/env/gluetun.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_piavpn = {
    rekeyFile = ./files/docker/env/piavpn.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_paperless_ngx = {
    rekeyFile = ./files/docker/env/paperless-ngx.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_postgres = {
    rekeyFile = ./files/docker/env/postgres.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_prometheus_plex_exporter = {
    rekeyFile = ./files/docker/env/prometheus-plex-exporter.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_romm = {
    rekeyFile = ./files/docker/env/romm.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_stepca = {
    rekeyFile = ./files/docker/env/stepca.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_messy_discord_bot = {
    rekeyFile = ./files/docker/env/messy-discord-bot.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_gatus = {
    rekeyFile = ./files/docker/env/gatus.env.age;
    mode = "600";
  };
  age.secrets.monolith_git_id_ed25519 = {
    rekeyFile = flake + /users/git/id_ed25519.age;
    path = "/home/git/.ssh/id_ed25519";
    mode = "600";
    symlink = false;
    owner = "git";
  };

  # age.secrets.monolith_docker_env_weatherflow = {
  #   file = ./files/docker/env/weatherflow.env.age;
  #   mode = "600";
  # };
}
