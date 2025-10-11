{config, ...}: {
  networking.firewall.allowedTCPPorts = [80 443];
  networking.firewall.allowedUDPPorts = [443];

  virtualisation.oci-containers = {
    backend = "docker";
    networks = {
      hostnet = {
        driver = "bridge";
      };
      proxynet = {
        driver = "bridge";
        internal = true;
      };
    };
    containers = {
      caddy = {
        image = "ghcr.io/caddybuilds/caddy-cloudflare:2.10.0";
        ports = [
          "80:80"
          "443:443"
          "443:443/udp"
          "2019:2019"
        ];
        extraOptions = [
          "--cap-add=NET_ADMIN"
        ];
        healthcheck = {
          test = [
            "CMD"
            "wget"
            "--no-verbose"
            "--tries=1"
            "--spider"
            "http://127.0.0.1:2019/metrics"
          ];
          start-period = "60s";
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
        networks = [ "hostnet" "proxynet" ];
      };
      open-webui = {
        image = "ghcr.io/open-webui/open-webui:main";
        restart = "unless-stopped";
        environment = {
          OLLAMA_BASE_URL = "http://ollama:11434";
        };
        volumes = [
          "/data/docker/open-webui/data:/app/backend/data"
        ];
        networks = [ "proxynet" ];
      };
      ollama = {
        image = "docker.io/ollama/ollama";
        restart = "unless-stopped";
        extraOptions = [
          "--gpus=all"
        ];
        volumes = [
          "/data/docker/ollama/config:/root/.ollama"
        ];
        networks = [ "proxynet" ];
      };
    };
  };

  age.secrets.obelisk_caddy_caddyfile = {
    file = ./files/caddy/Caddyfile.age;
    mode = "600";
  };
}