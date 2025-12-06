{config, ...}: {
  services.cloudflared = {
    enable = true;
    tunnels = {
      "42dd7769-8427-4b0a-be9e-5d50da2dcbbb" = {
        credentialsFile = "${config.age.secrets.pilaster_cloudflared_ma_alexa.path}";
        ingress = {"ma-alexa.meskill.farm" = "https://ma-alexa-int.meskill.farm";};
        default = "http_status:404";
      };
    };
  };

  age.secrets.pilaster_cloudflared_cert_pem = {
    rekeyFile = ./files/cloudflared/cert.pem.age;
    path = "/etc/cloudflared/cert.pem";
    mode = "644";
  };

  age.secrets.pilaster_cloudflared_ma_alexa = {
    rekeyFile = ./files/cloudflared/ma-alexa.json.age;
    mode = "644";
  };
}
