# Messy Attributes Editor - CRUD webservice for messy_attribute table
#
# Exposed at: https://attributes.messy.ruinage.ai
# Backend: PostgreSQL (n8n-agent database on monolith)
#
# Uses N8N_AGENT_PROD_POSTGRES_DATABASE_URI from existing opencode project env
# The service expects DATABASE_URL, so we create a wrapper env file
{
  config,
  pkgs,
  flake,
  ...
}: {
  imports = [
    flake.inputs.messy-attributes-editor.nixosModules.default
  ];

  # Add overlay to make package available as pkgs.messy-attributes-editor
  nixpkgs.overlays = [
    flake.inputs.messy-attributes-editor.overlays.default
  ];

  services.messy-attributes-editor = {
    # DISABLED: Waiting for upstream fix - ludic API incompatibility
    # See: https://forge.meskill.farm/iamruinous/messy-attributes-editor/issues/3
    enable = false;
    package = flake.inputs.messy-attributes-editor.packages.${pkgs.system}.default;
    host = "127.0.0.1";
    port = 8000;
    # Use the n8n project env which contains N8N_AGENT_PROD_POSTGRES_DATABASE_URI
    # The module's ExecStart script will need DATABASE_URL, so we create a wrapper
    environmentFile = config.age.secrets.chassis_messy_attributes_editor_env.path;
  };

  # Wrapper env file that maps N8N_AGENT_PROD_POSTGRES_DATABASE_URI to DATABASE_URL
  # Note: owner/group set to root while service is disabled (user doesn't exist)
  age.secrets.chassis_messy_attributes_editor_env = {
    rekeyFile = ./files/messy-attributes-editor/env.age;
    mode = "400";
    owner = "root";
    group = "root";
  };
}
