# Local PostgreSQL server for chassis
# Used by budgey-extractor for OpenCode session analytics
# Also provides admin access via TCP for MCP tools
{pkgs, ...}: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;

    # Enable TCP/IP for remote/MCP access
    enableTCPIP = true;

    # Create budgey database and user
    ensureDatabases = ["budgey"];
    ensureUsers = [
      {
        name = "budgey";
        ensureDBOwnership = true;
      }
    ];

    # Authentication:
    # - Local Unix socket: peer auth (no password)
    # - TCP connections: password auth (for MCP tools)
    authentication = pkgs.lib.mkOverride 10 ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      # Local socket connections (peer auth)
      local   all             all                                     peer
      # TCP connections from localhost and LAN (password auth)
      host    all             postgres        127.0.0.1/32            scram-sha-256
      host    all             postgres        ::1/128                 scram-sha-256
      host    all             postgres        10.55.0.0/16            scram-sha-256
    '';

    # Map system user jmeskill to postgres user budgey
    identMap = ''
      # MAPNAME       SYSTEM-USERNAME         PG-USERNAME
      budgey_map      jmeskill                budgey
    '';

    # NOTE: After first deploy, set the postgres password manually:
    # sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'your-password';"
    # Then add CHASSIS_POSTGRES_DATABASE_URI to .envrc.local
  };

  # Open firewall for PostgreSQL (LAN only via Tailscale/local network)
  networking.firewall.allowedTCPPorts = [5432];

  # Add jmeskill to postgres group for socket access
  users.users.jmeskill.extraGroups = ["postgres"];
}
