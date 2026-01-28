# Local PostgreSQL server for chassis
# Used by:
#   - budgey-assistant-dashboard (system service, TCP with password auth)
# Also provides admin access via TCP for MCP tools
{pkgs, ...}: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;

    # Enable TCP/IP for all budgey services
    enableTCPIP = true;

    # Create budgey and budgey_assistant databases and users
    ensureDatabases = ["budgey" "budgey_assistant"];
    ensureUsers = [
      {
        name = "budgey";
        ensureDBOwnership = true;
      }
      {
        name = "budgey_assistant";
        ensureDBOwnership = true;
      }
    ];

    # Identity mapping for peer auth (system user -> db user)
    identMap = ''
      # MAPNAME       SYSTEM-USERNAME   PG-USERNAME
      budgey_map      budgey-assistant  budgey_assistant
    '';

    # Authentication:
    # - Local Unix socket: postgres admin + budgey services (peer auth)
    # - TCP connections: password auth for all services
    authentication = pkgs.lib.mkOverride 10 ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      # Local socket connections - peer auth for postgres and budgey services
      local   all             postgres                                peer
      local   budgey_assistant budgey_assistant                        peer map=budgey_map
      # TCP connections from localhost (password auth for budgey services)
      host    all             all             127.0.0.1/32            scram-sha-256
      host    all             all             ::1/128                 scram-sha-256
      # TCP connections from LAN (password auth)
      host    all             all             10.55.0.0/16            scram-sha-256
      # TCP connections from Tailscale network (password auth)
      host    all             all             100.64.0.0/10           scram-sha-256
    '';

    # NOTE: Set the budgey password after first deploy:
    # sudo -u postgres psql -c "ALTER USER budgey WITH PASSWORD 'xxx';"
  };

  # Open firewall for PostgreSQL (LAN only via Tailscale/local network)
  networking.firewall.allowedTCPPorts = [5432];
}
