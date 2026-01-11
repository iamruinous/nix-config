{config, ...}: {
  services.cloudflared = {
    enable = true;
    tunnels = {
      "85e3d097-db45-457e-a69d-fd3d6414860b" = {
        credentialsFile = "${config.age.secrets.zenith_cloudflared_timeline.path}";
        ingress = {"timeline.meskill.farm" = "https://timeline-int.meskill.farm";};
        default = "http_status:404";
      };
    };
  };

  age.secrets.zenith_cloudflared_cert_pem = {
    rekeyFile = ./files/cloudflared/cert.pem.age;
    path = "/etc/cloudflared/cert.pem";
    mode = "644";
  };

  age.secrets.zenith_cloudflared_timeline = {
    rekeyFile = ./files/cloudflared/timeline.json.age;
    mode = "644";
  };
}
