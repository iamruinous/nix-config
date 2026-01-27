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
  lib,
  ...
}: let
  # Packages from flake inputs
  ingestTools = flake.inputs.budgey-assistant-ingest-tools.packages.${pkgs.system};
  dashboardPkg = flake.inputs.budgey-assistant-dashboard.packages.${pkgs.system}.default;

  # Archive repository URL
  archiveRepo = "git@forge.meskill.farm:iamruinous/assistant-sessions-archive.git";

  # State directory for all budgey-assistant data
  stateDir = "/var/lib/budgey-assistant";
  archiveDir = "${stateDir}/archive";
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
  #
  # NOTE: Disabled - upstream budgey-assistant-dashboard v0.4.1 package is still
  # incomplete (missing pages/ and components/ subdirectories in installed package).
  # See: https://forge.meskill.farm/iamruinous/budgey-assistant-dashboard/issues/3
  #
  # systemd.services.budgey-assistant-dashboard = {
  #   description = "Budgey Assistant Analytics Dashboard";
  #   wantedBy = ["multi-user.target"];
  #   after = ["network.target" "postgresql.service"];
  #   wants = ["postgresql.service"];
  #
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = "${dashboardPkg}/bin/budgey-dashboard --host 127.0.0.1 --port 8889";
  #     Restart = "on-failure";
  #     RestartSec = "5s";
  #     EnvironmentFile = config.age.secrets.chassis_budgey_assistant_dashboard_env.path;
  #     User = "budgey-assistant";
  #     Group = "budgey-assistant";
  #     NoNewPrivileges = true;
  #     ProtectSystem = "strict";
  #     ProtectHome = true;
  #     PrivateTmp = true;
  #     ProtectKernelTunables = true;
  #     ProtectKernelModules = true;
  #     ProtectControlGroups = true;
  #   };
  # };

  # ============================================================================
  # INGEST TOOLS (using upstream module)
  # ============================================================================

  services.budgey = {
    enable = true;
    package = ingestTools.all-tools;
    user = "budgey-assistant";
    group = "budgey-assistant";
    createUser = false; # We create our own user below with SSH access
    archivePath = archiveDir;
    hostName = "chassis";

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

    # Ingestion - run 45 minutes after extraction
    ingest = {
      enable = true;
      schedule = "*-*-* *:45:00";
      database = {
        host = "/run/postgresql";
        name = "budgey_assistant";
        user = "budgey_assistant";
        createLocally = false; # Using our own postgres.nix setup
      };
      batchSize = 100;
    };

    # Weaviate for vector search
    weaviate = {
      enable = true;
      host = "localhost:8080";
    };
  };

  # ============================================================================
  # ARCHIVE SYNC SERVICE (custom - not in upstream module)
  # ============================================================================

  # Archive sync - pull latest from remote, push local changes
  # This runs before and after the pipeline to keep the archive in sync
  systemd.services.budgey-assistant-sync = {
    description = "Budgey Assistant - Sync Archive Repository";
    after = ["network.target"];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "budgey-sync" ''
        set -euo pipefail
        cd ${archiveDir}

        # Initialize if not a git repo yet
        if [ ! -d ".git" ]; then
          ${pkgs.git}/bin/git clone ${archiveRepo} .
          ${pkgs.git}/bin/git config user.email "budgey@chassis.meskill.farm"
          ${pkgs.git}/bin/git config user.name "Budgey Assistant"
        fi

        # Pull latest
        ${pkgs.git}/bin/git pull --rebase || true

        # Add and commit any new files
        ${pkgs.git}/bin/git add -A
        if ! ${pkgs.git}/bin/git diff --cached --quiet; then
          ${pkgs.git}/bin/git commit -m "chore: sync sessions from chassis $(date -Iseconds)"
        fi

        # Push changes
        ${pkgs.git}/bin/git push || true
      '';
      User = "budgey-assistant";
      Group = "budgey-assistant";
      StateDirectory = "budgey-assistant";
      ReadWritePaths = [stateDir];
    };
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

  users.groups.budgey-assistant = {};

  # Ensure state directory exists
  systemd.tmpfiles.rules = [
    "d ${stateDir} 0755 budgey-assistant budgey-assistant -"
    "d ${archiveDir} 0755 budgey-assistant budgey-assistant -"
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

  # ============================================================================
  # SYSTEM PACKAGES
  # ============================================================================

  # Add CLI tools to system path for manual operations
  environment.systemPackages = [
    ingestTools.all-tools
  ];
}
