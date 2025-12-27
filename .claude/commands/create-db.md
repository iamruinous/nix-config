---
description: Create PostgreSQL database and user for a new service
---

Create a new PostgreSQL database and user for an internal service.

**Required arguments:** `$ARGUMENTS` should contain the service name (e.g., "wikijs", "rallly", "myapp")

## Steps

1. **Parse the service name** from `$ARGUMENTS`
   - If no service name provided, ask the user for it

2. **Ask which host** to create the database on:
   - `pilaster` - Main web services host (PostgreSQL 18)
   - `monolith` - Infrastructure services host (PostgreSQL 18)
   - `zenith` - AI/GPU workloads host (PostgreSQL 18)

3. **Generate a secure password:**
   ```bash
   openssl rand -base64 24 | tr -d '/+=' | head -c 20
   ```

4. **Create the database and user** using the appropriate MCP postgres tool:

   For **pilaster**:
   ```
   Use mcp__postgres-pilaster__execute_sql with:
   CREATE DATABASE <service>;
   CREATE USER <service> WITH PASSWORD '<password>';
   GRANT ALL PRIVILEGES ON DATABASE <service> TO <service>;
   \c <service>
   GRANT ALL ON SCHEMA public TO <service>;
   ```

   For **monolith**:
   ```
   Use mcp__postgres-monolith__execute_sql with the same SQL
   ```

   For **zenith**:
   ```
   Use mcp__postgres-zenith__execute_sql with the same SQL
   ```

5. **Output the connection details** for the user to add to their environment file:
   ```
   DATABASE_URL=postgres://<service>:<password>@postgres:5432/<service>
   ```

6. **Remind the user** to:
   - Add the container to the appropriate `datanet` network
   - Add `dependsOn = ["postgres"];` to the container definition

## Example Usage

```
/create-db rallly
```

Creates:
- Database: `rallly`
- User: `rallly`
- Password: (auto-generated)
- Connection string for docker-compose/env file
