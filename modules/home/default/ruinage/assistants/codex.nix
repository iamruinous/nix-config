# Codex CLI Assistant Integration
#
# This module provides:
# - Global Codex settings (ruinous.ruinage.assistants.codex.*)
# - Harness configurations (ruinagents)
# - Per-project Codex context file deployment
#
# Codex CLI (OpenAI) uses:
# - Global config: ~/.codex/
# - Context file: AGENTS.md
# - Skills directory: ~/.codex/skills/
#
# Example:
#   ruinous.ruinage = {
#     enable = true;
#
#     # Global Codex configuration
#     assistants.codex = {
#       enable = true;
#       harnesses.ruinagents.enable = true;
#     };
#
#     # Per-project Codex
#     projects.nix-config = {
#       repo = "nix-config";
#       assistants.codex.enable = true;
#     };
#   };
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage;
  codexAssistant = cfg.assistants.codex or {};

  # Ruinagents package from flake input
  ruinagentsPkgs = flake.inputs.ruinagents.packages.${pkgs.system};
  ruinagentsCodex = ruinagentsPkgs.codex;
  ruinagentsShare = "${ruinagentsCodex}/.codex";

  # Ruinagents skill and command paths
  skillSourcePath = "${ruinagentsShare}/skills";
  skillNames =
    if builtins.pathExists skillSourcePath
    then builtins.filter (name: builtins.pathExists "${skillSourcePath}/${name}/SKILL.md") (builtins.attrNames (builtins.readDir skillSourcePath))
    else [];

  # Filter projects that have assistants.codex.enable = true
  codexProjects = filterAttrs (
    name: project:
      project.assistants.codex.enable or false
  ) (cfg.projects or {});
in {
  options.ruinous.ruinage.assistants.codex = {
    enable = mkEnableOption "Codex CLI assistant configuration management";

    harnesses = {
      ruinagents = {
        enable = mkEnableOption "ruinagents harness for Codex CLI (AGENTS.md, skills)";
      };
    };
  };

  config = mkIf ((cfg.enable or false) && (codexAssistant.enable or false)) (mkMerge [
    # Global ruinagents files for Codex
    (mkIf (codexAssistant.harnesses.ruinagents.enable or false) {
      home.file = let
        configDir = "${config.home.homeDirectory}/.codex";
        skillLinks = builtins.listToAttrs (map (skill: {
            name = "${configDir}/skills/${skill}/SKILL.md";
            value = {source = "${skillSourcePath}/${skill}/SKILL.md";};
          })
          skillNames);
      in
        {
          "${configDir}/AGENTS.md".source = "${ruinagentsShare}/AGENTS.md";
        }
        // skillLinks;
    })

    # Per-project Codex context files
    (mkIf (codexProjects != {} && (codexAssistant.harnesses.ruinagents.enable or false)) {
      home.file = foldAttrs (a: b: a // b) {} (map (
        name: let
          project = cfg.projects.${name};
          projectDir = project.workdir;
          # Project-level skills symlinks
          projectSkillLinks = builtins.listToAttrs (map (skill: {
              name = "${projectDir}/.codex/skills/${skill}/SKILL.md";
              value = {source = "${skillSourcePath}/${skill}/SKILL.md";};
            })
            skillNames);
        in
          {
            # Project-level AGENTS.md
            "${projectDir}/.codex/AGENTS.md".source = "${ruinagentsShare}/AGENTS.md";
          }
          // projectSkillLinks
      ) (attrNames codexProjects));
    })
  ]);
}
