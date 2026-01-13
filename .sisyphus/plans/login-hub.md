# Ruinous Login Hub Implementation Plan

## Context

### Original Request
Replace the current SSH auto-attach to tmux with a custom Bubble Tea TUI menu that offers:
- Hub session (always-running tmux fallback)
- Discovered tmuxp sessions
- Plain shell option
- Bypass mechanism via environment variable

### Current Implementation
**Location:** `modules/home/default/fish.nix` lines 9-16

```fish
if test -z "$TMUX" -a -n "$SSH_TTY"
  exec ${pkgs.tmux}/bin/tmux new-session -A -s shell
end
```

**Option:** `ruinous.openssh.tmux.attach.enable` (defined in `options.nix`)

**Enabled on 11 hosts:** gap, monolith, armistice, void, pilaster, tty-ruinous-social, obelisk, ruinous-tty, chassis, zenith

### Research Findings
- Wishlist runs as a separate SSH server (not suitable for login shell replacement)
- Bubble Tea + Bubbles provides the TUI components needed
- `syscall.Exec` replaces the current process (proper exec behavior)
- tmuxp sessions stored in `~/.config/tmuxp/*.json`

---

## Work Objectives

### Core Objective
Create a custom Go-based TUI login menu (`ruinous-login-hub`) that presents options when SSHing into a host, with bypass capability.

### Concrete Deliverables
- `packages/ruinous-login-hub/` - New Go package with Bubble Tea TUI
- `modules/home/default/ruinous-login-hub.nix` - New home-manager module
- Updated `modules/home/default/fish.nix` - Integration with ruinous-login-hub
- Updated `modules/home/default/options.nix` - New options, deprecate old
- Migrated host configurations

### Definition of Done
- [ ] `ruinous-login-hub` binary builds and runs
- [ ] TUI displays menu with hub, tmuxp sessions, and plain shell
- [ ] TUI has a nice 'ascii' banner that has the current hostname (can use `toilet` to generate if needed)
- [ ] Selecting "Hub Session" execs into `tmux new-session -A -s hub`
- [ ] Selecting tmuxp session execs into `tmuxp load --yes <name>`
- [ ] Selecting "Plain Shell" exits cleanly (returns to shell)
- [ ] `BYPASS_LOGIN_HUB=1 ssh host` skips menu entirely
- [ ] All 11 hosts migrated from old option to new

### Must Have
- Arrow key navigation in menu
- tmuxp session auto-discovery from `~/.config/tmuxp/`
- Clean exec (replaces process, no orphan shells)
- Bypass via `BYPASS_LOGIN_HUB` environment variable

### Must NOT Have (Guardrails)
- No network calls or external service dependencies
- No configuration files for ruinous-login-hub itself (uses tmuxp discovery)
- No interactive prompts beyond the menu (single selection, then exec)
- No changes to SSH daemon configuration

---

## Verification Strategy

### Test Infrastructure
- Manual verification via SSH to test host
- Build verification via `nix build .#ruinous-login-hub`

### Manual QA Procedures
Each TODO includes verification steps for:
- SSH connection testing
- Menu navigation testing
- Exec behavior verification
- Bypass testing

---

## TODOs

### Phase 1: Create Go Package

- [x] 1. Create `packages/ruinous-login-hub/` directory structure

  **What to do**:
  - Create `packages/ruinous-login-hub/` directory
  - Create `go.mod` with module name `github.com/iamruinous/ruinous-login-hub`
  - Add dependencies: bubbletea, bubbles, lipgloss

  **References**:
  - `packages/docker-mcp-gateway/default.nix` - buildGoModule pattern
  - `packages/README.md` - Package structure conventions

  **Acceptance Criteria**:
  - [ ] Directory exists: `packages/ruinous-login-hub/`
  - [ ] `go.mod` file created with correct module path
  - [ ] Dependencies listed in go.mod

---

- [x] 2. Implement `main.go` - Core TUI application

  **What to do**:
  - Implement Bubble Tea model with list component
  - Add menu items: Hub Session, tmuxp sessions (discovered), Plain Shell
  - Implement `discoverTmuxpSessions()` to read `~/.config/tmuxp/*.json`
  - Implement selection handler with `syscall.Exec` for tmux/tmuxp
  - Style with lipgloss (minimal, clean look)

  **Menu Structure**:
  ```
  SSH Login Hub
  
  > Hub Session
    tmuxp: nix-config
    tmuxp: n8n-agent
    Plain Shell
  
  ↑/↓: navigate • enter: select • q: quit
  ```

  **Actions by selection**:
  | Selection | Exec Command |
  |-----------|--------------|
  | Hub Session | `tmux new-session -A -s hub` |
  | tmuxp: <name> | `tmuxp load --yes <name>` |
  | Plain Shell | `os.Exit(0)` (return to shell) |

  **References**:
  - Bubble Tea docs: https://github.com/charmbracelet/bubbletea
  - Bubbles list: https://github.com/charmbracelet/bubbles/tree/master/list
  - Lipgloss: https://github.com/charmbracelet/lipgloss

  **Acceptance Criteria**:
  - [ ] `go build` succeeds
  - [ ] Running binary shows TUI menu
  - [ ] Arrow keys navigate menu
  - [ ] Enter selects item
  - [ ] q or Ctrl+C exits cleanly

---

- [x] 3. Create `default.nix` for ruinous-login-hub package

  **What to do**:
  - Use `buildGoModule` pattern
  - Set vendorHash (compute on first build)
  - Add meta information

  **References**:
  - `packages/docker-mcp-gateway/default.nix:1-48` - buildGoModule example

  **Acceptance Criteria**:
  - [ ] `nix build .#ruinous-login-hub` succeeds
  - [ ] Binary at `result/bin/ruinous-login-hub`
  - [ ] `result/bin/ruinous-login-hub` runs and shows menu

---

- [x] 4. Create `README.md` for ruinous-login-hub package

  **What to do**:
  - Document purpose and usage
  - Document bypass mechanism
  - Document tmuxp discovery behavior

  **References**:
  - `packages/ssh-agent-check/README.md` - README format

  **Acceptance Criteria**:
  - [ ] README.md exists in `packages/ruinous-login-hub/`
  - [ ] Documents all features and usage

---

### Phase 2: Create Nix Module

- [x] 5. Create `modules/home/default/ruinous-login-hub.nix`

  **What to do**:
  - Define `ruinous.loginHub.enable` option
  - Define `ruinous.loginHub.bypassEnvVar` option (default: "BYPASS_LOGIN_HUB")
  - Define `ruinous.loginHub.hubSessionName` option (default: "hub")
  - Define `ruinous.loginHub.showTmuxpSessions` option (default: true)
  - Pass options to ruinous-login-hub via environment or arguments

  **Module Options**:
  ```nix
  ruinous.loginHub = {
    enable = mkEnableOption "SSH login hub with TUI menu";
    
    bypassEnvVar = mkOption {
      type = types.str;
      default = "BYPASS_LOGIN_HUB";
      description = "Environment variable to bypass the login hub";
    };
    
    hubSessionName = mkOption {
      type = types.str;
      default = "hub";
      description = "Name of the hub tmux session";
    };
    
    showTmuxpSessions = mkOption {
      type = types.bool;
      default = true;
      description = "Auto-discover and show tmuxp sessions in menu";
    };
  };
  ```

  **References**:
  - `modules/home/default/options.nix` - Option definition patterns
  - `modules/home/default/fish.nix` - Current tmux attach implementation

  **Acceptance Criteria**:
  - [ ] Module file exists
  - [ ] Options are defined and documented
  - [ ] No LSP errors

---

- [x] 6. Update `modules/home/default/fish.nix` - Integrate ruinous-login-hub

  **What to do**:
  - Replace `tmuxAttachScript` with `loginHubScript`
  - Check for bypass env var in addition to TMUX and SSH_TTY
  - Use ruinous-login-hub package path

  **New Script Logic**:
  ```fish
  if test -z "$TMUX" -a -n "$SSH_TTY" -a -z "$BYPASS_LOGIN_HUB"
    exec ${pkgs.ruinous-login-hub}/bin/ruinous-login-hub
  end
  ```

  **References**:
  - `modules/home/default/fish.nix:9-16` - Current implementation

  **Acceptance Criteria**:
  - [ ] Fish init script uses ruinous-login-hub when enabled
  - [ ] Bypass env var is checked
  - [ ] Old tmux attach behavior preserved if loginHub not enabled

---

- [x] 7. Update `modules/home/default/options.nix` - Add deprecation

  **What to do**:
  - Keep `ruinous.openssh.tmux.attach.enable` for backward compatibility
  - Add comment marking it as deprecated
  - Document migration path to `ruinous.loginHub.enable`

  **References**:
  - `modules/home/default/options.nix:35` - Current option

  **Acceptance Criteria**:
  - [ ] Deprecation comment added
  - [ ] Both options can coexist during migration

---

### Phase 3: Migrate Hosts

- [x] 8. Migrate chassis to use loginHub

  **What to do**:
  - Replace `openssh.tmux.attach.enable = true` with `loginHub.enable = true`
  - Test SSH connection to chassis

  **References**:
  - `hosts/chassis/users/jmeskill/home-configuration.nix:23`

  **Acceptance Criteria**:
  - [ ] SSH to chassis shows login hub menu
  - [ ] Hub session option works
  - [ ] tmuxp sessions appear in menu
  - [ ] Plain shell option works
  - [ ] `BYPASS_LOGIN_HUB=1 ssh chassis` skips menu

---

- [x] 9. Migrate remaining hosts to use loginHub

  **What to do**:
  - Update all hosts currently using `ruinous.openssh.tmux.attach.enable = true`:
    - `hosts/armistice/users/jmeskill/home-configuration.nix`
    - `hosts/pilaster/users/jmeskill/home-configuration.nix`
    - `hosts/gap/users/jmeskill/home-configuration.nix`
    - `hosts/obelisk/users/jmeskill/home-configuration.nix`
    - `hosts/monolith/users/jmeskill/home-configuration.nix`
    - `hosts/zenith/users/jmeskill/home-configuration.nix`
    - `hosts/tty-ruinous-social/users/jmeskill/home-configuration.nix`
    - `hosts/ruinous-tty/users/jmeskill/home-configuration.nix`
    - `hosts/void/users/jmeskill/home-configuration.nix`

  **References**:
  - Grep results showing all hosts with `tmux.attach.enable`

  **Acceptance Criteria**:
  - [ ] All hosts updated
  - [ ] `nix flake check` passes
  - [ ] Dry build succeeds for at least one host

---

### Phase 4: Cleanup

- [ ] 10. Remove deprecated option (optional, future)

  **What to do**:
  - After all hosts migrated, remove `ruinous.openssh.tmux.attach.enable`
  - Remove old `tmuxAttachScript` from fish.nix

  **Note**: This can be done in a follow-up PR after confirming migration works

  **Acceptance Criteria**:
  - [ ] Old option removed
  - [ ] No references to old option remain
  - [ ] All hosts still work

---

## Commit Strategy

| After Task | Message | Files |
|------------|---------|-------|
| 1-4 | `feat(packages): add ruinous-login-hub TUI for SSH login menu` | `packages/ruinous-login-hub/*` |
| 5-7 | `feat(home): add loginHub module for SSH login menu` | `modules/home/default/*.nix` |
| 8 | `refactor(chassis): migrate to loginHub from tmux.attach` | `hosts/chassis/...` |
| 9 | `refactor(hosts): migrate all hosts to loginHub` | `hosts/*/...` |

---

## Success Criteria

### Verification Commands
```bash
# Build the package
nix build .#ruinous-login-hub

# Test the binary
./result/bin/ruinous-login-hub

# Test SSH with menu
ssh chassis

# Test bypass
BYPASS_LOGIN_HUB=1 ssh chassis

# Verify no flake errors
nix flake check
```

### Final Checklist
- [ ] ruinous-login-hub package builds
- [ ] TUI menu displays correctly
- [ ] All menu options work (hub, tmuxp, shell)
- [ ] Bypass mechanism works
- [ ] All 11 hosts migrated
- [ ] No regressions in SSH functionality
