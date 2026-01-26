# Budgey Assistant Tools Integration

## Context

### Original Request
Integrate budgey-assistant-ingest-tools and budgey-assistant-dashboard into the nix-config infrastructure for multi-host token tracking and cost analysis across all AI assistants.

### Research Summary

**Existing Infrastructure (chassis):**
- PostgreSQL 17 with `budgey` database and user (TCP auth, password-based)
- Weaviate native service with Ollama text2vec integration
- Caddy reverse proxy with Cloudflare DNS ACME
- Existing `budgey-dashboard` (old version) at `budgey.ruinous.ai:8888`
- Existing `budgey-extractor` user timer service (hourly)
- Ollama with Vulkan backend (ROCm issues on gfx1151)

**Flake Inputs Already Added:**
- `budgey-assistant-ingest-tools` (v0.11.0) - extractors, enrich, ingest, export
- `budgey-assistant-dashboard` (main) - new dashboard

**Target Architecture:**
```
[zenith/other hosts] extractors → git push → [assistant-sessions-archive]
                                                      ↓
[chassis] git pull → enrich (ollama) → ingest (postgres/weaviate)
                                                      ↓
                                      [budgey-assistant-dashboard]
                                      assistants.dashboard.ruinage.ai
```

### Key Differences from Old budgey-extractor

| Feature | Old (budgey-extractor) | New (budgey-assistant-ingest-tools) |
|---------|------------------------|-------------------------------------|
| Format | Direct to Postgres | JSONL archive → then ingest |
| Assistants | OpenCode only | OpenCode, Claude Code, Codex, Gemini |
| Enrichment | None | ML summaries via Ollama |
| Archive | None | Git-versioned JSONL |
| Multi-host | Single host | Archive-based sync |

---

## Work Objectives

### Core Objective
Deploy the new budgey-assistant pipeline with extractors on multiple hosts, centralized enrich/ingest on chassis, and a new dashboard at `assistants.dashboard.ruinage.ai`.

### Concrete Deliverables
1. `hosts/chassis/budgey-assistant.nix` - New pipeline configuration
2. `hosts/chassis/caddy.nix` - Add `assistants.dashboard.ruinage.ai` route
3. Postgres database `budgey_assistant` (separate from old `budgey`)
4. Encrypted secrets for new pipeline
5. Systemd services for extract/enrich/ingest
6. Extractor configuration for zenith (and pattern for other hosts)

### Definition of Done
- [ ] `curl https://assistants.dashboard.ruinage.ai` returns dashboard
- [ ] Extractors run on chassis and zenith
- [ ] Archive repo cloned and receiving commits
- [ ] Enrich/ingest pipeline populating new database
- [ ] Weaviate schema created for semantic search

### Must Have
- Separate database from old budgey (migration path later)
- Git-based archive sync between hosts
- Scheduled extraction (hourly)
- Scheduled enrich/ingest (after extraction)
- Dashboard accessible via HTTPS

### Must NOT Have (Guardrails)
- Do NOT modify existing `budgey-dashboard.nix` or `budgey` database
- Do NOT break existing `budgey.ruinous.ai` dashboard
- Do NOT hardcode credentials in nix files
- Do NOT use `:latest` Docker tags
- Do NOT skip secrets encryption

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: YES (just, nix build)
- **User wants tests**: Manual verification
- **Framework**: N/A (infrastructure)

### Manual Verification Procedures
Each task includes specific `curl`, `psql`, or `systemctl` commands to verify.

---

## Task Flow

```
1. Create Postgres DB
       ↓
2. Create Weaviate schema
       ↓
3. Clone archive repo → 4. Create secrets (parallel)
       ↓                        ↓
5. Create budgey-assistant.nix (depends on 1,2,3,4)
       ↓
6. Add Caddy route
       ↓
7. Add DNS record
       ↓
8. Deploy chassis
       ↓
9. Configure zenith extractors
       ↓
10. Deploy zenith
       ↓
11. End-to-end verification
```

## Parallelization

| Group | Tasks | Reason |
|-------|-------|--------|
| A | 3, 4 | Archive clone and secrets are independent |

| Task | Depends On | Reason |
|------|------------|--------|
| 5 | 1, 2, 3, 4 | Needs DB, Weaviate, archive, secrets |
| 6 | 5 | Needs service port defined |
| 8 | 5, 6, 7 | Needs full config |
| 10 | 8 | Zenith pushes to archive that chassis pulls |

---

## TODOs

- [ ] 1. Provision PostgreSQL database `budgey_assistant`

  **What to do**:
  - Edit `hosts/chassis/postgres.nix`
  - Add `budgey_assistant` to `ensureDatabases`
  - Add `budgey_assistant` user to `ensureUsers` with `ensureDBOwnership = true`
  - Deploy and set password manually

  **Must NOT do**:
  - Modify existing `budgey` database or user
  - Store password in nix files

  **Parallelizable**: NO (foundation task)

  **References**:
  - `hosts/chassis/postgres.nix:14-21` - Existing pattern for budgey database
  - `hosts/chassis/postgres.nix:39-40` - Password setting pattern

  **Acceptance Criteria**:
  - [ ] `sudo nixos-rebuild switch --flake .#chassis`
  - [ ] `sudo -u postgres psql -c "\du"` shows `budgey_assistant` user
  - [ ] `sudo -u postgres psql -c "\l"` shows `budgey_assistant` database
  - [ ] Set password: `sudo -u postgres psql -c "ALTER USER budgey_assistant WITH PASSWORD 'xxx';"`

  **Commit**: YES
  - Message: `feat(chassis): add budgey_assistant PostgreSQL database`
  - Files: `hosts/chassis/postgres.nix`

---

- [ ] 2. Create Weaviate schema for budgey-assistant

  **What to do**:
  - Research required schema from budgey-assistant-ingest-tools
  - Create schema via Weaviate REST API or migration script
  - Document schema in comments

  **Must NOT do**:
  - Delete existing Weaviate collections
  - Modify existing schema

  **Parallelizable**: NO (depends on Weaviate service running)

  **References**:
  - `hosts/chassis/weaviate.nix` - Weaviate service config
  - budgey-assistant-ingest-tools README - Schema requirements

  **Acceptance Criteria**:
  - [ ] `curl -H "Authorization: Bearer $API_KEY" http://localhost:8080/v1/schema` shows new collection
  - [ ] Collection configured with `text2vec-ollama` vectorizer

  **Commit**: NO (runtime configuration, not nix)

---

- [ ] 3. Clone assistant-sessions-archive repository

  **What to do**:
  - Create `/data/budgey/archive` directory structure
  - Clone `git@forge.meskill.farm:iamruinous/assistant-sessions-archive.git`
  - Configure git user for commits
  - Set up SSH key for push access

  **Must NOT do**:
  - Use HTTPS (needs SSH for push)
  - Clone as root (use service user)

  **Parallelizable**: YES (with task 4)

  **References**:
  - `hosts/chassis/weaviate.nix:73` - StateDirectory pattern
  - Archive repo structure from budgey-assistant-ingest-tools README

  **Acceptance Criteria**:
  - [ ] `/data/budgey/archive/.git` exists
  - [ ] `git -C /data/budgey/archive remote -v` shows forge.meskill.farm
  - [ ] Can push: `git -C /data/budgey/archive push --dry-run`

  **Commit**: YES
  - Message: `feat(chassis): add budgey archive directory setup`
  - Files: `hosts/chassis/budgey-assistant.nix` (directory creation)

---

- [ ] 4. Create encrypted secrets for budgey-assistant

  **What to do**:
  - Create `hosts/chassis/files/budgey-assistant/env.age` with:
    - `DATABASE_URL=postgresql://budgey_assistant:xxx@localhost/budgey_assistant`
    - `WEAVIATE_URL=http://localhost:8080`
    - `WEAVIATE_API_KEY=xxx`
    - `OLLAMA_URL=http://localhost:11434`
    - `BUDGEY_ARCHIVE=/data/budgey/archive`
  - Create dashboard env file with same DB/Weaviate credentials
  - Add to `secrets/secrets.nix`
  - Run `agenix rekey -a`

  **Must NOT do**:
  - Commit unencrypted files
  - Reuse old budgey secrets (different database)

  **Parallelizable**: YES (with task 3)

  **References**:
  - `hosts/chassis/users/jmeskill/home-configuration.nix:274-277` - budgey env pattern
  - `hosts/chassis/budgey-dashboard.nix:24-28` - dashboard secrets pattern
  - `/encrypt-secret` skill

  **Acceptance Criteria**:
  - [ ] `hosts/chassis/files/budgey-assistant/env.age` exists
  - [ ] `hosts/chassis/files/budgey-assistant/dashboard.env.age` exists
  - [ ] `agenix rekey -a` succeeds
  - [ ] `git status` shows rekeyed files

  **Commit**: YES
  - Message: `feat(chassis): add budgey-assistant encrypted secrets`
  - Files: `hosts/chassis/files/budgey-assistant/*.age`, `secrets/secrets.nix`

---

- [ ] 5. Create `hosts/chassis/budgey-assistant.nix`

  **What to do**:
  - Create new module for budgey-assistant services
  - Import `flake.inputs.budgey-assistant-dashboard.nixosModules.default`
  - Configure dashboard service on port 8889 (different from old 8888)
  - Create systemd services:
    - `budgey-assistant-extract` - Run all extractors
    - `budgey-assistant-enrich` - Run enrichment
    - `budgey-assistant-ingest` - Load to Postgres/Weaviate
    - `budgey-assistant-sync` - Git pull/push archive
  - Create systemd timers for scheduled runs
  - Add age.secrets declarations

  **Must NOT do**:
  - Use same port as old dashboard (8888)
  - Modify `budgey-dashboard.nix`

  **Parallelizable**: NO (depends on 1, 2, 3, 4)

  **References**:
  - `hosts/chassis/budgey-dashboard.nix` - Dashboard service pattern
  - `hosts/chassis/users/jmeskill/home-configuration.nix:281-310` - Timer pattern
  - `hosts/chassis/weaviate.nix:31-86` - Systemd service pattern
  - budgey-assistant-ingest-tools README - CLI commands

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.chassis.config.systemd.services.budgey-assistant-dashboard` succeeds
  - [ ] `nix eval .#nixosConfigurations.chassis.config.systemd.services.budgey-assistant-extract` succeeds
  - [ ] `nix eval .#nixosConfigurations.chassis.config.systemd.timers.budgey-assistant-pipeline` succeeds

  **Commit**: YES
  - Message: `feat(chassis): add budgey-assistant pipeline services`
  - Files: `hosts/chassis/budgey-assistant.nix`, `hosts/chassis/configuration.nix`

---

- [ ] 6. Add Caddy route for `assistants.dashboard.ruinage.ai`

  **What to do**:
  - Edit `hosts/chassis/caddy.nix`
  - Add `budgeyAssistantDashboardHost` virtual host
  - Point to `localhost:8889`
  - Merge into `virtualHosts`

  **Must NOT do**:
  - Modify existing `budgeyDashboardHost` (port 8888)
  - Remove any existing routes

  **Parallelizable**: NO (depends on 5)

  **References**:
  - `hosts/chassis/caddy.nix:117-124` - budgeyDashboardHost pattern
  - `hosts/chassis/caddy.nix:156-157` - virtualHosts merge pattern

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.chassis.config.services.caddy.virtualHosts` includes `assistants.dashboard.ruinage.ai`

  **Commit**: YES (groups with 5)
  - Message: `feat(chassis): add budgey-assistant Caddy route`
  - Files: `hosts/chassis/caddy.nix`

---

- [ ] 7. Add DNS record for `assistants.dashboard.ruinage.ai`

  **What to do**:
  - Use `/add-dns-record` skill
  - Create CNAME pointing to `chassis.meskill.farm` or A record to chassis IP
  - Verify DNS propagation

  **Must NOT do**:
  - Delete existing DNS records
  - Use wrong record type

  **Parallelizable**: YES (independent of nix changes)

  **References**:
  - `/add-dns-record` skill
  - Existing `budgey.ruinous.ai` DNS pattern

  **Acceptance Criteria**:
  - [ ] `dig assistants.dashboard.ruinage.ai` resolves
  - [ ] Points to chassis

  **Commit**: NO (external DNS, not in repo)

---

- [ ] 8. Deploy chassis configuration

  **What to do**:
  - Run `just remote-dry-build chassis` to verify
  - Run `just remote-rebuild chassis` to deploy
  - Verify all services started
  - Set database password
  - Test dashboard

  **Must NOT do**:
  - Deploy without dry-run first
  - Skip password setup

  **Parallelizable**: NO (depends on 5, 6, 7)

  **References**:
  - `justfile` - Deployment commands

  **Acceptance Criteria**:
  - [ ] `just remote-dry-build chassis` succeeds
  - [ ] `just remote-rebuild chassis` succeeds
  - [ ] `systemctl status budgey-assistant-dashboard` shows active
  - [ ] `curl -I https://assistants.dashboard.ruinage.ai` returns 200
  - [ ] `systemctl status budgey-assistant-extract.timer` shows active

  **Commit**: NO (deployment, not code)

---

- [ ] 9. Configure zenith extractors

  **What to do**:
  - Add extractors to zenith user environment (home-manager)
  - Configure `BUDGEY_ARCHIVE` pointing to local archive clone
  - Create systemd user timer for extraction
  - Set up SSH key for archive push
  - Clone archive repo on zenith

  **Must NOT do**:
  - Run enrich/ingest on zenith (chassis only)
  - Store archive credentials in plain text

  **Parallelizable**: NO (depends on 8 - archive must exist)

  **References**:
  - `hosts/chassis/users/jmeskill/home-configuration.nix:281-310` - Timer pattern
  - `modules/shared/universal/packages-overlay.nix:10` - Package overlay pattern

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.zenith.config.systemd.user.services.budgey-extract` succeeds
  - [ ] zenith can push to archive repo

  **Commit**: YES
  - Message: `feat(zenith): add budgey-assistant extractors`
  - Files: `hosts/zenith/users/*/home-configuration.nix`

---

- [ ] 10. Deploy zenith configuration

  **What to do**:
  - Run `just remote-dry-build zenith`
  - Run `just remote-rebuild zenith`
  - Trigger manual extraction
  - Verify archive receives commits

  **Must NOT do**:
  - Deploy before chassis is working

  **Parallelizable**: NO (depends on 8)

  **Acceptance Criteria**:
  - [ ] `just remote-rebuild zenith` succeeds
  - [ ] Manual extraction: `systemctl --user start budgey-extract`
  - [ ] Archive shows new commits from zenith

  **Commit**: NO (deployment)

---

- [ ] 11. End-to-end verification

  **What to do**:
  - Trigger extraction on zenith
  - Verify archive updated
  - Trigger enrich/ingest on chassis
  - Verify dashboard shows data
  - Verify Weaviate has embeddings

  **Must NOT do**:
  - Skip any verification step

  **Parallelizable**: NO (final validation)

  **References**:
  - Dashboard URL: `https://assistants.dashboard.ruinage.ai`
  - Weaviate URL: `https://weaviate.ruinous.ai`

  **Acceptance Criteria**:
  - [ ] Dashboard shows projects and sessions
  - [ ] Semantic search returns results
  - [ ] Cost metrics visible

  **Commit**: NO (verification)

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1 | `feat(chassis): add budgey_assistant PostgreSQL database` | postgres.nix | dry-build |
| 4 | `feat(chassis): add budgey-assistant encrypted secrets` | files/*.age, secrets.nix | agenix rekey |
| 5+6 | `feat(chassis): add budgey-assistant pipeline and dashboard` | budgey-assistant.nix, caddy.nix, configuration.nix | dry-build |
| 9 | `feat(zenith): add budgey-assistant extractors` | zenith user config | dry-build |

---

## Success Criteria

### Verification Commands
```bash
# Dashboard accessible
curl -I https://assistants.dashboard.ruinage.ai

# Services running
ssh chassis systemctl status budgey-assistant-dashboard
ssh chassis systemctl status budgey-assistant-extract.timer

# Database populated
ssh chassis sudo -u postgres psql budgey_assistant -c "SELECT count(*) FROM sessions;"

# Weaviate has data
curl -H "Authorization: Bearer $KEY" https://weaviate.ruinous.ai/v1/objects?class=Session&limit=1

# Zenith extracting
ssh zenith systemctl --user status budgey-extract.timer
```

### Final Checklist
- [ ] Dashboard accessible at `assistants.dashboard.ruinage.ai`
- [ ] Extractors running on chassis and zenith
- [ ] Archive syncing between hosts
- [ ] Enrich adding ML metadata
- [ ] Ingest populating Postgres and Weaviate
- [ ] Old `budgey.ruinous.ai` still working (no regression)

---

## GitHub Issue

Tracking: https://github.com/iamruinous/nix-config/issues/298
