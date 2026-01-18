# Local PostgreSQL server for chassis
# Used by budgey-extractor for OpenCode session analytics
{pkgs, ...}: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;

    # Listen only on localhost (no network access needed)
    enableTCPIP = false;

    # Create budgey database and user
    ensureDatabases = ["budgey"];
    ensureUsers = [
      {
        name = "budgey";
        ensureDBOwnership = true;
      }
    ];

    # Allow local connections via Unix socket with peer auth
    # jmeskill can connect as budgey user via: psql -U budgey -d budgey
    authentication = pkgs.lib.mkOverride 10 ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     peer
      local   budgey          budgey                                  peer
    '';

    # Map system user jmeskill to postgres user budgey
    identMap = ''
      # MAPNAME       SYSTEM-USERNAME         PG-USERNAME
      budgey_map      jmeskill                budgey
    '';
  };

  # Add jmeskill to postgres group for socket access
  users.users.jmeskill.extraGroups = ["postgres"];
}
