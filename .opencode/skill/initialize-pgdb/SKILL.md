---
name: initialize-pgdb
description: Initialize a PostgreSQL database and user on any configured host
compatibility: Requires postgres MCP servers (pilaster, monolith, zenith)
metadata:
  author: ruinous.ai
  version: "1.0"
  domain: database
parameters:
  hostname:
    type: select
    description: PostgreSQL host to create the database on
    required: true
    options:
      - label: "pilaster (Recommended)"
        description: "Main web services - PILASTER_POSTGRES_DATABASE_URI"
      - label: "monolith"
        description: "Infrastructure services - MONOLITH_POSTGRES_DATABASE_URI"
      - label: "zenith"
        description: "AI/GPU workloads - ZENITH_POSTGRES_DATABASE_URI"
      - label: "chassis"
        description: "AI development workstation - CHASSIS_POSTGRES_DATABASE_URI"
      - label: "tty-ruinous-social"
        description: "Cloud VPS - TTY_RUINOUS_SOCIAL_POSTGRES_DATABASE_URI"
  db_name:
    type: string
    description: Database name (also used as username)
    required: true
    placeholder: "myservice"
---

# Initialize PostgreSQL Database

Create a new PostgreSQL database and user with sane defaults on any configured host.

## Parameter Handling

**If parameters are missing from `$ARGUMENTS`, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "Which PostgreSQL host should the database be created on?",
      header: "Host",
      options: [
        { label: "pilaster (Recommended)", description: "Main web services host" },
        { label: "monolith", description: "Infrastructure services" },
        { label: "zenith", description: "AI/GPU workloads" },
        { label: "chassis", description: "AI development workstation" },
        { label: "tty-ruinous-social", description: "Cloud VPS" }
      ]
    },
    {
      question: "What should the database be named? (Also used as username)",
      header: "DB Name",
      options: [
        { label: "Enter name...", description: "e.g., myservice, n8n, wikijs" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `<hostname> <db_name>`
- Example: `pilaster myservice`
- Example: `zenith openwebui`

## Environment Variables

The skill uses these environment variables from `.envrc.local` to connect:

| Host | Environment Variable |
|------|---------------------|
| pilaster | `PILASTER_POSTGRES_DATABASE_URI` |
| monolith | `MONOLITH_POSTGRES_DATABASE_URI` |
| zenith | `ZENITH_POSTGRES_DATABASE_URI` |
| chassis | `CHASSIS_POSTGRES_DATABASE_URI` |
| tty-ruinous-social | `TTY_RUINOUS_SOCIAL_POSTGRES_DATABASE_URI` |

## Steps

### 1. Parse arguments and select MCP tool

Based on hostname, select the appropriate MCP postgres tool:
- `pilaster` → `mcp_postgres-pilaster_query`
- `monolith` → `mcp_postgres-monolith_query`
- `zenith` → `mcp_postgres-zenith_query`
- `tty-ruinous-social` → Not available via MCP (use SSH)

### 2. Generate secure password

```bash
openssl rand -base64 24 | tr -d '/+=' | head -c 20
```

### 3. Create database and user

Run each SQL statement separately using the appropriate MCP tool:

```sql
CREATE DATABASE <db_name>;
```

```sql
CREATE USER <db_name> WITH PASSWORD '<generated_password>';
```

```sql
GRANT ALL PRIVILEGES ON DATABASE <db_name> TO <db_name>;
```

### 4. Grant schema permissions

Connect to the new database and grant schema permissions:

```sql
-- This requires connecting to the new database
-- For MCP tools, this may need to be done via the container
GRANT ALL ON SCHEMA public TO <db_name>;
```

**Note:** The MCP postgres tools connect to the `postgres` database. To grant schema permissions on the new database, you may need to:
1. Use `\c <db_name>` if the tool supports it, OR
2. Run via SSH: `ssh <hostname> "docker exec -i postgres psql -U postgres -d <db_name> -c 'GRANT ALL ON SCHEMA public TO <db_name>;'"`

### 5. Output connection details

Provide the connection string in multiple formats:

**For Docker containers (internal network):**
```
DATABASE_URL=postgresql://<db_name>:<password>@postgres:5432/<db_name>
```

**For external access (via hostname):**
```
DATABASE_URL=postgresql://<db_name>:<password>@<hostname>.meskill.farm:5432/<db_name>
```

### 6. Remind user of next steps

- Add container to `servicenet` and `datanet` networks
- Add `dependsOn = ["postgres"];` to container definition
- Store credentials in encrypted env file using `/encrypt-secret`

## Host Details

| Host | Internal Hostname | Port | Notes |
|------|-------------------|------|-------|
| pilaster | postgres | 5432 | Main web services |
| monolith | postgres | 5432 | Infrastructure |
| zenith | postgres | 5432 | AI workloads |
| tty-ruinous-social | postgres | 5432 | Cloud VPS |

## Example Usage

```bash
# Create database on pilaster
/initialize-pgdb pilaster rallly

# Create database on zenith for AI service
/initialize-pgdb zenith openwebui

# Create database on monolith
/initialize-pgdb monolith gatus
```

## Output Example

```
✅ Database created successfully!

Host: pilaster
Database: rallly
Username: rallly
Password: xK7mN2pQ9rT4vW6y

Connection Strings:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Docker (internal):
DATABASE_URL=postgresql://rallly:xK7mN2pQ9rT4vW6y@postgres:5432/rallly

External:
DATABASE_URL=postgresql://rallly:xK7mN2pQ9rT4vW6y@pilaster.meskill.farm:5432/rallly

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next steps:
1. Add to container networks: ["servicenet", "datanet"]
2. Add dependency: dependsOn = ["postgres"];
3. Encrypt credentials: /encrypt-secret hosts/pilaster/files/docker/env/rallly.env.age
```

## Troubleshooting

### Database already exists
```sql
-- Check if database exists
SELECT datname FROM pg_database WHERE datname = '<db_name>';

-- Drop if needed (CAREFUL!)
DROP DATABASE <db_name>;
DROP USER <db_name>;
```

### User already exists
```sql
-- Check existing users
SELECT usename FROM pg_user WHERE usename = '<db_name>';

-- Update password instead
ALTER USER <db_name> WITH PASSWORD '<new_password>';
```

### Connection refused
- Verify the MCP postgres server is configured in opencode
- Check that the environment variable is set in `.envrc.local`
- Ensure the host is accessible via network
