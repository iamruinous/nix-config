{pkgs, ...}:
pkgs.writeShellApplication {
  name = "microvm-backup";

  runtimeInputs = with pkgs; [
    rsync
    coreutils
    gnused
    systemd
  ];

  text = builtins.readFile ./microvm-backup.sh;

  meta = {
    description = "Backup MicroVM persistent data locally";
    mainProgram = "microvm-backup";
  };
}
