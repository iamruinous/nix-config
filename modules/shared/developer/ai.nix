{
  pkgs,
  lib,
  ...
}: {
  # Sandboxing tools for AI CLI agents (Linux only)
  # The actual AI CLI packages (claude-code, gemini-cli, opencode) are installed
  # via their respective home-manager modules when enabled (ruinous.ai-cli.*)
  environment.systemPackages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.socat
    pkgs.bubblewrap
  ];
}
