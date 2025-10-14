{
  config,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [80 443 21115 21116 21117];
  networking.firewall.allowedUDPPorts = [443 21116];

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

  systemd.services.docker-remotenet-network = {
    description = "create docker remotenet network";
    wantedBy = ["multi-user.target"];
    after = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "create-remotenet-network" ''
        if ! ${pkgs.docker}/bin/docker network inspect remotenet >/dev/null 2>&1; then
          ${pkgs.docker}/bin/docker network create remotenet --internal
        fi
      '';
    };
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      caddy = {
        image = "ghcr.io/caddybuilds/caddy-cloudflare:2.10.0";
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
          "${config.age.secrets.tty_ruinous_social_caddy_caddyfile.path}:/etc/caddy/Caddyfile"
          "/data/docker/caddy/site:/srv"
          "/data/docker/caddy/data:/data"
          "/data/docker/caddy/config:/config"
        ];
      };
      postgres = {
        image = "docker.io/postgres:17";
        ports = ["5432:5432"];
        environment = {
          PGDATA = "/var/lib/postgresql/17/docker";
        };
        environmentFiles = [config.age.secrets.tty_ruinous_social_docker_env_postgres.path];
        networks = ["datanet" "proxynet"];
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
      albyhub = {
        image = "ghcr.io/getalby/hub:v1.19.3";
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
      forgejo = {
        image = "codeberg.org/forgejo/forgejo:12";
        environment = {
          USER_UID = "2000";
          USER_GID = "2000";
        };
        networks = [
          "proxynet"
          "datanet"
          "servicenet"
        ];
        ports = [
          "127.0.0.1:2222:22"
        ];
        volumes = [
          "/data/docker/forgejo/data:/data"
          "/home/git/.ssh:/data/git/.ssh"
          "/home/git/.gnupg:/data/git/.gnupg"
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };
      karakeep = {
        image = "ghcr.io/karakeep-app/karakeep:release";
        environmentFiles = [config.age.secrets.tty_ruinous_social_docker_env_karakeep.path];
        networks = ["servicenet"];
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
        image = "docker.io/getmeili/meilisearch:v1.13.3";
        environmentFiles = [config.age.secrets.tty_ruinous_social_docker_env_karakeep.path];
        networks = ["servicenet"];
        volumes = [
          "/data/docker/karakeep/meili_data:/meili_data"
        ];
      };
      "mastodon-sidekiq" = {
        image = "ghcr.io/mastodon/mastodon:v4.4";
        environmentFiles = [config.age.secrets.tty_ruinous_social_docker_env_mastodon.path];
        networks = ["datanet" "servicenet"];
        cmd = [
          "bundle"
          "exec"
          "sidekiq"
        ];
        # healthcheck = {
        #   test = [
        #     "CMD-SHELL"
        #     "ps aux | grep '[s]idekiq\ 7' || false"
        #   ];
        #   start-period = "60s";
        #   interval = "60s";
        #   timeout = "5s";
        #   retries = 3;
        # };
        volumes = [
          "/data/docker/mastodon/public/system:/mastodon/public/system"
        ];
      };
      "mastodon-streaming" = {
        image = "ghcr.io/mastodon/mastodon-streaming:v4.4";
        environmentFiles = [config.age.secrets.tty_ruinous_social_docker_env_mastodon.path];
        networks = ["datanet" "servicenet"];
        cmd = [
          "node"
          "./streaming/index.js"
        ];
        # healthcheck = {
        #   test = [
        #     "CMD-SHELL"
        #     "curl -s --noproxy localhost localhost:4000/api/v1/streaming/health | grep -q 'OK' || exit 1"
        #   ];
        #   start-period = "60s";
        #   interval = "60s";
        #   timeout = "5s";
        #   retries = 3;
        # };
      };
      "mastodon-web" = {
        image = "ghcr.io/mastodon/mastodon:v4.4";
        environmentFiles = [config.age.secrets.tty_ruinous_social_docker_env_mastodon.path];
        networks = ["datanet" "servicenet"];
        cmd = [
          "bundle"
          "exec"
          "puma"
          "-C"
          "config/puma.rb"
        ];
        # healthcheck = {
        #   test = [
        #     "CMD-SHELL"
        #     "curl -s --noproxy localhost localhost:3000/health | grep -q 'OK' || exit 1"
        #   ];
        #   start-period = "60s";
        #   interval = "60s";
        #   timeout = "5s";
        #   retries = 3;
        # };
        volumes = [
          "/data/docker/mastodon/public/system:/mastodon/public/system"
        ];
      };
      mealie = {
        image = "ghcr.io/mealie-recipes/mealie:latest";
        environmentFiles = [config.age.secrets.tty_ruinous_social_docker_env_mealie.path];
        networks = ["servicenet"];
        volumes = [
          "/data/docker/mealie/data:/app/data"
        ];
      };
      synapse = {
        image = "ghcr.io/element-hq/synapse:latest";
        environmentFiles = [config.age.secrets.tty_ruinous_social_docker_env_synapse.path];
        networks = ["datanet" "servicenet"];
        volumes = [
          "/data/docker/synapse/data:/data"
        ];
      };
      "maubot" = {
        image = "dock.mau.dev/maubot/maubot:latest";
        networks = ["servicenet"];
        volumes = [
          "/data/docker/maubot/data:/data"
        ];
      };
      writefreely = {
        image = "docker.io/writeas/writefreely:latest";
        networks = ["servicenet"];
        volumes = [
          "/data/docker/writefreely/keys:/go/keys"
          "/data/docker/writefreely/db:/db"
          "/data/docker/writefreely/config.ini:/go/config.ini"
        ];
      };
      # remotenet
      rustdesk-hbbr = {
        image = "docker.io/rustdesk/rustdesk-server:latest";
        networks = ["remotenet"];
        ports = [
          "21117:21117"
        ];
        environment = {
          ALWAYS_USE_RELAY = "Y";
        };
        volumes = [
          "/data/docker/rustdesk/hbbr:/root"
        ];
      };
      rustdesk-hbbs = {
        image = "docker.io/rustdesk/rustdesk-server:latest";
        networks = ["remotenet"];
        ports = [
          "21115:21115"
          "21116:21116"
          "21116:21116/udp"
        ];
        dependsOn = ["rustdesk-hbbr"];
        environment = {
          ALWAYS_USE_RELAY = "Y";
        };
        volumes = [
          "/data/docker/rustdesk/hbbs:/root"
        ];
      };
    };
  };

  age.secrets.tty_ruinous_social_caddy_caddyfile = {
    file = ./files/caddy/Caddyfile.age;
    mode = "600";
  };
  # mosquitto container chowns the file
  age.secrets.tty_ruinous_social_mosquitto_config = {
    file = ./files/mosquitto/mosquitto.conf.age;
    path = "/data/docker/mosquitto/config/mosquitto.conf";
    mode = "600";
    owner = "1883";
    group = "1883";
    symlink = false;
  };
  age.secrets.tty_ruinous_social_docker_env_karakeep = {
    file = ./files/docker/env/karakeep.env.age;
    mode = "600";
  };
  age.secrets.tty_ruinous_social_docker_env_mastodon = {
    file = ./files/docker/env/mastodon.env.age;
    mode = "600";
  };
  age.secrets.tty_ruinous_social_docker_env_mealie = {
    file = ./files/docker/env/mealie.env.age;
    mode = "600";
  };
  age.secrets.tty_ruinous_social_docker_env_postgres = {
    file = ./files/docker/env/postgres.env.age;
    mode = "600";
  };
  age.secrets.tty_ruinous_social_docker_env_synapse = {
    file = ./files/docker/env/synapse.env.age;
    mode = "600";
  };
}
