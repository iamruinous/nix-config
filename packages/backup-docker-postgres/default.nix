{
  pkgs,
  # Configuration options (can be overridden)
  containerName ? "postgres",
  backupDir ? "/backup",
  postgresUser ? "postgres",
  excludedDatabases ? ["template0" "template1" "postgres" "postgres=CTc/postgres"],
  ...
}: let
  lib = pkgs.lib;

  # Convert excluded databases list to comma-separated string
  excludedDbsString = lib.concatStringsSep "," excludedDatabases;
in
  pkgs.stdenv.mkDerivation {
    pname = "backup-docker-postgres";
    version = "1.0.0";
    dontUnpack = true;

    propagatedBuildInputs = with pkgs; [
      docker
      gawk
      coreutils
    ];

    passthru.shellPath = "/bin/backup-docker-postgres";
    outputs = ["out"];

    buildPhase = ''
      mkdir -p $out/bin

      # Substitute configuration variables in the shell script
      substitute ${./backup-docker-postgres.sh} $out/bin/backup-docker-postgres \
        --replace '@docker@' '${pkgs.docker}' \
        --replace '@containerName@' '${containerName}' \
        --replace '@backupDir@' '${backupDir}' \
        --replace '@postgresUser@' '${postgresUser}' \
        --replace '@excludedDatabases@' '${excludedDbsString}'

      chmod +x $out/bin/backup-docker-postgres
    '';

    installPhase = ''
      # No installation steps needed beyond what's done in buildPhase
      true
    '';

    meta = with lib; {
      description = "Backup script for PostgreSQL databases running in Docker containers";
      homepage = "https://github.com/iamruinous/nix-config";
      license = licenses.mit;
      maintainers = [];
      mainProgram = "backup-docker-postgres";
      platforms = platforms.linux;
    };
  }
