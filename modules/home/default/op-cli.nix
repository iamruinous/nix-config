{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.ruinous.op-cli;
in {
  options.ruinous.op-cli = {
    enable = lib.mkEnableOption "0p-cli - Op management CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ruinous-0p-cli;
      defaultText = lib.literalExpression "pkgs.ruinous-0p-cli";
      description = "The 0p-cli package to use.";
    };

    opsDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Projects/.ops";
      description = "Directory for Op worktrees.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.local/share/0p";
      description = "Directory for Op state database.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    # Ensure directories exist
    home.file.${cfg.opsDir} = {
      source = builtins.toFile "empty" "";
      recursive = true;
    };

    # Shell integration - add aliases
    programs.bash.shellAliases = {
      "0p-new" = "0p new";
      "0p-ls" = "0p list";
      "0p-st" = "0p status";
      "0p-at" = "0p attach";
    };

    programs.fish.shellAliases = {
      "0p-new" = "0p new";
      "0p-ls" = "0p list";
      "0p-st" = "0p status";
      "0p-at" = "0p attach";
    };

    programs.zsh.shellAliases = {
      "0p-new" = "0p new";
      "0p-ls" = "0p list";
      "0p-st" = "0p status";
      "0p-at" = "0p attach";
    };
  };
}
