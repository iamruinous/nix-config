# ruinous.ai-cli.budgey-extractor.enable = true;
#
# Scheduled ingestion of OpenCode session data into PostgreSQL and Weaviate.
# Runs daily, executing dbmate migrations followed by ingest-postgres and
# optionally ingest-weaviate for semantic search.
#
# Requires:
#   - ruinous.ai-cli.opencode-projects.enable = true (for registry file)
#   - Either databaseUrl (for local socket) or environmentFile (for remote)
#
# Example (local postgres with peer auth):
#   ruinous.ai-cli.budgey-extractor = {
#     enable = true;
#     databaseUrl = "postgresql:///budgey?host=/run/postgresql";
#   };
#
# Example (remote postgres with password + weaviate):
#   ruinous.ai-cli.budgey-extractor = {
#     enable = true;
#     environmentFile = config.age.secrets.budgey_env.path;
#     weaviate.enable = true;  # Uses WEAVIATE_URL and WEAVIATE_API_KEY from environmentFile
#   };
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.ai-cli.budgey-extractor;
  projectsCfg = config.ruinous.ai-cli.opencode-projects;
in {
  options.ruinous.ai-cli.budgey-extractor = {
    enable = mkEnableOption "budgey-extractor scheduled ingestion";

    package = mkOption {
      type = types.package;
      default = pkgs.budgey-extractor;
      description = "The budgey-extractor package to use.";
    };

    dbmatePackage = mkOption {
      type = types.package;
      default = pkgs.dbmate;
      description = "The dbmate package to use for migrations.";
    };

    databaseUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        DATABASE_URL for PostgreSQL connection.
        For local Unix socket: postgresql:///budgey?host=/run/postgresql
        For remote: postgresql://user:pass@host:5432/budgey

        If set, this takes precedence over environmentFile.
      '';
      example = "postgresql:///budgey?host=/run/postgresql";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to environment file containing DATABASE_URL.
        This should be an agenix-encrypted file.
        Only used if databaseUrl is not set.

        Example contents:
          DATABASE_URL=postgresql://budgey:password@host:5432/budgey
      '';
      example = "/run/agenix/budgey_env";
    };

    registryPath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.config/ruinagents/budgey/projects.json";
      description = "Path to the budgey projects registry JSON file.";
    };

    migrationsDir = mkOption {
      type = types.str;
      default = "${cfg.package}/share/budgey-extractor/migrations";
      description = "Path to the dbmate migrations directory.";
    };

    schedule = mkOption {
      type = types.str;
      default = "*-*-* 02:00:00";
      description = "Systemd timer schedule (OnCalendar format). Default: 2 AM daily.";
      example = "*-*-* 03:30:00";
    };

    persistent = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to run missed jobs if the system was off.";
    };

    weaviate = {
      enable = mkEnableOption "Weaviate vector database ingestion for semantic search";

      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Weaviate URL for vector database connection.
          If set, this takes precedence over WEAVIATE_URL from environmentFile.
        '';
        example = "http://localhost:8080";
      };

      apiKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Weaviate API key for authentication.
          If set, this takes precedence over WEAVIATE_API_KEY from environmentFile.
          For secrets, prefer using environmentFile with WEAVIATE_API_KEY.
        '';
      };

      className = mkOption {
        type = types.str;
        default = "OpenCodeSession";
        description = "Weaviate class name for storing session data.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = projectsCfg.enable;
        message = "budgey-extractor requires ruinous.ai-cli.opencode-projects.enable = true";
      }
      {
        assertion = cfg.databaseUrl != null || cfg.environmentFile != null;
        message = "budgey-extractor requires either databaseUrl or environmentFile to be set";
      }
    ];

    systemd.user.services.budgey-extractor = {
      Unit = {
        Description = "Budgey Extractor - OpenCode session ingestion to PostgreSQL and Weaviate";
        After = ["network.target"];
      };
      Service =
        {
          Type = "oneshot";
          ExecStart = let
            # Determine the DSN source - either direct config or from env var
            dsnArg =
              if cfg.databaseUrl != null
              then "--dsn '${cfg.databaseUrl}'"
              else "--dsn \"$DATABASE_URL\"";

            # Weaviate arguments
            weaviateUrlArg =
              if cfg.weaviate.url != null
              then "--weaviate-url '${cfg.weaviate.url}'"
              else "--weaviate-url \"$WEAVIATE_URL\"";
            weaviateApiKeyArg =
              if cfg.weaviate.apiKey != null
              then "--weaviate-api-key '${cfg.weaviate.apiKey}'"
              else "--weaviate-api-key \"$WEAVIATE_API_KEY\"";
            weaviateClassArg = "--class-name '${cfg.weaviate.className}'";

            script = pkgs.writeShellScript "budgey-extractor-run" ''
              set -euo pipefail

              echo "Running dbmate migrations..."
              ${cfg.dbmatePackage}/bin/dbmate \
                --migrations-dir "${cfg.migrationsDir}" \
                --no-dump-schema \
                up

              echo "Running budgey-extractor ingest-postgres..."
              ${cfg.package}/bin/budgey-extractor \
                --registry "${cfg.registryPath}" \
                ingest-postgres ${dsnArg}

              ${optionalString cfg.weaviate.enable ''
                echo "Running budgey-extractor ingest-weaviate..."
                ${cfg.package}/bin/budgey-extractor \
                  --registry "${cfg.registryPath}" \
                  ingest-weaviate ${weaviateUrlArg} ${weaviateApiKeyArg} ${weaviateClassArg}
              ''}

              echo "Budgey extraction complete."
            '';
          in "${script}";
        }
        // optionalAttrs (cfg.databaseUrl != null) {
          # Still set DATABASE_URL for dbmate which uses it
          Environment = ["DATABASE_URL=${cfg.databaseUrl}"];
        }
        // optionalAttrs (cfg.environmentFile != null && cfg.databaseUrl == null) {
          EnvironmentFile = cfg.environmentFile;
        };
    };

    systemd.user.timers.budgey-extractor = {
      Unit = {
        Description = "Daily timer for Budgey Extractor";
      };
      Timer = {
        OnCalendar = cfg.schedule;
        Persistent = cfg.persistent;
        Unit = "budgey-extractor.service";
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };
}
