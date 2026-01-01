# Create Database Recipe

**Description:** Create a new PostgreSQL database and user for an internal service.

## Usage
Use this recipe when asked to "create a database" or "create a db for X".

## Supported Hosts
*   **pilaster** (Main web services)
*   **monolith** (Infrastructure)
*   **zenith** (AI/GPU)

## Steps
1.  **Identify Service & Host:** Ask user if not specified.
2.  **Generate Password:**
    ```bash
    openssl rand -base64 24 | tr -d '/+=' | head -c 20
    ```
3.  **Execute SQL:** Use the appropriate MCP postgres tool (`mcp__postgres-<host>__execute_sql`).
    *   `CREATE DATABASE <service>;`
    *   `CREATE USER <service> WITH PASSWORD '<password>';`
    *   `GRANT ALL PRIVILEGES ON DATABASE <service> TO <service>;`
    *   (Optional/Context dependent) `GRANT ALL ON SCHEMA public TO <service>;`
4.  **Output Connection String:**
    ```
    DATABASE_URL=postgres://<service>:<password>@postgres:5432/<service>
    ```
5.  **Reminders:**
    *   Add container to `datanet`.
    *   Add `dependsOn = ["postgres"]`.
