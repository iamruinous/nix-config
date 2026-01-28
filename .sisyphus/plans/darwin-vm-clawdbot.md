# Deploy clawd.bot to macOS VM on jpex

## Context

### Original Request
Deploy clawd.bot to a virtual machine on macOS. Use nix-darwin to manage VMs declaratively, and nix-clawdbot to deploy clawd.bot. Create modules to make this possible on jpex (Mac mini M4).

### Interview Summary
**Key Discussions**:
- User wants macOS-on-macOS VMs (NOT Linux) for isolation and mac-only features (iMessage, GUI)
- Tart is the best fit for Apple Silicon macOS virtualization
- nix-clawdbot provides Home Manager module, runs as launchd service on macOS
- No existing nix-darwin Tart module exists - need to create one
- Module should be reusable across Darwin hosts
- 1 VM instance initially, GUI+SSH access, autostart on boot
- Plugins: Core + iMessage (summarize, peekaboo, imsg)
- Semi-automated guest setup with documentation
- Verification via dry-build only

**Research Findings**:
- jpex: Mac mini M4, 10 cores, 24GB RAM, macOS 26.2
- Tart: Available in nixpkgs, uses Apple Virtualization.framework
- nix-clawdbot: github:clawdbot/nix-clawdbot (Home Manager module)
- macOS 15+: Requires unlocked login.keychain for headless VMs
- nix-darwin: Has launchd module for managing services

### Metis Review
**Identified Gaps** (addressed):
1. iMessage authentication in VMs - Added validation task
2. Keychain unlock strategy - Added to documentation requirements
3. VM image source - Default to Cirrus Labs registry
4. Guest user account - Use default 'admin' user
5. Secrets delivery to guest - Document manual copy process
6. Resource allocation - Explicit in jpex config (4 cores, 8GB)
7. Persistence strategy - Document, not automate

---

## Work Objectives

### Core Objective
Create a reusable nix-darwin module for Tart VM management, configure jpex to run a macOS VM with nix-clawdbot for clawd.bot deployment.

### Concrete Deliverables
- `modules/darwin/tart-vm.nix` - Reusable Tart VM management module
- `hosts/jpex/tart.nix` - jpex-specific Tart VM configuration
- `hosts/jpex/README.md` - Host documentation (matching other Darwin hosts)
- `docs/CLAWDBOT-VM-SETUP.md` - Guest setup guide (nix-darwin + nix-clawdbot)
- Updated `flake.nix` - Add nix-clawdbot input

### Definition of Done
- [x] `just darwin-dry-build jpex` passes without errors
- [x] Module options documented with `lib.mkOption` descriptions
- [x] jpex README.md follows jmacmini pattern
- [x] Guest setup guide is complete and actionable

### Must Have
- Tart VM module with enable option, VM definitions, resource allocation
- launchd service for VM autostart
- Keychain unlock documentation
- Guest setup documentation for nix-clawdbot

### Must NOT Have (Guardrails)
- NO combined "clawdbot-vm" module - keep Tart generic
- NO automated macOS guest installation
- NO Homebrew for Tart - use nixpkgs
- NO hardcoded jpex-specific values in module
- NO multi-VM support initially (1 VM only)
- NO networking beyond NAT + SSH
- NO monitoring, backup, or snapshot management
- NO actual deployment - dry-build only

---

## Verification Strategy (MANDATORY)

### Test Decision
- **Infrastructure exists**: NO (no test framework for nix-darwin modules)
- **User wants tests**: Manual verification only
- **QA approach**: Dry-build + documentation review

### Manual Execution Verification

**For nix-darwin module changes:**
- [x] Run: `just darwin-dry-build jpex`
- [x] Expected: Build succeeds, no evaluation errors
- [x] Verify: Module options appear in darwin-rebuild --help

**For documentation:**
- [x] Review: README.md follows jmacmini pattern
- [x] Review: Guest setup guide is complete

---

## Task Flow

```
Task 0 (validation)
    ↓
Task 1 → Task 2 → Task 3 → Task 4
                       ↘ Task 5 (parallel)
    ↓
Task 6 (verification)
```

## Parallelization

| Group | Tasks | Reason |
|-------|-------|--------|
| A | 4, 5 | Independent documentation files |

| Task | Depends On | Reason |
|------|------------|--------|
| 2 | 1 | Uses module from task 1 |
| 3 | 1 | Requires module structure |
| 6 | 1-5 | Verifies all prior work |

---

## TODOs

- [x] 0. Validate iMessage works in Tart VMs (CRITICAL BLOCKER)

  **What to do**:
  - Research whether iMessage authentication works in Tart macOS VMs
  - Check Tart GitHub issues for iMessage-related problems
  - If blocking: Document limitation and discuss alternatives with user
  - If works: Proceed with implementation

  **Must NOT do**:
  - Do not skip this validation - it's the core use case

  **Parallelizable**: NO (blocking check)

  **References**:
  - `https://github.com/cirruslabs/tart/issues` - Search for iMessage issues
  - `https://tart.run/faq/` - FAQ for known limitations

  **Acceptance Criteria**:
  - [x] Research completed on iMessage in Tart VMs
  - [x] Decision documented: proceed or pivot

  **Commit**: NO (research only)

---

- [x] 1. Create Tart VM nix-darwin module

  **What to do**:
  - Create `modules/darwin/tart-vm.nix` with:
    - `ruinous.tart-vm.enable` option
    - `ruinous.tart-vm.package` option (default: pkgs.tart)
    - `ruinous.tart-vm.vms.<name>` attrset for VM definitions
    - Each VM has: `enable`, `cpu`, `memory`, `diskSize`, `display`, `autostart`, `headless`, `sharedDirs`
    - launchd service generation for autostart VMs
    - Environment setup for `tart` commands
  - Follow existing module patterns from `modules/darwin/desktop/`
  - Use `lib.mkEnableOption`, `lib.mkOption`, `lib.mkIf`

  **Must NOT do**:
  - Do not hardcode host-specific values
  - Do not use Homebrew for Tart
  - Do not create combined clawdbot-vm module
  - Do not add multi-VM management complexity

  **Parallelizable**: NO (foundational)

  **References**:
  **Pattern References**:
  - `modules/darwin/desktop/default.nix` - Module organization pattern
  - `modules/darwin/desktop/aerospace.nix` - Application-specific Darwin module
  - `hosts/obelisk/microvm.nix:12-26` - VM definition pattern (microvm.vms attrset)
  - `modules/nixos/server/docker-caddy.nix:97-329` - Complex service module with options

  **API/Type References**:
  - `https://tart.run/quick-start/` - Tart CLI usage
  - `tart run --help` - Command options for VM execution

  **Documentation References**:
  - `https://nix-darwin.github.io/nix-darwin/manual/` - nix-darwin options reference
  - `https://github.com/nix-darwin/nix-darwin/blob/master/modules/launchd/launchd.nix` - launchd module

  **Acceptance Criteria**:
  - [x] File exists: `modules/darwin/tart-vm.nix`
  - [x] Module has `ruinous.tart-vm.enable` option
  - [x] Module has `ruinous.tart-vm.vms.<name>` attrset
  - [x] VM options include: `enable`, `cpu`, `memory`, `autostart`, `headless`
  - [x] launchd plist generated for autostart VMs
  - [x] `nix eval .#darwinModules.tart-vm` succeeds

  **Commit**: YES
  - Message: `✨ feat(darwin): add Tart VM management module`
  - Files: `modules/darwin/tart-vm.nix`
  - Pre-commit: `nix flake check` (if available)

---

- [x] 2. Add nix-clawdbot flake input

  **What to do**:
  - Add nix-clawdbot to `flake.nix` inputs:
    ```nix
    nix-clawdbot.url = "github:clawdbot/nix-clawdbot";
    nix-clawdbot.inputs.nixpkgs.follows = "nixpkgs";
    ```
  - Run `nix flake lock --update-input nix-clawdbot`

  **Must NOT do**:
  - Do not pin to specific version yet (use main branch)
  - Do not add any host configuration (that's task 3)

  **Parallelizable**: YES (with task 1)

  **References**:
  - `flake.nix:119-150` - Existing flake input patterns
  - `https://github.com/clawdbot/nix-clawdbot/blob/main/flake.nix` - nix-clawdbot flake structure

  **Acceptance Criteria**:
  - [x] `flake.nix` has `nix-clawdbot` input
  - [x] `nix flake lock` succeeds
  - [x] `nix eval .#inputs.nix-clawdbot` shows the flake

  **Commit**: YES
  - Message: `📦 build(flake): add nix-clawdbot input`
  - Files: `flake.nix`, `flake.lock`
  - Pre-commit: `nix flake check`

---

- [x] 3. Configure jpex with Tart VM for clawdbot

  **What to do**:
  - Create `hosts/jpex/tart.nix` with:
    - Import Tart module
    - Enable Tart VM management
    - Define clawdbot VM with resources (4 cores, 8GB RAM)
    - Enable autostart
    - Configure shared directory for secrets (if needed)
  - Update `hosts/jpex/darwin-configuration.nix` to import tart.nix
  - Create agenix secrets structure (placeholder files):
    - `hosts/jpex/files/clawdbot/telegram-token.age` (placeholder)
    - `hosts/jpex/files/clawdbot/anthropic-key.age` (placeholder)

  **Must NOT do**:
  - Do not configure nix-clawdbot (that's in guest, not host)
  - Do not hardcode real credentials
  - Do not deploy (dry-build only)

  **Parallelizable**: NO (depends on task 1)

  **References**:
  **Pattern References**:
  - `hosts/jmacmini/darwin-configuration.nix` - Darwin host config pattern
  - `hosts/obelisk/microvm.nix` - VM host configuration pattern
  - `secrets/README.md` - Secrets management patterns

  **Acceptance Criteria**:
  - [x] File exists: `hosts/jpex/tart.nix`
  - [x] `darwin-configuration.nix` imports `./tart.nix`
  - [x] Clawdbot VM defined with 4 cores, 8GB RAM
  - [x] Autostart enabled
  - [x] Secrets placeholder structure created
  - [x] `just darwin-dry-build jpex` succeeds

  **Commit**: YES
  - Message: `✨ feat(jpex): add Tart VM configuration for clawdbot`
  - Files: `hosts/jpex/tart.nix`, `hosts/jpex/darwin-configuration.nix`
  - Pre-commit: `just darwin-dry-build jpex`

---

- [x] 4. Create jpex README.md

  **What to do**:
  - Create `hosts/jpex/README.md` following jmacmini pattern
  - Include:
    - Hardware specs (Mac mini M4, 10 cores, 24GB RAM)
    - Platform (aarch64-darwin)
    - Key features (development environment, Tart VM hosting)
    - Tart VM section documenting clawdbot VM
    - User configuration
    - Purpose statement

  **Must NOT do**:
  - Do not deviate from existing README patterns
  - Do not include sensitive information

  **Parallelizable**: YES (with task 5)

  **References**:
  - `hosts/jmacmini/README.md` - Darwin host README pattern
  - `hosts/obelisk/README.md` - VM host README pattern (for Tart section inspiration)

  **Acceptance Criteria**:
  - [x] File exists: `hosts/jpex/README.md`
  - [x] Hardware section matches neofetch/system_profiler output
  - [x] Tart VM section documents clawdbot VM
  - [x] Follows jmacmini README structure

  **Commit**: YES
  - Message: `📚 docs(jpex): add host README`
  - Files: `hosts/jpex/README.md`
  - Pre-commit: None

---

- [x] 5. Create clawdbot VM guest setup guide

  **What to do**:
  - Create `docs/CLAWDBOT-VM-SETUP.md` with:
    - Prerequisites (Tart installed, base macOS image)
    - VM creation steps (`tart clone`, `tart set`)
    - macOS initial setup (user account, skip Apple ID initially)
    - Nix installation in guest (Determinate Systems installer)
    - nix-darwin setup in guest
    - nix-clawdbot configuration
    - Telegram bot setup (@BotFather, @userinfobot)
    - Anthropic API key setup
    - Secrets file creation
    - Testing clawdbot connection
    - Keychain unlock for headless operation
    - Troubleshooting section

  **Must NOT do**:
  - Do not automate guest setup
  - Do not include real credentials
  - Do not assume iMessage works without validation

  **Parallelizable**: YES (with task 4)

  **References**:
  - `https://github.com/clawdbot/nix-clawdbot/blob/main/README.md` - nix-clawdbot setup
  - `https://tart.run/quick-start/` - Tart VM creation
  - `https://docs.determinate.systems/determinate-nix/` - Nix installation

  **Acceptance Criteria**:
  - [x] File exists: `docs/CLAWDBOT-VM-SETUP.md`
  - [x] All setup steps are documented
  - [x] Keychain unlock documented
  - [x] Troubleshooting section exists

  **Commit**: YES
  - Message: `📚 docs: add clawdbot VM guest setup guide`
  - Files: `docs/CLAWDBOT-VM-SETUP.md`
  - Pre-commit: None

---

- [x] 6. Verify complete implementation

  **What to do**:
  - Run `just darwin-dry-build jpex`
  - Verify no evaluation errors
  - Review all created files
  - Ensure documentation is complete

  **Must NOT do**:
  - Do not deploy to jpex
  - Do not create actual VMs

  **Parallelizable**: NO (final verification)

  **References**:
  - `justfile` - Build commands

  **Acceptance Criteria**:
  - [x] `just darwin-dry-build jpex` passes
  - [x] No nix evaluation errors
  - [x] All 5 deliverables complete

  **Commit**: NO (verification only)

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1 | `✨ feat(darwin): add Tart VM management module` | modules/darwin/tart-vm.nix | nix eval |
| 2 | `📦 build(flake): add nix-clawdbot input` | flake.nix, flake.lock | nix flake check |
| 3 | `✨ feat(jpex): add Tart VM configuration for clawdbot` | hosts/jpex/tart.nix, hosts/jpex/darwin-configuration.nix | darwin-dry-build |
| 4 | `📚 docs(jpex): add host README` | hosts/jpex/README.md | - |
| 5 | `📚 docs: add clawdbot VM guest setup guide` | docs/CLAWDBOT-VM-SETUP.md | - |

---

## Success Criteria

### Verification Commands
```bash
# Verify Tart module evaluates
nix eval .#darwinModules.tart-vm

# Verify jpex configuration builds
just darwin-dry-build jpex

# Verify flake inputs
nix flake metadata
```

### Final Checklist
- [x] All "Must Have" present (module, launchd service, docs)
- [x] All "Must NOT Have" absent (no automation, no deployment)
- [x] Dry-build passes
- [x] Documentation complete
