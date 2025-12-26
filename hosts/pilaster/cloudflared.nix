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
      "349b3137-7c32-4070-b3ef-e1394eb5aa7b" = {
        credentialsFile = "${config.age.secrets.pilaster_cloudflared_dav_ruinous.path}";
        ingress = {"dav.ruinous.social" = "https://dav-int.ruinous.social";};
        default = "http_status:404";
      };
      "4ea360b8-6313-4e2b-8f8c-4aa7dc248006" = {
        credentialsFile = "${config.age.secrets.pilaster_cloudflared_meals_ruinous.path}";
        ingress = {"meals.ruinous.social" = "https://meals-int.ruinous.social";};
        default = "http_status:404";
      };
      "dbca8b29-fd35-41d2-8ef8-57eeb179a8f5" = {
        credentialsFile = "${config.age.secrets.pilaster_cloudflared_blog_ruinous.path}";
        ingress = {"blog.ruinous.social" = "https://blog-int.ruinous.social";};
        default = "http_status:404";
      };
      "195e5cd1-5efb-4c18-b603-443a96be3ca6" = {
        credentialsFile = "${config.age.secrets.pilaster_cloudflared_keep_ruinous.path}";
        ingress = {
          "keep.ruinous.social" = "https://keep-int.ruinous.social";
          "hoarder.ruinous.social" = "https://keep-int.ruinous.social";
          "karakeep.ruinous.social" = "https://keep-int.ruinous.social";
        };
        default = "http_status:404";
      };
      "43ed79a6-53c3-4ff2-a4ec-64ff2ad149d6" = {
        credentialsFile = "${config.age.secrets.pilaster_cloudflared_matrix_ruinous.path}";
        ingress = {"matrix.ruinous.social" = "https://matrix-int.ruinous.social";};
        default = "http_status:404";
      };
      "24beff9c-420f-4274-97b6-9eee990e0c17" = {
        credentialsFile = "${config.age.secrets.pilaster_cloudflared_mastodon_ruinous.path}";
        ingress = {"ruinous.social" = "https://ruinous-int.ruinous.social";};
        default = "http_status:404";
      };
      "60663185-1ef1-41bc-bd71-ad875b10205e" = {
        credentialsFile = "${config.age.secrets.pilaster_cloudflared_links_ruinous.path}";
        ingress = {"links.ruinous.social" = "https://links-int.ruinous.social";};
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

  age.secrets.pilaster_cloudflared_dav_ruinous = {
    rekeyFile = ./files/cloudflared/dav-ruinous.json.age;
    mode = "644";
  };

  age.secrets.pilaster_cloudflared_meals_ruinous = {
    rekeyFile = ./files/cloudflared/meals-ruinous.json.age;
    mode = "644";
  };

  age.secrets.pilaster_cloudflared_blog_ruinous = {
    rekeyFile = ./files/cloudflared/blog-ruinous.json.age;
    mode = "644";
  };

  age.secrets.pilaster_cloudflared_keep_ruinous = {
    rekeyFile = ./files/cloudflared/keep-ruinous.json.age;
    mode = "644";
  };

  age.secrets.pilaster_cloudflared_matrix_ruinous = {
    rekeyFile = ./files/cloudflared/matrix-ruinous.json.age;
    mode = "644";
  };

  age.secrets.pilaster_cloudflared_mastodon_ruinous = {
    rekeyFile = ./files/cloudflared/mastodon-ruinous.json.age;
    mode = "644";
  };

  age.secrets.pilaster_cloudflared_links_ruinous = {
    rekeyFile = ./files/cloudflared/links-ruinous.json.age;
    mode = "644";
  };
}
