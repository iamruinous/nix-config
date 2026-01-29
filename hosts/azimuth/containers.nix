{
  lib,
  pkgs,
  ...
}: {
  # Note: Port 80, 443 handled by docker-caddy module (see caddy.nix)
  networking.firewall.allowedTCPPorts = [5432];

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

  # Caddy reverse proxy is now managed by docker-caddy module (see caddy.nix)

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      open-webui = {
        image = "ghcr.io/open-webui/open-webui:v0.7.2";
        dependsOn = ["llama-cpp"];
        environment = {
          OPENAI_API_BASE_URL = "http://llama-cpp:8000/v1";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/open-webui/data:/app/backend/data"
        ];
      };

      # llama.cpp - OpenAI-compatible API server with ROCm GPU acceleration
      # Replaces vLLM for better unified memory handling on Strix Halo
      # Model: Qwen2.5-Coder-32B-Instruct Q4_K_M (~24GB weights)
      # Context: 100K tokens for OpenCode coding workflows
      # Tool calling enabled via --jinja flag

      # Init container to download model if not present
      llama-cpp-init = {
        image = "docker.io/curlimages/curl:8.11.1";
        volumes = [
          "/data/docker/llama-cpp/models:/models"
        ];
        cmd = [
          "sh"
          "-c"
          ''
            if [ ! -f /models/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf ]; then
              echo "Model not found, downloading Qwen2.5-Coder-32B-Instruct Q4_K_M (~24GB)..."
              curl -L --progress-bar -o /models/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf \
                "https://huggingface.co/bartowski/Qwen2.5-Coder-32B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf"
              echo "Download complete!"
            else
              echo "Model already exists at /models/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf, skipping download"
            fi
          ''
        ];
      };

      # llama.cpp server with ROCm GPU acceleration for Strix Halo
      # Using kyuz0 AMD Strix Halo Toolboxes ROCm 7.1.1 image
      # ROCm 7.1.1 works with gfx1151! Previous crashes were caused by init container restart loop
      # Reference: https://strixhalo.wiki/AI/llamacpp-with-ROCm
      llama-cpp = {
        image = "docker.io/kyuz0/amd-strix-halo-toolboxes:rocm-7.1.1";
        dependsOn = ["llama-cpp-init"];
        extraOptions = [
          "--device=/dev/kfd"
          "--device=/dev/dri"
          "--group-add=26" # video group (GID on NixOS)
          "--group-add=303" # render group (GID on NixOS)
          "--shm-size=128g" # Full RAM for unified memory APU
          "--security-opt=seccomp=unconfined"
          "--ipc=host"
        ];
        networks = ["servicenet"];
        volumes = [
          "/data/docker/llama-cpp/models:/models"
        ];
        cmd = [
          "llama-server"
          "--model"
          "/models/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf"
          "--ctx-size"
          "32768"
          "--host"
          "0.0.0.0"
          "--port"
          "8000"
          "--n-gpu-layers"
          "999"
          "--no-mmap"
          "--no-warmup"
        ];
      };
    };
  };

  # Fix llama-cpp-init restart loop: init containers should stay "active" after
  # completion so dependent services dont cascade-restart. Without this,
  # systemds default Restart=always causes the init container to restart
  # every ~10 seconds, which cascades to llama-cpp and open-webui via Requires=.
  systemd.services.docker-llama-cpp-init = {
    serviceConfig = {
      Restart = lib.mkForce "no";
      RemainAfterExit = true;
    };
  };
}
