{
  flake,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [flake.inputs.nix-homebrew.darwinModules.nix-homebrew];

  # Add nix-homebrew configuration
  nix-homebrew = {
    enable = pkgs.stdenv.isDarwin;
    enableRosetta = pkgs.stdenv.isDarwin && pkgs.system == "aarch64-darwin";
    user = config.system.primaryUser;
    autoMigrate = lib.mkDefault true;
  };

  homebrew = {
    enable = pkgs.stdenv.isDarwin;
    onActivation.upgrade = true;
    brews = [
      "boring"
      "crush"
      "gemini-cli"
      "mas"
      "step"
    ];
    casks = [
      "1password"
      "1password-cli"
      "aerospace"
      "audacity"
      "balenaetcher"
      "blockblock"
      "claude"
      "cyberduck"
      "deskpad"
      "dropbox"
      "element"
      "gog-galaxy"
      "google-chrome"
      "jellyfin"
      "keka"
      "knockknock"
      "loopback"
      "lulu"
      "micro-snitch"
      "mimestream"
      "obsidian"
      "oversight"
      "plex"
      "private-internet-access"
      "raycast"
      "slack"
      "soundsource"
      "spotify"
      "steam"
    ];
    taps = [
      "charmbracelet/tap"
      "ggozad/formulas"
      "nikitabobko/tap"
    ];
    onActivation.cleanup = "zap";
    masApps = {
      "Amphetamine" = 937984704;
      "Bitwarden" = 1352778147;
      "Fantastical" = 975937182;
      "Kindle" = 302584613;
      "PCalc" = 403504866;
      "Paprika3" = 1303222628;
      "PixelmatorPro" = 1289583905;
      "Tailscale" = 1475387142;
      "Todoist" = 585829637;
      "aSPICEPro" = 1560593107;
      "reMarkable" = 1276493162;
    };
  };
}
