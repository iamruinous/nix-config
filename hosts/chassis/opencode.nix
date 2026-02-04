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

  # === n8n-agent project MCP secrets ===
  # These secrets enable file-based authentication for n8n-agent MCP servers
  # Sourced from Infisical /hosts/chassis/n8n-agent path

  # Production n8n API
  age.secrets.chassis_n8n_prod_api_key = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "N8N_PROD_API_KEY";
      path = "/hosts/chassis/n8n-agent";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  age.secrets.chassis_n8n_prod_api_url = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "N8N_PROD_API_URL";
      path = "/hosts/chassis/n8n-agent";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Development n8n API
  age.secrets.chassis_n8n_dev_api_key = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "N8N_DEV_API_KEY";
      path = "/hosts/chassis/n8n-agent";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  age.secrets.chassis_n8n_dev_api_url = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "N8N_DEV_API_URL";
      path = "/hosts/chassis/n8n-agent";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Production PostgreSQL URIs
  age.secrets.chassis_n8n_prod_postgres_uri = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "N8N_PROD_POSTGRES_DATABASE_URI";
      path = "/hosts/chassis/n8n-agent";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  age.secrets.chassis_n8n_agent_prod_postgres_uri = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "N8N_AGENT_PROD_POSTGRES_DATABASE_URI";
      path = "/hosts/chassis/n8n-agent";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Development PostgreSQL URIs
  age.secrets.chassis_n8n_dev_postgres_uri = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "N8N_DEV_POSTGRES_DATABASE_URI";
      path = "/hosts/chassis/n8n-agent";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  age.secrets.chassis_n8n_agent_dev_postgres_uri = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "N8N_AGENT_DEV_POSTGRES_DATABASE_URI";
      path = "/hosts/chassis/n8n-agent";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };
}
