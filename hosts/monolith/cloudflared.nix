{config, ...}: {
  services.cloudflared = {
    enable = true;
    tunnels = {
      "9b4d96ca-4911-46d3-979e-38f3d6dae733" = {
        credentialsFile = "${config.age.secrets.monolith_cloudflared_n8n_webhook.path}";
        ingress = {
          "n8h.meskill.farm" = "https://n8n.meskill.farm";
          # GitHub webhook proxy for internal Forgejo
          "hooks.forge.meskill.farm" = "https://hooks.forge.meskill.farm";
        };
        default = "http_status:404";
      };
    };
  };

  age.secrets.monolith_cloudflared_cert_pem = {
    rekeyFile = ./files/cloudflared/cert.pem.age;
    path = "/etc/cloudflared/cert.pem";
    mode = "644";
  };

  age.secrets.monolith_cloudflared_n8n_webhook = {
    rekeyFile = ./files/cloudflared/n8n-webhook.json.age;
    mode = "644";
  };
}
