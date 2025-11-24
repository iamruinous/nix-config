# Imports the NixOS module from the backup-docker-mariadb package
# Enable with: ruinous.mariadb.docker.backup.enable = true;
# Note: Requires MARIADB_ROOT_PASSWORD environment variable (set via EnvironmentFile)
{pkgs, ...}:
pkgs.backup-docker-mariadb.nixosModules.default
