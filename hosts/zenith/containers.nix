{
  config,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [80 443];
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

  # this is for forgejo actions runners
  systemd.services.docker-forgejo-actions-network = {
    description = "create docker forgejo-actions network for CI runners";
    wantedBy = ["multi-user.target"];
    after = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "create-forgejo-actions-network" ''
        if ! ${pkgs.docker}/bin/docker network inspect forgejo-actions >/dev/null 2>&1; then
          ${pkgs.docker}/bin/docker network create forgejo-actions
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
          "${config.age.secrets.zenith_caddy_caddyfile.path}:/etc/caddy/Caddyfile"
          "/data/docker/caddy/site:/srv"
          "/data/docker/caddy/data:/data"
          "/data/docker/caddy/config:/config"
          "/var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock"
        ];
      };
      "forgejo-dind" = {
        image = "code.forgejo.org/oci/docker:dind";
        environment = {
          DOCKER_TLS_CERTDIR = "/certs";
        };
        extraOptions = [
          "--privileged"
        ];
        networks = ["forgejo-actions"];
        volumes = [
          "/data/docker/forgejo-dind/docker:/var/lib/docker"
          "/data/docker/forgejo-dind/certs:/certs"
        ];
        cmd = ["dockerd" "-H" "tcp://0.0.0.0:2375" "--tls=false"];
      };
      "forgejo-runner" = {
        image = "code.forgejo.org/forgejo/runner:12.0.1";
        dependsOn = ["forgejo-dind"];
        environment = {
          DOCKER_HOST = "tcp://forgejo-dind:2375";
        };
        networks = [
          "forgejo-actions"
        ];
        volumes = [
          "/data/docker/forgejo-runner/data:/data"
          "${./files/forgejo-runner/config.yaml}:/data/config.yaml:ro"
        ];
        cmd = ["forgejo-runner" "daemon" "--config" "/data/config.yaml"];
      };
      ollama = {
        image = "docker.io/ollama/ollama:0.13.3-rocm";
        extraOptions = [
          "--device=/dev/kfd"
          "--device=/dev/dri"
          "--group-add=video"
          "--group-add=render"
        ];
        networks = ["servicenet"];
        volumes = [
          "/data/docker/ollama/config:/root/.ollama"
        ];
      };
      open-webui = {
        image = "ghcr.io/open-webui/open-webui:v0.6.41";
        dependsOn = ["ollama"];
        environment = {
          OLLAMA_BASE_URL = "http://ollama:11434";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/open-webui/data:/app/backend/data"
        ];
      };
    };
  };

  age.secrets.zenith_caddy_caddyfile = {
    rekeyFile = ./files/caddy/Caddyfile.age;
    mode = "600";
  };

  age.secrets.zenith_forgejo_runner_token = {
    rekeyFile = ./files/forgejo-runner/token.age;
    mode = "600";
  };

  # Restart docker-caddy service when Caddyfile secret changes
  systemd.services.docker-caddy = {
    restartTriggers = [config.age.secrets.zenith_caddy_caddyfile.path];
  };
}
