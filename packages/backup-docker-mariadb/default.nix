{
  pkgs,
  # Configuration options (can be overridden)
  containerName ? "mariadb",
  backupDir ? "/backup",
  mariadbUser ? "root",
  excludedDatabases ? ["information_schema" "performance_schema" "mysql" "sys"],
  ...
}: let
  lib = pkgs.lib;

  # Convert excluded databases list to comma-separated string
  excludedDbsString = lib.concatStringsSep "," excludedDatabases;
in
  pkgs.stdenv.mkDerivation {
    pname = "backup-docker-mariadb";
    version = "1.0.0";
    dontUnpack = true;

    propagatedBuildInputs = with pkgs; [
      docker
      coreutils
    ];

    passthru.shellPath = "/bin/backup-docker-mariadb";
    outputs = ["out"];

    buildPhase = ''
      mkdir -p $out/bin

      # Substitute configuration variables in the shell script
      substitute ${./backup-docker-mariadb.sh} $out/bin/backup-docker-mariadb \
        --replace '@docker@' '${pkgs.docker}' \
        --replace '@containerName@' '${containerName}' \
        --replace '@backupDir@' '${backupDir}' \
        --replace '@mariadbUser@' '${mariadbUser}' \
        --replace '@excludedDatabases@' '${excludedDbsString}'

      chmod +x $out/bin/backup-docker-mariadb
    '';

    installPhase = ''
      # No installation steps needed beyond what's done in buildPhase
      true
    '';

    meta = with lib; {
      description = "Backup script for MariaDB databases running in Docker containers";
      homepage = "https://github.com/iamruinous/nix-config";
      license = licenses.mit;
      maintainers = [];
      mainProgram = "backup-docker-mariadb";
      platforms = platforms.linux;
    };
  }
