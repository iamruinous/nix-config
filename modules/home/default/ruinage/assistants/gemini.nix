# Gemini CLI Assistant Integration
#
# This module provides:
# - Global Gemini settings (ruinous.ruinage.assistants.gemini.*)
# - Harness configurations (ruinagents)
# - Per-project Gemini context file deployment
# - Custom context file discovery (AGENTS.md support)
#
# Gemini CLI (Google) uses:
# - Global config: ~/.gemini/
# - Context file: GEMINI.md (we extend to also discover AGENTS.md)
# - Skills directory: ~/.gemini/skills/
# - Settings: ~/.gemini/settings.json
#
# Example:
#   ruinous.ruinage = {
#     enable = true;
#
#     # Global Gemini configuration
#     assistants.gemini = {
#       enable = true;
#       harnesses.ruinagents.enable = true;
#     };
#
#     # Per-project Gemini
#     projects.nix-config = {
#       repo = "nix-config";
#       assistants.gemini.enable = true;
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
  geminiAssistant = cfg.assistants.gemini or {};

  # Ruinagents package from flake input
  ruinagentsPkgs = flake.inputs.ruinagents.packages.${pkgs.system};
  ruinagentsGemini = ruinagentsPkgs.gemini;
  ruinagentsShare = "${ruinagentsGemini}/.gemini";

  # Ruinagents skill and command paths
  skillSourcePath = "${ruinagentsShare}/skills";
  skillNames =
    if builtins.pathExists skillSourcePath
    then builtins.filter (name: builtins.pathExists "${skillSourcePath}/${name}/SKILL.md") (builtins.attrNames (builtins.readDir skillSourcePath))
    else [];

  # Filter projects that have assistants.gemini.enable = true
  geminiProjects = filterAttrs (
    name: project:
      project.assistants.gemini.enable or false
  ) (cfg.projects or {});

  # Global settings.json for Gemini CLI
  # Configures context file discovery to include AGENTS.md (agents.md spec)
  # alongside the default GEMINI.md
  globalSettings = {
    context = {
      # Load both AGENTS.md and GEMINI.md as context files
      # AGENTS.md follows the agents.md spec (https://agents.md/)
      # GEMINI.md is the Gemini CLI default
      fileName = ["AGENTS.md" "GEMINI.md"];
    };
  };
in {
  options.ruinous.ruinage.assistants.gemini = {
    enable = mkEnableOption "Gemini CLI assistant configuration management";

    harnesses = {
      ruinagents = {
        enable = mkEnableOption "ruinagents harness for Gemini CLI (GEMINI.md, skills)";
      };
    };
  };

  config = mkIf ((cfg.enable or false) && (geminiAssistant.enable or false)) (mkMerge [
    # Global ruinagents files for Gemini
    (mkIf (geminiAssistant.harnesses.ruinagents.enable or false) {
      home.file = let
        configDir = "${config.home.homeDirectory}/.gemini";
        skillLinks = builtins.listToAttrs (map (skill: {
            name = "${configDir}/skills/${skill}/SKILL.md";
            value = {source = "${skillSourcePath}/${skill}/SKILL.md";};
          })
          skillNames);
      in
        {
          "${configDir}/GEMINI.md".source = "${ruinagentsShare}/GEMINI.md";
          # Global settings.json with AGENTS.md context discovery
          "${configDir}/settings.json".text = builtins.toJSON globalSettings;
        }
        // skillLinks;
    })

    # Per-project Gemini context files
    (mkIf (geminiProjects != {} && (geminiAssistant.harnesses.ruinagents.enable or false)) {
      home.file = foldAttrs (a: b: a // b) {} (map (
        name: let
          project = cfg.projects.${name};
          projectDir = project.workdir;
          # Project-level skills symlinks
          projectSkillLinks = builtins.listToAttrs (map (skill: {
              name = "${projectDir}/.gemini/skills/${skill}/SKILL.md";
              value = {source = "${skillSourcePath}/${skill}/SKILL.md";};
            })
            skillNames);
        in
          {
            # Project-level GEMINI.md
            "${projectDir}/.gemini/GEMINI.md".source = "${ruinagentsShare}/GEMINI.md";
          }
          // projectSkillLinks
      ) (attrNames geminiProjects));
    })
  ]);
}
