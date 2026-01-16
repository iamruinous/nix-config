{flake, pkgs, ...}: {
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
  #
  # The microvm.nix module checks for "--enable-seccomp" in QEMU's configureFlags
  # to decide whether to add "-sandbox on". By providing a QEMU package without
  # seccomp, the sandbox is not enabled in the first place.
  microvm.vmHostPackages = pkgs // {
    qemu_kvm = pkgs.qemu_kvm.override {
      seccompSupport = false;
    };
    qemu-utils = pkgs.qemu-utils.override {
      seccompSupport = false;
    };
  };
}
