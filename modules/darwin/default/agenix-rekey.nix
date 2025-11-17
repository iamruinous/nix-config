# agenix-rekey configuration module for macOS
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
#     jmacmini = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBucoQ40ZvFyVdqtLqcITFVflxliTOHddWIso4fGwlX+";
#     studio = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBVXtjGlDK/b/8KU5edVlMcF/pcrcqlm4S2o94XtGOPD";
#     jbookpro = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFnhRtaSC1HFo3hF2Wdq2KzgCTk1/5BlAZvjkE2ZZauo";
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
#     "Host '${hostname}' is not configured in agenix-rekey module. Add SSH public key to modules/darwin/default/agenix-rekey.nix";
# }

