# Gemini CLI Assistant Integration
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
  globalSettings = {
    context = {
      fileName = ["AGENTS.md" "GEMINI.md"];
    };
  };
  globalSettingsJson = builtins.toJSON globalSettings;

in {
  options.ruinous.ruinage.assistants.gemini = {
    enable = mkEnableOption "Gemini CLI assistant configuration management";
    harnesses.ruinagents.enable = mkEnableOption "ruinagents harness for Gemini CLI (GEMINI.md, skills)";
  };

  config = mkIf ((cfg.enable or false) && (geminiAssistant.enable or false)) {
    # Manage global files and activation script
    home.file =
      # Global ruinagents files for Gemini
      (
        if (geminiAssistant.harnesses.ruinagents.enable or false)
        then let
          configDir = "${config.home.homeDirectory}/.gemini";
          skillLinks = builtins.listToAttrs (map (
            skill: {
              name = "${configDir}/skills/${skill}/SKILL.md";
              value = {source = "${skillSourcePath}/${skill}/SKILL.md";};
            }
          ) skillNames);
        in
          {
            "${configDir}/GEMINI.md".source = "${ruinagentsGemini}/GEMINI.md";
          }
          // skillLinks
        else {}
      )
      # Per-project Gemini context files
      // (
        if (geminiProjects != {} && (geminiAssistant.harnesses.ruinagents.enable or false))
        then
          foldAttrs (a: b: a // b) {} (
            map (
              name:
                let
                  project = cfg.projects.${name};
                  projectDir = project.workdir;
                  projectSkillLinks = listToAttrs (map (
                    skill: {
                      name = "${projectDir}/.gemini/skills/${skill}/SKILL.md";
                      value = {source = "${skillSourcePath}/${skill}/SKILL.md";};
                    }
                  ) skillNames);
                in
                  {
                    "${projectDir}/.gemini/GEMINI.md".source = "${ruinagentsShare}/GEMINI.md";
                  }
                  // projectSkillLinks
            )
            (attrNames geminiProjects)
          )
        else {}
      );

    home.activation.manage-gemini-settings =
      mkIf (geminiAssistant.harnesses.ruinagents.enable or false)
      (lib.hm.dag.entryAfter ["writeBoundary"] ''
        CONFIG_DIR="${config.home.homeDirectory}/.gemini"
        CONFIG_FILE="$CONFIG_DIR/settings.json"
        BACKUP_FILE="$CONFIG_FILE.nix-deployed"
        NIX_CONTENT='${globalSettingsJson}'

        $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"

        # If config exists and has changed since last deploy, warn the user.
        if [ -f "$CONFIG_FILE" ] && [ -f "$BACKUP_FILE" ] && ! diff -q "$BACKUP_FILE" <(echo "$NIX_CONTENT") > /dev/null 2>&1; then
            echo " "
            echo "------------------------------------------------------------------------"
            echo "⚠️  WARNING: Runtime changes detected in $CONFIG_FILE"
            echo "------------------------------------------------------------------------"
            echo "Nix is overwriting the file with its configured version."
            echo "To preserve your changes, add them to your Nix configuration."
            echo "Diff:"
            diff --color=always -u "$BACKUP_FILE" "$CONFIG_FILE" || true
            echo "------------------------------------------------------------------------"
            echo " "
        fi

        # Always write the Nix-defined content to the file and the backup.
        echo "$NIX_CONTENT" > "$CONFIG_FILE"
        echo "$NIX_CONTENT" > "$BACKUP_FILE"
      '');
  };
}
