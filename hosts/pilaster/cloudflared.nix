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
      "d8d6be85-1f3c-4853-82c6-a9875430ee84" = {
        credentialsFile = "${config.age.secrets.pilaster_cloudflared_monica.path}";
        ingress = {"monica.meskill.farm" = "https://monica-int.meskill.farm";};
        default = "http_status:404";
      };
      "41238cf1-06ab-47e6-ba9c-eb6238a7534c" = {
        credentialsFile = "${config.age.secrets.pilaster_cloudflared_twenty.path}";
        ingress = {"twenty.meskill.farm" = "https://twenty-int.meskill.farm";};
        default = "http_status:404";
      };
      # Migrated from tty-ruinous-social
      "89b669e6-32ac-4063-a030-dc6b98c61bdf" = {
        credentialsFile = "${config.age.secrets.pilaster_cloudflared_alby_ruinous.path}";
        ingress = {"alby.ruinous.social" = "https://alby-int.ruinous.social";};
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

  age.secrets.pilaster_cloudflared_music_assistant = {
    rekeyFile = ./files/cloudflared/music-assistant.json.age;
    mode = "644";
  };

  age.secrets.pilaster_cloudflared_monica = {
    rekeyFile = ./files/cloudflared/monica.json.age;
    mode = "644";
  };

  age.secrets.pilaster_cloudflared_twenty = {
    rekeyFile = ./files/cloudflared/twenty.json.age;
    mode = "644";
  };

  age.secrets.pilaster_cloudflared_alby_ruinous = {
    rekeyFile = ./files/cloudflared/alby-ruinous.json.age;
    mode = "644";
  };
}
