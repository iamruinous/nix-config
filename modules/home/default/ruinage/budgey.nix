#
# Budgey-Extractor Registry Generator
#
# This module generates ~/.config/ruinagents/budgey/projects.json
# containing all projects with budgey enabled for any assistant.
#
# Budgey is configured per-assistant:
#   projects.X.assistants.opencode.budgey.enable = true
#   projects.X.assistants.kimaki.budgey.enable = true
#   (future assistants)
#
# The registry includes:
# - Project ID (SHA1 hash of workdir + assistant)
# - Project name, assistant type, and root directory
# - XDG paths (config, state, data)
# - Budget limits (weekly/monthly USD)
# - Project tags for categorization
#
# Usage:
#   ruinous.ruinage.budgey = {
#     defaultProject.opencode.enable = true;
#   };
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage;

  # Helper to compute XDG paths for an OpenCode project
  mkOpencodePaths = projectName: {
    config = "${config.home.homeDirectory}/.config/opencode-${projectName}";
    state = "${config.home.homeDirectory}/.local/state/opencode-${projectName}";
    data = "${config.home.homeDirectory}/.local/share/opencode-${projectName}";
  };

  # Helper to compute XDG paths for a Kimaki project
  mkKimakiPaths = projectName: {
    config = "${config.home.homeDirectory}/.config/kimaki-${projectName}";
    state = "${config.home.homeDirectory}/.local/state/kimaki-${projectName}";
    data = "${config.home.homeDirectory}/.local/share/kimaki-${projectName}";
  };

  # Helper to compute kimaki workdir (different from ruinage workdir)
  mkKimakiWorkdir = name: "${config.home.homeDirectory}/Projects/kimaki/${name}";

  # Generate budgey registry entry for an assistant
  mkBudgeyEntry = {
    name,
    assistant,
    workdir,
    budgeyCfg,
    defaultPaths,
  }: let
    id = builtins.hashString "sha1" "${workdir}:${assistant}";

    # Build budgets object with only non-null values
    budgets =
      {}
      // optionalAttrs (budgeyCfg.budgets.weeklyUsd != null) {
        weekly_usd = budgeyCfg.budgets.weeklyUsd;
      }
      // optionalAttrs (budgeyCfg.budgets.monthlyUsd != null) {
        monthly_usd = budgeyCfg.budgets.monthlyUsd;
      };

    # Use budgey path overrides if set, otherwise use computed paths
    configDir =
      if budgeyCfg.configDir != null
      then budgeyCfg.configDir
      else defaultPaths.config;

    stateDir =
      if budgeyCfg.stateDir != null
      then budgeyCfg.stateDir
      else defaultPaths.state;

    dataDir =
      if budgeyCfg.dataDir != null
      then budgeyCfg.dataDir
      else defaultPaths.data;
  in
    {
      inherit id name assistant;
      root = workdir;
      opencode_config_dir = configDir;
      xdg_config_home = configDir;
      xdg_state_home = stateDir;
      xdg_data_home = dataDir;
    }
    // optionalAttrs (budgets != {}) {inherit budgets;}
    // optionalAttrs (budgeyCfg.tags != []) {tags = budgeyCfg.tags;};

  # Collect all OpenCode budgey entries
  opencodeEntries = concatLists (mapAttrsToList (name: project:
    optionals (project.assistants.opencode.budgey.enable or false) [
      (mkBudgeyEntry {
        inherit name;
        assistant = "opencode";
        workdir = project.workdir;
        budgeyCfg = project.assistants.opencode.budgey;
        defaultPaths = mkOpencodePaths name;
      })
    ]
  ) cfg.projects);

  # Collect all Kimaki budgey entries (future use)
  # Kimaki uses ~/Projects/kimaki/<name>, not the ruinage workdir
  kimakiEntries = concatLists (mapAttrsToList (name: project:
    optionals (project.assistants.kimaki.budgey.enable or false) [
      (mkBudgeyEntry {
        inherit name;
        assistant = "kimaki";
        workdir = mkKimakiWorkdir name;
        budgeyCfg = project.assistants.kimaki.budgey;
        defaultPaths = mkKimakiPaths name;
      })
    ]
  ) cfg.projects);

  # Collect all Claude Code budgey entries (future use)
  claudeCodeEntries = concatLists (mapAttrsToList (name: project:
    optionals (project.assistants.claude-code.budgey.enable or false) [
      (mkBudgeyEntry {
        inherit name;
        assistant = "claude-code";
        workdir = project.workdir;
        budgeyCfg = project.assistants.claude-code.budgey;
        defaultPaths = mkOpencodePaths name; # Use same path structure for now
      })
    ]
  ) cfg.projects);

  # Collect all Gemini budgey entries (future use)
  geminiEntries = concatLists (mapAttrsToList (name: project:
    optionals (project.assistants.gemini.budgey.enable or false) [
      (mkBudgeyEntry {
        inherit name;
        assistant = "gemini";
        workdir = project.workdir;
        budgeyCfg = project.assistants.gemini.budgey;
        defaultPaths = mkOpencodePaths name; # Use same path structure for now
      })
    ]
  ) cfg.projects);

  # Collect all Codex budgey entries (future use)
  codexEntries = concatLists (mapAttrsToList (name: project:
    optionals (project.assistants.codex.budgey.enable or false) [
      (mkBudgeyEntry {
        inherit name;
        assistant = "codex";
        workdir = project.workdir;
        budgeyCfg = project.assistants.codex.budgey;
        defaultPaths = mkOpencodePaths name; # Use same path structure for now
      })
    ]
  ) cfg.projects);

  # Build project entries from configured projects
  projectEntries =
    opencodeEntries
    ++ kimakiEntries
    ++ claudeCodeEntries
    ++ geminiEntries
    ++ codexEntries;

  # Default project entry for interactive OpenCode sessions
  defaultOpencodeEntry = let
    homeDir = config.home.homeDirectory;
    id = builtins.hashString "sha1" "${homeDir}:opencode:default";
    budgetsCfg = cfg.budgey.defaultProject.opencode;
    budgets =
      {}
      // optionalAttrs (budgetsCfg.budgets.weeklyUsd != null) {
        weekly_usd = budgetsCfg.budgets.weeklyUsd;
      }
      // optionalAttrs (budgetsCfg.budgets.monthlyUsd != null) {
        monthly_usd = budgetsCfg.budgets.monthlyUsd;
      };
  in
    {
      inherit id;
      name = "default";
      assistant = "opencode";
      root = homeDir;
      opencode_config_dir = "${homeDir}/.config/opencode";
      xdg_config_home = "${homeDir}/.config/opencode";
      xdg_state_home = "${homeDir}/.local/state/opencode";
      xdg_data_home = "${homeDir}/.local/share/opencode";
    }
    // optionalAttrs (budgets != {}) {inherit budgets;}
    // optionalAttrs (budgetsCfg.tags != []) {tags = budgetsCfg.tags;};

  # Combine project entries with optional default project
  allProjects =
    projectEntries
    ++ optionals cfg.budgey.defaultProject.opencode.enable [defaultOpencodeEntry];

  # Build the complete registry
  budgeyRegistry = {
    version = "1.0";
    projects = allProjects;
  };

  # Check if we have any projects to include
  hasProjects = projectEntries != [] || cfg.budgey.defaultProject.opencode.enable;
in {
  options.ruinous.ruinage.budgey = {
    defaultProject = {
      opencode = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Include a default OpenCode project entry for interactive sessions.";
        };

        budgets = {
          weeklyUsd = mkOption {
            type = types.nullOr types.float;
            default = null;
            description = "Weekly budget limit in USD for default OpenCode project.";
            example = 50.0;
          };

          monthlyUsd = mkOption {
            type = types.nullOr types.float;
            default = null;
            description = "Monthly budget limit in USD for default OpenCode project.";
            example = 200.0;
          };
        };

        tags = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Tags for the default OpenCode project.";
          example = ["default" "interactive"];
        };
      };

      # Future: Add kimaki, claude-code, gemini, codex default projects here
    };
  };

  config = mkIf ((cfg.enable or false) && hasProjects) {
    xdg.configFile."ruinagents/budgey/projects.json".text = builtins.toJSON budgeyRegistry;
  };
}
