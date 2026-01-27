# Budgey Assistant Pipeline - Multi-CLI session extraction and analytics
#
# Architecture:
#   [chassis] extractors → archive → enrich (ollama) → ingest (postgres/weaviate)
#                                                              ↓
#                                           [budgey-assistant-dashboard]
#                                           assistants.dashboard.ruinage.ai
#
# Uses upstream NixOS module from:
#   - budgey-assistant-ingest-tools: extractors, enrich, ingest (services.budgey)
#
# Note: The dashboard is configured manually (not via module) because the
# budgey-assistant-dashboard module conflicts with the existing budgey-dashboard
# module (both define services.budgey-dashboard).
{
  config,
  pkgs,
  flake,
  ...
}: let
  # Packages from flake inputs
  ingestTools = flake.inputs.budgey-assistant-ingest-tools.packages.${pkgs.system};
  dashboardPkg = flake.inputs.budgey-assistant-dashboard.packages.${pkgs.system}.default;

  # State directory for all budgey-assistant data
  stateDir = "/var/lib/budgey-assistant";
in {
  imports = [
    # Import upstream NixOS module for ingest tools
    flake.inputs.budgey-assistant-ingest-tools.nixosModules.default
    # Note: NOT importing budgey-assistant-dashboard module to avoid conflict
    # with budgey-dashboard module (both define services.budgey-dashboard)
  ];

  # ============================================================================
  # DASHBOARD SERVICE (manual configuration to avoid module conflict)
  # ============================================================================

  systemd.services.budgey-assistant-dashboard = {
    description = "Budgey Assistant Analytics Dashboard";
    wantedBy = ["multi-user.target"];
    after = ["network.target" "postgresql.service"];
    wants = ["postgresql.service"];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${dashboardPkg}/bin/budgey-dashboard --host 127.0.0.1 --port 8889";
      Restart = "on-failure";
      RestartSec = "5s";
      EnvironmentFile = config.age.secrets.chassis_budgey_assistant_dashboard_env.path;
      User = "budgey-assistant";
      Group = "budgey-assistant";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
    };
  };

  # ============================================================================
  # INGEST TOOLS (using upstream module v0.15.1+)
  # ============================================================================

  services.budgey = {
    enable = true;
    package = ingestTools.all-tools;
    user = "budgey-assistant";
    group = "budgey-assistant";
    createUser = false; # We create our own user below with SSH access
    hostName = "chassis";

    # Archive configuration (v0.14.0+)
    archive = {
      mode = "git";
      path = "${stateDir}/archive";
      git = {
        url = "ssh://git@forge.meskill.farm/iamruinous/assistant-session-archive.git";
        branch = "main";
        sshKeyFile = config.age.secrets.chassis_budgey_assistant_deploy_key.path;
      };
    };

    git = {
      autoCommit = true;
      autoPush = true;
    };

    # Extractors - run hourly
    extractors = {
      opencode = {
        enable = true;
        schedule = "hourly";
        since = "24h";
      };
      claude = {
        enable = true;
        schedule = "hourly";
        since = "24h";
      };
      codex = {
        enable = true;
        schedule = "hourly";
        since = "24h";
      };
      gemini = {
        enable = true;
        schedule = "hourly";
        since = "24h";
      };
    };

    # Enrichment - run 30 minutes after extraction
    enrich = {
      enable = true;
      schedule = "*-*-* *:30:00";
      ollamaUrl = "http://localhost:11434";
      summaryModel = "phi3:mini";
      embedModel = "nomic-embed-text";
    };

    # Ingestion with upstream migrations (v0.15.1+)
    ingest = {
      enable = true;
      schedule = "*-*-* *:45:00";
      runMigrations = true;
      database = {
        host = "localhost";
        port = 5432;
        name = "budgey_assistant";
        user = "budgey_assistant";
        passwordFile = config.age.secrets.chassis_budgey_assistant_db_password.path;
        sslmode = "disable"; # Local PostgreSQL without SSL
        createLocally = false; # We manage database in postgres.nix
      };
    };

    # Weaviate for vector search
    # TODO: Enable once we create a separate API key secret file for the client
    # The server's API key is in chassis_weaviate_env, but we need a plain-text file
    # containing just the key value for the weaviate.apiKeyFile option (added in v0.15.0)
    weaviate = {
      enable = false;
      # host = "localhost:8080";
      # apiKeyFile = config.age.secrets.chassis_budgey_weaviate_api_key.path;
    };
  };

  # Archive sync handled by upstream budgey-archive-init.service
  # All fixes integrated in v0.15.1: passwordFile, sslmode, Claude session_id

  # ============================================================================
  # EXTRACTOR SERVICE OVERRIDES
  # ============================================================================
  # Run extractors as jmeskill (who owns the session data) instead of budgey-assistant.
  # This avoids permission issues with reading ~/.claude, ~/.codex, etc.
  # The archive directory is made group-writable so jmeskill can write to it.
  # See: https://forge.meskill.farm/iamruinous/budgey-assistant-ingest-tools/issues/15

  systemd.services.budgey-extract-claude.serviceConfig = {
    User = pkgs.lib.mkForce "jmeskill";
    Group = pkgs.lib.mkForce "budgey-assistant";
  };

  systemd.services.budgey-extract-opencode.serviceConfig = {
    User = pkgs.lib.mkForce "jmeskill";
    Group = pkgs.lib.mkForce "budgey-assistant";
  };

  systemd.services.budgey-extract-codex.serviceConfig = {
    User = pkgs.lib.mkForce "jmeskill";
    Group = pkgs.lib.mkForce "budgey-assistant";
  };

  systemd.services.budgey-extract-gemini.serviceConfig = {
    User = pkgs.lib.mkForce "jmeskill";
    Group = pkgs.lib.mkForce "budgey-assistant";
  };

  # ============================================================================
  # USER AND PERMISSIONS
  # ============================================================================

  users.users.budgey-assistant = {
    isSystemUser = true;
    group = "budgey-assistant";
    home = stateDir;
    description = "Budgey Assistant service user";
    # Need SSH access for git operations
    openssh.authorizedKeys.keys = [];
  };

  # Add jmeskill to budgey-assistant group for archive write access
  users.users.jmeskill.extraGroups = ["budgey-assistant"];

  users.groups.budgey-assistant = {};

  # Ensure state directory exists with group-write access for extractors
  # Extractors run as jmeskill (to read session data) but need to write to archive
  systemd.tmpfiles.rules = [
    "d ${stateDir} 0775 budgey-assistant budgey-assistant -"
    "d ${stateDir}/archive 0775 budgey-assistant budgey-assistant -"
  ];

  # ============================================================================
  # SECRETS
  # ============================================================================

  age.secrets.chassis_budgey_assistant_env = {
    rekeyFile = ./files/budgey-assistant/env.age;
    mode = "400";
    owner = "budgey-assistant";
    group = "budgey-assistant";
  };

  age.secrets.chassis_budgey_assistant_dashboard_env = {
    rekeyFile = ./files/budgey-assistant/dashboard.env.age;
    mode = "400";
    owner = "budgey-assistant";
    group = "budgey-assistant";
  };

  age.secrets.chassis_budgey_assistant_deploy_key = {
    rekeyFile = ./files/budgey-assistant/deploy-key.age;
    mode = "400";
    owner = "budgey-assistant";
    group = "budgey-assistant";
  };

  age.secrets.chassis_budgey_assistant_db_password = {
    rekeyFile = ./files/budgey-assistant/db-password.age;
    mode = "400";
    owner = "budgey-assistant";
    group = "budgey-assistant";
  };

  # ============================================================================
  # SYSTEM PACKAGES
  # ============================================================================

  # Add CLI tools to system path for manual operations
  environment.systemPackages = [
    ingestTools.all-tools
  ];
}
