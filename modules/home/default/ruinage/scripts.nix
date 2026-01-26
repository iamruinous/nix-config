# Ruinage OpenCode Wrapper Scripts
#
# This module generates shell-agnostic wrapper scripts for projects with OpenCode
# web service enabled. Each project gets a script at:
#   ~/.local/bin/opencode-<project-name>
#
# The scripts:
# - cd to the project workdir
# - Set project-specific XDG environment variables
# - Attach to the running OpenCode web service on the correct port
#
# This approach works regardless of shell (fish, bash, zsh) and is directly
# callable from tmuxp sessions.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage;

  # Filter projects with opencode web service enabled
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

  # Generate wrapper script for a project
  mkWrapperScript = name: project: let
    port = getProjectPort name project;
    homeDir = config.home.homeDirectory;
  in pkgs.writeShellScript "opencode-${name}" ''
    #!/usr/bin/env bash
    # Auto-generated OpenCode wrapper for project: ${name}
    # Attaches to the running web service with project-specific XDG paths

    cd "${project.workdir}" || exit 1

    export OPENCODE_CONFIG_DIR="${homeDir}/.config/opencode-${name}"
    export XDG_CACHE_HOME="${homeDir}/.cache/opencode-${name}"
    export XDG_STATE_HOME="${homeDir}/.local/state/opencode-${name}"
    export XDG_DATA_HOME="${homeDir}/.local/share/opencode-${name}"

    exec opencode attach "http://localhost:${toString port}" "$@"
  '';

in {
  config = mkIf (cfg.enable && opencodeWebProjects != {}) {
    # Install wrapper scripts to ~/.local/bin/
    home.file = mapAttrs' (name: project:
      nameValuePair ".local/bin/opencode-${name}" {
        source = mkWrapperScript name project;
        executable = true;
      }
    ) opencodeWebProjects;
  };
}
