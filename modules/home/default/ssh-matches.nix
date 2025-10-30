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

      # svc
      "mono" = {
        hostname = "mono.svc.farmhouse.meskill.network";
        user = "jmeskill";
      };
      "tip" = {
        hostname = "tip.svc.farmhouse.meskill.network";
        user = "root";
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
      "void86" = {
        hostname = "void86.manage.farmhouse.meskill.network";
        user = "jmeskill";
      };
      "gap86" = {
        hostname = "gap86.manage.farmhouse.meskill.network";
        user = "jmeskill";
      };
      "it" = {
        hostname = "it.manage.farmhouse.meskill.network";
        user = "root";
      };
      "monolith" = {
        hostname = "monolith.manage.farmhouse.meskill.network";
        user = "jmeskill";
      };
      "moonstone" = {
        hostname = "moonstone.manage.farmhouse.meskill.network";
        user = "jmeskill";
      };
      "nut" = {
        hostname = "nut.manage.farmhouse.meskill.network";
        user = "root";
      };
      "obelisk" = {
        hostname = "obelisk.manage.farmhouse.meskill.network";
        user = "jmeskill";
      };
      "obsidian" = {
        hostname = "obsidian.manage.farmhouse.meskill.network";
        user = "root";
      };
      "onyx" = {
        hostname = "onyx.manage.farmhouse.meskill.network";
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

      "tty.ruinous.social" = {
        hostname = "tty.ruinous.social";
        user = "iamruinous";
      };

      "ruinous.social tty2.ruinous.social" = {
        hostname = "tty2.ruinous.social";
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
