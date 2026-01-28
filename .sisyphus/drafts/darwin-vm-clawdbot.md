# Draft: Deploy clawd.bot to macOS VM on jpex

## Requirements (confirmed)
- Deploy clawd.bot to a virtual machine running on jpex (aarch64-darwin, Apple Silicon Mac)
- Use nix-clawdbot for deployment
- Manage VMs declaratively through nix-darwin modules

## Research Findings

### jpex Host (from explore agent + user specs)
- **Model**: Mac mini (Mac16,10)
- **Chip**: Apple M4 (10 cores: 4 performance + 6 efficiency)
- **Memory**: 24 GB unified
- **Platform**: aarch64-darwin (Apple Silicon)
- **OS**: macOS 26.2
- **Current Config**: Minimal nix-darwin config with desktop and developer modules
- **User**: jmeskill (uid 501)
- **Hostname**: jpex
- **Home Manager**: Uses ruinage modules including OpenCode, Claude Code, Codex, Gemini assistants

**VM Resource Budget**: With 24GB RAM and 10 cores, can comfortably run 1-2 macOS VMs with ~4-8GB RAM and 2-4 cores each.

### nix-clawdbot (from librarian agent + web search)
- **Repository**: github:clawdbot/nix-clawdbot
- **Deployment Method**: Home Manager module (NOT NixOS-specific)
- **macOS**: Runs as launchd service (`com.steipete.clawdbot.gateway`)
- **Linux**: Runs as systemd user service (`clawdbot-gateway`)
- **Requirements**:
  - Telegram bot token (from @BotFather)
  - User's chat ID (from @userinfobot)  
  - Anthropic API key
- **Key Options**:
  ```nix
  programs.clawdbot = {
    enable = true;
    providers.telegram = {
      enable = true;
      botTokenFile = "/path/to/token";
      allowFrom = [ 12345678 ];  # Chat ID
    };
    providers.anthropic.apiKeyFile = "/path/to/key";
    documents = ./documents;  # AGENTS.md, SOUL.md, TOOLS.md
    firstParty = { summarize.enable = true; peekaboo.enable = true; };
    plugins = [{ source = "github:owner/repo"; }];
  };
  ```
- **NOTE**: nix-clawdbot can run directly on macOS via Home Manager - VM may not be needed!

### nix-darwin VM Capabilities (from librarian agent)
- **No native VM module**: nix-darwin does NOT have a general-purpose VM management module like NixOS's `virtualisation.libvirt`
- **Built-in**: `nix.linux-builder` - uses Apple's Virtualization.framework for Linux builds only
- **Options for declarative VMs**:

| Tool | Type | Nix Integration | Best Use Case |
|------|------|-----------------|---------------|
| **phaer/nixos-vm-on-macos** | Flake (vfkit) | Native Nix | Full NixOS on Darwin, Rosetta 2, virtiofs |
| **Tart** | CLI/OCI | In nixpkgs | CI/CD, macOS-on-macOS, Linux VMs |
| **UTM** | GUI/CLI | Cask only | Interactive use |
| **nix.linux-builder** | Built-in | Native | Package builds only |

### phaer/nixos-vm-on-macos (from web fetch)
- **Repository**: github:phaer/nixos-vm-on-macos
- **Backend**: vfkit (Apple Virtualization.framework)
- **Features**:
  - Boot NixOS closure directly from kernel/initrd
  - virtiofs for file sharing (writable overlay over host nix store)
  - Rosetta 2 support (build aarch64-linux AND x86_64-linux)
  - Bridged networking via virtio-net
  - Graphical mode with virtio-gpu
- **Builder VM**: Proof-of-concept replacement for nix-darwin's linux-builder
- **Status**: "Experimental, weekend hack" but promising

### Existing MicroVM Patterns (from explore agent)
- **obelisk** hosts MicroVMs (messy-tty, ruinous-tty, builder-tty)
- Pattern uses:
  - `microvm.autostart` for VMs to start automatically
  - `microvm.vms` for VM definitions
  - `systemd.tmpfiles.rules` to create persistent directories
  - Persistent storage under `/persistent/microvms/<vm>/persistent`
- MicroVM.nix is Linux-only (QEMU-based), NOT compatible with Darwin

### Tart VM Tool (from librarian agent)
- **Repository**: github:cirruslabs/tart
- **Documentation**: tart.run
- **Backend**: Apple Virtualization.framework (native performance)
- **Features**:
  - CLI-based VM management
  - OCI registry for images (ghcr.io/cirruslabs/...)
  - Packer plugin for declarative image builds
  - softnet for isolated networking
  - Directory mounting with `--dir` flag
- **Nix Integration**: Available in nixpkgs (`tart`, `softnet`, `orchard`)
- **NixOS on Tart**: No official image, but can build with nixos-generators → qcow2 → import

### Comparison: VM Technologies for Darwin

| Technology | Type | Best For | nix-darwin Module? |
|------------|------|----------|-------------------|
| **phaer/nixos-vm-on-macos** | vfkit/Virtualization.framework | Full NixOS dev environment | No (flake) |
| **Tart** | CLI/Virtualization.framework | CI/CD, pre-built images | No (manual/Packer) |
| **nix.linux-builder** | Built-in | Nix package builds | Yes |
| **nix-clawdbot (direct)** | Home Manager | Single-machine clawdbot | Yes |

## Requirements (user confirmed)

### Why VM? (CONFIRMED)
- **Isolation**: Keep clawdbot sandboxed from main environment
- **Multiple instances**: Different user accounts with different Telegram bots
- **macOS VM (NOT Linux)**: Need GUI access, iMessage, and other mac-only features
- **Key insight**: This is macOS-on-macOS virtualization, which changes the technology choice

### Technology Decision: Tart is the Best Fit

Given the requirement for **macOS VMs** (not Linux):

| Technology | macOS VM Support | Fit |
|------------|------------------|-----|
| **Tart** | ✅ Native macOS-on-macOS | **Best choice** |
| phaer/nixos-vm-on-macos | ❌ NixOS/Linux only | Not applicable |
| UTM | ✅ macOS support | Less automatable |

**Tart is specifically designed for macOS-on-macOS virtualization on Apple Silicon.**

## Technical Decisions
- **VM Technology**: Tart (macOS-on-macOS native support)
- **Guest OS**: macOS (need GUI, iMessage, mac-only features)
- TBD: VM networking approach (bridged vs NAT)
- TBD: Persistence strategy for VM state
- TBD: How to install nix-clawdbot in guest macOS (nix-darwin in VM)

## Confirmed Decisions

1. **Instance Count**: 1 instance initially (can add more later)
2. **Module Scope**: Reusable nix-darwin module (`modules/darwin/tart-vm.nix`)
3. **Credentials**: Not yet ready - need to create bot via @BotFather and get Anthropic API key
4. **VM Access**: GUI + SSH (need visual access for iMessage setup)
5. **VM Autostart**: Yes, via launchd on host boot
6. **VM Resources**: ~4-6 cores, ~8GB RAM (comfortable for jpex's 10-core/24GB)
7. **Plugins**: Core + iMessage (summarize, peekaboo, imsg)
8. **Guest Automation**: Semi-automated (module provides scripts/instructions, macOS setup manual)
9. **Additional task**: Create README.md for jpex host (matching jmacmini pattern)

## Remaining Questions

1. **Networking** (minor, can default):
   - NAT sufficient (Tart default) vs bridged?
   - SSH access from host? (default: yes, via `tart ip`)

## Scope Boundaries

### INCLUDE
- Create reusable `modules/darwin/tart-vm.nix` module for Tart VM management
- Create `modules/darwin/tart-clawdbot.nix` module combining Tart VM + nix-clawdbot
- Configure jpex to use the module with 1 clawdbot VM instance
- Create jpex README.md matching other Darwin hosts
- Create setup scripts/instructions for guest macOS setup
- Add nix-clawdbot flake input
- Create agenix secrets structure (placeholder, credentials created later)

### EXCLUDE
- Fully automated Packer image builds (future scope)
- Multiple VM instances (add later as needed)
- Actual credential creation (user does this separately)
- Custom AGENTS.md/SOUL.md/TOOLS.md (use defaults initially)
