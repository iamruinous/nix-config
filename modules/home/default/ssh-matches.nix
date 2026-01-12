{
  lib,
  pkgs,
  ...
}: let
  identityAgent =
    if (pkgs.stdenv.isDarwin)
    then "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else "~/.1password/agent.sock";
in {
  programs.ssh = {
    enable = lib.mkDefault true;
    enableDefaultConfig = lib.mkDefault false;

    # Wildcard patterns and match conditions that can't use the hosts module
    matchBlocks = {
      # ─────────────────────────────────────────────────────────────────────────
      # Special match conditions (ordering prefix ensures proper precedence)
      # ─────────────────────────────────────────────────────────────────────────
      "z-ssh-chassis" = {
        match = "host * exec \"test $(uname -n) = 'chassis'\"";
        extraOptions = {
          IdentityAgent = "none";
          IdentityFile = "~/.ssh/id_codey_ed25519";
        };
      };

      "z-ssh-zenith" = {
        match = "host * exec \"test $(uname -n) = 'zenith'\"";
        extraOptions = {
          IdentityAgent = "none";
          IdentityFile = "~/.ssh/id_codey_ed25519";
        };
      };

      "y-ssh-tty" = {
        match = "host * exec \"test -z $SSH_TTY\"";
        extraOptions = {
          IdentityAgent = "\"${identityAgent}\"";
        };
      };
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # Declarative SSH Hosts (format: "user@hostname")
  # ═══════════════════════════════════════════════════════════════════════════
  ruinous.ssh.hosts = {
    # ─────────────────────────────────────────────────────────────────────────
    # Cabin Network
    # ─────────────────────────────────────────────────────────────────────────
    cabinpi.host = "root@pi.cabin.meskill.network";
    hacabin.host = "hass@ha.cabin.meskill.network";
    plexicabin.host = "root@plexi.cabin.meskill.network";

    # ─────────────────────────────────────────────────────────────────────────
    # Service Network
    # ─────────────────────────────────────────────────────────────────────────
    armistice.host = "jmeskill@armistice.svc.farmhouse.meskill.network";
    monolith.host = "jmeskill@monolith.svc.farmhouse.meskill.network";
    obelisk.host = "jmeskill@obelisk.svc.farmhouse.meskill.network";
    pilaster.host = "jmeskill@pilaster.svc.farmhouse.meskill.network";
    zenith.host = "jmeskill@zenith.svc.farmhouse.meskill.network";

    # ─────────────────────────────────────────────────────────────────────────
    # TTY Hosts
    # ─────────────────────────────────────────────────────────────────────────
    mtty.host = "messy@messy.tty.meskill.farm";
    rtty.host = "jmeskill@ruinous.tty.meskill.farm";

    # ─────────────────────────────────────────────────────────────────────────
    # Management Network
    # ─────────────────────────────────────────────────────────────────────────
    void.host = "jmeskill@void.manage.farmhouse.meskill.network";
    gap.host = "jmeskill@gap.manage.farmhouse.meskill.network";
    pbs.host = "root@pbs.manage.farmhouse.meskill.network";
    terranas.host = "admin@terranas.manage.farmhouse.meskill.network";
    truenas.host = "admin@truenas.manage.farmhouse.meskill.network";
    unifi.host = "root@unifi.manage.farmhouse.meskill.network";

    # ─────────────────────────────────────────────────────────────────────────
    # Desktops/Laptops
    # ─────────────────────────────────────────────────────────────────────────
    chassis.host = "jmeskill@chassis.home.farmhouse.meskill.network";

    # ─────────────────────────────────────────────────────────────────────────
    # External Services
    # ─────────────────────────────────────────────────────────────────────────
    "de1381b.rsync.net" = {
      host = "root@de1381b.rsync.net";
      aliases = ["rsync.net"];
    };

    "pico.sh" = {
      host = "iamruinous@pico.sh";
      extraOptions = {
        ForwardAgent = "no";
        AddKeysToAgent = "no";
      };
    };

    # ─────────────────────────────────────────────────────────────────────────
    # Ruinous Computers
    # ─────────────────────────────────────────────────────────────────────────
    "mail.ruinous.social".host = "iamruinous@mail.ruinous.social";

    "ruinous.computer" = {
      host = "iamruinous@tty.ruinous.computer";
      aliases = ["tty.ruinous.computer"];
    };

    "ruinous.social" = {
      host = "jmeskill@tty.ruinous.social";
      aliases = ["tty.ruinous.social"];
    };
  };
}
