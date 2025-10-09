{config, ...}: {
  networking.firewall.allowedTCPPorts = [80 443];
  networking.firewall.allowedUDPPorts = [443];

  virtualisation.arion = {
    backend = "docker";
    projects."obelisk".settings = {
      networks = {
        "hostnet" = {
          name = "hostnet";
        };
        "proxynet" = {
          name = "proxynet";
        };
      };
      services = {
        # hostnet services
        "caddy".service = {
          container_name = "caddy";
          image = "ghcr.io/caddybuilds/caddy-cloudflare:2.10.0";
          networks = [
            "hostnet"
            "proxynet"
          ];
          ports = [
            "80:80"
            "443:443"
            "443:443/udp"
            "2019:2019"
          ];
          capabilities = {
            NET_ADMIN = true;
          };
          healthcheck = {
            test = [
              "CMD"
              "wget"
              "--no-verbose"
              "--tries=1"
              "--spider"
              "http://127.0.0.1:2019/metrics"
            ];
            start_period = "60s";
            interval = "60s";
            timeout = "5s";
            retries = 3;
          };
          restart = "unless-stopped";
          volumes = [
            "${config.age.secrets.obelisk_caddy_caddyfile.path}:/etc/caddy/Caddyfile"
            "/data/docker/caddy/site:/srv"
            "/data/docker/caddy/data:/data"
            "/data/docker/caddy/config:/config"
            "/data/docker/caddy/static:/static"
            "/var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock"
          ];
        };
        # proxynet services
        "open-webui".service = {
          container_name = "open-webui";
          image = "ghcr.io/open-webui/open-webui:main";
          networks = ["proxynet"];
          restart = "unless-stopped";
          environment = {
            OLLAMA_BASE_URL = "http://ollama:11434";
          };
          volumes = [
            "/data/docker/open-webui/data:/app/backend/data"
          ];
        };
        "ollama".service = {
          container_name = "ollama";
          image = "docker.io/ollama/ollama";
          networks = ["proxynet"];
          restart = "unless-stopped";
          devices = ["nvidia.com/gpu=all"];
          volumes = [
            "/data/docker/ollama/config:/root/.ollama"
          ];
        };
      };
    };
  };

  age.secrets.obelisk_caddy_caddyfile = {
    file = ./files/caddy/Caddyfile.age;
    mode = "600";
  };
}
