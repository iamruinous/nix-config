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
    matchBlocks = {
      "z-ssh-tty" = {
        match = "host * exec \"test -z $SSH_TTY\"";
        extraOptions = {
          IdentityAgent = "\"${identityAgent}\"";
        };
      };

      # cabin
      "cabinpi" = {
        hostname = "pi.cabin.meskill.network";
        user = "root";
      };
      "hacabin" = {
        hostname = "ha.cabin.meskill.network";
        user = "hass";
      };
      "plexicabin" = {
        hostname = "plexi.cabin.meskill.network";
        user = "root";
      };

      # svc
      "armistice" = {
        hostname = "armistice.svc.farmhouse.meskill.network";
        user = "jmeskill";
      };
      "monolith" = {
        hostname = "monolith.svc.farmhouse.meskill.network";
        user = "jmeskill";
      };
      "obelisk" = {
        hostname = "obelisk.svc.farmhouse.meskill.network";
        user = "jmeskill";
      };
      "pilaster" = {
        hostname = "pilaster.svc.farmhouse.meskill.network";
        user = "jmeskill";
      };
      "tip" = {
        hostname = "tip.svc.farmhouse.meskill.network";
        user = "root";
      };

      # ttys
      "mtty" = {
        hostname = "messy.tty.meskill.farm";
        user = "messy";
      };
      "rtty" = {
        hostname = "ruinous.tty.meskill.farm";
        user = "jmeskill";
      };

      # manage
      "void" = {
        hostname = "void.manage.farmhouse.meskill.network";
        user = "jmeskill";
      };
      "gap" = {
        hostname = "gap.manage.farmhouse.meskill.network";
        user = "jmeskill";
      };
      "it" = {
        hostname = "it.manage.farmhouse.meskill.network";
        user = "root";
      };
      "nut" = {
        hostname = "nut.manage.farmhouse.meskill.network";
        user = "root";
      };
      "pbs" = {
        hostname = "pbs.manage.farmhouse.meskill.network";
        user = "root";
      };
      "pit" = {
        hostname = "pit.manage.farmhouse.meskill.network";
        user = "root";
      };
      "terranas" = {
        hostname = "terranas.manage.farmhouse.meskill.network";
        user = "admin";
      };
      "truenas" = {
        hostname = "truenas.manage.farmhouse.meskill.network";
        user = "admin";
      };
      "unifi" = {
        hostname = "unifi.manage.farmhouse.meskill.network";
        user = "root";
      };

      # rsync
      "de1381b.rsync.net rsync.net" = {
        hostname = "de1381b.rsync.net";
        user = "root";
      };

      # pico.sh
      "pico.sh" = {
        hostname = "pico.sh";
        user = "iamruinous";
        extraOptions = {
          ForwardAgent = "no";
          AddKeysToAgent = "no";
        };
      };

      # ruinous computers
      "mail.ruinous.social" = {
        hostname = "mail.ruinous.social";
        user = "iamruinous";
      };

      "ruinous.computer tty.ruinous.computer" = {
        hostname = "tty.ruinous.computer";
        user = "iamruinous";
      };

      "ruinous.social tty.ruinous.social" = {
        hostname = "tty.ruinous.social";
        user = "jmeskill";
      };

      # tailscale
      "*.greyhound-triceratops.ts.net 100.*" = {
        user = "root";
      };
      "ts-monolith" = {
        hostname = "monolith.greyhound-triceratops.ts.net";
        user = "jmeskill";
      };
      "ts-moonstone" = {
        hostname = "moonstone.greyhound-triceratops.ts.net";
        user = "jmeskill";
      };
      "ts-nut" = {
        hostname = "nut.greyhound-triceratops.ts.net";
        user = "root";
      };
      "ts-obelisk" = {
        hostname = "obelisk.greyhound-triceratops.ts.net";
        user = "jmeskill";
      };
      "ts-obsidian" = {
        hostname = "obsidian.greyhound-triceratops.ts.net";
        user = "root";
      };
      "ts-onyx" = {
        hostname = "onyx.greyhound-triceratops.ts.net";
        user = "root";
      };
      "ts-pit" = {
        hostname = "pit.greyhound-triceratops.ts.net";
        user = "root";
      };
      "ts-terranas" = {
        hostname = "terranas.greyhound-triceratops.ts.net";
        user = "admin";
      };
      "ts-tip" = {
        hostname = "tip.greyhound-triceratops.ts.net";
        user = "admin";
      };
      "ts-truenas" = {
        hostname = "truenas.greyhound-triceratops.ts.net";
        user = "root";
      };
    };
  };
}
