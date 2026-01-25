# Pilaster Caddy configuration using docker-caddy module
#
# Routes migrated from Caddyfile.age
# See files/caddy/README.md for route documentation
{config, ...}: {
  services.docker-caddy = {
    enable = true;
    secretsFile = config.age.secrets.pilaster_caddy_secrets.path;
    email = "admin@meskill.network";

    # Simple reverse proxy routes
    routes = {
      # Authentik identity provider
      "auth.meskill.farm" = {
        upstream = "authentik:9000";
        description = "Authentik identity provider";
      };

      # ArchiveBox web archiver
      "archive.meskill.farm" = {
        upstream = "archivebox:8000";
        description = "ArchiveBox web archiver";
      };

      # Homebox inventory
      "homebox.meskill.farm" = {
        upstream = "homebox:7745";
        description = "Homebox inventory";
      };

      # Rallly polls (internal)
      "poll-int.meskill.family" = {
        upstream = "rallly:3000";
        description = "Rallly polls (internal)";
      };

      # Rallly polls (external)
      "poll.meskill.family" = {
        upstream = "rallly:3000";
        description = "Rallly polls (external)";
      };

      # Azimutt database explorer
      "azimutt.meskill.farm" = {
        upstream = "azimutt:4000";
        description = "Azimutt database explorer";
      };

      # Wiki.js documentation
      "docs.meskill.farm" = {
        upstream = "wikijs:3000";
        description = "Wiki.js documentation";
      };

      # Wiki.js documentation (alt)
      "wiki.meskill.farm" = {
        upstream = "wikijs:3000";
        description = "Wiki.js documentation (alt)";
      };

      # Music Assistant (internal) - uses host networking
      "ma-int.meskill.farm" = {
        upstream = "172.17.0.1:8095";
        description = "Music Assistant (internal)";
      };

      # Music Assistant (external) - uses host networking
      "ma.meskill.farm" = {
        upstream = "172.17.0.1:8097";
        description = "Music Assistant (external)";
      };

      # Music Assistant Alexa (internal)
      "ma-alexa-int.meskill.farm" = {
        upstream = "music-assistant-alexa:8080";
        description = "Music Assistant Alexa (internal)";
      };

      # Music Assistant Alexa (external)
      "ma-alexa.meskill.farm" = {
        upstream = "music-assistant-alexa:8080";
        description = "Music Assistant Alexa (external)";
      };

      # Model Context Protocol gateway
      "mcp.meskill.farm" = {
        upstream = "mcp-gateway:8080";
        description = "Model Context Protocol gateway";
      };

      # Nutify UPS monitor (Netrack)
      "nutify-netrack.meskill.farm" = {
        upstream = "nutify-netrack:5000";
        description = "Nutify UPS monitor (Netrack)";
      };

      # Nutify UPS monitor (Servers)
      "nutify-servers.meskill.farm" = {
        upstream = "nutify-servers:5000";
        description = "Nutify UPS monitor (Servers)";
      };

      # Qdrant vector database
      "qdrant.meskill.farm" = {
        upstream = "qdrant:6333";
        description = "Qdrant vector database";
      };

      # Monica CRM (internal)
      "monica-int.meskill.farm" = {
        upstream = "monica:80";
        description = "Monica CRM (internal)";
      };

      # Monica CRM (external)
      "monica.meskill.farm" = {
        upstream = "monica:80";
        description = "Monica CRM (external)";
      };

      # Twenty CRM (internal)
      "twenty-int.meskill.farm" = {
        upstream = "twenty:3000";
        description = "Twenty CRM (internal)";
      };

      # Twenty CRM (external)
      "twenty.meskill.farm" = {
        upstream = "twenty:3000";
        description = "Twenty CRM (external)";
      };

      # Netboot.xyz PXE server
      "netboot.meskill.farm" = {
        upstream = "netbootxyz:3000";
        description = "Netboot.xyz PXE server";
      };

      # Filestash file manager
      "files.meskill.farm" = {
        upstream = "filestash:8334";
        description = "Filestash file manager";
      };

      # Homarr dashboard
      "homarr.meskill.farm" = {
        upstream = "homarr:7575";
        description = "Homarr dashboard";
      };

      # FreshRSS feed aggregator
      "rss.meskill.farm" = {
        upstream = "freshrss:80";
        description = "FreshRSS feed aggregator";
      };

      # --- ruinous.social Services (Migrated) ---

      # Alby Hub Bitcoin wallet (internal)
      "alby-int.ruinous.social" = {
        upstream = "albyhub:8080";
        description = "Alby Hub Bitcoin wallet (internal)";
      };

      # Alby Hub Bitcoin wallet (external)
      "alby.ruinous.social" = {
        upstream = "albyhub:8080";
        description = "Alby Hub Bitcoin wallet (external)";
      };

      # Baikal CalDAV/CardDAV (internal)
      "dav-int.ruinous.social" = {
        upstream = "baikal:80";
        description = "Baikal CalDAV/CardDAV (internal)";
      };

      # Baikal CalDAV/CardDAV (external)
      "dav.ruinous.social" = {
        upstream = "baikal:80";
        description = "Baikal CalDAV/CardDAV (external)";
      };

      # Mealie recipes (internal)
      "meals-int.ruinous.social" = {
        upstream = "mealie:9000";
        description = "Mealie recipes (internal)";
      };

      # Mealie recipes (external)
      "meals.ruinous.social" = {
        upstream = "mealie:9000";
        description = "Mealie recipes (external)";
      };

      # WriteFreely blog (internal)
      "blog-int.ruinous.social" = {
        upstream = "writefreely:80";
        description = "WriteFreely blog (internal)";
      };

      # WriteFreely blog (external)
      "blog.ruinous.social" = {
        upstream = "writefreely:80";
        description = "WriteFreely blog (external)";
      };

      # Karakeep bookmarks (internal)
      "keep-int.ruinous.social" = {
        upstream = "karakeep:3000";
        description = "Karakeep bookmarks (internal)";
      };

      # Karakeep bookmarks (external)
      "keep.ruinous.social" = {
        upstream = "karakeep:3000";
        description = "Karakeep bookmarks (external)";
      };

      # Karakeep bookmarks (legacy)
      "hoarder.ruinous.social" = {
        upstream = "karakeep:3000";
        description = "Karakeep bookmarks (legacy)";
      };

      # Karakeep bookmarks (alt)
      "karakeep.ruinous.social" = {
        upstream = "karakeep:3000";
        description = "Karakeep bookmarks (alt)";
      };

      # LinkStack links (internal)
      "links-int.ruinous.social" = {
        upstream = "linkstack:80";
        description = "LinkStack links (internal)";
      };

      # LinkStack links (external)
      "links.ruinous.social" = {
        upstream = "linkstack:80";
        description = "LinkStack links (external)";
      };
    };

    # Complex routes with raw Caddy config
    rawRoutes = {
      # Matrix homeserver (internal) - path-based routing
      "matrix-int.ruinous.social" = {
        description = "Matrix homeserver (internal)";
        config = ''
          reverse_proxy /_matrix/maubot/* maubot:29316
          reverse_proxy /_matrix/* synapse:8008
          reverse_proxy /_synapse/client/* synapse:8008
        '';
      };

      # Matrix homeserver (external) - path-based routing
      "matrix.ruinous.social" = {
        description = "Matrix homeserver (external)";
        config = ''
          reverse_proxy /_matrix/maubot/* maubot:29316
          reverse_proxy /_matrix/* synapse:8008
          reverse_proxy /_synapse/client/* synapse:8008
        '';
      };

      # Mastodon + Matrix (internal)
      "ruinous-int.ruinous.social" = {
        description = "Mastodon + Matrix (internal)";
        config = ''
          reverse_proxy /api/v1/streaming/* mastodon-streaming:4000
          reverse_proxy mastodon-web:3000
        '';
      };

      # Mastodon + Matrix (external)
      "ruinous.social" = {
        description = "Mastodon + Matrix (external)";
        config = ''
          reverse_proxy /api/v1/streaming/* mastodon-streaming:4000
          reverse_proxy mastodon-web:3000
        '';
      };
    };
  };

  # Caddy secrets (global config with ACME credentials)
  age.secrets.pilaster_caddy_secrets = {
    rekeyFile = ./files/caddy/secrets.age;
    mode = "600";
  };
}
