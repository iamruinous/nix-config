# Shared library for Ruinage services (opencode, kimaki, claude-code, gemini, codex)
#
# This module provides common functionality for AI assistant services:
# - Wrapped OpenCode derivation with NIX_LD setup for dynamic linking
# - Systemd environment configuration (PATH includes system/user profiles)
# - Auth symlink helpers for isolated data directories
# - Git URL construction and parsing for repository management
#
# Usage:
#   let
#     ruinageLib = import ../../lib/ruinage/wrapper.nix { inherit lib pkgs; };
#   in {
#     # Create wrapped opencode with NIX_LD
#     wrappedOpencode = ruinageLib.mkWrappedOpencode {
#       package = llmAgentsPkgs.opencode;
#     };
#
#     # Build systemd environment (PATH includes all system/user packages)
#     environment = ruinageLib.mkSystemdEnvironment {
#       homeDirectory = config.home.homeDirectory;
#       configDir = cfg.configDir;
#     };
#
#     # Construct git SSH URL
#     url = ruinageLib.mkGitUrl {
#       owner = "iamruinous";
#       repo = "nix-config";
#       forge = "github.com";
#     };
#     # => "ssh://git@github.com/iamruinous/nix-config.git"
#   }
{
  lib,
  pkgs,
}: let
  # Default forge for repositories (used when not specified)
  defaultForge = "forge.meskill.farm";

  # Construct a git SSH URL from components
  # mkGitUrl { owner = "iamruinous"; repo = "test"; } => "ssh://git@forge.meskill.farm/iamruinous/test.git"
  # mkGitUrl { owner = "iamruinous"; repo = "test"; forge = "github.com"; } => "ssh://git@github.com/iamruinous/test.git"
  mkGitUrl = {
    owner,
    repo,
    forge ? defaultForge,
  }:
    "ssh://git@${forge}/${owner}/${repo}.git";

  # Parse a git URL into components
  # Supports SSH URLs: ssh://git@github.com/owner/repo.git
  # Supports SCP-style: git@github.com:owner/repo.git
  # Supports HTTPS: https://github.com/owner/repo.git
  # Returns: { forge, owner, repo } or null if parsing fails
  parseGitUrl = url: let
    # SSH URL format: ssh://git@host/owner/repo.git
    sshMatch = builtins.match "ssh://git@([^/]+)/([^/]+)/([^/]+)\\.git" url;
    # SCP-style format: git@host:owner/repo.git
    scpMatch = builtins.match "git@([^:]+):([^/]+)/([^/]+)\\.git" url;
    # HTTPS format: https://host/owner/repo.git
    httpsMatch = builtins.match "https://([^/]+)/([^/]+)/([^/]+)\\.git" url;
    # HTTPS without .git: https://host/owner/repo
    httpsNoGitMatch = builtins.match "https://([^/]+)/([^/]+)/([^/]+)" url;
  in
    if sshMatch != null
    then {
      forge = builtins.elemAt sshMatch 0;
      owner = builtins.elemAt sshMatch 1;
      repo = builtins.elemAt sshMatch 2;
    }
    else if scpMatch != null
    then {
      forge = builtins.elemAt scpMatch 0;
      owner = builtins.elemAt scpMatch 1;
      repo = builtins.elemAt scpMatch 2;
    }
    else if httpsMatch != null
    then {
      forge = builtins.elemAt httpsMatch 0;
      owner = builtins.elemAt httpsMatch 1;
      repo = builtins.elemAt httpsMatch 2;
    }
    else if httpsNoGitMatch != null
    then {
      forge = builtins.elemAt httpsNoGitMatch 0;
      owner = builtins.elemAt httpsNoGitMatch 1;
      repo = builtins.elemAt httpsNoGitMatch 2;
    }
    else null;

  # Construct project path for a namespace
  # mkProjectPath { homeDirectory = "/home/user"; namespace = "ruinage"; repo = "nix-config"; }
  # => "/home/user/Projects/ruinage/nix-config"
  mkProjectPath = {
    homeDirectory,
    namespace,
    repo,
  }:
    "${homeDirectory}/Projects/${namespace}/${repo}";

  # Create a wrapped OpenCode with NIX_LD configured for dynamic linking
  mkWrappedOpencode = {
    package,
  }: let
    ldLibPath = "${lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib]}:/run/current-system/sw/share/nix-ld/lib";
  in
    pkgs.symlinkJoin {
      name = "opencode-wrapped";
      paths = [package];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/opencode \
          --set NIX_LD /run/current-system/sw/share/nix-ld/lib/ld.so \
          --set NIX_LD_LIBRARY_PATH ${ldLibPath} \
          --set LD_LIBRARY_PATH ${ldLibPath} \
          --set OPENCODE_LIBC ${pkgs.glibc}/lib/libc.so.6
      '';
    };

  # Build the PATH string for systemd services
  # System and user profile paths provide all installed packages
  mkPath = {
    prependPaths ? [], # Additional paths to prepend (e.g., wrapped opencode bin)
    username, # Username for per-user profile path (required)
  }: let
    prependStr =
      if prependPaths != []
      then (lib.concatStringsSep ":" prependPaths) + ":"
      else "";
    # Use literal username since systemd doesn't expand shell variables
    userProfilePath = "/etc/profiles/per-user/${username}/bin";
    systemPaths = "/run/current-system/sw/bin:${userProfilePath}:/usr/bin:/bin";
  in "${prependStr}${systemPaths}";

  # Build systemd Environment list for OpenCode-based services
  # This handles PATH, NIX_LD, and XDG directories consistently
  mkSystemdEnvironment = {
    homeDirectory,
    configDir ? null,
    cacheDir ? null,
    stateDir ? null,
    dataDir ? null,
    prependPaths ? [], # Additional paths to prepend (e.g., wrapped opencode bin)
    extraEnv ? [],
  }: let
    ldLibraryPath = "${lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib]}:/run/current-system/sw/share/nix-ld/lib";
    # Extract username from homeDirectory (e.g., "/home/jmeskill" -> "jmeskill")
    username = builtins.baseNameOf homeDirectory;
  in
    [
      "HOME=${homeDirectory}"
      "TERM=xterm-256color"
      "PATH=${mkPath {inherit prependPaths username;}}"
      "NIX_LD=/run/current-system/sw/share/nix-ld/lib/ld.so"
      "NIX_LD_LIBRARY_PATH=${ldLibraryPath}"
      "LD_LIBRARY_PATH=${ldLibraryPath}"
    ]
    ++ lib.optionals (configDir != null) [
      "OPENCODE_CONFIG_DIR=${configDir}"
    ]
    ++ lib.optionals (cacheDir != null) [
      "XDG_CACHE_HOME=${cacheDir}"
    ]
    ++ lib.optionals (stateDir != null) [
      "XDG_STATE_HOME=${stateDir}"
    ]
    ++ lib.optionals (dataDir != null) [
      "XDG_DATA_HOME=${dataDir}"
    ]
    ++ extraEnv;

  # Create home.file entries for auth symlinks when using isolated dataDir
  # This allows services to share authentication tokens with interactive opencode
  # Note: OpenCode stores auth in XDG_DATA_HOME (~/.local/share/opencode/), not XDG_STATE_HOME
  mkAuthSymlinks = {
    dataDir,
    homeDirectory,
    mkOutOfStoreSymlink,
  }: {
    "${dataDir}/opencode/auth.json".source =
      mkOutOfStoreSymlink "${homeDirectory}/.local/share/opencode/auth.json";
    "${dataDir}/opencode/mcp-auth.json".source =
      mkOutOfStoreSymlink "${homeDirectory}/.local/share/opencode/mcp-auth.json";
  };
in {
  inherit
    defaultForge
    mkGitUrl
    parseGitUrl
    mkProjectPath
    mkWrappedOpencode
    mkPath
    mkSystemdEnvironment
    mkAuthSymlinks
    ;
}
