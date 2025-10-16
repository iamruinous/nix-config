# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  flake,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    flake.nixosModules.default
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    inputs.hardware.nixosModules.raspberry-pi-3
  ];

  networking.hostName = "void"; # Define your hostname.

  services.blocky = {
    enable = true;
    settings = {
      ports.dns = 53; # Port for incoming DNS Queries.
      upstreams.groups.default = [
        "https://one.one.one.one/dns-query" # Using Cloudflare's DNS over HTTPS server for resolving queries.
      ];
      # For initially solving DoH/DoT Requests when no system Resolver is available.
      bootstrapDns = {
        upstream = "https://one.one.one.one/dns-query";
        ips = ["1.1.1.1" "1.0.0.1"];
      };
      #Enable Blocking of certain domains.
      blocking = {
        denylists = {
          #Adblocking
          ads = ["https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"];
          #Another filter for blocking adult sites
          adult = ["https://blocklistproject.github.io/Lists/porn.txt"];
          #You can add additional categories
        };
        #Configure what block categories are used
        clientGroupsBlock = {
          default = ["ads"];
          kids-ipad = ["ads" "adult"];
        };
      };
      caching = {
        minTime = "5m";
        maxTime = "30m";
        prefetching = true;
      };
    };
  };

  services.keepalived = {
    enable = true;

    # openFirewall = true;

    extraGlobalDefs = ''
      use_symlink_paths true
    '';

    vrrpInstances.VIP_35 = {
      state = "MASTER";
      interface = "enp4s0";
      virtualRouterId = 35;
      useVmac = true;
      priority = 44;
      noPreempt = true;
      virtualIps = [{addr = "10.55.10.34/24";}];
      # trackScripts = ["track_homepage"];
    };

    # vrrpScripts = {
    #   track_homepage = {
    #     # Note: Shell pipes are not supported here. Call a self written
    #     # script or something like that instead.
    #     script = "${docker-ps}/bin/docker-ps homepage";
    #     interval = 10;
    #     timeout = 2;
    #     rise = 2;
    #     fall = 2;
    #     weight = 10;
    #     user = "root";
    #   };
    # };

    # extraConfig = ''
    #   #
    #   # Track by Process
    #   #
    #   vrrp_track_process track_portainer {
    #     process portainer
    #     weight 10
    #   }
    #
    #   vrrp_track_process track_smokeping {
    #     process smokeping
    #     weight 10
    #   }
    #
    #   #
    #   # Order this section by IP
    #   #
    #   vrrp_instance VIP_41 {
    #     state BACKUP
    #     interface eth0
    #     virtual_router_id 41
    #     priority 44
    #     advert_int 5
    #     virtual_ipaddress {
    #       172.16.1.41/24
    #     }
    #     track_process {
    #       track_smokeping
    #     }
    #   }
    #
    #   vrrp_instance VIP_42 {
    #     state BACKUP
    #     interface eth0
    #     virtual_router_id 42
    #     priority 44
    #     advert_int 5
    #     virtual_ipaddress {
    #       172.16.1.42/24
    #     }
    #     track_process {
    #       track_portainer
    #     }
    #   }
    # '';
  };

  # environment.systemPackages = with pkgs; [
  #   raspberrypi-tools
  # ];

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
