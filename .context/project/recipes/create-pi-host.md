# Create Raspberry Pi Host Recipe

**Description:** Create a new Raspberry Pi host for the RPC (Raspberry Pi Cluster).

## Naming Convention
*   `rpc` = Raspberry Pi Cluster prefix
*   `<model>` = Pi model: `4` or `5`
*   `<name>` = NATO phonetic alphabet (alpha, bravo, ... zulu)
*   **Format:** `rpc-<model>-<name>` (e.g., `rpc-5-alpha`)

## Steps
1.  **Validate Hostname:** Must match `rpc-[45]-(alpha|...|zulu)`.
2.  **Check Existence:** Ensure `hosts/$HOSTNAME` does not exist.
3.  **Create Directory:** `mkdir -p hosts/$HOSTNAME/users/jmeskill`
4.  **Create Config Files:**
    *   `hosts/$HOSTNAME/configuration.nix` (Use standard Pi template)
    *   `hosts/$HOSTNAME/hardware-configuration.nix` (Use `nixos-raspberrypi` module conventions)
    *   `hosts/$HOSTNAME/users/jmeskill/home-configuration.nix` (Home Manager import)
5.  **Update Flake:** Add to `piHosts` in `flake.nix` using correct model module (`raspberry-pi-4` or `raspberry-pi-5`).
6.  **Docs:** Update `hosts/raspberry-pi/README.md`.
7.  **Verify:** `nix eval .#nixosConfigurations.$HOSTNAME.config.system.build.toplevel.outPath`

## Standard Configuration Template
```nix
{ flake, inputs, lib, pkgs, ... }: {
  imports = [
    flake.nixosModules.default
    flake.nixosModules.server
    ./hardware-configuration.nix
  ];
  networking.hostName = "$HOSTNAME";
  boot.loader.raspberryPi.bootloader = "kernel";
  nix.registry.nixpkgs.to = lib.mkForce { type = "path"; path = inputs.nixpkgs.outPath; };
  power.ups.enable = lib.mkForce false;
  services.openssh = { enable = true; settings = { PasswordAuthentication = false; PermitRootLogin = "prohibit-password"; }; };
  users.users.jmeskill = {
    uid = 1000; isNormalUser = true; extraGroups = ["wheel"]; shell = pkgs.fish;
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8rjXP/sjewv6kM1aTtNWkVZKJpZvIAXIRqL81IyEsm iamruinous@ruinous.social" ];
  };
  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = lib.mkForce true;
  system.stateVersion = "25.11";
}
```
