{flake, ...}: {
  # microvm defaults
  imports = [
    flake.inputs.microvm.nixosModules.microvm
    flake.inputs.impermanence.nixosModules.impermanence

    flake.nixosModules.common
  ];

  # Disable QEMU's seccomp sandbox which blocks setuid/setgid syscalls
  # This is required for:
  # - home-manager activation (runs as non-root user via systemd)
  # - D-Bus (needs to switch users)
  # - sudo/su commands (user privilege transitions)
  # Without this, any process trying to run as a non-root user fails with "Permission denied"
  microvm.qemu.extraArgs = ["-sandbox" "off"];
}
