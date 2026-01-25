# Ruinage Direnv Integration
#
# This module generates direnv snippets for projects with direnv.enable = true.
# For each project:
# - Generates snippet at ~/.config/direnv/envrc.d/<name>.sh
# - Auto-injects into .envrc.local if direnv.autoInject = true
# - For OpenCode web projects, creates an `opencode` wrapper function that auto-attaches
#
# Snippet format sources environmentFiles using direnv's dotenv command.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage;
  ruinageLib = import ../../../../lib/ruinage/wrapper.nix { inherit lib pkgs; };

  # Filter projects that have direnv enabled
  projectsWithDirenv = filterAttrs (_: p:
    p.direnv.enable && (p.environmentFiles != [] || cfg.environmentFiles != [])
  ) cfg.projects;

  # Filter projects with opencode web service enabled (for port assignment)
  opencodeWebProjects = filterAttrs (_: p:
    p.assistants.opencode.enable or false
    && p.assistants.opencode.web.enable or false
  ) cfg.projects;

  # Auto-assign ports starting from 9500 (must match opencode.nix logic)
  sortedOpencodeNames = sort (a: b: a < b) (attrNames opencodeWebProjects);
  projectPortMap = listToAttrs (imap0 (idx: projectName: {
    name = projectName;
    value = 9500 + idx;
  }) sortedOpencodeNames);

  # Get effective port for a project
  getProjectPort = projectName: project:
    if project.assistants.opencode.web.port != null
    then project.assistants.opencode.web.port
    else projectPortMap.${projectName} or null;

  # Generate direnv snippet for a project
  # Snippet uses direnv's dotenv command to load environment files
  mkDirenvSnippet = name: project: let
    # Combine global and per-project env files
    allEnvFiles = cfg.environmentFiles ++ project.environmentFiles;
    # Extract secret names from paths (e.g., /path/to/agenix/secret_name -> secret_name)
    secretNames = map (p: baseNameOf (toString p)) allEnvFiles;
    # Generate dotenv commands for each secret
    dotenvCommands = concatMapStringsSep "\n" (secretName: ''
      # Load ${secretName} if available
      if [[ -f "${cfg.direnv.secretsDir}/${secretName}" ]]; then
        dotenv "${cfg.direnv.secretsDir}/${secretName}"
      fi'') secretNames;

    # Check if this project has opencode web service
    hasOpencodeWeb = project.assistants.opencode.enable or false
      && project.assistants.opencode.web.enable or false;
    port = getProjectPort name project;

    # OpenCode wrapper function for auto-attach
    # Uses the ruinage workdir (~/Projects/ruinage/<repo>) as working directory
    opencodeWrapper = optionalString hasOpencodeWeb ''

      # OpenCode auto-attach wrapper for project: ${name}
      # When run without arguments, attaches to the running web service
      # Uses ruinage workdir: ${project.workdir}
      opencode() {
        if [[ $# -gt 0 ]]; then
          command opencode "$@"
        else
          cd "${project.workdir}" || return 1
          export OPENCODE_CONFIG_DIR="${config.home.homeDirectory}/.config/opencode-${name}"
          export XDG_CACHE_HOME="${config.home.homeDirectory}/.cache/opencode-${name}"
          export XDG_STATE_HOME="${config.home.homeDirectory}/.local/state/opencode-${name}"
          export XDG_DATA_HOME="${config.home.homeDirectory}/.local/share/opencode-${name}"
          command opencode attach "http://localhost:${toString port}" "$@"
        fi
      }
    '';
  in ''
    # Auto-generated direnv snippet for project: ${name}
    # Source this in your project's .envrc:
    #   source_env ~/.config/direnv/envrc.d/${name}.sh
    #
    # Or add to .envrc.local:
    #   source ~/.config/direnv/envrc.d/${name}.sh

    ${dotenvCommands}
    ${opencodeWrapper}
  '';
in {
  # Auto-enable when any project has direnv enabled, or when explicitly enabled
  config = mkIf (cfg.direnv.enable || projectsWithDirenv != {}) {
    # Generate direnv snippets in ~/.config/direnv/envrc.d/
    xdg.configFile = mapAttrs' (name: project:
      nameValuePair "direnv/envrc.d/${name}.sh" {
        text = mkDirenvSnippet name project;
        executable = false;
      }) projectsWithDirenv;

    # Auto-inject source line into .envrc.local for each project
    home.activation.injectDirenvSnippets = lib.mkIf cfg.direnv.autoInject (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        ${concatMapStringsSep "\n" (name: let
          project = projectsWithDirenv.${name};
          snippetPath = "${config.home.homeDirectory}/.config/direnv/envrc.d/${name}.sh";
          projectPath = ruinageLib.mkProjectPath {
            homeDirectory = config.home.homeDirectory;
            namespace = "ruinage";
            repo = project.repo;
          };
          envrcLocal = "${projectPath}/.envrc.local";
          sourceLine = "source_env ${snippetPath}";
          markerComment = "# ruinage: auto-injected";
        in ''
          # Project: ${name}
          if [ -d "${projectPath}" ]; then
            # Check if .envrc.local exists and already has our source line
            if [ -f "${envrcLocal}" ]; then
              if ! ${pkgs.gnugrep}/bin/grep -qF "${sourceLine}" "${envrcLocal}"; then
                $VERBOSE_ECHO "ruinage: injecting direnv snippet into ${name}/.envrc.local"
                echo "" >> "${envrcLocal}"
                echo "${markerComment}" >> "${envrcLocal}"
                echo "${sourceLine}" >> "${envrcLocal}"
              fi
            else
              $VERBOSE_ECHO "ruinage: creating ${name}/.envrc.local with direnv snippet"
              echo "${markerComment}" > "${envrcLocal}"
              echo "${sourceLine}" >> "${envrcLocal}"
            fi
          fi
        '') (attrNames projectsWithDirenv)}
      ''
    );
  };
}
