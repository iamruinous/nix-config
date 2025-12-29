{
  pkgs,
  lib,
  ...
}: {
  # ai utilities and assistants, linux only (installed via brew on macos)
  environment.systemPackages = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
    # ai code agents
    claude-code
    codex
    crush
    gemini-cli
    gemini-cli-preview
    opencode

    # sandboxing
    socat
    bubblewrap
  ]);
}
