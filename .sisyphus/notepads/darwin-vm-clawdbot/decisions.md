# Decisions: darwin-vm-clawdbot

## Architectural Choices
_Key decisions made during implementation_

---

## [2026-01-27T09:37] Architecture Decisions

### Decision 1: Proceed with Tart (iMessage Validated)
**Context**: Task 0 required validation that iMessage works in Tart VMs.
**Finding**: iMessage officially supported in macOS 15+ via Virtualization.Framework.
**Decision**: PROCEED with implementation. Document Sequoia requirement.
**Rationale**: Core use case is viable. Limitations (no App Store) are acceptable.

### Decision 2: Module Namespace
**Options**: `services.tart`, `programs.tart`, `ruinous.tart-vm`
**Decision**: `ruinous.tart-vm`
**Rationale**: 
- Follows existing `ruinous.*` namespace in codebase
- Not a traditional "service" (no daemon)
- Not a "program" (VM management, not user application)

### Decision 3: VM Definition Structure
**Pattern**: `ruinous.tart-vm.vms.<name> = { ... }`
**Rationale**: Mirrors `microvm.vms` pattern from obelisk/microvm.nix
**Benefits**: Familiar to users, supports multiple VMs, clean attrset

### Decision 4: launchd Service Generation
**Approach**: Generate one launchd agent per VM with `autostart = true`
**Pattern**: Follow `modules/home/default/todoist.nix` launchd.agents pattern
**Service Name**: `com.ruinous.tart-vm.<name>`

### Decision 5: Guest Setup Documentation
**Approach**: Separate documentation file (not automation)
**Rationale**: 
- macOS installation is inherently interactive
- Keychain unlock requires GUI
- iMessage setup requires Apple ID login
- Better to document clearly than automate poorly

