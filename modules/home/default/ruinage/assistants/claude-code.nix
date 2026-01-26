# Claude Code Assistant Integration
#
# This module provides:
# - Global Claude Code settings (ruinous.ruinage.assistants.claude-code.*)
# - Harness configurations (ruinagents)
# - Per-project Claude Code context file deployment
#
# Claude Code (Anthropic) uses:
# - Global config: ~/.claude/
# - Context file: CLAUDE.md
# - Skills directory: ~/.claude/skills/
#
# Example:
#   ruinous.ruinage = {
#     enable = true;
#
#     # Global Claude Code configuration
#     assistants.claude-code = {
#       enable = true;
#       harnesses.ruinagents.enable = true;
#     };
#
#     # Per-project Claude Code
#     projects.nix-config = {
#       repo = "nix-config";
#       assistants.claude-code.enable = true;
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
  claudeCodeAssistant = cfg.assistants.claude-code or {};

  # Ruinagents package from flake input
  ruinagentsPkgs = flake.inputs.ruinagents.packages.${pkgs.system};
  ruinagentsClaudeCode = ruinagentsPkgs.claude-code;
  ruinagentsShare = "${ruinagentsClaudeCode}/.claude";

  # Ruinagents skill and command paths
  skillSourcePath = "${ruinagentsShare}/skills";
  skillNames =
    if builtins.pathExists skillSourcePath
    then builtins.filter (name: builtins.pathExists "${skillSourcePath}/${name}/SKILL.md") (builtins.attrNames (builtins.readDir skillSourcePath))
    else [];

  # Filter projects that have assistants.claude-code.enable = true
  claudeCodeProjects = filterAttrs (
    name: project:
      project.assistants.claude-code.enable or false
  ) (cfg.projects or {});
in {
  options.ruinous.ruinage.assistants.claude-code = {
    enable = mkEnableOption "Claude Code assistant configuration management";

    harnesses = {
      ruinagents = {
        enable = mkEnableOption "ruinagents harness for Claude Code (CLAUDE.md, skills)";
      };
    };
  };

  config = mkIf ((cfg.enable or false) && (claudeCodeAssistant.enable or false)) (mkMerge [
    # Global ruinagents files for Claude Code
    (mkIf (claudeCodeAssistant.harnesses.ruinagents.enable or false) {
      home.file = let
        configDir = "${config.home.homeDirectory}/.claude";
        skillLinks = builtins.listToAttrs (map (skill: {
            name = "${configDir}/skills/${skill}/SKILL.md";
            value = {source = "${skillSourcePath}/${skill}/SKILL.md";};
          })
          skillNames);
      in
        {
          "${configDir}/CLAUDE.md".source = "${ruinagentsShare}/CLAUDE.md";
        }
        // skillLinks;
    })

    # Per-project Claude Code context files
    (mkIf (claudeCodeProjects != {} && (claudeCodeAssistant.harnesses.ruinagents.enable or false)) {
      home.file = foldAttrs (a: b: a // b) {} (map (
        name: let
          project = cfg.projects.${name};
          projectDir = project.workdir;
          # Project-level skills symlinks
          projectSkillLinks = builtins.listToAttrs (map (skill: {
              name = "${projectDir}/.claude/skills/${skill}/SKILL.md";
              value = {source = "${skillSourcePath}/${skill}/SKILL.md";};
            })
            skillNames);
        in
          {
            # Project-level CLAUDE.md
            "${projectDir}/.claude/CLAUDE.md".source = "${ruinagentsShare}/CLAUDE.md";
          }
          // projectSkillLinks
      ) (attrNames claudeCodeProjects));
    })
  ]);
}
