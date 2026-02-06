# Ruinous Starship Theme Compositor
# Combines colorways and styles into themed starship configuration
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ruinous.starship;

  # ===========================================================================
  # COLOR DEFINITIONS
  # ===========================================================================
  
  # Shared colors across all colorways (N0FRILLS design system)
  shared = {
    white = "#eeeeee";
    gray = "#8a8a8a";
    muted = "#626262";
    dim = "#4e4e4e";
    border = "#3a3a3a";
    bg = "#1c1c1c";
  };

  # Colorway palettes
  colorways = {
    classic = {
      primary = "purple";
      accent = "208";
      hotAccent = "red";
      highlight = "bold blue";
    };
    ruin = {
      primary = "#d75fd7";
      accent = "#ffafd7";
      hotAccent = "#ff5faf";
      highlight = "#5fd7d7";
    };
    siege = {
      primary = "#875fd7";
      accent = "#af87ff";
      hotAccent = "#5f5fff";
      highlight = "#00afaf";
    };
    ghost = {
      primary = "#eeeeee";
      accent = "#bcbcbc";
      hotAccent = "#eeeeee";
      highlight = "#ffaf00";
    };
  };

  # Select colorway based on config
  colorway = colorways.${cfg.themeVariant};

  # ===========================================================================
  # STYLE DEFINITIONS
  # ===========================================================================

  # BASIC: Brutalist, minimal decoration
  basicStyle = {
    format = lib.concatStrings [
      "$username"
      "[@](${shared.muted})"
      "$hostname"
      " "
      "$directory"
      " "
      "$git_branch"
      "$git_status"
      "$line_break"
      "$character"
    ];

    right_format = "$cmd_duration";

    username = {
      format = "[$user]($style)";
      style_user = shared.gray;
      style_root = colorway.hotAccent;
      disabled = false;
    };

    hostname = {
      format = "[$hostname]($style)";
      style = "bold ${colorway.primary}";
      ssh_only = false;
      disabled = false;
    };

    directory = {
      format = "[$path]($style)";
      style = colorway.highlight;
      truncation_length = 3;
      truncation_symbol = ".../";
    };

    git_branch = {
      format = "[$symbol$branch]($style) ";
      style = colorway.primary;
      symbol = "";
    };

    git_status = {
      format = "[$all_status$ahead_behind]($style)";
      style = colorway.accent;
      conflicted = "!";
      ahead = "+$count";
      behind = "-$count";
      diverged = "~";
      untracked = "?";
      stashed = "S";
      modified = "M";
      staged = "A";
      renamed = "R";
      deleted = "D";
    };

    character = {
      success_symbol = "[>](${colorway.primary})";
      error_symbol = "[>](bold ${colorway.hotAccent})";
    };

    cmd_duration = {
      format = "[$duration]($style)";
      style = shared.muted;
      min_time = 2000;
    };

    package.disabled = true;
    golang.disabled = true;
    rust.disabled = true;
    nodejs.disabled = true;
    python.disabled = true;
    docker_context.disabled = true;
  };

  # ADVANCED: Structured tech-forward with N0FRILLS bracket notation
  advancedStyle = {
    format = lib.concatStrings [
      "[\\[~\\]](${shared.gray})"
      " "
      "$directory"
      " "
      "[\\[>\\]](${shared.gray})"
      " "
      "$git_branch"
      "$git_status"
      "$fill"
      "$line_break"
      "$character"
    ];

    right_format = lib.concatStrings [
      "$package"
      "$golang"
      "$rust"
      "$nodejs"
      "$python"
      "$docker_context"
      "[\\[@\\]](${shared.muted})"
      " "
      "$username"
      "$hostname"
      " "
      "$cmd_duration"
      "$battery"
    ];

    add_newline = true;

    fill.symbol = " ";

    username = {
      format = "[$user](${shared.gray})[@](${shared.muted})";
      style_root = colorway.hotAccent;
      disabled = false;
    };

    hostname = {
      format = "[$hostname]($style)";
      style = colorway.primary;
      ssh_only = false;
      disabled = false;
    };

    directory = {
      format = "[$path]($style)";
      style = "bold ${colorway.highlight}";
      truncation_length = 4;
      truncation_symbol = ".../";
    };

    git_branch = {
      format = "[$branch]($style) ";
      style = "bold ${colorway.primary}";
      symbol = "";
    };

    git_status = {
      format = "[$all_status$ahead_behind]($style)";
      style = colorway.accent;
      conflicted = "[!](${colorway.hotAccent})";
      ahead = "+$count";
      behind = "-$count";
      diverged = "!";
      untracked = "?";
      stashed = "S";
      modified = "~";
      staged = "+";
      renamed = ">";
      deleted = "x";
    };

    package = {
      format = "[$symbol$version]($style) ";
      symbol = "pkg ";
      style = shared.muted;
    };

    golang = {
      format = "[$symbol$version]($style) ";
      symbol = "go ";
      style = shared.muted;
    };

    rust = {
      format = "[$symbol$version]($style) ";
      symbol = "rs ";
      style = shared.muted;
    };

    nodejs = {
      format = "[$symbol$version]($style) ";
      symbol = "node ";
      style = shared.muted;
    };

    python = {
      format = "[$symbol$version]($style) ";
      symbol = "py ";
      style = shared.muted;
    };

    docker_context = {
      format = "[\\[docker\\]](${shared.gray}) [$context](${colorway.accent}) ";
      disabled = false;
    };

    character = {
      success_symbol = "[\\[>\\]](${colorway.highlight})";
      error_symbol = "[\\[!\\]](bold ${colorway.hotAccent})";
    };

    cmd_duration = {
      format = "[$duration]($style) ";
      style = shared.muted;
      min_time = 2000;
      show_milliseconds = true;
    };

    battery = {
      full_symbol = "B";
      charging_symbol = "B+";
      discharging_symbol = "B";
      display = [
        {
          threshold = 20;
          style = colorway.hotAccent;
        }
        {
          threshold = 50;
          style = colorway.accent;
        }
      ];
    };
  };

  # HANDCRAFTED: Artisanal box-drawing (original style)
  handcraftedStyle = {
    format = lib.concatStrings [
      "$line_break"
      "[┍](${shared.gray})[━](${shared.muted})[━](${shared.muted})[━](${shared.muted})[━](${shared.muted})[━](${shared.muted})[┫](${shared.gray})"
      "$username"
      "$hostname"
      "\${custom.ssh_auth_sock}"
      "[┣](${shared.gray})[━](${shared.muted})[━](${shared.muted})[━](${shared.muted})[━](${shared.muted})[╾](${shared.dim})[╶](${shared.dim})"
      " "
      "$directory"
      "$fill"
      "$docker_context"
      "$package"
      "$golang"
      "$rust"
      "$git_branch"
      " "
      "$git_status"
      "\${custom.ssh}"
      "$line_break"
      "[┕](${shared.gray})[━](${shared.muted})[❯](${shared.gray})"
      " "
      "$jobs"
      "$character"
    ];

    right_format = "$cmd_duration$battery";

    add_newline = true;

    fill.symbol = " ";

    character = {
      success_symbol = "[λ](${colorway.primary})";
      error_symbol = "[✗](bold ${colorway.hotAccent})";
    };

    cmd_duration = {
      min_time = 500;
      show_milliseconds = true;
      format = " [󱎫$duration]($style) ";
      style = "bold ${colorway.accent}";
    };

    directory = {
      truncation_length = 7;
      truncation_symbol = "…/";
      style = colorway.highlight;
    };

    git_branch = {
      always_show_remote = true;
      style = "bold ${colorway.primary}";
      format = "[─](${shared.muted})[╼━](${shared.gray})[┫](${shared.gray})[$symbol$branch(:$remote_branch)]($style)[┣](${shared.gray})[━╾](${shared.gray})[─](${shared.muted})";
    };

    git_status = {
      ahead = "⇡$count";
      diverged = "⇕⇡$ahead_count⇣$behind_count";
      behind = "⇣$count";
      conflicted = " ";
      untracked = "󰠗 ";
      stashed = "󰽄 ";
      modified = " ";
      staged = " $count";
      renamed = " ";
      deleted = "󰆴 ";
      style = colorway.accent;
      format = "[$all_status$ahead_behind]($style)";
    };

    package = {
      style = colorway.accent;
      symbol = "";
      format = "[─](${shared.dim})[╼━](${shared.muted})[┫](${shared.gray})[$symbol $version]($style)[─](${shared.dim})";
    };

    rust = {
      style = colorway.accent;
      symbol = "";
      format = "[$symbol $version]($style)[┣](${shared.gray})[━╾](${shared.muted})[─](${shared.dim}) ";
    };

    golang = {
      symbol = "";
      style = colorway.highlight;
      format = "[─](${shared.muted})[╼━](${shared.gray})[┫](${shared.gray})[$symbol $version]($style)[┣](${shared.gray})[━╾](${shared.gray})[─](${shared.muted}) ";
    };

    jobs = {
      symbol = "󰬑";
      format = " [$symbol$number]($style)";
    };

    docker_context = {
      format = "[󰡨 $context](${colorway.primary}) ";
      disabled = false;
    };

    username = {
      style_user = shared.gray;
      style_root = colorway.hotAccent;
      format = "[$user]($style)[󰁥](${shared.gray})";
      disabled = false;
    };

    hostname = {
      style = "bold ${colorway.primary}";
      ssh_only = false;
      ssh_symbol = "󰹑";
      format = "[$hostname]($style)";
      trim_at = ".";
      disabled = false;
    };

    "custom.ssh" = {
      when = "test \"$SSH_CONNECTION\" != \"\"";
      symbol = "󰹑";
      style = shared.gray;
      format = "[$symbol]($style)";
    };

    "custom.ssh_auth_sock" = {
      when = "! ssh-agent-check";
      symbol = "󰌆";
      style = "bold ${colorway.hotAccent}";
      format = "[$symbol]($style)";
      description = "SSH agent is not responding";
    };

    battery = {
      full_symbol = "󰁹";
      charging_symbol = "󰚥 ";
      discharging_symbol = "󰁺 ";
      display = [
        {
          threshold = 10;
          discharging_symbol = "󰁺 ";
          style = colorway.hotAccent;
        }
        {
          threshold = 30;
          discharging_symbol = "󰁼 ";
          style = colorway.accent;
        }
        {
          threshold = 50;
          discharging_symbol = "󰁾 ";
          style = colorway.primary;
        }
        {
          threshold = 100;
          discharging_symbol = "󰂂 ";
          style = colorway.highlight;
        }
      ];
    };
  };

  # ===========================================================================
  # STYLE SELECTION
  # ===========================================================================

  styleSettings =
    if cfg.themeStyle == "basic" then basicStyle
    else if cfg.themeStyle == "advanced" then advancedStyle
    else handcraftedStyle;

  # Handle battery enable/disable
  batterySettings =
    if cfg.battery.enable
    then {}
    else {battery.disabled = true;};

  # Merge style settings with battery override
  finalSettings = styleSettings // batterySettings;

in {
  # Starship configuration
  programs.starship = {
    enable = lib.mkDefault true;
    enableInteractive = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    package = pkgs.starship;

    settings = finalSettings;
  };
}
