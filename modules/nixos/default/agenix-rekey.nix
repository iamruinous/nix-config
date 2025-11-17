# agenix-rekey configuration module
# This module configures agenix-rekey for automatic secret management
# without requiring secrets.nix maintenance
{...}: {}
# {
#   config,
#   lib,
#   ...
# }: let
#   # Import the master public key
#   masterPubkey = lib.strings.fileContents ../../../secrets/master-keys/master.pub;
#
#   # Map of host SSH public keys from secrets.nix
#   hostKeys = {
#     framework = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8xqxaR93hZCPoHmuZDi3NrIF/JD/1nFG4rV7O7iR26";
#     monolith = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHzI0xVuc0SbWyDk+sVC5N3W4FzcAPOd5JCoJfTU2mTF";
#     obelisk = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKz0mrGO9wDTjOq7wC8w5EFIxB0e/vKBGLnOL/kx7Ov+";
#     pilaster = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAg3OPJgudnx+mmP3HkFTHVhUnOFeMMb3pCUuXelPpBM";
#     tty-ruinous-social = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmSBDge9Ab890sUudOY01sWUxXbd640VV1gHA+n1RYr";
#     ruinous-tty = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINm7ZztoeyZEMUo6kHwq67INjpnn1BcZ2yCLT7FLYa3o";
#     messy-tty = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxKEwHn+sSw1E0JSGafv+W7K3RZkbKjM3hkEHSsTrSZ";
#     gap = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFpPwEg0FY03uNvOaQsGWax1vCRwdF3k6GfM/4KA4aDo";
#     # Hosts below don't have SSH keys yet - get them with:
#     # ssh root@<hostname> "cat /etc/ssh/ssh_host_ed25519_key.pub"
#     # gap = "ssh-ed25519 ...";
#     # void = "ssh-ed25519 ...";
#   };
#
#   hostname = config.networking.hostName;
#   hostPubkey = hostKeys.${hostname} or null;
# in {
#   age.rekey = {
#     # Store rekeyed secrets locally in the repository (must be set unconditionally)
#     storageMode = "local";
#     localStorageDir = ../../../. + "/secrets/rekeyed/${hostname}";
#
#     # Only set these if we have a host key
#     hostPubkey = lib.mkIf (hostPubkey != null) hostPubkey;
#
#     masterIdentities = lib.mkIf (hostPubkey != null) [
#       {
#         type = "age";
#         pubkey = lib.strings.removeSuffix "\n" masterPubkey;
#       }
#     ];
#
#     # Automatically generate age identity from SSH host key
#     agePlugins = lib.mkIf (hostPubkey != null) ["ssh-ed25519"];
#   };
#
#   # Warn if host key is missing
#   warnings =
#     lib.optional (hostPubkey == null)
#     "Host '${hostname}' is not configured in agenix-rekey module. Add SSH public key to modules/nixos/default/agenix-rekey.nix";
# }

