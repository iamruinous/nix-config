# ruinous.starship.battery.enabled = true;
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ruinous.starship;
in {
  # Starship configuration
  programs.starship = {
    enable = lib.mkDefault true;
    # enableTransience = true;
    enableInteractive = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    package = pkgs.starship;

    settings = {
      format = lib.concatStrings [
        "$line_break"
        "[┍](247)[━](246)[━](245)[━](244)[━](243)[━](242)[┫](241)"
        "$username"
        "$hostname"
        "[┣](241)[━](240)[━](239)[━](238)[━](237)[╾](236)[╶](236)"
        " "
        "$directory"
        "$fill"
        "$docker_context"
        "$package"
        "$golang"
        "$java"
        "$cmake"
        "$julia"
        "$kotlin"
        "$lua"
        "$nodejs"
        "$python"
        "$ruby"
        "$rust"
        "$git_branch"
        " "
        "$git_status"
        "\${custom.ssh}"
        "$line_break"
        "[┕](248)[━](249)[❯](250)"
        " "
        "$jobs"
        "$character"
      ];
      right_format = "$cmd_duration$battery";
      character = {
        success_symbol = "[λ](254)";
        error_symbol = " [✗](bold red)";
      };
      cmd_duration = {
        min_time = 500;
        show_milliseconds = true;
        format = " [󱎫$duration]($style) ";
        style = "bold yellow";
      };
      java = {
        symbol = "󰬷";
        style = "red";
        format = "via [$symbol ($version )](208)($style)";
      };
      lua = {
        style = "#7FFFD4";
      };
      cmake = {
        symbol = "";
        format = "via [$symbol ($version )]($style)";
      };
      kubernetes = {
        format = "context: [⎈ $context \($namespace\)](bold cyan) ";
        disabled = false;
      };
      memory_usage = {
        format = "with$symbol [$ram $ram_pct( | $swap $swap_pct)]($style) ";
        disabled = false;
        threshold = -1;
        symbol = " ";
        style = "bold dimmed green";
      };
      docker_context = {
        format = "[󰡨 $context](blue bold) ";
        disabled = false;
      };
      directory = {
        truncation_length = 7;
        truncation_symbol = "…/";
      };
      fill = {
        symbol = " ";
        style = "";
      };
      time = {
        disabled = false;
        format = "[\[ $time \]]($style) ";
      };
      custom.ssh = {
        when = "test \"$SSH_CONNECTION\" != \"\"";
        symbol = "󰹑";
        style = "250";
        format = "[$symbol]($style)";
      };
      git_branch = {
        always_show_remote = true;
        style = "bold blue";
        format = "[─](245)[╼━](246)[┫](247)[$symbol$branch(:$remote_branch)]($style)[┣](247)[━╾](246)[─](245)";
      };
      git_status = {
        ahead = "⇡$count";
        diverged = "⇕⇡😵$ahead_count⇣$behind_count";
        behind = "⇣😰$count";
        conflicted = " ";
        untracked = "󰠗 ";
        stashed = "󰽄 ";
        modified = " ";
        staged = "$count ";
        renamed = " ";
        deleted = "󰆴 ";
        style = "140";
        format = "[$all_status$ahead_behind]($style)";
      };
      package = {
        style = "208";
        symbol = "";
        format = "[─](238)[╼━](239)[┫](242)[$symbol $version]($style)[─](237)";
      };
      rust = {
        style = "208";
        symbol = "";
        format = "[$symbol $version]($style)[┣](242)[━╾](239)[─](238) ";
      };
      golang = {
        symbol = "";
        format = "[─](244)[╼━](243)[┫](242)[$symbol $version](bold cyan)[┣](242)[━╾](243)[─](244) ";
      };
      jobs = {
        symbol = "󰬑";
        format = " [$symbol$number]($style)";
      };
      battery = {
        full_symbol = "󰁹";
        charging_symbol = "󰚥 ";
        discharging_symbol = "󰁺 ";
        disabled = !cfg.battery.enable;
      };
      battery.display = [
        {
          threshold = 10;
          discharging_symbol = "󰁺 ";
          style = "red";
        }
        {
          threshold = 20;
          discharging_symbol = "󰁻 ";
          style = "166";
        }
        {
          threshold = 30;
          discharging_symbol = "󰁼 ";
          style = "yellow";
        }
        {
          threshold = 40;
          discharging_symbol = "󰁽 ";
          style = "172";
        }
        {
          threshold = 50;
          discharging_symbol = "󰁾 ";
          style = "170";
        }
        {
          threshold = 60;
          discharging_symbol = "󰁿 ";
          style = "purple";
        }
        {
          threshold = 70;
          discharging_symbol = "󰂀 ";
          style = "purple";
        }
        {
          threshold = 80;
          discharging_symbol = "󰂁 ";
          style = "purple";
        }
        {
          threshold = 90;
          discharging_symbol = "󰂂 ";
          style = "purple";
        }
        {
          threshold = 100;
          discharging_symbol = "󰂂 ";
          style = "green";
        }
      ];
      status = {
        style = "red";
        symbol = " ";
        format = "[\[$symbol$status\]]($style) ";
        disabled = false;
      };
      username = {
        style_user = "252";
        style_root = "red";
        format = "[$user]($style)[󰁥](241)";
        disabled = false;
      };
      hostname = {
        style = "purple bold";
        ssh_only = false;
        ssh_symbol = "󰹑";
        format = "[$hostname]($style)";
        trim_at = ".";
        disabled = false;
      };
      nix_shell = {
        disabled = true;
        impure_msg = "[impure shell](bold red)";
        pure_msg = "[pure shell](bold green)";
        unknown_msg = "[unknown shell](bold yellow)";
        format = "via [☃️ $state( \($name\))](bold blue) ";
      };
    };
  };
}
