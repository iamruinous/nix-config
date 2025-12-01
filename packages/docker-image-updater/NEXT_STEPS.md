# docker-image-updater - Next Steps

## Current Status

The Go rewrite (v2.0.0) has the following working:
- Container discovery from `hosts/**/containers.nix` files
- CLI flags: `--path`, `--host`, `--limit`, `--dry-run`, `--non-interactive`
- Nix file parsing with state machine
- Registry package structure (skopeo wrapper, version comparison)
- TUI framework with Bubbletea

## What's Not Working

1. **Update Detection** - The registry checker doesn't actually check for updates yet
2. **Interactive Selection** - The TUI menu options exist but don't function
3. **File Updates** - The updater package has the logic but isn't wired up

## Implementation Plan

### Phase 1: Registry Update Checking

**File:** `internal/registry/registry.go`

1. Implement `CheckForUpdate()` to actually call skopeo:
   ```go
   func (r *Registry) CheckForUpdate(container scanner.Container) (UpdateResult, error)
   ```

2. For versioned tags (e.g., `postgres:17`, `nginx:1.27.0`):
   - Call `skopeo list-tags docker://<image>` to get all tags
   - Parse tags into semantic versions
   - Compare against current tag to find latest
   - Return `UpdateResult{HasUpdate: true, LatestTag: "18"}` if newer exists

3. For floating tags (e.g., `latest`, `stable`):
   - Get digest of current tag: `skopeo inspect docker://<image>:<tag>`
   - Compare against stored/expected digest
   - Flag as `IsDigestOnly: true` (can't auto-update, just notify)

**Testing:**
- Add integration test with real registry calls (skip in CI)
- Mock skopeo output for unit tests

### Phase 2: Wire Up TUI States

**File:** `internal/tui/model.go`

1. **StateChecking** - Actually call registry checker:
   ```go
   case StateChecking:
       // Launch goroutine to check each container
       // Send CheckCompleteMsg when done
       // Populate m.updates with results
   ```

2. **StateMainMenu** - Enable menu options:
   - "Update all" → transition to StateApplying with all updates
   - "Select by host" → transition to StateHostSelect
   - "Select individual" → transition to StateImageSelect
   - "Show commands only" → transition to StateShowCommands

3. **StateHostSelect** - Filter updates by host:
   - Show list of hosts with update counts
   - On select, filter updates and go to StateApplying

4. **StateImageSelect** - Multi-select individual containers:
   - Show checkbox list of all updates
   - Space to toggle, Enter to confirm
   - Go to StateApplying with selected

5. **StateApplying** - Apply selected updates:
   - Call `updater.Apply()` for each selected update
   - Show progress spinner
   - Transition to StateComplete

6. **StateShowCommands** - Display sed commands:
   - Show `updater.GenerateCommand()` output for each
   - Allow copy to clipboard or just display

### Phase 3: File Update Implementation

**File:** `internal/updater/updater.go`

1. Implement `Apply()` to actually modify files:
   ```go
   func (u *Updater) Apply(result registry.UpdateResult) ApplyResult {
       // Read file
       // Find and replace image:oldTag with image:newTag
       // Write file back
       // Return success/failure
   }
   ```

2. Use Go's native file operations instead of sed:
   - Read entire file with `os.ReadFile()`
   - Use `strings.Replace()` or regex for targeted replacement
   - Write back with `os.WriteFile()`
   - This is safer and more portable than sed

3. Handle edge cases:
   - Multiple containers with same image in one file
   - Quoted vs unquoted image strings
   - Preserve file formatting/whitespace

### Phase 4: Polish and Error Handling

1. **Progress feedback:**
   - Show which container is being checked
   - Show success/failure for each update applied
   - Summary at the end

2. **Error handling:**
   - Network errors during registry check
   - Permission errors during file write
   - Invalid/malformed Nix files

3. **Confirmation prompts:**
   - "Apply N updates? [y/N]"
   - Option to preview changes before applying

4. **Dry-run mode:**
   - Full flow but skip actual file writes
   - Show what would be changed

## File-by-File Changes Needed

| File | Changes |
|------|---------|
| `internal/registry/registry.go` | Implement `CheckForUpdate()` with real skopeo calls |
| `internal/registry/registry_test.go` | Add tests with mocked skopeo output |
| `internal/tui/model.go` | Wire up all state transitions and commands |
| `internal/tui/views.go` | Add views for host select, image select, applying states |
| `internal/updater/updater.go` | Implement `Apply()` with native Go file operations |
| `internal/updater/updater_test.go` | Add tests for file modification |

## Testing Checklist

- [ ] Unit tests for version comparison edge cases
- [ ] Unit tests for Nix file parsing with various formats
- [ ] Unit tests for file update operations
- [ ] Integration test: scan → check → display (no update)
- [ ] Integration test: full flow with --dry-run
- [ ] Manual test: apply update to real containers.nix

## Commands for Testing

```bash
# Build and test
nix build .#docker-image-updater
./result/bin/docker-image-updater --dry-run --host monolith

# Run Go tests
cd packages/docker-image-updater
nix-shell -p go --run "go test ./..."

# Test with limit to avoid rate limiting
./result/bin/docker-image-updater --limit 5 --non-interactive
```

## Notes

- Docker Hub rate limits: 100 pulls/6 hours for anonymous
- ghcr.io is more lenient but still has limits
- Consider caching tag lists to reduce API calls
- The `--limit` flag is useful during development
