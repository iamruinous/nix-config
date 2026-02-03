# OpenCode MCP server secrets for chassis
# These secrets are used by the opencode assistant for MCP server authentication
# All sourced from Infisical /shared path (cross-service tokens)
{config, ...}: {
  # Enable Infisical integration (inherited from parent, but explicit for clarity)
  ruinous.infisical.enable = true;

  # GitHub token for GitHub Copilot MCP
  # Shared across services - same token as openclaw uses
  age.secrets.chassis_opencode_github_token = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "GITHUB_TOKEN";
      path = "/shared";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Forgejo token for Forgejo MCP (forge.meskill.farm)
  # Shared across services - same token as openclaw uses
  age.secrets.chassis_opencode_forgejo_token = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "FORGEJO_TOKEN";
      path = "/shared";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Todoist API token for Todoist MCP
  # Shared across services for task management integration
  age.secrets.chassis_opencode_todoist_token = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "TODOIST_API_TOKEN";
      path = "/shared";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Context7 API key for documentation lookup MCP
  # Shared across services for library documentation access
  age.secrets.chassis_opencode_context7_key = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "CONTEXT7_API_KEY";
      path = "/shared";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };
}
