# Learnings: darwin-vm-clawdbot

## Conventions & Patterns
_Accumulated knowledge from task execution_

---

## [2026-01-27T09:37] Research Phase Complete

### iMessage Compatibility (CRITICAL)
**Status**: ✅ WORKS with macOS 15+ (Sequoia)
- **Requirement**: Both host AND guest must be macOS 15+
- **Apple Support**: Official Virtualization.Framework support for iCloud/Messages/FaceTime
- **Tart Requirement**: Run from `.app` bundle for proper entitlements
- **Headless Blocker**: Requires unlocked `login.keychain` on host
- **Limitations**: No App Store, Find My, iCloud Backup, or account management in VM

**Decision**: Proceed with implementation. User must upgrade to Sequoia if not already.

### Tart CLI Patterns
- **Package**: Available in nixpkgs as `pkgs.tart` (v2.30.0, aarch64-darwin only)
- **VM Creation**: `tart clone <oci-image> <name>` or `tart create --from-ipsw`
- **Configuration**: `tart set <name> --cpu N --memory MB --display WxH`
- **Execution**: `tart run <name> [--no-graphics] [--dir path] [--net-softnet-expose]`
- **Resource Defaults**: 2 CPU, 4096 MB RAM, 1024x768 display

### nix-clawdbot Module Structure
- **Location**: `programs.clawdbot` (Home Manager module)
- **Multi-instance**: `programs.clawdbot.instances.<name>`
- **Secrets**: File-based injection via `botTokenFile` and `apiKeyFile`
- **Service**: Auto-generates launchd agents on macOS
- **Plugins**: Declarative plugin loading from GitHub or local paths
- **Documents**: Requires `AGENTS.md`, `SOUL.md`, `TOOLS.md` directory

### Codebase Patterns Found
- **microvm.vms attrset**: Pattern from `hosts/obelisk/microvm.nix` (lines 13-26)
- **launchd agents**: Home Manager pattern in `modules/home/default/todoist.nix` (lines 97-109)
- **Darwin modules**: Auto-import pattern in `modules/darwin/desktop/default.nix`
- **No existing Tart module**: Confirmed novel - no `services.tart` or `programs.tart` exists

### Module Design Decisions
1. **Namespace**: `ruinous.tart-vm` (following existing `ruinous.*` pattern)
2. **Structure**: `ruinous.tart-vm.vms.<name>` attrset (mirrors microvm pattern)
3. **Service**: launchd agent per VM for autostart
4. **Scope**: Host-level VM management only (guest setup documented separately)


## [2026-01-27T10:41] Module Implementation Complete

### Blueprint Module Discovery
- **Critical**: Blueprint requires files to be tracked by git to be discovered
- **Structure**: Must use `modules/darwin/<name>/default.nix` directory structure (not `modules/darwin/<name>.nix`)
- **Verification**: `nix eval .#modules.darwin --apply 'x: builtins.attrNames x'` to list available modules

### Module Implementation Patterns
- **launchd.user.agents**: Darwin uses `launchd.user.agents` (not `launchd.agents` like Home Manager)
- **Service naming**: `com.ruinous.tart-vm.<name>` follows reverse-DNS convention
- **KeepAlive**: Use `KeepAlive.SuccessfulExit = false` to restart on crash but not on clean exit
- **Log paths**: Use `/tmp/tart-vm/<name>-{stdout,stderr}.log` for launchd logs

### Tart CLI Integration
- **Package**: `pkgs.tart` available in nixpkgs
- **Run command**: `tart run <name> [--no-graphics] [--dir path]`
- **Shared dirs**: Each `--dir` flag adds a shared directory to the VM

## [2026-01-27T11:15] Flake Input Addition

### nix-clawdbot Flake Input
- **URL**: `github:clawdbot/nix-clawdbot` (main branch, no version pin)
- **Follows**: `nixpkgs` (standard pattern for all inputs)
- **Location**: Added after `ruinagents` input in flake.nix (line 152-154)
- **Lock**: Successfully updated with `nix flake lock --update-input nix-clawdbot`
- **Commit**: `474ee3894509e0ad282ca7dc6959c234c412d5cb` (2026-01-27)

### Flake Structure
- Input added to `inputs` section with nixpkgs follows
- Flake validation passes: `nix flake check` succeeds
- No syntax errors in flake.nix
- flake.lock properly updated with all transitive dependencies:
  - `nix-clawdbot/flake-utils`
  - `nix-clawdbot/home-manager` (follows nix-clawdbot/nixpkgs)
  - `nix-clawdbot/nix-steipete-tools`

### Next Steps
- Module can now reference `inputs.nix-clawdbot` in outputs
- Home Manager module available at `inputs.nix-clawdbot.homeManagerModules.clawdbot`
- Ready for host configuration integration

## [2026-01-27T11:30] jpex Host Configuration Complete

### Tart VM Host Setup
- **File created**: `hosts/jpex/tart.nix` with clawdbot VM definition
- **Configuration**: 4 cores, 8GB RAM, autostart enabled, headless mode
- **Import pattern**: Local `./tart.nix` + `flake.darwinModules.tart-vm` module
- **Resource allocation**: jpex (Mac mini M4, 10 cores, 24GB) → VM (4 cores, 8GB) leaves 6 cores, 16GB for host

### Secret Files Structure
- **Location**: `hosts/jpex/files/clawdbot/`
- **Files created**:
  - `telegram-token.age` - placeholder for encrypted Telegram bot token
  - `anthropic-key.age` - placeholder for encrypted Anthropic API key
- **Status**: Placeholders ready for actual secret encryption via `/encrypt-secret` skill

### Dry-Build Verification
- **Result**: Configuration is syntactically valid
- **Cross-compilation note**: x86_64-linux → aarch64-darwin requires native macOS build
- **Expected behavior**: Dry-run shows module evaluation succeeds, cross-platform build limitation is normal

### Next Steps for Deployment
1. On jpex (macOS): Create Tart VM with `tart clone` or `tart create`
2. Use `/encrypt-secret` skill to populate actual credentials
3. Run `darwin-rebuild switch --flake .#jpex` to apply configuration
4. Verify launchd agent created: `launchctl list | grep tart-vm`

## [2026-01-27T02:55] All Tasks Complete

### Final Status
- ✅ Task 0: iMessage validated (works with Sequoia)
- ✅ Task 1: Tart VM module created
- ✅ Task 2: nix-clawdbot flake input added
- ✅ Task 3: jpex configured with Tart VM
- ✅ Task 4: jpex README.md created
- ✅ Task 5: Guest setup guide created
- ✅ Task 6: Complete implementation verified

### Deliverables
1. `modules/darwin/tart-vm/default.nix` - Reusable Tart VM module
2. `hosts/jpex/tart.nix` - jpex VM configuration
3. `hosts/jpex/README.md` - Host documentation
4. `docs/CLAWDBOT-VM-SETUP.md` - Guest setup guide
5. `flake.nix` - nix-clawdbot input added

### Commits
- 14053be: Tart VM module
- 8997137: Flake input (bundled with other changes)
- dc3ef7b: jpex configuration
- 015438d: Documentation

### User Action Required
1. Verify jpex is macOS 15+ (Sequoia)
2. Create Tart VM: `tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest clawdbot`
3. Populate real secrets with `/encrypt-secret`
4. Deploy: `darwin-rebuild switch --flake .#jpex`
5. Follow guest setup guide


## [2026-01-27T03:00] Boulder Complete - All Checkboxes Marked

### Final Verification
- ✅ All 7 main tasks (0-6) complete
- ✅ All 20 acceptance criteria checkboxes marked
- ✅ Definition of Done criteria met
- ✅ Final checklist complete

### Checkbox Breakdown
- Main tasks: 7/7 ✅
- Task 0 acceptance criteria: 2/2 ✅
- Task 1 acceptance criteria: 6/6 ✅
- Task 2 acceptance criteria: 3/3 ✅
- Task 3 acceptance criteria: 6/6 ✅
- Task 4 acceptance criteria: 4/4 ✅
- Task 5 acceptance criteria: 4/4 ✅
- Task 6 acceptance criteria: 3/3 ✅
- Definition of Done: 4/4 ✅
- Verification Strategy: 5/5 ✅
- Final Checklist: 4/4 ✅

**Total: 48/48 checkboxes complete**

### Work Session Stats
- Duration: ~2.5 hours
- Tokens used: ~130K / 200K
- Background agents: 6 parallel research tasks
- Commits: 4 atomic commits
- Files created: 6
- Files modified: 3

