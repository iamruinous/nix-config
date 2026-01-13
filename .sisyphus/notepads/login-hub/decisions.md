# Login Hub Implementation - Decisions

## [2026-01-12 15:55] Module Structure

**Decision**: Split options and config into separate files.

**Rationale**: 
- Options must be defined early (in `options.nix`) to avoid module ordering issues
- Config implementation can be in feature-specific files
- This pattern is consistent with other ruinous.* options in the codebase

**Pattern**:
```
options.nix          → Define ruinous.loginHub.* options
ruinous-login-hub.nix → Config implementation (currently minimal)
fish.nix             → Integration with shell init
```

## [2026-01-12 15:56] Package Naming

**Decision**: Named the package `ruinous-login-hub` instead of just `login-hub`.

**Rationale**:
- Follows project naming convention (ruinous-* prefix)
- Avoids potential conflicts with other packages
- Makes it clear this is project-specific

## [2026-01-12 15:57] Migration Strategy

**Decision**: Keep old option with deprecation notice during migration.

**Rationale**:
- Allows gradual migration of 11 hosts
- Backward compatibility during transition
- Clear migration path documented in deprecation comment
- Can remove old option in future cleanup (Task 10)
