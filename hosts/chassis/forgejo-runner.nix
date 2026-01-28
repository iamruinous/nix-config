# Forgejo Actions Runner - Native Nix builds for binary cache
#
# Runs builds directly on the host (no Docker) so packages end up in
# the Nix store where Harmonia can serve them.
#
# Labels:
#   - nix:host - Native Nix builds (no container)
#
# Registration:
#   1. Generate token in Forgejo: Site Admin > Actions > Runners > Create new Runner
#   2. Encrypt with: agenix-helper unlock && agenix edit hosts/chassis/files/forgejo-runner/token.age
#   3. Deploy: just deploy chassis
#   4. Runner auto-registers on first start
#
# Workflow usage:
#   jobs:
#     build:
#       runs-on: nix
#       steps:
#         - uses: actions/checkout@v4
#         - run: nix build .#package-name
{
  config,
  pkgs,
  ...
}: {
  services.gitea-actions-runner = {
    # Use forgejo-runner package for better Forgejo compatibility
    package = pkgs.forgejo-runner;

    instances.chassis = {
      enable = true;
      name = "chassis";
      url = "https://forge.meskill.farm";
      tokenFile = config.age.secrets.chassis_forgejo_runner_token.path;

      # Native execution labels - builds run directly on host
      # The ":host" suffix signals act_runner to use host execution
      labels = [
        "nix:host" # Primary label for Nix builds
      ];

      # Packages available to actions in host mode
      hostPackages = with pkgs; [
        bash
        coreutils
        curl
        git
        gnutar
        gzip
        nix
        nodejs
      ];

      settings = {
        log.level = "info";

        runner = {
          # Run multiple jobs concurrently (chassis has 16 cores)
          capacity = 4;
          # Timeout for jobs
          timeout = "3h";
          # Fetch jobs frequently
          fetch_interval = "5s";
        };

        cache = {
          enabled = true;
          dir = "/var/cache/forgejo-runner/actions";
        };

        # Host execution settings (no containers)
        host = {
          workdir_parent = "/var/tmp/forgejo-runner";
        };
      };
    };
  };

  # Ensure cache directory exists and persists
  systemd.services.gitea-runner-chassis = {
    serviceConfig = {
      CacheDirectory = "forgejo-runner";
    };
  };

  # Allow runner to perform privileged Nix operations (signing, pushing to cache)
  nix.settings.trusted-users = ["gitea-runner"];

  # Runner registration token (generate in Forgejo admin)
  age.secrets.chassis_forgejo_runner_token = {
    rekeyFile = ./files/forgejo-runner/token.age;
    mode = "400";
  };
}
