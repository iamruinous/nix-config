# Shared library for OpenCode-based services (opencode-web, kimaki)
#
# This module provides common functionality for services that wrap OpenCode:
# - Default packages for MCP server dependencies
# - Builtin packages required for OpenCode functionality
# - Wrapped OpenCode derivation with proper PATH and NIX_LD setup
# - Systemd environment configuration helpers
# - Auth symlink helpers for isolated state directories
#
# Usage:
#   let
#     opcodeLib = import ../../lib/opencode/wrapper.nix { inherit lib pkgs; };
#   in {
#     # Use default packages
#     packages = opcodeLib.defaultPackages;
#
#     # Create wrapped opencode
#     wrappedOpencode = opcodeLib.mkWrappedOpencode {
#       package = llmAgentsPkgs.opencode;
#       extraPackages = cfg.packages;
#     };
#
#     # Build systemd environment
#     environment = opcodeLib.mkSystemdEnvironment {
#       homeDirectory = config.home.homeDirectory;
#       packages = builtinPackages ++ cfg.packages;
#       configDir = cfg.configDir;
#       cacheDir = cfg.cacheDir;
#       stateDir = cfg.stateDir;
#       includeSystemPath = cfg.includeSystemPath;
#     };
#   }
{
  lib,
  pkgs,
}: let
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

  # Create a wrapped OpenCode with all necessary environment setup
  # This ensures tools are available in PATH and NIX_LD is configured for dynamic linking
  mkWrappedOpencode = {
    package,
    extraPackages ? [],
  }:
    pkgs.symlinkJoin {
      name = "opencode-wrapped";
      paths = [package];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/opencode \
          --prefix PATH : ${lib.makeBinPath (builtinPackages ++ extraPackages)} \
          --set NIX_LD /run/current-system/sw/share/nix-ld/lib/ld.so \
          --prefix NIX_LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib]} \
          --prefix NIX_LD_LIBRARY_PATH : /run/current-system/sw/share/nix-ld/lib \
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
    includeSystemPath ? true,
    prependPaths ? [], # Additional paths to prepend (e.g., wrapped opencode bin)
    extraEnv ? [],
  }:
    [
      "HOME=${homeDirectory}"
      "TERM=xterm-256color"
      "PATH=${mkPath {inherit extraPackages includeSystemPath prependPaths;}}"
      "NIX_LD=/run/current-system/sw/share/nix-ld/lib/ld.so"
      "NIX_LD_LIBRARY_PATH=${lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib]}:/run/current-system/sw/share/nix-ld/lib"
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
    ++ extraEnv;

  # Create home.file entries for auth symlinks when using isolated stateDir
  # This allows services to share authentication tokens with interactive opencode
  mkAuthSymlinks = {
    stateDir,
    homeDirectory,
    mkOutOfStoreSymlink,
  }: {
    "${stateDir}/opencode/auth.json".source =
      mkOutOfStoreSymlink "${homeDirectory}/.local/state/opencode/auth.json";
    "${stateDir}/opencode/mcp-auth.json".source =
      mkOutOfStoreSymlink "${homeDirectory}/.local/state/opencode/mcp-auth.json";
  };
in {
  inherit
    defaultPackages
    builtinPackages
    mkWrappedOpencode
    mkPath
    mkSystemdEnvironment
    mkAuthSymlinks
    ;
}
