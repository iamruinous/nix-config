# Ruinage Project Processing
#
# This module handles:
# - Project option definitions (ruinous.ruinage.projects)
# - Auto-clone activation script
# - Project path resolution
#
# Projects are defined by their git repository and can be cloned to
# multiple namespaces (ruinage, kimaki) for different use cases.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage;
in {
  options.ruinous.ruinage = {
    projects = mkOption {
      type = types.attrsOf types.anything; # Will be refined in TODO 3
      default = {};
      description = ''
        Repository-first project definitions.
        Each project is keyed by name and defines:
        - Repository coordinates (repo, owner, forge)
        - Namespace enablement (ruinage, kimaki)
        - Assistant configurations (opencode, kimaki, etc.)
      '';
      example = literalExpression ''
        {
          nix-config = {
            repo = "nix-config";
            owner = "iamruinous";
            forge = "github.com";
            namespaces.ruinage.enable = true;
            assistants.opencode.enable = true;
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Project processing and auto-clone will be implemented in TODO 4
  };
}
