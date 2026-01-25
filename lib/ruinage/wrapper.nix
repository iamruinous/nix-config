# Shared library for Ruinage services (opencode, kimaki, claude-code, gemini, codex)
#
# This module provides common functionality for AI assistant services:
# - Default packages for MCP server dependencies
# - Builtin packages required for OpenCode functionality
# - Wrapped OpenCode derivation with proper PATH and NIX_LD setup
# - Systemd environment configuration helpers
# - Auth symlink helpers for isolated data directories
# - Git URL construction and parsing for repository management
#
# Usage:
#   let
#     ruinageLib = import ../../lib/ruinage/wrapper.nix { inherit lib pkgs; };
#   in {
#     # Use default packages
#     packages = ruinageLib.defaultPackages;
#
#     # Create wrapped opencode
#     wrappedOpencode = ruinageLib.mkWrappedOpencode {
#       package = llmAgentsPkgs.opencode;
#       extraPackages = cfg.packages;
#     };
#
#     # Build systemd environment
#     environment = ruinageLib.mkSystemdEnvironment {
#       homeDirectory = config.home.homeDirectory;
#       packages = builtinPackages ++ cfg.packages;
#       configDir = cfg.configDir;
#       cacheDir = cfg.cacheDir;
#       stateDir = cfg.stateDir;
#       dataDir = cfg.dataDir;
#       includeSystemPath = cfg.includeSystemPath;
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

  # Default packages for service functionality (tools available in PATH)
  # These are common dependencies for MCP servers and general CLI operations
  defaultPackages = with pkgs; [
    # VCS and forge tools
    gh
    tea
    cloudflare-cli

    # Data processing and search
    ripgrep
    jq
    fd
    miller
    yq-go

    # Python ecosystem
    python3
    uv # provides uv/uvx

    # Node.js ecosystem
    nodejs # provides node + npm
    pnpm
    bun

    # Container tools
    docker

    # Build tools
    gnumake # postgres-mcp and general builds
  ];

  # Packages that are always needed for OpenCode functionality
  # These are essential and should not be removed
  builtinPackages = with pkgs; [
    git # Git is essential for opencode's VCS operations
    openssh # SSH for git operations and signing
    nodejs # Node.js runtime for MCP servers and kimaki
  ];

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

  # Create a wrapped OpenCode with all necessary environment setup
  # This ensures tools are available in PATH and NIX_LD is configured for dynamic linking
  mkWrappedOpencode = {
    package,
    extraPackages ? [],
  }: let
    ldLibPath = "${lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib]}:/run/current-system/sw/share/nix-ld/lib";
  in
    pkgs.symlinkJoin {
      name = "opencode-wrapped";
      paths = [package];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/opencode \
          --prefix PATH : ${lib.makeBinPath (builtinPackages ++ extraPackages)} \
          --set NIX_LD /run/current-system/sw/share/nix-ld/lib/ld.so \
          --set NIX_LD_LIBRARY_PATH ${ldLibPath} \
          --set LD_LIBRARY_PATH ${ldLibPath} \
          --set OPENCODE_LIBC ${pkgs.glibc}/lib/libc.so.6
      '';
    };

  # Build the PATH string for systemd services
  # Includes builtin packages, extra packages, and optionally system/user profile paths
  mkPath = {
    extraPackages ? [],
    includeSystemPath ? true,
    prependPaths ? [], # Additional paths to prepend (e.g., wrapped opencode bin)
  }: let
    prependStr =
      if prependPaths != []
      then (lib.concatStringsSep ":" prependPaths) + ":"
      else "";
    basePath = lib.makeBinPath (builtinPackages ++ extraPackages);
    systemPaths =
      if includeSystemPath
      then "/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:/usr/bin:/bin"
      else "/run/current-system/sw/bin:/usr/bin:/bin";
  in "${prependStr}${basePath}:${systemPaths}";

  # Build systemd Environment list for OpenCode-based services
  # This handles PATH, NIX_LD, and XDG directories consistently
  mkSystemdEnvironment = {
    homeDirectory,
    extraPackages ? [],
    configDir ? null,
    cacheDir ? null,
    stateDir ? null,
    dataDir ? null,
    includeSystemPath ? true,
    prependPaths ? [], # Additional paths to prepend (e.g., wrapped opencode bin)
    extraEnv ? [],
  }: let
    ldLibraryPath = "${lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib]}:/run/current-system/sw/share/nix-ld/lib";
  in
    [
      "HOME=${homeDirectory}"
      "TERM=xterm-256color"
      "PATH=${mkPath {inherit extraPackages includeSystemPath prependPaths;}}"
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
    defaultPackages
    builtinPackages
    mkGitUrl
    parseGitUrl
    mkProjectPath
    mkWrappedOpencode
    mkPath
    mkSystemdEnvironment
    mkAuthSymlinks
    ;
}
