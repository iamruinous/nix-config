{
  config,
  pkgs,
  ...
}: {
  # Note: Port 80, 443 handled by docker-caddy module (see caddy.nix)
  networking.firewall.allowedTCPPorts = [5432];

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

  # Caddy reverse proxy is now managed by docker-caddy module (see caddy.nix)

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
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
        image = "code.forgejo.org/forgejo/runner:12.5.2";
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
          OLLAMA_DEFAULT_MODEL = "qwen2.5-coder-32b";
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
        image = "docker.io/postgres:18.1";
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
        image = "docker.io/redis:7.2.12";
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
      # Dawarich - Location tracking and history
      dawarich-db = {
        image = "postgis/postgis:17-3.5-alpine";
        environment = {
          POSTGRES_USER = "dawarich";
          POSTGRES_DB = "dawarich_production";
        };
        environmentFiles = [config.age.secrets.zenith_docker_env_dawarich.path];
        networks = ["datanet"];
        volumes = [
          "/data/docker/dawarich/db:/var/lib/postgresql/data"
          "/data/docker/dawarich/shared:/var/shared"
        ];
      };
      dawarich-app = {
        image = "freikin/dawarich:0.37.2";
        dependsOn = ["dawarich-db" "redis"];
        entrypoint = "web-entrypoint.sh";
        cmd = ["bin/rails" "server" "-p" "3000" "-b" "::"];
        environment = {
          RAILS_ENV = "production";
          REDIS_URL = "redis://redis:6379";
          DATABASE_HOST = "dawarich-db";
          DATABASE_PORT = "5432";
          DATABASE_USERNAME = "dawarich";
          DATABASE_NAME = "dawarich_production";
          MIN_MINUTES_SPENT_IN_CITY = "60";
          APPLICATION_HOSTS = "localhost,timeline.meskill.farm,timeline-int.meskill.farm";
          TIME_ZONE = "America/Phoenix";
          APPLICATION_PROTOCOL = "https";
          RAILS_LOG_TO_STDOUT = "true";
          SELF_HOSTED = "true";
          STORE_GEODATA = "true";
        };
        environmentFiles = [config.age.secrets.zenith_docker_env_dawarich.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        volumes = [
          "/data/docker/dawarich/public:/var/app/public"
          "/data/docker/dawarich/watched:/var/app/tmp/imports/watched"
          "/data/docker/dawarich/storage:/var/app/storage"
          "/data/docker/dawarich/db_data:/dawarich_db_data"
        ];
      };
      dawarich-sidekiq = {
        image = "freikin/dawarich:0.37.2";
        dependsOn = ["dawarich-db" "redis" "dawarich-app"];
        entrypoint = "sidekiq-entrypoint.sh";
        cmd = ["sidekiq"];
        environment = {
          RAILS_ENV = "production";
          REDIS_URL = "redis://redis:6379";
          DATABASE_HOST = "dawarich-db";
          DATABASE_PORT = "5432";
          DATABASE_USERNAME = "dawarich";
          DATABASE_NAME = "dawarich_production";
          APPLICATION_HOSTS = "localhost,timeline.meskill.farm,timeline-int.meskill.farm";
          BACKGROUND_PROCESSING_CONCURRENCY = "10";
          APPLICATION_PROTOCOL = "https";
          RAILS_LOG_TO_STDOUT = "true";
          SELF_HOSTED = "true";
          STORE_GEODATA = "true";
        };
        environmentFiles = [config.age.secrets.zenith_docker_env_dawarich.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        volumes = [
          "/data/docker/dawarich/public:/var/app/public"
          "/data/docker/dawarich/watched:/var/app/tmp/imports/watched"
          "/data/docker/dawarich/storage:/var/app/storage"
        ];
      };
      # Nominatim - OpenStreetMap geocoding service
      # Initial import of US-West will take several hours
      # Data persisted to /data/docker/nominatim/postgres
      nominatim = {
        image = "mediagis/nominatim:5.2.0";
        environment = {
          # Import US West region (smaller dataset for faster initial import)
          # Change to desired region: https://download.geofabrik.de/
          PBF_URL = "https://download.geofabrik.de/north-america/us-west-latest.osm.pbf";
          REPLICATION_URL = "https://download.geofabrik.de/north-america/us-west-updates/";
          # Tune for zenith's 128GB RAM
          POSTGRES_SHARED_BUFFERS = "8GB";
          POSTGRES_MAINTENANCE_WORK_MEM = "16GB";
          THREADS = "16";
        };
        environmentFiles = [config.age.secrets.zenith_docker_env_nominatim.path];
        networks = ["servicenet"];
        volumes = [
          "/data/docker/nominatim/postgres:/var/lib/postgresql/14/main"
        ];
      };

      # n8n Development Environment
      # External access via Cloudflare tunnel (n8n.meskill.dev, n8h.meskill.dev)
      # Internal access via Caddy (n8n-dev-int.meskill.farm)
      n8n-dev = {
        image = "docker.io/n8nio/n8n:2.4.1";
        environment = {
          TZ = "America/Phoenix";
          GENERIC_TIMEZONE = "America/Phoenix";
          N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
          N8N_RUNNERS_ENABLED = "true";
          N8N_RUNNERS_MODE = "external";
          N8N_RUNNERS_BROKER_LISTEN_ADDRESS = "0.0.0.0";
          N8N_RUNNERS_TASK_REQUEST_TIMEOUT = "30000";
          N8N_PROXY_HOPS = "1";
          DB_TYPE = "postgresdb";
          WEBHOOK_URL = "https://n8h.meskill.dev";
          N8N_EDITOR_BASE_URL = "https://n8n.meskill.dev";
          N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true";
          N8N_BLOCK_ENV_ACCESS_IN_NODE = "false";
          N8N_NATIVE_PYTHON_RUNNER = "true";
          WEAVIATE_URL = "http://weaviate-dev:8080";
          NODE_FUNCTION_ALLOW_BUILTIN = "*";
          N8N_BLOCK_INTERNAL_NETWORKS = "false";
          OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS = "true";
        };
        environmentFiles = [config.age.secrets.zenith_docker_env_n8n_dev.path];
        networks = ["servicenet" "datanet"];
        dependsOn = ["postgres" "redis" "weaviate-dev"];
        volumes = [
          "/data/docker/n8n-dev/config:/home/node/.n8n"
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };

      # n8n Runner for external task execution (JavaScript & Python)
      n8n-dev-runner-alpha = {
        image = "docker.io/n8nio/runners:2.4.1";
        environment = {
          TZ = "America/Phoenix";
          N8N_RUNNERS_TASK_BROKER_URI = "http://n8n-dev:5679";
          N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT = "0";
          N8N_RUNNERS_TASK_TIMEOUT = "900";
          N8N_RUNNERS_MAX_CONCURRENCY = "10";
          NODE_FUNCTION_ALLOW_BUILTIN = "*";
          N8N_BLOCK_INTERNAL_NETWORKS = "false";
        };
        environmentFiles = [config.age.secrets.zenith_docker_env_n8n_dev_runner.path];
        networks = ["servicenet"];
        dependsOn = ["n8n-dev"];
      };

      # Weaviate vector database for AI workflows
      weaviate-dev = {
        image = "cr.weaviate.io/semitechnologies/weaviate:1.35.1";
        cmd = ["--host" "0.0.0.0" "--port" "8080" "--scheme" "http"];
        environment = {
          QUERY_DEFAULTS_LIMIT = "25";
          AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED = "false";
          AUTHENTICATION_APIKEY_ENABLED = "true";
          PERSISTENCE_DATA_PATH = "/var/lib/weaviate";
          CLUSTER_HOSTNAME = "weaviate-dev";
          DEFAULT_VECTORIZER_MODULE = "none";
          ENABLE_API_BASED_MODULES = "true";
        };
        environmentFiles = [config.age.secrets.zenith_docker_env_weaviate_dev.path];
        networks = ["servicenet"];
        volumes = [
          "/data/docker/weaviate-dev/data:/var/lib/weaviate"
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

  # Caddy secrets now in caddy.nix (uses secrets.age instead of Caddyfile.age)

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

  age.secrets.zenith_docker_env_dawarich = {
    rekeyFile = ./files/docker/env/dawarich.env.age;
    mode = "600";
  };

  age.secrets.zenith_docker_env_nominatim = {
    rekeyFile = ./files/docker/env/nominatim.env.age;
    mode = "600";
  };

  age.secrets.zenith_docker_env_n8n_dev = {
    rekeyFile = ./files/docker/env/n8n-dev.env.age;
    mode = "600";
  };

  age.secrets.zenith_docker_env_n8n_dev_runner = {
    rekeyFile = ./files/docker/env/n8n-dev-runner.env.age;
    mode = "600";
  };

  age.secrets.zenith_docker_env_weaviate_dev = {
    rekeyFile = ./files/docker/env/weaviate-dev.env.age;
    mode = "600";
  };

  # docker-caddy restart triggers now handled by docker-caddy module (see caddy.nix)

  # Restart docker-mcp-gateway service when config secret changes
  systemd.services.docker-mcp-gateway = {
    restartTriggers = [config.age.secrets.zenith_docker_env_mcp_gateway.rekeyFile];
  };

  # Restart docker-n8n-dev service when config secret changes
  systemd.services.docker-n8n-dev = {
    restartTriggers = [config.age.secrets.zenith_docker_env_n8n_dev.rekeyFile];
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
