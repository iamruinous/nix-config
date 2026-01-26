# Weaviate Vector Database for Budgey semantic search
#
# Native Weaviate server with text2vec-ollama for local embeddings.
# Uses the local Ollama service with nomic-embed-text model.
# Accessible at localhost:8080 (REST) and localhost:50051 (gRPC), proxied via Caddy.
{
  config,
  pkgs,
  ...
}: {
  # Docker is still needed for other services - keep the basic config
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
    autoPrune = {
      enable = true;
      flags = ["--all"];
    };
  };

  # Allow jmeskill to use docker
  users.users.jmeskill.extraGroups = ["docker"];

  # Docker CLI tools
  environment.systemPackages = with pkgs; [
    lazydocker
    # weaviate # TODO: Use custom package once overlay is fixed
  ];

  # Weaviate systemd service using native package
  systemd.services.weaviate = {
    description = "Weaviate Vector Database";
    wantedBy = ["multi-user.target"];
    after = ["network.target" "ollama.service"];
    wants = ["ollama.service"];

    environment = {
      # Query settings
      QUERY_DEFAULTS_LIMIT = "25";

      # Authentication - API key required
      AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED = "false";
      AUTHENTICATION_APIKEY_ENABLED = "true";

      # Persistence
      PERSISTENCE_DATA_PATH = "/var/lib/weaviate";
      CLUSTER_HOSTNAME = "weaviate";

      # Vectorizer modules - use Ollama for local embeddings
      DEFAULT_VECTORIZER_MODULE = "text2vec-ollama";
      ENABLE_MODULES = "text2vec-ollama,generative-ollama";

      # Ollama connection (local service)
      OLLAMA_API_ENDPOINT = "http://localhost:11434";
    };

    serviceConfig = {
      Type = "simple";
      # Use nixpkgs weaviate (1.33.2) - TODO: switch to custom 1.35.3 once overlay works
      # Bind to localhost only - Caddy proxies external access
      ExecStart = "${pkgs.weaviate}/bin/weaviate --host 127.0.0.1 --port 8080 --scheme http";
      Restart = "on-failure";
      RestartSec = "5s";

      # Environment file contains AUTHENTICATION_APIKEY_ALLOWED_KEYS and AUTHENTICATION_APIKEY_USERS
      EnvironmentFile = config.age.secrets.chassis_weaviate_env.path;

      # Run as dedicated user
      User = "weaviate";
      Group = "weaviate";

      # State directory
      StateDirectory = "weaviate";
      StateDirectoryMode = "0750";

      # Security hardening
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ReadWritePaths = ["/var/lib/weaviate"];
    };
  };

  # Create weaviate user/group
  users.users.weaviate = {
    isSystemUser = true;
    group = "weaviate";
    home = "/var/lib/weaviate";
  };
  users.groups.weaviate = {};

  # Encrypted environment file with Weaviate API keys
  # Should contain:
  #   AUTHENTICATION_APIKEY_ALLOWED_KEYS=your-api-key
  #   AUTHENTICATION_APIKEY_USERS=admin
  age.secrets.chassis_weaviate_env = {
    rekeyFile = ./files/weaviate/env.age;
    mode = "400";
    owner = "weaviate";
    group = "weaviate";
  };
}
