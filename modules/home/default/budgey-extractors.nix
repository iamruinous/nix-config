# ruinous.budgey-extractors.enable = true;
#
# Budgey Assistant session extractors for macOS (launchd) and Linux (systemd)
#
# Extracts AI assistant sessions (OpenCode, Claude, Codex, Gemini) and pushes
# to a shared git archive. Designed to work with the budgey-assistant pipeline
# where a central server handles enrichment and ingestion.
#
# See: https://forge.meskill.farm/iamruinous/budgey-assistant-ingest-tools/issues/23
#
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.budgey-extractors;

  # Get package from flake input
  ingestTools = flake.inputs.budgey-assistant-ingest-tools.packages.${pkgs.system};

  # Directories
  dataDir = "${config.xdg.dataHome}/budgey";
  cacheDir = "${config.xdg.cacheHome}/budgey";
  archivePath = "${dataDir}/archive";

  # SSH wrapper for git operations with deploy key (or use default agent)
  sshWrapper =
    if cfg.git.sshKeyFile != null
    then
      pkgs.writeShellScript "budgey-ssh-wrapper" ''
        exec ${pkgs.openssh}/bin/ssh -i ${cfg.git.sshKeyFile} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new "$@"
      ''
    else
      pkgs.writeShellScript "budgey-ssh-wrapper" ''
        exec ${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new "$@"
      '';

  # Environment variables for extractors
  extractorEnv = {
    BUDGEY_ARCHIVE = archivePath;
    BUDGEY_HOST = cfg.hostName;
    BUDGEY_GIT_COMMIT = "1";
    BUDGEY_GIT_PUSH = "1";
    GIT_SSH_COMMAND = toString sshWrapper;
    HOME = config.home.homeDirectory;
    PATH = lib.makeBinPath [pkgs.git pkgs.openssh ingestTools.all-tools];
  };

  # Archive init script - clones or pulls the git archive
  archiveInitScript = pkgs.writeShellScript "budgey-archive-init" ''
    set -euo pipefail
    export GIT_SSH_COMMAND="${sshWrapper}"
    export HOME="${config.home.homeDirectory}"
    export PATH="${lib.makeBinPath [pkgs.git pkgs.openssh]}:$PATH"

    mkdir -p "${dataDir}"
    mkdir -p "${cacheDir}"

    if [ -d "${archivePath}/.git" ]; then
      echo "Archive exists, pulling latest..."
      cd "${archivePath}"
      ${pkgs.git}/bin/git pull --ff-only || echo "Pull failed, continuing..."
    else
      echo "Cloning archive from ${cfg.git.url}..."
      ${pkgs.git}/bin/git clone --branch "${cfg.git.branch}" "${cfg.git.url}" "${archivePath}"
    fi
    echo "Archive ready at ${archivePath}"
  '';

  # Generic extractor script
  mkExtractorScript = name: bin: pkgs.writeShellScript "budgey-extract-${name}" ''
    set -euo pipefail
    export GIT_SSH_COMMAND="${sshWrapper}"
    export HOME="${config.home.homeDirectory}"
    export PATH="${lib.makeBinPath [pkgs.git pkgs.openssh ingestTools.all-tools]}:$PATH"

    echo "Starting ${name} extraction at $(date)"

    # Ensure archive is initialized
    if [ ! -d "${archivePath}/.git" ]; then
      echo "Archive not initialized, running init..."
      ${archiveInitScript}
    fi

    # Run extraction with git commit and push
    if ${ingestTools.all-tools}/bin/${bin} extract \
        -output "${archivePath}" \
        -host "${cfg.hostName}" \
        -since "${cfg.since}" \
        -git-commit \
        -git-push; then
      echo "${name} extraction completed at $(date)"
    else
      echo "${name} extraction failed at $(date)" >&2
      exit 1
    fi
  '';

  # Extractor scripts
  opencodeScript = mkExtractorScript "opencode" "opencode-extractor";
  claudeScript = mkExtractorScript "claude" "claude-extractor";
  codexScript = mkExtractorScript "codex" "codex-extractor";
  geminiScript = mkExtractorScript "gemini" "gemini-extractor";
in {
  options.ruinous.budgey-extractors = {
    enable = mkEnableOption "Budgey assistant session extractors";

    hostName = mkOption {
      type = types.str;
      description = "Host name for archive organization";
      example = "jmacmini";
    };

    since = mkOption {
      type = types.str;
      default = "24h";
      description = "Extract sessions from this time period";
      example = "7d";
    };

    git = {
      url = mkOption {
        type = types.str;
        description = "Git repository URL for the session archive";
        example = "ssh://git@forge.meskill.farm/iamruinous/assistant-session-archive.git";
      };

      branch = mkOption {
        type = types.str;
        default = "main";
        description = "Git branch to use";
      };

      sshKeyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to SSH private key for git authentication. If null, uses SSH agent.";
        example = "~/.ssh/budgey-deploy-key";
      };
    };

    extractors = {
      opencode.enable = mkEnableOption "OpenCode session extraction";
      claude.enable = mkEnableOption "Claude Code session extraction";
      codex.enable = mkEnableOption "Codex CLI session extraction";
      gemini.enable = mkEnableOption "Gemini CLI session extraction";
    };

    schedule = mkOption {
      type = types.int;
      default = 3600;
      description = "Extraction interval in seconds (default: hourly)";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Common configuration
    {
      home.packages = [
        ingestTools.all-tools
        pkgs.git
      ];
    }

    # macOS: launchd agents
    (mkIf pkgs.stdenv.isDarwin (mkMerge [
      # Archive init agent (runs at load)
      {
        launchd.agents.budgey-archive-init = {
          enable = true;
          config = {
            Label = "ai.ruinous.budgey-archive-init";
            ProgramArguments = ["${archiveInitScript}"];
            RunAtLoad = true;
            StandardOutPath = "${cacheDir}/archive-init-stdout.log";
            StandardErrorPath = "${cacheDir}/archive-init-stderr.log";
          };
        };
      }

      # OpenCode extractor
      (mkIf cfg.extractors.opencode.enable {
        launchd.agents.budgey-extract-opencode = {
          enable = true;
          config = {
            Label = "ai.ruinous.budgey-extract-opencode";
            ProgramArguments = ["${opencodeScript}"];
            StartInterval = cfg.schedule;
            StandardOutPath = "${cacheDir}/opencode-stdout.log";
            StandardErrorPath = "${cacheDir}/opencode-stderr.log";
          };
        };
      })

      # Claude extractor
      (mkIf cfg.extractors.claude.enable {
        launchd.agents.budgey-extract-claude = {
          enable = true;
          config = {
            Label = "ai.ruinous.budgey-extract-claude";
            ProgramArguments = ["${claudeScript}"];
            StartInterval = cfg.schedule;
            StandardOutPath = "${cacheDir}/claude-stdout.log";
            StandardErrorPath = "${cacheDir}/claude-stderr.log";
          };
        };
      })

      # Codex extractor
      (mkIf cfg.extractors.codex.enable {
        launchd.agents.budgey-extract-codex = {
          enable = true;
          config = {
            Label = "ai.ruinous.budgey-extract-codex";
            ProgramArguments = ["${codexScript}"];
            StartInterval = cfg.schedule;
            StandardOutPath = "${cacheDir}/codex-stdout.log";
            StandardErrorPath = "${cacheDir}/codex-stderr.log";
          };
        };
      })

      # Gemini extractor
      (mkIf cfg.extractors.gemini.enable {
        launchd.agents.budgey-extract-gemini = {
          enable = true;
          config = {
            Label = "ai.ruinous.budgey-extract-gemini";
            ProgramArguments = ["${geminiScript}"];
            StartInterval = cfg.schedule;
            StandardOutPath = "${cacheDir}/gemini-stdout.log";
            StandardErrorPath = "${cacheDir}/gemini-stderr.log";
          };
        };
      })
    ]))

    # Linux: systemd user services
    (mkIf pkgs.stdenv.isLinux (mkMerge [
      # Archive init service
      {
        systemd.user.services.budgey-archive-init = {
          Unit = {
            Description = "Budgey archive git repository initialization";
            After = ["network-online.target"];
            Wants = ["network-online.target"];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${archiveInitScript}";
          };
          Install = {
            WantedBy = ["default.target"];
          };
        };
      }

      # OpenCode extractor
      (mkIf cfg.extractors.opencode.enable {
        systemd.user.services.budgey-extract-opencode = {
          Unit = {
            Description = "Budgey OpenCode extraction service";
            After = ["budgey-archive-init.service"];
            Requires = ["budgey-archive-init.service"];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${opencodeScript}";
          };
        };

        systemd.user.timers.budgey-extract-opencode = {
          Unit.Description = "Budgey OpenCode extraction timer";
          Timer = {
            OnCalendar = "*-*-* *:30:00"; # :30 past the hour (staggered)
            Persistent = true;
            RandomizedDelaySec = "5min";
          };
          Install.WantedBy = ["timers.target"];
        };
      })

      # Claude extractor
      (mkIf cfg.extractors.claude.enable {
        systemd.user.services.budgey-extract-claude = {
          Unit = {
            Description = "Budgey Claude extraction service";
            After = ["budgey-archive-init.service"];
            Requires = ["budgey-archive-init.service"];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${claudeScript}";
          };
        };

        systemd.user.timers.budgey-extract-claude = {
          Unit.Description = "Budgey Claude extraction timer";
          Timer = {
            OnCalendar = "*-*-* *:30:00";
            Persistent = true;
            RandomizedDelaySec = "5min";
          };
          Install.WantedBy = ["timers.target"];
        };
      })

      # Codex extractor
      (mkIf cfg.extractors.codex.enable {
        systemd.user.services.budgey-extract-codex = {
          Unit = {
            Description = "Budgey Codex extraction service";
            After = ["budgey-archive-init.service"];
            Requires = ["budgey-archive-init.service"];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${codexScript}";
          };
        };

        systemd.user.timers.budgey-extract-codex = {
          Unit.Description = "Budgey Codex extraction timer";
          Timer = {
            OnCalendar = "*-*-* *:30:00";
            Persistent = true;
            RandomizedDelaySec = "5min";
          };
          Install.WantedBy = ["timers.target"];
        };
      })

      # Gemini extractor
      (mkIf cfg.extractors.gemini.enable {
        systemd.user.services.budgey-extract-gemini = {
          Unit = {
            Description = "Budgey Gemini extraction service";
            After = ["budgey-archive-init.service"];
            Requires = ["budgey-archive-init.service"];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${geminiScript}";
          };
        };

        systemd.user.timers.budgey-extract-gemini = {
          Unit.Description = "Budgey Gemini extraction timer";
          Timer = {
            OnCalendar = "*-*-* *:30:00";
            Persistent = true;
            RandomizedDelaySec = "5min";
          };
          Install.WantedBy = ["timers.target"];
        };
      })
    ]))
  ]);
}
