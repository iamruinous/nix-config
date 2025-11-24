{
  config,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [80 443 3493 5050 9000];
  networking.firewall.allowedUDPPorts = [443];

  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.autoPrune.enable = true;

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
        volumes = [
          "${config.age.secrets.pilaster_caddy_caddyfile.path}:/etc/caddy/Caddyfile"
          "/data/docker/caddy/site:/srv"
          "/data/docker/caddy/data:/data"
          "/data/docker/caddy/config:/config"
          "/var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock"
        ];
      };
      postgres = {
        image = "docker.io/postgres:18";
        # ports = ["5432:5432"];
        environment = {
          PGDATA = "/var/lib/postgresql/18/docker";
        };
        environmentFiles = [config.age.secrets.pilaster_docker_env_postgres.path];
        networks = [
          "datanet"
          # "proxynet"
        ];
        volumes = [
          "/data/docker/postgres/pgdata:/var/lib/postgresql/18/docker"
          "/data/backup/postgres:/backup"
        ];
      };
      # services
      authentik = {
        image = "ghcr.io/goauthentik/server:2025.10.2";
        cmd = ["server"];
        environmentFiles = [config.age.secrets.pilaster_docker_env_authentik.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        volumes = [
          "/data/docker/authentik/media:/media"
          "/data/docker/authentik/templates:/templates"
        ];
      };
      authentik-worker = {
        image = "ghcr.io/goauthentik/server:2025.10.2";
        cmd = ["worker"];
        environmentFiles = [config.age.secrets.pilaster_docker_env_authentik.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/data/docker/authentik/certs:/certs"
          "/data/docker/authentik/media:/media"
          "/data/docker/authentik/templates:/templates"
        ];
      };
      mcpx = {
        image = "us-central1-docker.pkg.dev/prj-common-442813/mcpx/mcpx:latest";
        extraOptions = [
          "--privileged"
        ];
        networks = [
          "proxynet"
          "servicenet"
        ];
        ports = [
          "9000:9000"
        ];
        volumes = [
          "/data/docker/mcpx/config:/lunar/packages/mcpx-server/config"
        ];
      };
      nutify-netrack = {
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
      # supakong = {
      #   image = "docker.io/kong:2.8.1";
      #   environmentFiles = [config.age.secrets.pilaster_docker_env_supakong.path];
      #   networks = [
      #     "datanet"
      #     "servicenet"
      #   ];
      #   volumes = [
      #     "/data/docker/supakong/kong.yml:/home/kong/temp.yml:ro,z"
      #   ];
      # };
      # supastudio = {
      #   image = "docker.io/supabase/studio:2025.11.10-sha-5291fe3";
      #   environmentFiles = [config.age.secrets.pilaster_docker_env_supastudio.path];
      #   networks = [
      #     "datanet"
      #     "servicenet"
      #   ];
      #   volumes = [
      #     "/data/docker/supastudio/.env:/app/apps/studio/.env"
      #   ];
      # };
      qdrant = {
        image = "qdrant/qdrant";
        environmentFiles = [config.age.secrets.pilaster_docker_env_qdrant.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        volumes = [
          "/data/docker/qdrant/data:/qdrant/storage"
        ];
      };
    };
  };

  age.secrets.pilaster_caddy_caddyfile = {
    rekeyFile = ./files/caddy/Caddyfile.age;
    mode = "600";
  };

  # Restart docker-caddy service when Caddyfile secret changes
  systemd.services.docker-caddy = {
    restartTriggers = [config.age.secrets.pilaster_caddy_caddyfile.path];
  };
  age.secrets.pilaster_docker_env_authentik = {
    rekeyFile = ./files/docker/env/authentik.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_postgres = {
    rekeyFile = ./files/docker/env/postgres.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_supakong = {
    rekeyFile = ./files/docker/env/supakong.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_supastudio = {
    rekeyFile = ./files/docker/env/supastudio.env.age;
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
}
