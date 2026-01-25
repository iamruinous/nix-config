#
# Budgey-Extractor Registry Generator
#
# This module generates ~/.config/ruinagents/budgey/projects.json
# containing all projects with budgey.enable = true.
#
# The registry includes:
# - Project ID (SHA1 hash of workdir)
# - Project name and root directory
# - XDG paths (config, state, data)
# - Budget limits (weekly/monthly USD)
# - Project tags for categorization
#
# Usage:
#   ruinous.ruinage.budgey = {
#     enable = true;
#     defaultProject.enable = true;
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
  ruinageLib = import ../../../lib/ruinage/wrapper.nix {inherit lib pkgs;};

  # Helper to compute XDG paths for a project
  mkProjectPaths = projectName: {
    config = "${config.home.homeDirectory}/.config/opencode-${projectName}";
    state = "${config.home.homeDirectory}/.local/state/opencode-${projectName}";
    data = "${config.home.homeDirectory}/.local/share/opencode-${projectName}";
  };

  # Generate budgey registry entry for a project
  mkBudgeyEntry = name: project: let
    paths = mkProjectPaths name;
    id = builtins.hashString "sha1" project.workdir;

    # Build budgets object with only non-null values
    budgets =
      {}
      // optionalAttrs (project.budgey.budgets.weeklyUsd != null) {
        weekly_usd = project.budgey.budgets.weeklyUsd;
      }
      // optionalAttrs (project.budgey.budgets.monthlyUsd != null) {
        monthly_usd = project.budgey.budgets.monthlyUsd;
      };

    # Use budgey path overrides if set, otherwise use computed paths
    configDir =
      if project.budgey.configDir != null
      then project.budgey.configDir
      else paths.config;

    stateDir =
      if project.budgey.stateDir != null
      then project.budgey.stateDir
      else paths.state;

    dataDir =
      if project.budgey.dataDir != null
      then project.budgey.dataDir
      else paths.data;
  in
    {
      inherit id name;
      root = project.workdir;
      opencode_config_dir = configDir;
      xdg_config_home = configDir;
      xdg_state_home = stateDir;
      xdg_data_home = dataDir;
    }
    // optionalAttrs (budgets != {}) {inherit budgets;}
    // optionalAttrs (project.budgey.tags != []) {tags = project.budgey.tags;};

  # Filter projects with budgey.enable = true
  budgeyProjects = filterAttrs (_: p: p.budgey.enable) cfg.projects;

  # Build project entries from configured projects
  projectEntries = mapAttrsToList (name: project: mkBudgeyEntry name project) budgeyProjects;

  # Default project entry for interactive sessions
  defaultProjectEntry = let
    homeDir = config.home.homeDirectory;
    id = builtins.hashString "sha1" homeDir;
    budgets =
      {}
      // optionalAttrs (cfg.budgey.defaultProject.budgets.weeklyUsd != null) {
        weekly_usd = cfg.budgey.defaultProject.budgets.weeklyUsd;
      }
      // optionalAttrs (cfg.budgey.defaultProject.budgets.monthlyUsd != null) {
        monthly_usd = cfg.budgey.defaultProject.budgets.monthlyUsd;
      };
  in
    {
      inherit id;
      name = "default";
      root = homeDir;
      opencode_config_dir = "${homeDir}/.config/opencode";
      xdg_config_home = "${homeDir}/.config/opencode";
      xdg_state_home = "${homeDir}/.local/state/opencode";
      xdg_data_home = "${homeDir}/.local/share/opencode";
    }
    // optionalAttrs (budgets != {}) {inherit budgets;}
    // optionalAttrs (cfg.budgey.defaultProject.tags != []) {tags = cfg.budgey.defaultProject.tags;};

  # Combine project entries with optional default project
  allProjects =
    projectEntries
    ++ optionals cfg.budgey.defaultProject.enable [defaultProjectEntry];

  # Build the complete registry
  budgeyRegistry = {
    version = "1.0";
    projects = allProjects;
  };

  # Check if we have any projects to include
  hasProjects = budgeyProjects != {} || cfg.budgey.defaultProject.enable;
in {
  options.ruinous.ruinage.budgey = {
    defaultProject = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Include a default project entry for interactive sessions.";
      };

      budgets = {
        weeklyUsd = mkOption {
          type = types.nullOr types.float;
          default = null;
          description = "Weekly budget limit in USD for default project.";
          example = 50.0;
        };

        monthlyUsd = mkOption {
          type = types.nullOr types.float;
          default = null;
          description = "Monthly budget limit in USD for default project.";
          example = 200.0;
        };
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Tags for the default project.";
        example = ["default" "interactive"];
      };
    };
  };

  config = mkIf (cfg.enable && hasProjects) {
    xdg.configFile."ruinagents/budgey/projects.json".text = builtins.toJSON budgeyRegistry;
  };
}
