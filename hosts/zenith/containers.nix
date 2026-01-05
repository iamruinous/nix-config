{
  config,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [80 443 5432];
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
        image = "code.forgejo.org/forgejo/runner:12.4";
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
        image = "docker.io/ollama/ollama:0.13.4-rocm";
        extraOptions = [
          "--device=/dev/kfd"
          "--device=/dev/dri"
          # "--group-add=video"
          # "--group-add=render"
          "--security-opt=seccomp=unconfined"
        ];
        environment = {
          # Strix Halo (gfx1151) workarounds
          # OLLAMA_GPU_MEMORY = "96GB"; # Force full memory visibility
          # HSA_OVERRIDE_GFX_VERSION = "11.0.0"; # Try gfx1100 kernels (2-6x faster)
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/ollama/config:/root/.ollama"
        ];
      };
      open-webui = {
        image = "ghcr.io/open-webui/open-webui:v0.6.43";
        dependsOn = ["ollama"];
        environment = {
          OLLAMA_BASE_URL = "http://ollama:11434";
          # OPENAI_API_BASE_URL = "http://vllm:8080/v1";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/open-webui/data:/app/backend/data"
        ];
      };
      postgres = {
        image = "docker.io/postgres:18";
        ports = ["5432:5432"];
        environment = {
          PGDATA = "/var/lib/postgresql/18/docker";
        };
        environmentFiles = [config.age.secrets.zenith_docker_env_postgres.path];
        networks = [
          "datanet"
          "proxynet"
        ];
        volumes = [
          "/data/docker/postgres/pgdata:/var/lib/postgresql/18/docker"
          "/data/backup/postgres:/backup"
        ];
      };
      redis = {
        image = "docker.io/redis:7";
        cmd = ["redis-server" "--maxmemory-policy" "noeviction"];
        networks = ["datanet"];
        volumes = [
          "/data/docker/redis/data:/data"
        ];
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
          config.age.secrets.zenith_docker_env_mcp_gateway.path
        ];
        volumes = [
          "/home/jmeskill/.docker/mcp:/mcp:ro"
          "${config.age.secrets.zenith_docker_env_mcp_gateway.path}:/secrets/mcp.env:ro"
        ];
      };
      # vLLM disabled - ROCm gfx1151 (Strix Halo) support has open issues
      # See: https://github.com/ROCm/ROCm/issues/4909
      # Re-enable when ROCm properly supports Strix Halo
      # vllm = {
      #   image = "rocm/vllm-dev:rocm7.1_navi_ubuntu24.04_py3.12_pytorch_2.8_vllm_0.10.2rc1";
      #   extraOptions = [
      #     "--device=/dev/kfd"
      #     "--device=/dev/dri"
      #     "--group-add=video"
      #     "--group-add=render"
      #     "--shm-size=16g"
      #     "--security-opt=seccomp=unconfined"
      #     "--ipc=host"
      #   ];
      #   environment = {
      #     HF_HOME = "/data/huggingface";
      #     HSA_OVERRIDE_GFX_VERSION = "11.0.0";
      #   };
      #   networks = ["servicenet"];
      #   volumes = ["/data/docker/vllm/huggingface:/data/huggingface"];
      #   cmd = [
      #     "vllm" "serve" "Qwen/Qwen2.5-32B-Instruct"
      #     "--host" "0.0.0.0" "--port" "8000"
      #     "--tensor-parallel-size" "1" "--max-model-len" "32768"
      #   ];
      # };
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

  age.secrets.zenith_docker_env_postgres = {
    rekeyFile = ./files/docker/env/postgres.env.age;
    mode = "600";
  };

  age.secrets.zenith_docker_env_mcp_gateway = {
    rekeyFile = ./files/docker/env/mcp-gateway.env.age;
    mode = "600";
  };

  # Restart docker-caddy service when Caddyfile secret changes
  # Use rekeyFile (nix store path) instead of path (runtime path) so trigger fires on content change
  systemd.services.docker-caddy = {
    restartTriggers = [config.age.secrets.zenith_caddy_caddyfile.rekeyFile];
  };

  # Restart docker-mcp-gateway service when config secret changes
  systemd.services.docker-mcp-gateway = {
    restartTriggers = [config.age.secrets.zenith_docker_env_mcp_gateway.rekeyFile];
  };

  # Pull optimized models for zenith's 96GB VRAM after ollama starts
  systemd.services.ollama-pull-models = {
    description = "Pull Ollama models optimized for zenith";
    wantedBy = ["multi-user.target"];
    after = ["docker-ollama.service"];
    requires = ["docker-ollama.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ollama-pull-models" ''
        # Wait for ollama to be ready
        echo "Waiting for ollama to be ready..."
        for i in $(seq 1 30); do
          if ${pkgs.docker}/bin/docker exec ollama ollama list >/dev/null 2>&1; then
            break
          fi
          sleep 2
        done

        echo "Pulling gemma3:27b (largest Gemma 3, 128K context, multimodal)..."
        ${pkgs.docker}/bin/docker exec ollama ollama pull gemma3:27b

        echo "Pulling glm4:latest (GLM-4 9B, 128K context, multilingual)..."
        ${pkgs.docker}/bin/docker exec ollama ollama pull glm4:latest

        echo "Models pulled successfully!"
        ${pkgs.docker}/bin/docker exec ollama ollama list
      '';
    };
  };
}
