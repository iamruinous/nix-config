# Weaviate Vector Database for Budgey semantic search
#
# Provides vector storage for OpenCode session search via text2vec-openai.
# Accessible at localhost:8080 internally, proxied via Caddy.
{
  config,
  pkgs,
  ...
}: {
  # Enable Docker for containers
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
    autoPrune = {
      enable = true;
      flags = ["--all"];
    };
  };

  # Create servicenet network for container communication
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

  # Weaviate container with text2vec-openai module
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      weaviate = {
        image = "cr.weaviate.io/semitechnologies/weaviate:1.28.4";
        cmd = [
          "--host"
          "0.0.0.0"
          "--port"
          "8080"
          "--scheme"
          "http"
        ];
        environment = {
          # Query settings
          QUERY_DEFAULTS_LIMIT = "25";

          # Authentication - API key required
          AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED = "false";
          AUTHENTICATION_APIKEY_ENABLED = "true";

          # Persistence
          PERSISTENCE_DATA_PATH = "/var/lib/weaviate";
          CLUSTER_HOSTNAME = "weaviate";

          # Vectorizer modules - enable OpenAI text2vec
          DEFAULT_VECTORIZER_MODULE = "text2vec-openai";
          ENABLE_MODULES = "text2vec-openai,generative-openai";
          ENABLE_API_BASED_MODULES = "true";
        };
        # Environment file contains API keys (Weaviate + OpenAI)
        environmentFiles = [config.age.secrets.chassis_weaviate_env.path];

        # Expose on localhost only (Caddy will proxy)
        ports = ["127.0.0.1:8080:8080"];

        networks = ["servicenet"];
        volumes = [
          "/data/docker/weaviate/data:/var/lib/weaviate"
        ];

        # Ensure network exists before starting
        dependsOn = [];
        extraOptions = [
          "--network-alias=weaviate"
        ];
      };
    };
  };

  # Ensure docker-weaviate starts after network is created
  systemd.services.docker-weaviate = {
    after = ["docker-servicenet-network.service"];
    requires = ["docker-servicenet-network.service"];
  };

  # Encrypted environment file with Weaviate API key and OpenAI key
  age.secrets.chassis_weaviate_env = {
    rekeyFile = ./files/weaviate/env.age;
    mode = "400";
  };
}
