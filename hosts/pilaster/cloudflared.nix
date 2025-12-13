{config, ...}: {
  services.cloudflared = {
    enable = true;
    tunnels = {
      "42dd7769-8427-4b0a-be9e-5d50da2dcbbb" = {
        credentialsFile = "${config.age.secrets.pilaster_cloudflared_ma_alexa.path}";
        ingress = {"ma-alexa.meskill.farm" = "https://ma-alexa-int.meskill.farm";};
        default = "http_status:404";
      };
      "7991e506-c522-4db9-b08f-f6533f1cd8f6" = {
        credentialsFile = "${config.age.secrets.pilaster_cloudflared_music_assistant.path}";
        ingress = {"ma.meskill.farm" = "https://ma-int.meskill.farm";};
        default = "http_status:404";
      };
      # TODO: Create tunnel with: cloudflared tunnel create monica
      # Then replace TUNNEL_ID_HERE with the tunnel ID and encrypt the JSON credentials
      # "TUNNEL_ID_HERE" = {
      #   credentialsFile = "${config.age.secrets.pilaster_cloudflared_monica.path}";
      #   ingress = {"monica.meskill.farm" = "https://monica-int.meskill.farm";};
      #   default = "http_status:404";
      # };
      # TODO: Create tunnel with: cloudflared tunnel create twenty
      # Then replace TUNNEL_ID_HERE with the tunnel ID and encrypt the JSON credentials
      # "TUNNEL_ID_HERE" = {
      #   credentialsFile = "${config.age.secrets.pilaster_cloudflared_twenty.path}";
      #   ingress = {"twenty.meskill.farm" = "https://twenty-int.meskill.farm";};
      #   default = "http_status:404";
      # };
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

  age.secrets.pilaster_cloudflared_music_assistant = {
    rekeyFile = ./files/cloudflared/music-assistant.json.age;
    mode = "644";
  };

  # Uncomment after creating tunnels and encrypting credentials:
  # age.secrets.pilaster_cloudflared_monica = {
  #   rekeyFile = ./files/cloudflared/monica.json.age;
  #   mode = "644";
  # };
  # age.secrets.pilaster_cloudflared_twenty = {
  #   rekeyFile = ./files/cloudflared/twenty.json.age;
  #   mode = "644";
  # };
}
