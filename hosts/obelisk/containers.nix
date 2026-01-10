{
  config,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [80 443];
  networking.firewall.allowedUDPPorts = [443];

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

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      caddy = {
        image = "ghcr.io/caddybuilds/caddy-cloudflare:2.10.2";
        capabilities = {
          "NET_ADMIN" = true;
        };
        ports = [
          "80:80"
          "443:443"
          "443:443/udp"
          "2019:2019"
        ];
        networks = ["servicenet" "proxynet"];
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
          "${config.age.secrets.obelisk_caddy_caddyfile.path}:/etc/caddy/Caddyfile"
          "/data/docker/caddy/site:/srv"
          "/data/docker/caddy/data:/data"
          "/data/docker/caddy/config:/config"
          "/data/docker/caddy/static:/static"
          "/var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock"
        ];
      };
      open-webui = {
        image = "ghcr.io/open-webui/open-webui:v0.6.43";
        environment = {
          OLLAMA_BASE_URL = "http://ollama:11434";
        };
        networks = ["servicenet"];
        dependsOn = ["ollama"];
        volumes = [
          "/data/docker/open-webui/data:/app/backend/data"
        ];
      };
      ollama = {
        image = "docker.io/ollama/ollama:0.13.5";
        environment = {
          OLLAMA_DEFAULT_MODEL = "qwen2.5-coder-7b";
        };
        devices = ["nvidia.com/gpu=all"];
        networks = ["servicenet"];
        volumes = [
          "/data/docker/ollama/config:/root/.ollama"
        ];
      };
    };
  };

  age.secrets.obelisk_caddy_caddyfile = {
    rekeyFile = ./files/caddy/Caddyfile.age;
    mode = "600";
  };

  # Restart docker-caddy service when Caddyfile secret changes
  # Use rekeyFile (nix store path) instead of path (runtime path) so trigger fires on content change
  systemd.services.docker-caddy = {
    restartTriggers = [config.age.secrets.obelisk_caddy_caddyfile.rekeyFile];
  };
}

