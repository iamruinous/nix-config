# Budgey Assistant Extractors - Extract sessions and push to shared archive
#
# Architecture:
#   [zenith] extractors → archive (git push)
#                              ↓
#   [chassis] archive (git pull) → enrich (ollama) → ingest (postgres)
#                                                          ↓
#                                         [budgey-assistant-dashboard]
#                                         assistants.dashboard.ruinage.ai
#
# Zenith only runs extractors - no database, no dashboard, no enrichment.
# All extracted sessions are pushed to the shared git archive repository
# where chassis pulls and processes them.
{
  config,
  pkgs,
  flake,
  ...
}: let
  # Packages from flake inputs
  ingestTools = flake.inputs.budgey-assistant-ingest-tools.packages.${pkgs.system};

  # State directory for budgey-assistant data
  stateDir = "/var/lib/budgey-assistant";
in {
  imports = [
    # Import upstream NixOS module for ingest tools
    flake.inputs.budgey-assistant-ingest-tools.nixosModules.default
  ];

  # ============================================================================
  # EXTRACTORS ONLY (using upstream module v0.15.4+)
  # ============================================================================

  services.budgey = {
    enable = true;
    package = ingestTools.all-tools;
    user = "budgey-assistant";
    group = "budgey-assistant";
    createUser = false; # We create our own user below with SSH access
    hostName = "zenith";

    # Archive configuration - push to shared git repo
    archive = {
      mode = "git";
      path = "${stateDir}/archive";
      git = {
        url = "ssh://git@forge.meskill.farm/iamruinous/assistant-session-archive.git";
        branch = "main";
        sshKeyFile = config.age.secrets.zenith_budgey_assistant_deploy_key.path;
      };
    };

    git = {
      autoCommit = true;
      autoPush = true;
    };

    # Extractors - run at :15 past the hour (staggered from chassis at :00)
    # This reduces git push conflicts until upstream adds pull-before-push
    # See: https://forge.meskill.farm/iamruinous/budgey-assistant-ingest-tools/issues/21
    extractors = {
      opencode = {
        enable = true;
        schedule = "*-*-* *:15:00";
        since = "24h";
      };
      claude = {
        enable = true;
        schedule = "*-*-* *:15:00";
        since = "24h";
      };
      codex = {
        enable = true;
        schedule = "*-*-* *:15:00";
        since = "24h";
      };
      gemini = {
        enable = true;
        schedule = "*-*-* *:15:00";
        since = "24h";
      };
    };

    # NO enrich - chassis handles enrichment
    # NO ingest - chassis handles ingestion
    # NO weaviate - chassis handles vector search
  };

  # ============================================================================
  # EXTRACTOR SERVICE OVERRIDES
  # ============================================================================
  # Run extractors as jmeskill (who owns the session data) instead of budgey-assistant.
  # This avoids permission issues with reading ~/.claude, ~/.codex, etc.
  # The archive directory is made group-writable so jmeskill can write to it.

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

  age.secrets.zenith_budgey_assistant_deploy_key = {
    rekeyFile = ./files/budgey-assistant/deploy-key.age;
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
