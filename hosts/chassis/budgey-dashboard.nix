# Budgey Dashboard - Token usage analytics for OpenCode sessions
#
# Public service at https://budgey.ruinous.ai
# Connects to local PostgreSQL (budgey database)
{
  config,
  flake,
  ...
}: {
  imports = [
    flake.inputs.budgey-dashboard.nixosModules.default
  ];

  services.budgey-dashboard = {
    enable = true;
    host = "127.0.0.1";
    port = 8888;
    # Use placeholder - actual URL comes from environment file
    databaseUrl = "postgresql+asyncpg://budgey@localhost/budgey";
    environmentFile = config.age.secrets.chassis_budgey_dashboard_env.path;
  };

  # Encrypted environment file with BUDGEY_DATABASE_URL
  age.secrets.chassis_budgey_dashboard_env = {
    rekeyFile = ./files/budgey-dashboard/env.age;
    mode = "400";
    owner = "budgey-dashboard";
    group = "budgey-dashboard";
  };
}
