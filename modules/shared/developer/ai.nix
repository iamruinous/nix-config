{
  pkgs,
  lib,
  flake,
  ...
}: {
  # nixpkgs.overlays = [
  #   flake.inputs.claude-code.overlays.default
  #   flake.inputs.gemini-cli.overlays.default
  # ];

  # ai utilities and assistants, linux only (installed via brew on macos)
  environment.systemPackages = lib.optionals pkgs.stdenv.isLinux (with flake.inputs.llm-agents.packages.${pkgs.system}; [
    # ai code agents
    claude-code
    codex
    crush
    gemini-cli
    # gemini-cli-preview
    opencode

    # sandboxing
    pkgs.socat
    pkgs.bubblewrap
  ]);
}
