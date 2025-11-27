{
  config,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [80 443 3493 5050 9000];
  networking.firewall.allowedUDPPorts = [443];

  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.autoPrune.enable = true;

  # this is for services that need to talk to each other
  # they are not accessed directly, but typically through Caddy
  systemd.services.docker-servicenet-network = {
    description = "create docker servicenet network";
    wantedBy = ["multi-user.target"];
    after = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "create-servicenet-network" ''
        if ! ${pkgs.docker}/bin/docker network inspect servicenet >/dev/null 2>&1; then
          ${pkgs.docker}/bin/docker network create servicenet
        fi
      '';
    };
  };

  # this is for services that need to bind a port to the host
  # typically this is only caddy, but some other services that
  # use UDP or special protocols may also need to directly expose
  # a port on the host
  systemd.services.docker-proxynet-network = {
    description = "create docker proxynet network";
    wantedBy = ["multi-user.target"];
    after = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "create-proxynet-network" ''
        if ! ${pkgs.docker}/bin/docker network inspect proxynet >/dev/null 2>&1; then
          ${pkgs.docker}/bin/docker network create proxynet
        fi
      '';
    };
  };

  # this is for services like databases that should only be
  # accessible by other containers
  systemd.services.docker-datanet-network = {
    description = "create docker datanet network";
    wantedBy = ["multi-user.target"];
    after = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "create-datanet-network" ''
        if ! ${pkgs.docker}/bin/docker network inspect datanet >/dev/null 2>&1; then
          ${pkgs.docker}/bin/docker network create datanet --internal
        fi
      '';
    };
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      caddy = {
        image = "ghcr.io/caddybuilds/caddy-cloudflare:2.10.2";
        networks = [
          "proxynet"
          "servicenet"
        ];
        ports = [
          "80:80"
          "443:443"
          "443:443/udp"
          "2019:2019"
        ];
        capabilities = {
          "NET_ADMIN" = true;
        };
        volumes = [
          "${config.age.secrets.pilaster_caddy_caddyfile.path}:/etc/caddy/Caddyfile"
          "/data/docker/caddy/site:/srv"
          "/data/docker/caddy/data:/data"
          "/data/docker/caddy/config:/config"
          "/var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock"
        ];
      };
      postgres = {
        image = "docker.io/postgres:18";
        ports = ["5432:5432"];
        environment = {
          PGDATA = "/var/lib/postgresql/18/docker";
        };
        environmentFiles = [config.age.secrets.pilaster_docker_env_postgres.path];
        networks = [
          "datanet"
          "proxynet"
        ];
        volumes = [
          "/data/docker/postgres/pgdata:/var/lib/postgresql/18/docker"
          "/data/backup/postgres:/backup"
        ];
      };
      # services
      authentik = {
        image = "ghcr.io/goauthentik/server:2025.10.2";
        cmd = ["server"];
        environmentFiles = [config.age.secrets.pilaster_docker_env_authentik.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        volumes = [
          "/data/docker/authentik/media:/media"
          "/data/docker/authentik/templates:/templates"
        ];
      };
      authentik-worker = {
        image = "ghcr.io/goauthentik/server:2025.10.2";
        cmd = ["worker"];
        environmentFiles = [config.age.secrets.pilaster_docker_env_authentik.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/data/docker/authentik/certs:/certs"
          "/data/docker/authentik/media:/media"
          "/data/docker/authentik/templates:/templates"
        ];
      };
      nutify-netrack = {
        image = "dartsteven/nutify:amd64-latest";
        extraOptions = [
          "--privileged"
          "--device=/dev/bus/usb:/dev/bus/usb:rwm"
          "--device-cgroup-rule=c 189:* rwm"
        ];
        environmentFiles = [config.age.secrets.pilaster_docker_env_nutify.path];
        capabilities = {
          SYS_ADMIN = true;
          SYS_RAWIO = true;
          MKNOD = true;
        };
        networks = [
          "servicenet"
          "proxynet"
        ];
        ports = [
          "3494:3493"
        ];
        volumes = [
          "/data/docker/nutify-netrack/logs:/app/nutify/logs"
          "/data/docker/nutify-netrack/instance:/app/nutify/instance"
          "/data/docker/nutify-netrack/ssl:/app/ssl"
          "/data/docker/nutify-netrack/etc/nut:/etc/nut"
          "/dev:/dev:rw"
          "/run/udev:/run/udev:ro"
        ];
      };
      nutify-servers = {
        image = "dartsteven/nutify:amd64-latest";
        extraOptions = [
          "--privileged"
          "--device=/dev/bus/usb:/dev/bus/usb:rwm"
          "--device-cgroup-rule=c 189:* rwm"
        ];
        environmentFiles = [config.age.secrets.pilaster_docker_env_nutify.path];
        capabilities = {
          SYS_ADMIN = true;
          SYS_RAWIO = true;
          MKNOD = true;
        };
        networks = [
          "servicenet"
          "proxynet"
        ];
        ports = [
          "3493:3493"
        ];
        volumes = [
          "/data/docker/nutify-servers/logs:/app/nutify/logs"
          "/data/docker/nutify-servers/instance:/app/nutify/instance"
          "/data/docker/nutify-servers/ssl:/app/ssl"
          "/data/docker/nutify-servers/etc/nut:/etc/nut"
          "/dev:/dev:rw"
          "/run/udev:/run/udev:ro"
        ];
      };
      qdrant = {
        image = "qdrant/qdrant";
        environmentFiles = [config.age.secrets.pilaster_docker_env_qdrant.path];
        networks = [
          "datanet"
          "servicenet"
        ];
        dependsOn = ["postgres"];
        volumes = [
          "/data/docker/qdrant/data:/qdrant/storage"
        ];
      };
      # Supabase Services
      supabase-db = {
        image = "supabase/postgres:15.8.1.085";
        cmd = [
          "postgres"
          "-c"
          "config_file=/etc/postgresql/postgresql.conf"
          "-c"
          "log_min_messages=fatal"
        ];
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_supabase_db.path
        ];
        environment = {
          POSTGRES_HOST = "/var/run/postgresql";
        };
        networks = [
          "datanet"
          "servicenet"
        ];
        volumes = [
          "/data/docker/supabase-db/pgdata:/var/lib/postgresql/data"
          "${./files/supabase/postgres/postgresql.conf}:/etc/postgresql/postgresql.conf:ro"
        ];
        extraOptions = [
          "--health-cmd=pg_isready -U postgres -h localhost"
          "--health-interval=5s"
          "--health-timeout=5s"
          "--health-retries=10"
        ];
      };
      supabase-studio = {
        image = "supabase/studio:2025.11.10-sha-5291fe3";
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_supabase_common.path
          config.age.secrets.pilaster_docker_env_supabase_db.path
        ];
        environment = {
          STUDIO_PG_META_URL = "http://supabase-meta:8080";
          SUPABASE_ANON_KEY = "\${ANON_KEY}";
          SUPABASE_SERVICE_KEY = "\${SERVICE_ROLE_KEY}";
        };
        networks = ["servicenet"];
        dependsOn = ["supabase-db" "supabase-analytics"];
      };
      supabase-kong = {
        image = "kong:2.8.1";
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_supabase_common.path
        ];
        environment = {
          KONG_DATABASE = "off";
          KONG_DECLARATIVE_CONFIG = "/var/lib/kong/kong.yml";
          KONG_DNS_ORDER = "LAST,A,CNAME";
          KONG_PLUGINS = "request-transformer,cors,key-auth,acl,basic-auth,request-termination,ip-restriction";
          KONG_NGINX_PROXY_PROXY_BUFFER_SIZE = "160k";
          KONG_NGINX_PROXY_PROXY_BUFFERS = "64 160k";
          SUPABASE_ANON_KEY = "\${ANON_KEY}";
          SUPABASE_SERVICE_KEY = "\${SERVICE_ROLE_KEY}";
        };
        networks = [
          "servicenet"
          "proxynet"
        ];
        volumes = [
          "${./files/supabase/api/kong.yml}:/var/lib/kong/kong.yml:ro"
        ];
        dependsOn = ["supabase-analytics"];
      };
      supabase-auth = {
        image = "supabase/gotrue:v2.182.1";
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_supabase_common.path
          config.age.secrets.pilaster_docker_env_supabase_db.path
        ];
        environment = {
          GOTRUE_API_HOST = "0.0.0.0";
          GOTRUE_API_PORT = "9999";
          GOTRUE_DB_DRIVER = "postgres";
          GOTRUE_SITE_URL = "\${SITE_URL}";
          GOTRUE_URI_ALLOW_LIST = "*";
          GOTRUE_DISABLE_SIGNUP = "false";
          GOTRUE_JWT_ADMIN_ROLES = "service_role";
          GOTRUE_JWT_AUD = "authenticated";
          GOTRUE_JWT_DEFAULT_GROUP_NAME = "authenticated";
          GOTRUE_EXTERNAL_EMAIL_ENABLED = "true";
          GOTRUE_MAILER_AUTOCONFIRM = "false";
        };
        networks = [
          "servicenet"
          "datanet"
        ];
        dependsOn = [
          "supabase-db"
          "supabase-analytics"
        ];
      };
      supabase-rest = {
        image = "postgrest/postgrest:v13.0.7";
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_supabase_db.path
        ];
        environment = {
          PGRST_DB_USE_LEGACY_GUCS = "false";
          PGRST_APP_SETTINGS_JWT_SECRET = "\${PGRST_JWT_SECRET}";
        };
        networks = [
          "servicenet"
          "datanet"
        ];
        dependsOn = [
          "supabase-db"
          "supabase-analytics"
        ];
      };
      supabase-realtime = {
        image = "supabase/realtime:v2.63.0";
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_supabase_common.path
          config.age.secrets.pilaster_docker_env_supabase_db.path
        ];
        environment = {
          PORT = "4000";
          DB_AFTER_CONNECT_QUERY = "SET search_path TO _realtime";
          DB_ENC_KEY = "supabaserealtime";
          FLY_ALLOC_ID = "fly123";
          FLY_APP_NAME = "realtime";
          ERL_AFLAGS = "-proto_dist inet_tcp";
          ENABLE_TAILSCALE = "false";
          DNS_NODES = "'realtime-dev.supabase-realtime@supabase-realtime'";
        };
        networks = [
          "servicenet"
          "datanet"
        ];
        cmd = [
          "bash"
          "-c"
          "./prod/rel/realtime/bin/realtime eval 'Realtime.Release.migrate' && ./prod/rel/realtime/bin/realtime start"
        ];
        dependsOn = [
          "supabase-db"
          "supabase-analytics"
        ];
      };
      supabase-storage = {
        image = "supabase/storage-api:v1.29.0";
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_supabase_common.path
          config.age.secrets.pilaster_docker_env_supabase_db.path
        ];
        environment = {
          POSTGREST_URL = "http://rest:3000";
          SERVICE_KEY = "\${SERVICE_ROLE_KEY}";
          PGRST_JWT_SECRET = "\${JWT_SECRET}";
          STORAGE_BACKEND = "file";
          FILE_STORAGE_BACKEND_PATH = "/var/lib/storage";
          TENANT_ID = "stub";
          REGION = "stub";
          GLOBAL_S3_BUCKET = "stub";
          ENABLE_IMAGE_TRANSFORMATION = "true";
        };
        networks = [
          "servicenet"
          "datanet"
        ];
        volumes = [
          "/data/docker/supabase/storage:/var/lib/storage"
        ];
        dependsOn = [
          "supabase-db"
          "supabase-rest"
          "supabase-imgproxy"
        ];
      };
      supabase-imgproxy = {
        image = "darthsim/imgproxy:v3.8.0";
        environment = {
          IMGPROXY_BIND = ":5001";
          IMGPROXY_LOCAL_FILESYSTEM_ROOT = "/";
          IMGPROXY_USE_ETAG = "true";
          IMGPROXY_ENABLE_WEBP_DETECTION = "true";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/supabase/storage:/var/lib/storage:ro"
        ];
      };
      supabase-meta = {
        image = "supabase/postgres-meta:v0.93.1";
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_supabase_db.path
        ];
        networks = [
          "servicenet"
          "datanet"
        ];
        dependsOn = [
          "supabase-db"
          "supabase-analytics"
        ];
      };
      supabase-functions = {
        image = "supabase/edge-runtime:v1.69.23";
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_supabase_common.path
          config.age.secrets.pilaster_docker_env_supabase_db.path
        ];
        environment = {
          SUPABASE_ANON_KEY = "\${ANON_KEY}";
          SUPABASE_SERVICE_ROLE_KEY = "\${SERVICE_ROLE_KEY}";
          VERIFY_JWT = "true";
        };
        networks = ["servicenet"];
        volumes = [
          "/data/docker/supabase/functions:/home/deno/functions:ro"
        ];
      };
      supabase-analytics = {
        image = "supabase/logflare:1.22.6";
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_supabase_analytics.path
        ];
        environment = {
          LOGFLARE_NODE_HOST = "0.0.0.0";
          LOGFLARE_SINGLE_TENANT = "true";
          LOGFLARE_SUPABASE_MODE = "true";
          LOGFLARE_MIN_CLUSTER_SIZE = "1";
          POSTGRES_BACKEND_SCHEMA = "_analytics";
          LOGFLARE_API_KEY = "\${LOGFLARE_PUBLIC_ACCESS_TOKEN}";
        };
        networks = [
          "servicenet"
          "datanet"
        ];
        dependsOn = ["supabase-db"];
      };
      supabase-vector = {
        image = "timberio/vector:0.28.1-alpine";
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_supabase_analytics.path
        ];
        networks = ["servicenet"];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
          "${./files/supabase/logs/vector.yml}:/etc/vector/vector.yaml:ro"
        ];
        cmd = ["--config" "/etc/vector/vector.yaml"];
      };
      supabase-pooler = {
        image = "supabase/supavisor:2.7.4";
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_supabase_pooler.path
        ];
        networks = [
          "servicenet"
          "datanet"
        ];
        dependsOn = [
          "supabase-db"
          "supabase-analytics"
        ];
      };
      mcp-gateway = {
        image = "docker/mcp-gateway";
        cmd = [
          "--catalog=/mcp/catalogs/docker-mcp.yaml"
          "--config=/mcp/config.yaml"
          "--registry=/mcp/registry.yaml"
          "--tools-config=/mcp/tools.yaml"
          "--watch=true"
          "--secrets=/secrets/mcp.env"
          "--transport=sse"
          "--port=8811"
        ];
        extraOptions = [
          "--use-api-socket"
        ];
        networks = [
          "servicenet"
        ];
        environmentFiles = [
          config.age.secrets.pilaster_docker_env_mcp_gateway.path
        ];
        volumes = [
          "/home/jmeskill/.docker/mcp:/mcp:ro"
          "${config.age.secrets.pilaster_docker_env_mcp_gateway.path}:/secrets/mcp.env:ro"
        ];
      };
    };
  };

  age.secrets.pilaster_caddy_caddyfile = {
    rekeyFile = ./files/caddy/Caddyfile.age;
    mode = "600";
  };

  # Restart docker-caddy service when Caddyfile secret changes
  systemd.services.docker-caddy = {
    restartTriggers = [config.age.secrets.pilaster_caddy_caddyfile.path];
  };
  age.secrets.pilaster_docker_env_authentik = {
    rekeyFile = ./files/docker/env/authentik.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_postgres = {
    rekeyFile = ./files/docker/env/postgres.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_qdrant = {
    rekeyFile = ./files/docker/env/qdrant.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_nutify = {
    rekeyFile = ./files/docker/env/nutify.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_supabase_common = {
    rekeyFile = ./files/docker/env/supabase-common.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_supabase_db = {
    rekeyFile = ./files/docker/env/supabase-db.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_supabase_analytics = {
    rekeyFile = ./files/docker/env/supabase-analytics.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_supabase_pooler = {
    rekeyFile = ./files/docker/env/supabase-pooler.env.age;
    mode = "600";
  };
  age.secrets.pilaster_docker_env_mcp_gateway = {
    rekeyFile = ./files/docker/env/mcp-gateway.env.age;
    mode = "600";
  };
}
