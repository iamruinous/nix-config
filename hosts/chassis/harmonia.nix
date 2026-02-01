# Harmonia - Nix binary cache server
#
# Provides a private binary cache for custom packages at cache.nix.meskill.farm
# Access: Tailscale network only (via Caddy)
#
# Usage from clients:
#   nix.settings = {
#     substituters = [ "https://cache.nix.meskill.farm" ];
#     trusted-public-keys = [ "cache.nix.meskill.farm-1:<public-key>" ];
#   };
#
# Pushing packages:
#   nix copy --to http://localhost:5000 ./result
#   # Or with signing:
#   nix store sign --key-file /path/to/key ./result
#   nix copy --to http://localhost:5000 ./result
{
  config,
  pkgs,
  ...
}: {
  # Harmonia binary cache service
  services.harmonia = {
    enable = true;
    signKeyPaths = [config.age.secrets.chassis_harmonia_signing_key.path];
    settings = {
      # Bind to localhost only - Caddy handles external access
      bind = "127.0.0.1:5000";
      # Priority for substituters (lower = higher priority)
      priority = 30;
      # Number of workers
      workers = 4;
    };
  };

  # Grant harmonia access to Nix store
  nix.settings.trusted-users = ["harmonia"];

  # Harmonia signing key (generated with nix-store --generate-binary-cache-key)
  age.secrets.chassis_harmonia_signing_key = {
    rekeyFile = ./files/harmonia/signing-key.sec.age;
    mode = "400";
    owner = "harmonia";
    group = "harmonia";
  };
}
