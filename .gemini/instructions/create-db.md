# Create Database Recipe

Create a new PostgreSQL database and user for an internal service.

## Usage

When asked to "create a database" or "create a db for X", follow these steps.

**Hosts:**
- `pilaster` (Main web services)
- `monolith` (Infrastructure)
- `zenith` (AI/GPU)

## Steps

1. **Identify the service name** (e.g., "wikijs", "rallly", "myapp"). If not provided, ask.
2. **Identify the host**. If not provided or implied by context, ask the user.

3. **Generate a secure password:**
   ```bash
   openssl rand -base64 24 | tr -d '/+=' | head -c 20
   ```

4. **Create the database and user** using the appropriate MCP postgres tool for the host (`mcp__postgres-pilaster__execute_sql`, `mcp__postgres-monolith__execute_sql`, etc.).

   **SQL Commands (Execute separately):**
   ```sql
   CREATE DATABASE <service>;
   ```
   ```sql
   CREATE USER <service> WITH PASSWORD '<password>';
   ```
   ```sql
   GRANT ALL PRIVILEGES ON DATABASE <service> TO <service>;
   ```

   **Grant Schema Permissions:**
   Connect to the *new* database (this might require a separate tool call specifying the DB name if the tool supports it, or `\c <service>` if the tool supports psql-style commands in a script, otherwise rely on the initial grant or check tool capabilities. The MCP tool likely connects to `postgres` by default. If the tool allows specifying the database, use that. If not, the `GRANT ALL PRIVILEGES ON DATABASE` is usually sufficient for the user to own the DB, but they might need public schema access).

   *Refined Step:*
   ```sql
   -- If possible in the same session or new session to the specific DB
   GRANT ALL ON SCHEMA public TO <service>;
   ```

5. **Output the connection details** for the user to add to their environment file:
   ```
   DATABASE_URL=postgres://<service>:<password>@postgres:5432/<service>
   ```

6. **Remind the user** to:
   - Add the container to the appropriate `datanet` network
   - Add `dependsOn = ["postgres"];` to the container definition

## Example

**User:** "Create a db for n8n on monolith"

**Agent:**
1. Generates password: `abc123...`
2. Calls `mcp__postgres-monolith__execute_sql` with:
   `CREATE DATABASE n8n;`
   `CREATE USER n8n WITH PASSWORD 'abc123...';`
   `GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;`
3. Responds:
   "Created database `n8n` on monolith.
   Connection: `DATABASE_URL=postgres://n8n:abc123...@postgres:5432/n8n`
   Remember to add to `datanet` and depend on `postgres`."
