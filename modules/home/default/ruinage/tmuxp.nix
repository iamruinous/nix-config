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

  # Generate a tmuxp session for a project
  mkTmuxpSession = name: project: let
    hasWebService = projectHasWeb project;
    projectPath = ruinageLib.mkProjectPath {
      homeDirectory = config.home.homeDirectory;
      namespace = "ruinage";
      repo = project.repo;
    };
   in {
     startDirectory = projectPath;

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
           {
             name = "attach";
             command = "opencode attach http://localhost:${toString project.assistants.opencode.port}";
             focus = true;
           }
         ]
         else [
           # No web service, run server in tmux
           {
             name = "server";
             command = "opencode serve --print-logs --hostname ${project.assistants.opencode.hostname} --port ${toString project.assistants.opencode.port}";
           }
           {
             name = "attach";
             command = "sleep 2 && opencode attach http://localhost:${toString project.assistants.opencode.port}";
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

  # Filter projects that have tmuxp enabled in ruinage namespace
  tmuxpProjects = filterAttrs (name: project:
    project.namespaces.ruinage.enable
    && project.tmuxp.enable
    && project.assistants.opencode.enable
  ) cfg.projects;

   # Generate all tmuxp sessions
   tmuxpSessions = mapAttrs mkTmuxpSession tmuxpProjects;
in {
  config = mkIf (tmuxpProjects != {}) {
    ruinous.tmuxp.sessions = tmuxpSessions;
  };
}
