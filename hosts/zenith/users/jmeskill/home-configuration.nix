{
  flake,
  config,
  pkgs,
  lib,
  ...
}: let
  mcpConfigDir = ../../../../hosts/zenith/files/docker/mcp;
in {
  imports = [
    flake.homeModules.default
  ];

  ruinous.rust-motd.enable = true;
  ruinous.openssh.tmux.attach.enable = true;
  ruinous.openssh.remote.forwarding.enable = true;

  home.file.".docker/cli-plugins/docker-mcp".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.docker-mcp-gateway}/bin/docker-mcp";

  home.activation.mcpConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.docker/mcp/catalogs"
    cp -f ${mcpConfigDir}/catalogs/farm-catalog.yaml "$HOME/.docker/mcp/catalogs/farm-catalog.yaml"
    cp -f ${mcpConfigDir}/config.yaml "$HOME/.docker/mcp/config.yaml"
    cp -f ${mcpConfigDir}/registry.yaml "$HOME/.docker/mcp/registry.yaml"
    cp -f ${mcpConfigDir}/tools.yaml "$HOME/.docker/mcp/tools.yaml"
  '';

  # Git config - use zenith-specific defaults for all repos
  ruinous.git.default = {
    userEmail = "jade@ruinous.ai";
    signingKey = "/home/jmeskill/.ssh/id_codey_ed25519";
  };

  ruinous.ai-cli = {
    gemini = {
      enable = true;
      email = "jadeisfalling@gmail.com";
    };
    claude-code = {
      enable = true;
    };
    opencode = {
      enable = true;
      notifier.enable = true;
    };
    opencode-web = {
      enable = true;
      package = flake.inputs.llm-agents.packages.${pkgs.system}.opencode;
      packages = with pkgs; [
        uv # Provides uvx for Python-based MCP servers
        pnpm # For JavaScript-based MCP servers
        nodejs # Node.js runtime for MCP servers
        bun
      ];
      services = {
        "nix-config" = {
          projectPath = "/home/jmeskill/Projects/ruinous.ai/nix-config";
          port = 18080;
          logLevel = "WARN";
          cors = ["zenith.meskill.farm"];
        };
        "n8n-agent" = {
          projectPath = "/home/jmeskill/Projects/ruinous.ai/n8n-agent";
          port = 18081;
          logLevel = "WARN";
          cors = ["zenith.meskill.farm"];
        };
        "dossiq-ai" = {
          projectPath = "/home/jmeskill/Projects/ruinous.ai/dossiq-ai";
          port = 18082;
          logLevel = "WARN";
          cors = ["zenith.meskill.farm"];
        };
      };
    };
    kimaki = {
      enable = true;
      opencodePackage = flake.inputs.llm-agents.packages.${pkgs.system}.opencode;
      packages = with pkgs; [
        uv # Provides uvx for Python-based MCP servers
        pnpm # For JavaScript-based MCP servers
        nodejs # Node.js runtime for MCP servers
        bun
      ];
    };
  };

  home.stateVersion = "26.05";
}
