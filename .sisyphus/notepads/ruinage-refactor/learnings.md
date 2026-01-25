# Ruinage Refactor - Learnings

## Session: ses_40c584140ffeEzeYwbbul6QjFP
Started: 2026-01-25T06:32:22.554Z

### TODO 1-2: Foundation (COMPLETE)
- lib/ruinage/wrapper.nix must use `let` bindings, not expose as module options
- Module auto-imports work via modules/home/default/default.nix recursive pattern
- Git files must be staged for flake to see them (`git add`)

### TODO 3: Type Schema (COMPLETE)
- Types module must return empty `{}`, define types in `let` binding
- Exposing types as options causes "option does not exist" errors
- projectType successfully includes all required options:
  - Repository: repo, owner, forge, ref
  - Namespaces: ruinage, kimaki
  - Assistants: opencode (full), claude-code/gemini/codex (stubs)
  - Integrations: tmuxp, direnv, budgey, docs

### Patterns Learned
- Subagent delegation: Single atomic tasks only, no batching
- Verification: Always run `nix eval` after type changes
- Module structure: `let types = ... in { options = ...; config = ...; }`

### TODO 4: Auto-Clone Activation Script (COMPLETE)
- Import pattern: `typesModule = import ./types.nix { inherit config lib pkgs; }; projectType = typesModule.projectType;`
- Activation script uses `lib.hm.dag.entryAfter ["writeBoundary"]` for proper ordering
- Key implementation details:
  - Use `concatMapStringsSep "\n"` to iterate projects
  - Check `project.repo != null` to skip local-only projects
  - Use `optionalString` for conditional namespace cloning
  - Use `ruinageLib.mkProjectPath` and `ruinageLib.mkGitUrl` helpers
  - Check `[ ! -d "$path" ]` before cloning (skip existing)
  - Use `|| echo "Warning: ..."` pattern to warn on failure without failing activation
  - Use `$VERBOSE_ECHO` for verbose logging (home-manager standard)
- Syntax verified with `nix-instantiate --parse` (no errors)
- Activation script generates correct bash with proper quoting and escaping

### Key Patterns
- Namespace-aware cloning: Each project can be cloned to multiple namespaces
- Non-destructive: Skips existing directories with verbose message
- Resilient: Warns on clone failure but continues (doesn't fail activation)
- Helpers from wrapper.nix: mkGitUrl, mkProjectPath reduce duplication

### TODO 4 Fix: projectType Import (COMPLETE)
- **Issue**: types.nix is a module that returns `{}`, not a library that exports projectType
- **Solution**: Copied projectType definition from types.nix into projects.nix `let` binding
- **Rationale**: types.nix should remain a module (returns `{}`), projects.nix now has its own projectType definition
- **Verification**: `nix-instantiate --parse` succeeds, no LSP diagnostics
- **Pattern**: When importing modules that define types in `let` bindings, copy the type definition to the consuming module

### TODO 4: Auto-clone Activation (COMPLETE)
- types.nix is a MODULE (returns `{}`), not a library
- Can't import and extract values from a module
- Solution: Copy projectType definition into projects.nix
- Activation script uses lib.hm.dag.entryAfter ["writeBoundary"]
- Use $VERBOSE_ECHO for conditional output
- Clone failures should warn, not fail activation

### TODO 5-6: OpenCode Integration (COMPLETE)
- Ported 9 type definitions from opencode.nix
- Global options: model, plugins, mcpServers, providers, harnesses
- Per-project services: systemd units, XDG dirs, fish function
- Service naming preserved: opencode-<name>.service
- XDG pattern preserved: ~/.config/opencode-<name>/
- Used ruinageLib.mkSystemdEnvironment for consistent env setup

### TODO 7: Kimaki Integration (COMPLETE)
- Ported all global options from kimaki.nix
- Auto-discovery of projects with namespaces.kimaki.enable = true
- Project registration via activation script
- Symlink ~/.opencode/bin/opencode (kimaki hardcoded requirement)
- Used ruinageLib.mkSystemdEnvironment for consistency

### Progress: 7/17 tasks (41%)
- Foundation complete (lib, modules, schema, activation)
- Core assistants integrated (opencode, kimaki)
- Ready for supporting features (tmuxp, direnv, budgey)
