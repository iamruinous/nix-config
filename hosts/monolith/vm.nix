{
  userConfig,
  config,
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs) NixVirt;
  debian-netinst = pkgs.fetchurl {
    url = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.9.0-amd64-netinst.iso";
    hash = "sha256-Elc3PHBtjAfmkXlCc2qGXf/1V9IdduowQLsQOetyoFQ=";
  };
in {
  users.groups.libvirtd.members = [userConfig.name];
  virtualisation.libvirt.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.allowedBridges = [
    "virbr0"
    "br0"
  ];
  virtualisation.libvirtd.qemu.verbatimConfig = ''
    bridge_helper = "${pkgs.qemu}/libexec/qemu-bridge-helper"
  '';
  virtualisation.spiceUSBRedirection.enable = true;

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@meskill.network";
    certs."monolith.svc.farmhouse.meskill.network" = {
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.monolith_acme_cloudflare.path;
    };
  };
  services.spice-autorandr.enable = true;

  # services.networking.websockify = {
  #   enable = true;
  #   sslCert = "/var/lib/acme/monolith.svc.farmhouse.meskill.network/cert.pem";
  #   sslKey = "/var/lib/acme/monolith.svc.farmhouse.meskill.network/key.pem";
  #   portMap = {
  #     "5959" = 5900;
  #   };
  # };

  virtualisation.libvirt.connections."qemu:///system" = {
    networks = [
      {
        definition = NixVirt.lib.network.writeXML (NixVirt.lib.network.templates.bridge
          {
            uuid = "70b08691-28dc-4b47-90a1-45bbeac9ab5a";
            subnet_byte = 71;
          });
        active = true;
      }
    ];
    pools = [
      {
        active = true;
        definition = NixVirt.lib.pool.writeXML {
          name = "prod";
          uuid = "e937ca2e-993a-4886-87ae-800f3d1cbe5b";
          type = "dir";
          target = {path = "/data/kvms/pools/prod";};
        };
      }
      {
        active = true;
        definition = NixVirt.lib.pool.writeXML {
          name = "devel";
          uuid = "f937ca2e-993a-4886-87ae-800f3d1cbe5a";
          type = "dir";
          target = {path = "/data/kvms/pools/devel";};
        };
        volumes = [
          {
            present = true;
            definition =
              NixVirt.lib.volume.writeXML
              {
                name = "debiantest.qcow2";
                capacity = {
                  count = 20;
                  unit = "GiB";
                };
                target = {
                  format = {
                    type = "qcow2";
                  };
                };
              };
          }
        ];
      }
    ];
    # domains = [
    #   {
    #     active = true;
    #     definition = ./files/libvirt/domains/debiantest.xml;
    #   }
    # ];
  };

  age.secrets.monolith_acme_cloudflare = {
    file = ./files/acme/cloudflare.env.age;
    mode = "600";
  };
}
