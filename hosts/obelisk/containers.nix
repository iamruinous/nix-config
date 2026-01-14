{
  config,
  pkgs,
  ...
}: {
  # Note: Port 80, 443 handled by docker-caddy module (see caddy.nix)

  virtualisation.docker.autoPrune = {
    enable = true;
    flags = ["--all"]; # Remove all unused images, not just dangling
  };

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

  # Caddy reverse proxy is now managed by docker-caddy module (see caddy.nix)

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
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

}

