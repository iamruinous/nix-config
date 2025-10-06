{config, ...}: {
  virtualisation.docker.storageDriver = "btrfs";

  virtualisation.arion = {
    backend = "docker";
    projects."monolith".settings = {
      networks = {
        "hostnet" = {
          name = "hostnet";
        };
        "proxynet" = {
          name = "proxynet";
        };
        "datanet" = {
          name = "datanet";
          internal = true;
        };
      };
      services = {
        # hostnet services
        "caddy".service = {
          container_name = "caddy";
          image = "ghcr.io/caddybuilds/caddy-cloudflare:2.10.0";
          networks = [
            "hostnet"
            "proxynet"
          ];
          ports = [
            "80:80"
            "443:443"
            "443:443/udp"
            "2019:2019"
          ];
          capabilities = {
            NET_ADMIN = true;
          };
          healthcheck = {
            test = [
              "CMD"
              "wget"
              "--no-verbose"
              "--tries=1"
              "--spider"
              "http://127.0.0.1:2019/metrics"
            ];
            start_period = "60s";
            interval = "60s";
            timeout = "5s";
            retries = 3;
          };
          restart = "unless-stopped";
          volumes = [
            "${config.age.secrets.monolith_caddy_caddyfile.path}:/etc/caddy/Caddyfile"
            "/data/docker/caddy/site:/srv"
            "/data/docker/caddy/data:/data"
            "/data/docker/caddy/config:/config"
            "/var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock"
          ];
        };
        # datanet services
        "mariadb".service = {
          container_name = "mariadb";
          image = "docker.io/mariadb:11";
          ports = ["3306:3306"];
          env_file = [config.age.secrets.monolith_docker_env_mariadb.path];
          networks = [
            "datanet"
            "hostnet"
          ];
          healthcheck = {
            test = [
              "CMD"
              "healthcheck.sh"
              "--connect"
              "--innodb_initialized"
            ];
            start_period = "10s";
            interval = "60s";
            timeout = "5s";
            retries = 3;
          };
          restart = "unless-stopped";
          volumes = [
            "/data/docker/mariadb/mysql:/var/lib/mysql"
            "/data/backup/mariadb:/backup"
          ];
        };
        "openldap".service = {
          container_name = "openldap";
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
            "hostnet"
          ];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/openldap/ldap:/var/lib/ldap"
            "/data/docker/openldap/slapd:/etc/ldap/slapd.d"
          ];
        };
        "postgres".service = {
          container_name = "postgres";
          image = "docker.io/postgres:17";
          ports = ["5432:5432"];
          environment = {
            PGDATA = "/var/lib/postgresql/17/docker";
          };
          env_file = [config.age.secrets.monolith_docker_env_postgres.path];
          networks = [
            "datanet"
            "hostnet"
          ];
          healthcheck = {
            test = [
              "CMD-SHELL"
              "pg_isready"
            ];
            start_period = "10s";
            interval = "60s";
            timeout = "5s";
            retries = 3;
          };
          restart = "unless-stopped";
          volumes = [
            "/data/docker/postgres/pgdata:/var/lib/postgresql/17/docker"
            "/data/backup/postgres:/backup"
          ];
        };
        "prometheus".service = {
          container_name = "prometheus";
          image = "docker.io/prom/prometheus:v3.6.0";
          ports = ["9090:9090"];
          networks = [
            "datanet"
            "hostnet"
          ];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/prometheus/data:/prometheus"
            "${./files/prometheus/prometheus.yml}:/etc/prometheus/prometheus.yml"
            "${./files/prometheus/rules.yml}:/etc/prometheus/rules.yml"
          ];
        };
        "redis".service = {
          container_name = "redis";
          image = "docker.io/redis:8-alpine";
          networks = ["datanet"];
          healthcheck = {
            test = [
              "CMD"
              "redis-cli"
              "ping"
            ];
            start_period = "60s";
            interval = "60s";
            timeout = "5s";
            retries = 3;
          };
          restart = "unless-stopped";
          volumes = [
            "/data/docker/redis/data:/data"
          ];
        };
        # proxynet services
        "acme-dns".service = {
          container_name = "acme-dns";
          image = "docker.io/joohoi/acme-dns";
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/acme-dns/config:/etc/acme-dns:ro"
            "/data/docker/acme-dns/data:/var/lib/acme-dns"
          ];
        };
        "adminer".service = {
          container_name = "adminer";
          image = "docker.io/adminer:5";
          environment = {
            TZ = "America/Phoenix";
          };
          networks = [
            "proxynet"
            "datanet"
          ];
          restart = "unless-stopped";
          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };
        "apprise".service = {
          container_name = "apprise";
          image = "lscr.io/linuxserver/apprise-api:1.2.0";
          environment = {
            TZ = "America/Phoenix";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/apprise/config:/config"
          ];
        };
        "autobrr".service = {
          container_name = "autobrr";
          image = "ghcr.io/autobrr/autobrr:latest";
          environment = {
            PUID = "4000";
            PGID = "4000";
            TZ = "America/Phoenix";
            AUTO_UPDATE = "false";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/autobrr/config:/config"
          ];
        };
        "bazarr".service = {
          container_name = "bazarr";
          image = "lscr.io/linuxserver/bazarr:1.5.2";
          environment = {
            PUID = "4000";
            PGID = "4000";
            TZ = "America/Phoenix";
            AUTO_UPDATE = "false";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
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
        "calibre".service = {
          container_name = "calibre";
          image = "lscr.io/linuxserver/calibre:latest";
          environment = {
            PUID = "4000";
            PGID = "4000";
            TZ = "America/Phoenix";
            CALIBRE_TEMP_DIR = "/config/tmp";
            CALIBRE_CACHE_DIRECTORY = "/config/cache";
            AUTO_UPDATE = "false";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/calibre/config:/config"
            "/nas/media/Books:/mnt/calibre"
          ];
        };
        "calibre-automated".service = {
          container_name = "calibre-automated";
          image = "ghcr.io/crocodilestick/calibre-web-automated:latest";
          environment = {
            PUID = "4000";
            PGID = "4000";
            TZ = "America/Phoenix";
            AUTO_UPDATE = "false";
            #DOCKER_MODS = "lscr.io/linuxserver/mods:universal-calibre-v7.16.0";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/calibre-automated/config:/config"
            "/nas/media/Books:/calibre-library"
            "/nas/media/xfer/ingest/calibre-automated:/cwa-book-ingest"
          ];
        };
        "calibre-automated-dl".service = {
          container_name = "calibre-automated-dl";
          image = "ghcr.io/calibrain/calibre-web-automated-book-downloader:latest";
          environment = {
            UID = "4000";
            GID = "4000";
            TZ = "America/Phoenix";
            FLASK_PORT = "8084";
            LOG_LEVEL = "info";
            BOOK_LANGUAGE = "en";
            USE_BOOK_TITLE = "true";
            APP_ENV = "prod";
            CWA_DB_PATH = "/auth/app.db";
          };
          network_mode = "service:piavpn";
          restart = "unless-stopped";
          depends_on = ["piavpn"];
          volumes = [
            "/data/docker/calibre-automated/config/app.db:/auth/app.db:ro"
            #"/data/docker/calibre-automated/patch/book_manager.py:/app/book_manager.py:ro"
            "/nas/media/xfer/ingest/calibre-automated:/cwa-book-ingest"
          ];
        };
        "changedetection".service = {
          container_name = "changedetection";
          image = "ghcr.io/dgtlmoon/changedetection.io";
          environment = {
            TZ = "America/Phoenix";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/changedetection/data:/datastore"
          ];
        };
        "deluge".service = {
          container_name = "deluge";
          image = "lscr.io/linuxserver/deluge:2.2.0";
          environment = {
            PUID = "4000";
            PGID = "4000";
            TZ = "America/Phoenix";
            AUTO_UPDATE = "false";
            DELUGE_LOGLEVEL = "error";
          };
          network_mode = "service:piavpn";
          restart = "unless-stopped";
          depends_on = ["piavpn"];
          volumes = [
            "/data/docker/piavpn/shared:/pia"
            "/data/docker/deluge/config:/config"
            "/nas/media/xfer:/data/xfer"
          ];
        };
        "ersatztv".service = {
          container_name = "ersatztv";
          image = "docker.io/jasongdove/ersatztv:latest-vaapi";
          ports = ["8409:8409"];
          environment = {
            TZ = "America/Phoenix";
          };
          networks = [
            "hostnet"
            "proxynet"
          ];
          healthcheck = {
            test = [
              "CMD"
              "curl"
              "--fail"
              "http://127.0.0.1:8409"
            ];
            start_period = "60s";
            interval = "60s";
            timeout = "5s";
            retries = 3;
          };
          restart = "unless-stopped";
          tmpfs = ["/transcode,size=4g"];
          volumes = [
            "/data/docker/ersatztv/config:/config"
            "/nas/media:/mnt/plex:ro"
          ];
          devices = [
            "/dev/dri/card0:/dev/dri/card0"
            "/dev/dri/renderD128:/dev/dri/renderD128"
          ];
        };
        "flaresolverr".service = {
          container_name = "flaresolverr";
          image = "ghcr.io/flaresolverr/flaresolverr:latest";
          environment = {
            PUID = "4000";
            PGID = "4000";
            TZ = "America/Phoenix";
            AUTO_UPDATE = "false";
          };
          network_mode = "service:piavpn";
          restart = "unless-stopped";
          depends_on = ["piavpn"];
        };
        "frigate".service = {
          container_name = "frigate";
          image = "ghcr.io/blakeblackshear/frigate:stable";
          networks = ["proxynet"];
          restart = "unless-stopped";
          capabilities = {
            CAP_PERFMON = true;
          };
          tmpfs = ["/tmp/cache,size=2g"];
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
        "glance".service = {
          container_name = "glance";
          image = "docker.io/glanceapp/glance:v0.8.4";
          environment = {
            TZ = "America/Phoenix";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/glance/config:/app/config"
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };
        "grafana".service = {
          container_name = "grafana";
          image = "docker.io/grafana/grafana-oss:12.1.1";
          networks = [
            "datanet"
            "proxynet"
          ];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/grafana/data:/var/lib/grafana"
            "${./files/grafana/datasources}:/etc/grafana/provisioning/datasources"
            "${./files/grafana/dashboards}:/etc/grafana/provisioning/dashboards"
          ];
        };
        # "hbbs".service = {
        #   container_name = "hbbs";
        #   image = "docker.io/rustdesk/rustdesk-server:latest";
        #   environment = {
        #     ALWAYS_USE_RELAY = "Y";
        #   };
        #   depends_on = ["hbbr"];
        #   network_mode = "host";
        #   restart = "unless-stopped";
        #   volumes = [
        #     "/data/docker/hbbs/config:/root"
        #   ];
        # };
        # "hbbr".service = {
        #   container_name = "hbbr";
        #   image = "docker.io/rustdesk/rustdesk-server:latest";
        #   network_mode = "host";
        #   restart = "unless-stopped";
        #   volumes = [
        #     "/data/docker/hbbs/config:/root"
        #   ];
        # };
        "jellyseerr".service = {
          container_name = "jellyseerr";
          image = "docker.io/fallenbagel/jellyseerr:2";
          environment = {
            PUID = "4000";
            PGID = "4000";
            TZ = "America/Phoenix";
            AUTO_UPDATE = "false";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/jellyseerr/config:/app/config"
          ];
        };
        "kavita".service = {
          container_name = "kavita";
          image = "lscr.io/linuxserver/kavita:0.8.7";
          environment = {
            PUID = "4000";
            PGID = "4000";
            TZ = "America/Phoenix";
          };
          networks = ["proxynet"];
          healthcheck = {
            test = [
              "CMD"
              "curl"
              "--fail"
              "http://127.0.0.1:5000"
            ];
            start_period = "60s";
            interval = "60s";
            timeout = "5s";
            retries = 3;
          };
          restart = "unless-stopped";
          volumes = [
            "/data/docker/kavita/config:/config"
            "/nas/media/Books:/mnt/books"
          ];
        };
        "mqtt-explorer".service = {
          container_name = "mqtt-explorer";
          image = "docker.io/smeagolworms4/mqtt-explorer:browser-1.0.3";
          environment = {
            TZ = "America/Phoenix";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/mqtt-explorer/config:/mqtt-explorer/config"
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };
        "n8n".service = {
          # command = ["start" "--tunnel"];
          container_name = "n8n";
          image = "docker.n8n.io/n8nio/n8n:1.112.6";
          environment = {
            TZ = "America/Phoenix";
            GENERIC_TIMEZONE = "America/Phoenix";
            N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
            N8N_RUNNERS_ENABLED = "true";
            DB_TYPE = "postgresdb";
            WEBHOOK_URL = "https://n8n.meskill.farm";
            N8N_EDITOR_BASE_URL = "https://n8n.meskill.farm";
          };
          env_file = [config.age.secrets.monolith_docker_env_n8n.path];
          networks = [
            "proxynet"
            "datanet"
          ];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/n8n/config:/home/node/.n8n"
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };
        "paperless-ai".service = {
          container_name = "paperless-ai";
          image = "docker.io/clusterzx/paperless-ai:latest";
          environment = {
            PUID = "4000";
            PGUID = "4000";
            RAG_SERVICE_URL = "http://localhost:8000";
            RAG_SERVICE_ENABLED = "true";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/paperless-ai/data:/app/data"
          ];
        };
        "paperless-ngx".service = {
          container_name = "paperless-ngx";
          image = "ghcr.io/paperless-ngx/paperless-ngx:2.18";
          # depends_on = [
          #   "gotenberg"
          #   "postgres"
          #   "redis"
          #   "tika"
          # ];
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
          env_file = [config.age.secrets.monolith_docker_env_paperless_ngx.path];
          networks = [
            "proxynet"
            "datanet"
          ];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/paperless-ngx/data:/usr/src/paperless/data"
            "/nas/paperless/media:/usr/src/paperless/media"
            "/nas/paperless/consume:/usr/src/paperless/consume"
            "/nas/paperless/export:/usr/src/paperless/export"
          ];
        };
        "paperless-gotenberg".service = {
          container_name = "gotenberg";
          command = [
            "gotenberg"
            "--chromium-disable-javascript=true"
            "--chromium-allow-list=file:///tmp/.*"
          ];
          image = "docker.io/gotenberg/gotenberg:8.22";
          networks = ["proxynet"];
          restart = "unless-stopped";
        };
        "paperless-tika".service = {
          container_name = "tika";
          image = "docker.io/apache/tika:latest";
          networks = ["proxynet"];
          restart = "unless-stopped";
        };
        "phpldapadmin".service = {
          container_name = "phpldapadmin";
          image = "docker.io/phpldapadmin/phpldapadmin:2.2.2";
          environment = {
            PHPLDAPADMIN_HTTPS = "false";
            PHPLDAPADMIN_LDAP_HOSTS = "#PYTHON2BASH:[{'openldap': [{'server': [{'tls': False}]},{'login': [{'bind_id': 'cn=admin,dc=meskill-farmhouse,dc=lan'}]}]}]";
          };
          networks = [
            "datanet"
            "proxynet"
          ];
          restart = "unless-stopped";
        };
        "piavpn".service = {
          container_name = "piavpn";
          image = "docker.io/thrnz/docker-wireguard-pia";
          env_file = [config.age.secrets.monolith_docker_env_piavpn.path];
          ports = [
            "8080:8080"
            "8084:8084"
            "8112:8112"
            "8191:8191"
            "6789:6789"
            "9999:9999"
          ];
          capabilities = {
            NET_ADMIN = true;
            NET_RAW = true;
            SYS_MODULE = true;
          };
          sysctls = {
            "net.ipv4.conf.all.src_valid_mark" = "1";
            "net.ipv6.conf.default.disable_ipv6" = "1";
            "net.ipv6.conf.all.disable_ipv6" = "1";
            "net.ipv6.conf.lo.disable_ipv6" = "1";
          };
          networks = ["hostnet"];
          restart = "unless-stopped";
          healthcheck = {
            test = [
              "CMD"
              "ping"
              "-c 1"
              "www.google.com"
              "||"
              "exit 1"
            ];
            interval = "30s";
            timeout = "30s";
            retries = 3;
          };
          volumes = [
            "/data/docker/piavpn/config:/config"
            "/data/docker/piavpn/shared:/pia-shared"
            "/lib/modules:/lib/modules"
          ];
        };
        "pinchflat".service = {
          container_name = "pinchflat";
          image = "ghcr.io/kieraneglin/pinchflat:v2025.6.6";
          environment = {
            TZ = "America/Phoenix";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/pinchflat/config:/config"
            "/nas/media/YT:/downloads"
          ];
        };
        "prom-alert-manager".service = {
          container_name = "alert-manager";
          image = "docker.io/prom/alertmanager:v0.28.1";
          networks = [
            "datanet"
            "proxynet"
          ];
          restart = "unless-stopped";
          volumes = [
            "${./files/prometheus/alertmanager.yml}:/alertmanager/alertmanager.yml"
          ];
        };
        "prom-graphite-exporter".service = {
          container_name = "graphite-exporter";
          image = "docker.io/prom/graphite-exporter:v0.16.0";
          networks = [
            "datanet"
            "proxynet"
            "hostnet"
          ];
          ports = [
            "9109:9109"
            "9109:9109/udp"
          ];
          restart = "unless-stopped";
        };
        "prom-node-exporter".service = {
          container_name = "node-exporter";
          image = "docker.io/prom/node-exporter:v1.9.1";
          networks = [
            "datanet"
            "proxynet"
          ];
          restart = "unless-stopped";
        };
        "prom-plex-exporter".service = {
          container_name = "plex-exporter";
          image = "ghcr.io/timothystewart6/prometheus-plex-exporter:latest";
          networks = [
            "datanet"
            "proxynet"
          ];
          restart = "unless-stopped";
          env_file = [config.age.secrets.monolith_docker_env_prometheus_plex_exporter.path];
          environment = {
            TZ = "America/Phoenix";
          };
        };
        "prowlarr".service = {
          container_name = "prowlarr";
          image = "lscr.io/linuxserver/prowlarr:2.0.2-nightly";
          environment = {
            PUID = "4000";
            PGID = "4000";
            TZ = "America/Phoenix";
            AUTO_UPDATE = "false";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/prowlarr/config:/config"
          ];
        };
        "radarr".service = {
          container_name = "radarr";
          image = "lscr.io/linuxserver/radarr:5.26.2";
          environment = {
            PUID = "4000";
            PGID = "4000";
            TZ = "America/Phoenix";
            AUTO_UPDATE = "false";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/radarr/config:/config"
            "/nas/media/xfer/completed:/data/xfer/completed"
            "/nas/media/Movies:/mnt/movies"
            "/nas/media/Kids/Movies:/mnt/kids"
            "/nas/media/Anime/Movies:/mnt/anime"
            "/nas/media/Holidays:/mnt/holidays"
          ];
        };
        "readarr".service = {
          container_name = "readarr";
          image = "lscr.io/linuxserver/readarr:0.4.19-nightly";
          environment = {
            PUID = "4000";
            PGID = "4000";
            TZ = "America/Phoenix";
            AUTO_UPDATE = "false";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/readarr/config:/config"
            "/nas/media/Books:/books"
            "/nas/media/audiobooks:/audiobooks"
            "/nas/media/xfer/completed:/data/xfer/completed"
          ];
        };
        "romm".service = {
          container_name = "romm";
          image = "docker.io/rommapp/romm:3";
          env_file = [config.age.secrets.monolith_docker_env_romm.path];
          networks = [
            "proxynet"
            "datanet"
          ];
          healthcheck = {
            test = [
              "CMD"
              "curl"
              "--fail"
              "http://127.0.0.1:8080"
            ];
            start_period = "60s";
            interval = "60s";
            timeout = "5s";
            retries = 3;
          };
          restart = "unless-stopped";
          volumes = [
            "/data/docker/romm/resources:/romm/resources"
            "/data/docker/romm/config:/romm/config"
            "/data/docker/romm/assets:/romm/assets"
            "/data/docker/romm/redis:/redis-data"
            "/nas/roms:/romm/library"
          ];
        };
        "sabnzbd".service = {
          container_name = "sabnzbd";
          image = "lscr.io/linuxserver/sabnzbd:4.5.2";
          environment = {
            PUID = "4000";
            PGID = "4000";
            TZ = "America/Phoenix";
            AUTO_UPDATE = "false";
          };
          network_mode = "service:piavpn";
          restart = "unless-stopped";
          depends_on = ["piavpn"];
          volumes = [
            "/data/docker/sabnzbd/config:/config"
            "/nas/media/xfer:/data/xfer"
          ];
        };
        "sonarr".service = {
          container_name = "sonarr";
          image = "lscr.io/linuxserver/sonarr:4.0.15";
          environment = {
            PUID = "4000";
            PGID = "4000";
            TZ = "America/Phoenix";
            AUTO_UPDATE = "false";
          };
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/sonarr/config:/config"
            "/nas/media/xfer/completed:/data/xfer/completed"
            "/nas/media/TV:/mnt/tv"
            "/nas/media/Kids/TV:/mnt/kids"
            "/nas/media/Anime/TV:/mnt/anime"
          ];
        };
        "stepca".service = {
          container_name = "stepca";
          image = "docker.io/smallstep/step-ca:0.28.4";
          env_file = [config.age.secrets.monolith_docker_env_stepca.path];
          networks = ["proxynet"];
          restart = "unless-stopped";
          capabilities = {
            NET_ADMIN = true;
          };
          volumes = [
            "/data/docker/stepca/config:/home/step"
          ];
        };
        "tasktrove".service = {
          container_name = "tasktrove";
          image = "ghcr.io/dohsimpson/tasktrove";
          networks = ["proxynet"];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/tasktrove/config:/app/data"
          ];
        };
        "weatherflow".service = {
          container_name = "weatherflow";
          image = "docker.io/briis/weatherflow2mqtt:3.2.2";
          ports = ["50222:50222/udp"];
          env_file = [config.age.secrets.monolith_docker_env_weatherflow.path];
          networks = [
            "hostnet"
          ];
          restart = "unless-stopped";
          volumes = [
            "/data/docker/weatherflow/config:/usr/local/config"
          ];
        };
      };
    };
  };

  age.secrets.monolith_caddy_caddyfile = {
    file = ./files/caddy/Caddyfile.age;
    mode = "600";
  };
  age.secrets.monolith_glance_config = {
    file = ./files/glance/glance.yml.age;
    path = "/data/docker/glance/config/glance.yml";
    mode = "600";
    symlink = false;
  };
  age.secrets.monolith_docker_env_mariadb = {
    file = ./files/docker/env/mariadb.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_n8n = {
    file = ./files/docker/env/n8n.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_piavpn = {
    file = ./files/docker/env/piavpn.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_paperless_ngx = {
    file = ./files/docker/env/paperless-ngx.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_postgres = {
    file = ./files/docker/env/postgres.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_prometheus_plex_exporter = {
    file = ./files/docker/env/prometheus-plex-exporter.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_romm = {
    file = ./files/docker/env/romm.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_stepca = {
    file = ./files/docker/env/stepca.env.age;
    mode = "600";
  };
  age.secrets.monolith_docker_env_weatherflow = {
    file = ./files/docker/env/weatherflow.env.age;
    mode = "600";
  };
}
