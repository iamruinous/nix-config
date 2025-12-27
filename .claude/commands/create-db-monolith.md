---
description: Create PostgreSQL database and user on monolith
---

Create a new PostgreSQL database and user on **monolith** for an internal service.

**Required arguments:** `$ARGUMENTS` should contain the service name (e.g., "n8n", "gatus", "myapp")

## Steps

1. **Parse the service name** from `$ARGUMENTS`
   - If no service name provided, ask the user for it

2. **Generate a secure password:**
   ```bash
   openssl rand -base64 24 | tr -d '/+=' | head -c 20
   ```

3. **Create the database and user** on monolith using `mcp__postgres-monolith__execute_sql`:

   Run each SQL statement separately:
   ```sql
   CREATE DATABASE <service>;
   ```
   ```sql
   CREATE USER <service> WITH PASSWORD '<password>';
   ```
   ```sql
   GRANT ALL PRIVILEGES ON DATABASE <service> TO <service>;
   ```

   Then connect to the new database and grant schema permissions:
   ```sql
   -- Run against the new database
   GRANT ALL ON SCHEMA public TO <service>;
   ```

4. **Output the connection details** for the user to add to their environment file:
   ```
   DATABASE_URL=postgres://<service>:<password>@postgres:5432/<service>
   ```

5. **Remind the user** to:
   - Add the container to `servicenet` and `datanet` networks
   - Add `dependsOn = ["postgres"];` to the container definition

## Example

```
/create-db-monolith n8n
```
