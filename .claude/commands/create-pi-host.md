---
description: Create a new Raspberry Pi cluster host configuration
---

Create a new Raspberry Pi host for the RPC (Raspberry Pi Cluster).

**Required arguments:** `$ARGUMENTS` should contain the hostname in format `rpc-<model>-<member>` (e.g., "rpc-5-1", "rpc-4-2")

## Naming Convention

- `rpc` = Raspberry Pi Cluster prefix
- `<model>` = Pi model: `4` for Pi 4, `5` for Pi 5
- `<member>` = Cluster member number (1, 2, 3, ...)

## Steps

1. **Parse and validate the hostname** from `$ARGUMENTS`
   - Must match pattern `rpc-[45]-[0-9]+`
   - Extract the model number (4 or 5)
   - Extract the member number
   - If invalid, ask the user to provide a valid hostname

2. **Check if host already exists:**
   ```bash
   ls hosts/$HOSTNAME 2>/dev/null
   ```
   If exists, warn user and ask to confirm overwrite

3. **Create directory structure:**
   ```bash
   mkdir -p hosts/$HOSTNAME/users/jmeskill
   ```

4. **Create configuration.nix** at `hosts/$HOSTNAME/configuration.nix`:
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

     # Use the recommended "kernel" bootloader for Raspberry Pi
     boot.loader.raspberryPi.bootloader = "kernel";

     # Resolve nixpkgs registry conflict between main nixpkgs and nixos-raspberrypi's nixpkgs
     nix.registry.nixpkgs.to = lib.mkForce {
       type = "path";
       path = inputs.nixpkgs.outPath;
     };

     # Disable UPS monitoring (no UPS connected to this Pi)
     power.ups.enable = lib.mkForce false;

     # Enable SSH for remote access
     services.openssh = {
       enable = true;
       settings = {
         PasswordAuthentication = false;
         PermitRootLogin = "prohibit-password";
       };
     };

     # User configuration
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

5. **Create hardware-configuration.nix** at `hosts/$HOSTNAME/hardware-configuration.nix`:
   ```nix
   {lib, ...}: {
     # Hardware configuration for Raspberry Pi $MODEL
     # Most hardware config is handled by nixos-raspberrypi modules

     hardware.enableRedistributableFirmware = true;

     # File system configuration for SD card boot
     # NOTE: Update these labels after imaging if needed
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

6. **Create user home-configuration.nix** at `hosts/$HOSTNAME/users/jmeskill/home-configuration.nix`:
   ```nix
   {flake, ...}: {
     imports = [
       flake.homeModules.default
     ];
   }
   ```

7. **Add to piHosts in flake.nix:**

   Find the `piHosts = {` section and add the new host entry. Use the correct modules based on model:

   For Pi 5:
   ```nix
   $HOSTNAME = inputs.nixos-raspberrypi.lib.nixosSystem {
     specialArgs = {
       inherit inputs;
       flake = inputs.self;
       nixos-raspberrypi = inputs.nixos-raspberrypi;
       perSystem = {
         self = blueprintOutputs.packages.aarch64-linux;
       };
     };
     modules = [
       inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
       inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
       inputs.nixos-raspberrypi.nixosModules.sd-image
       ./hosts/$HOSTNAME/configuration.nix
     ];
   };
   ```

   For Pi 4:
   ```nix
   $HOSTNAME = inputs.nixos-raspberrypi.lib.nixosSystem {
     specialArgs = {
       inherit inputs;
       flake = inputs.self;
       nixos-raspberrypi = inputs.nixos-raspberrypi;
       perSystem = {
         self = blueprintOutputs.packages.aarch64-linux;
       };
     };
     modules = [
       inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.base
       inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.display-vc4
       inputs.nixos-raspberrypi.nixosModules.sd-image
       ./hosts/$HOSTNAME/configuration.nix
     ];
   };
   ```

8. **Update hosts/raspberry-pi/README.md** - Add the new host to the "Cluster Members" table

9. **Verify the configuration builds:**
   ```bash
   nix eval .#nixosConfigurations.$HOSTNAME.config.system.build.toplevel.outPath
   ```

10. **Output summary:**
    ```
    Created new Raspberry Pi host: $HOSTNAME

    Files created:
    - hosts/$HOSTNAME/configuration.nix
    - hosts/$HOSTNAME/hardware-configuration.nix
    - hosts/$HOSTNAME/users/jmeskill/home-configuration.nix

    Build SD image:
      nix build .#nixosConfigurations.$HOSTNAME.config.system.build.sdImage \
        --builders "ssh://armistice.meskill.farm aarch64-linux" --max-jobs 0

    Flash to SD card:
      zstd -d result/sd-image/*.img.zst -o nixos-$HOSTNAME.img
      sudo dd if=nixos-$HOSTNAME.img of=/dev/sdX bs=4M status=progress
    ```

## Example Usage

```
/create-pi-host rpc-5-1
/create-pi-host rpc-4-1
/create-pi-host rpc-5-2
```
