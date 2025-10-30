{lib, ...}: {
  # Zed editor configuration
  programs.zed-editor = {
    enable = lib.mkDefault false;
    userSettings = {
      theme = {
        mode = "dark";
        light = "Tokyo Night";
        dark = "Tokyo Night";
      };
      vim_mode = true;
      ui_font_size = 16;
      buffer_font_size = 18;
    };
    extensions = [
      "tokyo-night"
      "nix"
      "zig"
      "dockerfile"
      "fish"
      "tmux"
      "typos"
      "ruff"
      "lua"
    ];
  };
}
