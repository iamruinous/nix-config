{pkgs, ...}:
pkgs.writeShellApplication {
  name = "microvm-transfer";

  runtimeInputs = with pkgs; [
    rsync
    openssh
    coreutils
    gnused
    systemd
  ];

  text = builtins.readFile ./microvm-transfer.sh;

  meta = {
    description = "Transfer MicroVMs between hosts via SSH";
    mainProgram = "microvm-transfer";
  };
}
