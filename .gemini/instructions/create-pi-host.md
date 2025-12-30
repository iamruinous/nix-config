# Create Raspberry Pi Host Recipe

Create a new Raspberry Pi host for the RPC (Raspberry Pi Cluster).

## Usage

When asked to "create a pi host" or "add a new raspberry pi", follow these steps.

**Naming Convention:**
- `rpc` = Raspberry Pi Cluster prefix
- `<model>` = Pi model: `4` for Pi 4, `5` for Pi 5
- `<name>` = NATO phonetic alphabet (alpha, bravo, ... zulu)
- Format: `rpc-<model>-<name>` (e.g., `rpc-5-alpha`)

## Steps

1. **Validate Hostname**: Ensure it matches `rpc-[45]-(alpha|...|zulu)`.
2. **Check Existence**: `ls hosts/$HOSTNAME` to ensure it doesn't already exist.
3. **Create Directory**: `mkdir -p hosts/$HOSTNAME/users/jmeskill`

4. **Create `hosts/$HOSTNAME/configuration.nix`**:
   (See content template below - use standard NixOS Pi config)

5. **Create `hosts/$HOSTNAME/hardware-configuration.nix`**:
   (See content template below - use `nixos-raspberrypi` conventions)

6. **Create `hosts/$HOSTNAME/users/jmeskill/home-configuration.nix`**:
   (Standard home-manager import)

7. **Update `flake.nix`**:
   - Add the new host to the `piHosts` set.
   - Use `inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base` (or 4) as appropriate.

8. **Update Documentation**:
   - Add to `hosts/raspberry-pi/README.md` table.

9. **Verify**:
   - `nix eval .#nixosConfigurations.$HOSTNAME.config.system.build.toplevel.outPath`

10. **Output Instructions**:
    - Provide commands to build the SD image and flash it.

## Templates

### configuration.nix
```nix
{
  flake,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    flake.nixosModules.default
    flake.nixosModules.server
    ./hardware-configuration.nix
  ];

  networking.hostName = "$HOSTNAME";
  boot.loader.raspberryPi.bootloader = "kernel";

  nix.registry.nixpkgs.to = lib.mkForce {
    type = "path";
    path = inputs.nixpkgs.outPath;
  };

  power.ups.enable = lib.mkForce false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.jmeskill = {
    uid = 1000;
    isNormalUser = true;
    description = "Jade Meskill";
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8rjXP/sjewv6kM1aTtNWkVZKJpZvIAXIRqL81IyEsm iamruinous@ruinous.social"
    ];
    shell = pkgs.fish;
  };

  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = lib.mkForce true;
  users.defaultUserShell = lib.mkForce pkgs.fish;

  system.stateVersion = "25.11";
}
```

### hardware-configuration.nix
```nix
{lib, ...}: {
  hardware.enableRedistributableFirmware = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = ["noatime"];
  };

  swapDevices = [];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = "aarch64-linux";
}
```
