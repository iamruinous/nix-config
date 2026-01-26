# Ruinage tmuxp Session Generator
#
# This module generates tmuxp sessions for ruinage projects with tmuxp.enable = true.
# Each session includes:
# - logs window (if web service is enabled)
# - attach window (for opencode attach)
# - editor window (nvim)
# - shell window
# - any extra windows defined in tmuxp.extraWindows
#
# Sessions use the ruinage namespace path as startDirectory.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage;
  ruinageLib = import ../../../../lib/ruinage/wrapper.nix { inherit lib pkgs; };

  # Helper to check if a project has web service enabled
  projectHasWeb = project:
    project.assistants.opencode.web.enable or false;

  # Filter projects that have tmuxp enabled
  tmuxpProjects = filterAttrs (name: project:
    project.tmuxp.enable
    && project.assistants.opencode.enable
  ) cfg.projects;

  # Auto-assign ports starting from 9500 for projects without explicit port
  # Sort project names for deterministic port assignment (must match opencode.nix logic)
  sortedProjectNames = sort (a: b: a < b) (attrNames tmuxpProjects);
  projectPortMap = listToAttrs (imap0 (idx: projectName: {
    name = projectName;
    value = 9500 + idx;
  }) sortedProjectNames);

  # Get effective port for a project
  getProjectPort = projectName: project:
    if project.assistants.opencode.web.port != null
    then project.assistants.opencode.web.port
    else projectPortMap.${projectName};

  # Generate a tmuxp session for a project
  mkTmuxpSession = name: project: let
    hasWebService = projectHasWeb project;
    webCfg = project.assistants.opencode.web;
    port = getProjectPort name project;
    projectPath = ruinageLib.mkProjectPath {
      homeDirectory = config.home.homeDirectory;
      namespace = "ruinage";
      repo = project.repo;
    };
    homeDir = config.home.homeDirectory;
    # Use the project-specific wrapper script from ~/.local/bin/
    # The script handles cd, XDG vars, and attaching to the correct port
    attachCommand = "${homeDir}/.local/bin/opencode-${name}";
   in {
     startDirectory = projectPath;

     # Auto-allow direnv once before session starts
     beforeScript = "direnv allow ${projectPath}";

     windows =
       (
         if hasWebService
         then [
           # Tail the systemd service logs
           {
             name = "logs";
             command = "journalctl --user -fu opencode-${name}.service";
           }
            # Web service is running via systemd, just attach to it
             # The direnv snippet's opencode() function handles XDG vars and port
             {
              name = "attach";
              command = attachCommand;
              focus = true;
            }
           ]
           else [
             # No web service - fallback to running server directly in tmux (uses default XDG paths)
             {
               name = "server";
               command = "opencode serve --print-logs --hostname ${webCfg.hostname} --port ${toString port}";
             }
             {
               name = "attach";
               command = "sleep 2 && opencode attach http://localhost:${toString port}";
               focus = true;
             }
           ]
       )
       ++ [
         {
           name = "editor";
           command = "nvim .";
         }
         {
           name = "shell";
         }
       ]
       ++ (map (window: {
         name = window.name;
         command = window.command;
         focus = window.focus or false;
       })
       project.tmuxp.extraWindows);
   };

   # Generate all tmuxp sessions
   tmuxpSessions = mapAttrs mkTmuxpSession tmuxpProjects;
in {
  config = mkIf (tmuxpProjects != {}) {
    ruinous.tmuxp.enable = true;
    ruinous.tmuxp.sessions = tmuxpSessions;
  };
}
