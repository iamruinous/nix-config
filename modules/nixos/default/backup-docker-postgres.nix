# Imports the NixOS module from the backup-docker-postgres package
# Enable with: ruinous.postgres.docker.backup.enable = true;
{pkgs, ...}:
pkgs.backup-docker-postgres.nixosModules.default
