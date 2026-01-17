{
  config,
  pkgs,
  ...
}: {
  # Note: Port 80, 443 handled by docker-caddy module (see caddy.nix)
  networking.firewall.allowedTCPPorts = [3306 3493 5050 5432 8080 8095 8097 9000 21115 21116 21117];
  networking.firewall.allowedUDPPorts = [69 21116];

  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.autoPrune = {
    enable = true;
    flags = ["--all"]; # Remove all unused images, not just dangling
  };

  # this is for services that need to talk to each other
  # they are not accessed directly, but typically through Caddy
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

  # this is for services that need to bind a port to the host
  # typically this is only caddy, but some other services that
  # use UDP or special protocols may also need to directly expose
  # a port on the host
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

  # this is for services like databases that should only be
  # accessible by other containers
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

  # Caddy reverse proxy is now managed by docker-caddy module (see caddy.nix)

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      postgres = {
        image = "docker.io/postgres:18.1";
        ports = ["5432:5432"];
        environment = {
          PGDATA = "/var/lib/postgresql/18/docker";
        };
        environmentFiles = [config.age.secrets.pilaster_docker_env_postgres.path];
        networks = [
          "datanet"
          "proxynet"
        ];
        volumes = [
          "/data/docker/postgres/pgdata:/var/lib/postgresql/18/docker"
          "/data/backup/postgres:/backup"
        ];
      };
      # services
      authentik = {
        image = "ghcr.io/goauthentik/server:2025.10.3";
        cmd = ["server"];
        environmentFiles = [config.age.secrets.pilaster_docker_env_authentik.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        dependsOn = ["postgres" "redis"];
        volumes = [
          "/data/docker/authentik/media:/media"
          "/data/docker/authentik/templates:/templates"
        ];
      };
      authentik-worker = {
        image = "ghcr.io/goauthentik/server:2025.10.3";
        cmd = ["worker"];
        environmentFiles = [config.age.secrets.pilaster_docker_env_authentik.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        dependsOn = ["authentik"];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/data/docker/authentik/certs:/certs"
          "/data/docker/authentik/media:/media"
          "/data/docker/authentik/templates:/templates"
        ];
      };
      nutify-netrack = {
        # IMAGECHECK: disabled - no semver tags, only latest-style tags
        image = "dartsteven/nutify:amd64-latest";
        extraOptions = [
          "--privileged"
          "--device=/dev/bus/usb:/dev/bus/usb:rwm"
          "--device-cgroup-rule=c 189:* rwm"
        ];
        environmentFiles = [config.age.secrets.pilaster_docker_env_nutify.path];
        capabilities = {
          SYS_ADMIN = true;
          SYS_RAWIO = true;
          MKNOD = true;
        };
        networks = [
          "servicenet"
          "proxynet"
        ];
        ports = [
          "3494:3493"
        ];
        volumes = [
          "/data/docker/nutify-netrack/logs:/app/nutify/logs"
          "/data/docker/nutify-netrack/instance:/app/nutify/instance"
          "/data/docker/nutify-netrack/ssl:/app/ssl"
          "/data/docker/nutify-netrack/etc/nut:/etc/nut"
          "/dev:/dev:rw"
          "/run/udev:/run/udev:ro"
        ];
      };
      nutify-servers = {
        # IMAGECHECK: disabled - no semver tags, only latest-style tags
        image = "dartsteven/nutify:amd64-latest";
        extraOptions = [
          "--privileged"
          "--device=/dev/bus/usb:/dev/bus/usb:rwm"
          "--device-cgroup-rule=c 189:* rwm"
        ];
        environmentFiles = [config.age.secrets.pilaster_docker_env_nutify.path];
        capabilities = {
          SYS_ADMIN = true;
          SYS_RAWIO = true;
          MKNOD = true;
        };
        networks = [
          "servicenet"
          "proxynet"
        ];
        ports = [
          "3493:3493"
        ];
        volumes = [
          "/data/docker/nutify-servers/logs:/app/nutify/logs"
          "/data/docker/nutify-servers/instance:/app/nutify/instance"
          "/data/docker/nutify-servers/ssl:/app/ssl"
          "/data/docker/nutify-servers/etc/nut:/etc/nut"
          "/dev:/dev:rw"
          "/run/udev:/run/udev:ro"
        ];
      };
      qdrant = {
        image = "qdrant/qdrant:v1.16.3";
        environmentFiles = [config.age.secrets.pilaster_docker_env_qdrant.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        volumes = [
          "/data/docker/qdrant/data:/qdrant/storage"
        ];
      };
      music-assistant = {
        # IMAGECHECK: disabled - only beta/dev versions available, no stable releases
        image = "ghcr.io/music-assistant/server:latest";
        extraOptions = [
          "--pull=always"
          "--network=host"
          "--security-opt=apparmor:unconfined"
        ];
        capabilities = {
          SYS_ADMIN = true;
          DAC_READ_SEARCH = true;
        };
        volumes = [
          "/data/docker/music-assistant/data:/data"
        ];
      };
      music-assistant-alexa = {
        # IMAGECHECK: disabled - no semver tags available
        image = "ghcr.io/alams154/music-assistant-alexa-api:latest";
        extraOptions = ["--pull=always"];
        environmentFiles = [config.age.secrets.pilaster_docker_env_music_assistant_alexa.path];
        networks = [
          "servicenet"
        ];
        dependsOn = ["music-assistant"];
      };
      mcp-gateway = {
        image = "docker/mcp-gateway:v2";
        cmd = [
          "--catalog=/mcp/catalogs/farm-catalog.yaml"
          "--config=/mcp/config.yaml"
          "--registry=/mcp/registry.yaml"
          "--tools-config=/mcp/tools.yaml"
          "--watch=true"
          "--secrets=/secrets/mcp.env"
          "--transport=sse"
          "--port=8811"
        ];
        extraOptions = [
          "--use-api-socket"
        ];
        networks = [
          "servicenet"
        ];
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_mcp_gateway.path
        ];
        volumes = [
          "/home/jmeskill/.docker/mcp:/mcp:ro"
          "${config.age.secrets.pilaster_docker_env_mcp_gateway.path}:/secrets/mcp.env:ro"
        ];
      };
      wikijs = {
        image = "ghcr.io/requarks/wiki:2.5.277";
        environment = {
          DB_TYPE = "postgres";
          DB_HOST = "postgres";
          DB_PORT = "5432";
        };
        environmentFiles = [config.age.secrets.pilaster_docker_env_wikijs.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        dependsOn = ["postgres"];
        volumes = [
          "/data/docker/wikijs/data:/wiki/data"
        ];
      };
      meshtastic-message-relay = {
        image = "ghcr.io/iamruinous/meshtastic-message-relay:v0.2.0";
        cmd = ["run" "--config" "/etc/meshtastic-relay/config.yaml"];
        extraOptions = [
          "--device=/dev/ttyUSB0:/dev/ttyUSB0"
        ];
        networks = [
          "servicenet"
        ];
        volumes = [
          "${config.age.secrets.pilaster_meshtastic_relay_config.path}:/etc/meshtastic-relay/config.yaml:ro"
          "/data/docker/meshtastic-relay/logs:/var/log/meshtastic"
        ];
      };
      mariadb = {
        image = "docker.io/mariadb:11.8.5";
        ports = ["3306:3306"];
        environmentFiles = [config.age.secrets.pilaster_docker_env_mariadb.path];
        networks = [
          "datanet"
          "proxynet"
        ];
        volumes = [
          "/data/docker/mariadb/data:/var/lib/mysql"
          "/data/backup/mariadb:/backup"
        ];
      };
      # Personal CRM Evaluation
      monica = {
        image = "docker.io/monica:4.1.2";
        environmentFiles = [config.age.secrets.pilaster_docker_env_monica.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        dependsOn = ["mariadb" "redis"];
        volumes = [
          "/data/docker/monica/storage:/var/www/html/storage"
        ];
      };
      redis = {
        image = "docker.io/redis:7.4.7";
        cmd = ["redis-server" "--maxmemory-policy" "noeviction"];
        networks = ["datanet"];
        volumes = [
          "/data/docker/redis/data:/data"
        ];
      };
      twenty = {
        image = "docker.io/twentycrm/twenty:v1.15";
        environment = {
          REDIS_URL = "redis://redis:6379";
          STORAGE_TYPE = "local";
          STORAGE_LOCAL_PATH = "/app/docker-data";
          ENABLE_DB_MIGRATIONS = "true";
          SIGN_IN_PREFILLED = "false";
          SERVER_URL = "https://twenty.meskill.farm";
        };
        environmentFiles = [config.age.secrets.pilaster_docker_env_twenty.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        dependsOn = ["postgres" "redis"];
        volumes = [
          "/data/docker/twenty/data:/app/docker-data"
        ];
      };
      twenty-worker = {
        image = "docker.io/twentycrm/twenty:v1.15";
        cmd = ["yarn" "worker:prod"];
        environment = {
          REDIS_URL = "redis://redis:6379";
          STORAGE_TYPE = "local";
          STORAGE_LOCAL_PATH = "/app/docker-data";
          ENABLE_DB_MIGRATIONS = "false";
        };
        environmentFiles = [config.age.secrets.pilaster_docker_env_twenty.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        dependsOn = ["postgres" "redis" "twenty"];
        volumes = [
          "/data/docker/twenty/data:/app/docker-data"
        ];
      };
      netbootxyz = {
        image = "lscr.io/linuxserver/netbootxyz:2.0.53";
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Phoenix";
        };
        networks = [
          "servicenet"
          "proxynet"
        ];
        ports = [
          "69:69/udp"
          "8080:80"
        ];
        volumes = [
          "/data/docker/netbootxyz/config:/config"
          "/data/docker/netbootxyz/assets:/assets"
        ];
      };
      # Migrated from tty-ruinous-social
      albyhub = {
        image = "ghcr.io/getalby/hub:v1.21.2";
        environment = {
          WORK_DIR = "/data/albyhub";
          TZ = "America/Phoenix";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/albyhub/data:/data"
        ];
      };
      baikal = {
        image = "docker.io/ckulka/baikal:0.10.1-nginx-php8.2";
        networks = ["servicenet"];
        volumes = [
          "/data/docker/baikal/config:/var/www/baikal/config"
          "/data/docker/baikal/specific:/var/www/baikal/Specific"
        ];
      };
      mealie = {
        image = "ghcr.io/mealie-recipes/mealie:v3.8.0";
        environmentFiles = [config.age.secrets.pilaster_docker_env_mealie.path];
        networks = ["servicenet"];
        volumes = [
          "/data/docker/mealie/data:/app/data"
        ];
      };
      writefreely = {
        image = "ghcr.io/writefreely/writefreely:v0.16.0";
        networks = ["servicenet"];
        volumes = [
          "/data/docker/writefreely/keys:/go/keys"
          "/data/docker/writefreely/db:/db"
          "/data/docker/writefreely/config.ini:/go/config.ini"
        ];
      };
      karakeep = {
        # IMAGECHECK: disabled - uses release tag, no semver versions
        image = "ghcr.io/karakeep-app/karakeep:release";
        environmentFiles = [config.age.secrets.pilaster_docker_env_karakeep.path];
        networks = ["servicenet"];
        dependsOn = ["karakeep-chrome" "karakeep-meilisearch"];
        volumes = [
          "/data/docker/karakeep/data:/data"
        ];
      };
      "karakeep-chrome" = {
        image = "gcr.io/zenika-hub/alpine-chrome:124";
        networks = ["servicenet"];
        cmd = [
          "--no-sandbox"
          "--disable-gpu"
          "--disable-dev-shm-usage"
          "--remote-debugging-address=0.0.0.0"
          "--remote-debugging-port=9222"
          "--hide-scrollbars"
        ];
      };
      "karakeep-meilisearch" = {
        # Pinned to v1.31 - database created with this version, v1.32 is incompatible
        image = "docker.io/getmeili/meilisearch:v1.31.0";
        environmentFiles = [config.age.secrets.pilaster_docker_env_karakeep.path];
        networks = ["servicenet"];
        volumes = [
          "/data/docker/karakeep/meili_data:/meili_data"
        ];
      };
      linkstack = {
        # IMAGECHECK: disabled - no semver tags available
        image = "docker.io/linkstackorg/linkstack:latest";
        extraOptions = ["--pull=always"];
        environment = {
          TZ = "America/Phoenix";
          SERVER_ADMIN = "admin@ruinous.social";
          HTTP_SERVER_NAME = "links.ruinous.social";
          HTTPS_SERVER_NAME = "links.ruinous.social";
          LOG_LEVEL = "info";
          PHP_MEMORY_LIMIT = "256M";
          UPLOAD_MAX_FILESIZE = "8M";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/linkstack/data:/htdocs"
        ];
      };
      homebox = {
        image = "ghcr.io/sysadminsmedia/homebox:0.22.3";
        environment = {
          TZ = "America/Phoenix";
          HBOX_LOG_LEVEL = "info";
          HBOX_LOG_FORMAT = "text";
          HBOX_WEB_MAX_UPLOAD_SIZE = "10";
          HBOX_OPTIONS_ALLOW_REGISTRATION = "false";
          HBOX_OPTIONS_ALLOW_ANALYTICS = "false";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/homebox/data:/data"
        ];
      };
      rallly = {
        image = "docker.io/lukevella/rallly:3.11.2";
        environmentFiles = [config.age.secrets.pilaster_docker_env_rallly.path];
        networks = ["servicenet" "datanet"];
        dependsOn = ["postgres"];
      };
      filestash = {
        # IMAGECHECK: disabled - no semver tags available
        image = "docker.io/machines/filestash:latest";
        extraOptions = ["--pull=always"];
        environment = {
          TZ = "America/Phoenix";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/filestash/state:/app/data/state"
        ];
      };
      homarr = {
        # IMAGECHECK: disabled - no semver tags available
        image = "ghcr.io/homarr-labs/homarr:latest";
        extraOptions = ["--pull=always"];
        environment = {
          TZ = "America/Phoenix";
          SECRET_ENCRYPTION_KEY = "d1ae027ac0960fdfb7f0bed426c39cb6279f99975322c650f45232b90d517f7d";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/homarr/appdata:/appdata"
        ];
      };
      synapse = {
        image = "ghcr.io/element-hq/synapse:v1.144.0";
        environmentFiles = [config.age.secrets.pilaster_docker_env_synapse.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        dependsOn = ["postgres"];
        volumes = [
          "/data/docker/synapse/data:/data"
        ];
      };
      maubot = {
        image = "dock.mau.dev/maubot/maubot:v0.6.0";
        networks = ["servicenet"];
        dependsOn = ["synapse"];
        volumes = [
          "/data/docker/maubot/data:/data"
        ];
      };
      # "rustdesk-hbbr" = {
      #   image = "docker.io/rustdesk/rustdesk-server:1.1.14";
      #   cmd = ["hbbr"];
      #   networks = ["proxynet"];
      #   ports = ["21117:21117"];
      #   environment = {
      #     ALWAYS_USE_RELAY = "Y";
      #   };
      #   volumes = [
      #     "/data/docker/rustdesk/config:/root"
      #   ];
      # };
      # "rustdesk-hbbs" = {
      #   image = "docker.io/rustdesk/rustdesk-server:1.1.14";
      #   cmd = ["hbbs"];
      #   networks = ["proxynet"];
      #   ports = [
      #     "21115:21115"
      #     "21116:21116"
      #     "21116:21116/udp"
      #   ];
      #   dependsOn = ["rustdesk-hbbr"];
      #   environment = {
      #     ALWAYS_USE_RELAY = "Y";
      #   };
      #   volumes = [
      #     "/data/docker/rustdesk/config:/root"
      #   ];
      # };
      "mastodon-web" = {
        image = "ghcr.io/mastodon/mastodon:v4.5.3";
        environmentFiles = [config.age.secrets.pilaster_docker_env_mastodon.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        dependsOn = ["postgres" "redis"];
        cmd = ["bundle" "exec" "puma" "-C" "config/puma.rb"];
        volumes = [
          "/data/docker/mastodon/public/system:/mastodon/public/system"
        ];
      };
      "mastodon-streaming" = {
        image = "ghcr.io/mastodon/mastodon-streaming:v4.5.3";
        environmentFiles = [config.age.secrets.pilaster_docker_env_mastodon.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        dependsOn = ["postgres" "redis"];
        cmd = ["node" "./streaming/index.js"];
      };
      "mastodon-sidekiq" = {
        image = "ghcr.io/mastodon/mastodon:v4.5.3";
        environmentFiles = [config.age.secrets.pilaster_docker_env_mastodon.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        dependsOn = ["postgres" "redis"];
        cmd = ["bundle" "exec" "sidekiq"];
        volumes = [
          "/data/docker/mastodon/public/system:/mastodon/public/system"
        ];
      };
      azimutt = {
        image = "ghcr.io/azimuttapp/azimutt:main";
        environmentFiles = [config.age.secrets.pilaster_docker_env_azimutt.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        dependsOn = ["postgres" "azimutt-gateway"];
        volumes = [
          "/data/docker/azimutt/data:/app/data"
        ];
      };
      azimutt-gateway = {
        image = "docker.io/node:18-slim";
        cmd = ["sh" "-c" "npm install -g azimutt && azimutt gateway"];
        environment = {
          API_HOST = "0.0.0.0";
          API_PORT = "4177";
        };
        environmentFiles = [config.age.secrets.pilaster_docker_env_azimutt_gateway.path];
        extraOptions = ["--network=host"];
      };
      # Web archiving platform
      archivebox = {
        image = "archivebox/archivebox:0.7.3";
        environmentFiles = [config.age.secrets.pilaster_docker_env_archivebox.path];
        networks = ["servicenet"];
        volumes = [
          "/data/docker/archivebox/data:/data"
        ];
        dependsOn = ["archivebox-sonic"];
      };
      archivebox-sonic = {
        image = "valeriansaliou/sonic:v1.4.9";
        networks = ["servicenet"];
        volumes = [
          "/data/docker/archivebox/sonic:/var/lib/sonic/store"
          "${./files/archivebox/sonic.cfg}:/etc/sonic.cfg:ro"
        ];
      };
      archivebox-scheduler = {
        image = "archivebox/archivebox:0.7.3";
        cmd = ["schedule" "--foreground" "--update" "--every=day"];
        environmentFiles = [config.age.secrets.pilaster_docker_env_archivebox.path];
        networks = ["servicenet"];
        volumes = [
          "/data/docker/archivebox/data:/data"
        ];
        dependsOn = ["archivebox" "archivebox-sonic"];
      };
      # Builder Bot MCP - automation for docs package updates
      # Provides MCP tools for n8n to update nix-config packages when docs repos are tagged
      builder-bot-mcp = {
        image = "forge.meskill.farm/iamruinous/builder-bot-mcp:latest";
        extraOptions = ["--pull=always"];
        environment = {
          MCP_TRANSPORT = "sse";
          MCP_HOST = "0.0.0.0";
          MCP_PORT = "8000";
          BUILDER_BOT_CONFIG = "/data/config/repos.json";
          NIX_CONFIG_DIR = "/data/repos/nix-config";
          FORGEJO_URL = "https://forge.meskill.farm";
          FORGEJO_OWNER = "codey-bot";
        };
        environmentFiles = [config.age.secrets.pilaster_docker_env_builder_bot.path];
        networks = ["servicenet"];
        volumes = [
          # Persistent storage for cloned repos
          "/data/docker/builder-bot-mcp/repos:/data/repos"
          # Config files (repos.json, SSH keys, allowed_signers)
          "/data/docker/builder-bot-mcp/config:/data/config:ro"
        ];
      };
    };
  };

  # Restart docker-meshtastic-message-relay service when config secret changes
  systemd.services.docker-meshtastic-message-relay = {
    restartTriggers = [config.age.secrets.pilaster_meshtastic_relay_config.rekeyFile];
  };
  # Restart docker-mcp-gateway service when config secret changes
  systemd.services.docker-mcp-gateway = {
    restartTriggers = [config.age.secrets.pilaster_docker_env_mcp_gateway.rekeyFile];
  };
  age.secrets.pilaster_docker_env_authentik = {
    rekeyFile = ./files/docker/env/authentik.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_postgres = {
    rekeyFile = ./files/docker/env/postgres.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_qdrant = {
    rekeyFile = ./files/docker/env/qdrant.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_nutify = {
    rekeyFile = ./files/docker/env/nutify.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_mcp_gateway = {
    rekeyFile = ./files/docker/env/mcp-gateway.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_music_assistant_alexa = {
    rekeyFile = ./files/docker/env/music-assistant-alexa.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_wikijs = {
    rekeyFile = ./files/docker/env/wikijs.env.age;
    mode = "600";
  };
  age.secrets.pilaster_meshtastic_relay_config = {
    rekeyFile = ./files/meshtastic-message-relay/config.yaml.age;
    mode = "666";
  };
  age.secrets.pilaster_docker_env_mariadb = {
    rekeyFile = ./files/docker/env/mariadb.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_monica = {
    rekeyFile = ./files/docker/env/monica.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_twenty = {
    rekeyFile = ./files/docker/env/twenty.env.age;
    mode = "600";
  };
  # Migrated from tty-ruinous-social
  age.secrets.pilaster_docker_env_mealie = {
    rekeyFile = ./files/docker/env/mealie.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_karakeep = {
    rekeyFile = ./files/docker/env/karakeep.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_synapse = {
    rekeyFile = ./files/docker/env/synapse.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_mastodon = {
    rekeyFile = ./files/docker/env/mastodon.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_azimutt = {
    rekeyFile = ./files/docker/env/azimutt.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_azimutt_gateway = {
    rekeyFile = ./files/docker/env/azimutt-gateway.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_archivebox = {
    rekeyFile = ./files/docker/env/archivebox.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_rallly = {
    rekeyFile = ./files/docker/env/rallly.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_builder_bot = {
    rekeyFile = ./files/docker/env/builder-bot.env.age;
    mode = "600";
  };
}
