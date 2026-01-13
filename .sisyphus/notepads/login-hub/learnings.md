# Login Hub Implementation - Learnings

## [2026-01-12 15:52] Module Ordering Issue

**Problem**: When creating a new home-manager module with options, if another module tries to use those options, you get "attribute missing" errors.

**Root Cause**: Modules in `modules/home/default/` are imported alphabetically. If `fish.nix` (alphabetically before `ruinous-login-hub.nix`) tries to access `config.ruinous.loginHub`, the option doesn't exist yet.

**Solution**: Define options in `options.nix` (which is loaded early) and keep only config implementation in the feature-specific module file.

**Pattern**:
- `options.nix` - Define all `ruinous.*` options
- `feature-name.nix` - Implement config using those options

**Example**:
```nix
# options.nix
options.ruinous.loginHub = {
  enable = lib.mkEnableOption "...";
  # ... other options
};

# ruinous-login-hub.nix
config = lib.mkIf cfg.enable {
  # implementation
};

# fish.nix (can now safely use)
loginHubCfg = config.ruinous.loginHub;
```

## [2026-01-12 15:53] Package Overlay Registration

**Lesson**: New packages must be added to `modules/shared/universal/overlay.nix` to be available in configurations.

**Pattern**:
```nix
# overlay.nix
{
  package-name = perSystem.self.package-name;
}
```

Without this, `pkgs.package-name` won't resolve even if the package builds successfully.
