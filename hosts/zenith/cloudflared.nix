{config, ...}: {
  services.cloudflared = {
    enable = true;
    tunnels = {
      "85e3d097-db45-457e-a69d-fd3d6414860b" = {
        credentialsFile = "${config.age.secrets.zenith_cloudflared_timeline.path}";
        ingress = {"timeline.meskill.farm" = "https://timeline-int.meskill.farm";};
        default = "http_status:404";
      };
      # n8n Development Environment - external access via Cloudflare
      # n8n.meskill.dev - main editor UI
      # n8h.meskill.dev - webhook endpoint
      "294618f0-8cf4-4ef9-9744-5cfeead72799" = {
        credentialsFile = "${config.age.secrets.zenith_cloudflared_n8n_dev.path}";
        ingress = {
          "n8n.meskill.dev" = "https://n8n-dev-int.meskill.farm";
          "n8h.meskill.dev" = "https://n8n-dev-int.meskill.farm";
        };
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

  age.secrets.zenith_cloudflared_n8n_dev = {
    rekeyFile = ./files/cloudflared/n8n-dev.json.age;
    mode = "644";
  };
}
