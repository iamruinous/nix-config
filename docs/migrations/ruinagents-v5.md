# Migration Guide: ruinagents v3.x → v5.0.0-alpha.1

> **Status:** Alpha release. Test in development environments before production deployment.

## Overview

ruinagents v5 introduces a **foundry-based architecture** with portable personas, layered context expressions (Lens/Undertone), and the Four Boxes runtime discovery pattern. This guide covers updating the nix-config integration.

### Version Jump Explanation

- **v3.11.0** → Last stable v3 release
- **v4.0.0** → Constitutional architecture (internal restructure)
- **v5.0.0-alpha.1** → Foundry pattern + Four Boxes + Lens expressions

---

## What's Preserved (No Breaking Changes)

The Nix package interface is **backward compatible**:

| Aspect | v3 | v5 | Change |
|--------|----|----|--------|
| Package names | `opencode`, `claude-code`, `codex`, `gemini`, `antigravity`, `moltbot`, `n8n` | Same | None |
| Install paths | `.config/opencode`, `.claude`, `.codex`, `.gemini`, etc. | Same | None |
| Context files | `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` | Same | None |
| Skills directory | `skills/` | Same | None |
| Commands directory | `commands/` | Same | None |

**Your existing nix-config modules will work without modification.**

---

## Step 1: Update Flake Input

### Current (v3.11.0)

```nix
# flake.nix
ruinagents.url = "git+ssh://git@forge.meskill.farm/iamruinous/ruinagents.git?ref=refs/tags/v3.11.0";
```

### Updated (v5.0.0-alpha.1)

```nix
# flake.nix
ruinagents.url = "git+ssh://git@forge.meskill.farm/iamruinous/ruinagents.git?ref=refs/tags/v5.0.0-alpha.1";
```

### Using the Skill

```bash
# From nix-config directory
/update-flake-input ruinagents
```

---

## Step 2: Verify Build

```bash
# Test that packages still build
nix build .#ruinagents.packages.x86_64-linux.opencode --dry-run
nix build .#ruinagents.packages.x86_64-linux.claude-code --dry-run

# Or check via flake input
nix eval .#inputs.ruinagents.packages.x86_64-linux.opencode.version
```

---

## Step 3: Deploy and Test

```bash
# Deploy to test host
just deploy chassis  # or your preferred test host

# Verify files are installed
ls -la ~/.config/opencode/AGENTS.md
ls -la ~/.config/opencode/skills/
ls -la ~/.claude/CLAUDE.md
```

---

## What's New in v5

### 1. Foundry-Based Architecture

Content source has been reorganized:

| v3/v4 Location | v5 Location | Purpose |
|----------------|-------------|---------|
| `src/RUINAGENTS.md` | `foundry/collective/` + build | Collective context |
| `kernels/{persona}/` | `foundry/personas/{persona}/` | Persona definitions |
| `collective/` | `foundry/collective/` | Shared values, guardrails |

### 2. Three-Tier Persona Expressions

Each persona now has three output tiers:

| Tier | File | Tokens | Use Case |
|------|------|--------|----------|
| **Full** | `PERSONA.md` | 500-1000 | Complete persona context |
| **Lens** | `LENS.md` | ~200 | Quick perspective filter |
| **Undertone** | `UNDERTONE.md` | ~100 | Minimal identity for constrained environments |

These are available in the `dist/personas/{name}/` directory.

### 3. Four Boxes Runtime Discovery

Personas now understand capabilities abstractly and discover implementations at runtime:

- **memorybox** - How do I remember? (Memory/History/Levels)
- **sensorium** - What can I perceive? (Text/Vision/Files/Browser)
- **rolodex** - Who can I contact? (Agents/Services/Humans)
- **toolbox** - What can I do? (Skills/Tools/Capabilities)

### 4. Purpose & Relations

Each persona now has:
- **purpose** - Organizing principle ("why I exist")
- **core_question** - Decision-making filter
- **relations** - Formal delegation/escalation patterns

---

## Optional Enhancements

### Expose Persona Lenses (Future)

If you want to make persona lenses available to specific assistants, you could extend the modules. The v5 packages include these files, but the current nix-config modules don't expose them yet.

Example future enhancement in `opencode.nix`:

```nix
# Future: expose persona lenses
personaLensPath = "${ruinagentsShare}/personas";

# Would create symlinks like:
# ~/.config/opencode/personas/messy/LENS.md
# ~/.config/opencode/personas/codey/LENS.md
```

### Test Persona Distribution

v5 enables different persona subsets per target:

| Target | Personas Included |
|--------|-------------------|
| opencode, claude-code, codex, gemini, antigravity | All 9 personas |
| moltbot | MESSY only |
| n8n | NATEY only |

---

## Rollback Procedure

If issues arise, revert the flake input:

```nix
# flake.nix
ruinagents.url = "git+ssh://git@forge.meskill.farm/iamruinous/ruinagents.git?ref=refs/tags/v3.11.0";
```

Then rebuild:

```bash
nix flake lock --update-input ruinagents
just deploy <host>
```

---

## Known Limitations (Alpha)

1. **Build system requires bun** - The v5 build uses TypeScript with bun. Nix packages use pre-built `dist/` directory.

2. **Growth Tracking deferred** - The three-level learning hierarchy (Instance/Entity/Collective) is specified but implementation is deferred to v5.1.0.

3. **Docs site restructure** - The MkDocs site navigation has changed. Some URLs may differ from v3.

---

## Verification Checklist

After migration:

- [ ] `just check <host>` passes
- [ ] `~/.config/opencode/AGENTS.md` exists and contains v5 content
- [ ] `~/.claude/CLAUDE.md` exists and contains v5 content
- [ ] Skills symlinks are functional: `ls ~/.config/opencode/skills/`
- [ ] No orphaned v3 files (manually clean if needed)
- [ ] OpenCode session works with new context

---

## References

- **v5 Changelog:** [CHANGELOG.md](https://forge.meskill.farm/iamruinous/ruinagents/src/tag/v5.0.0-alpha.1/CHANGELOG.md)
- **v5 README:** [README.md](https://forge.meskill.farm/iamruinous/ruinagents/src/tag/v5.0.0-alpha.1/README.md)
- **v5 Specifications:** [specs/v5/](https://forge.meskill.farm/iamruinous/ruinagents/src/tag/v5.0.0-alpha.1/specs/v5)
- **Foundry Structure:** [foundry/](https://forge.meskill.farm/iamruinous/ruinagents/src/tag/v5.0.0-alpha.1/foundry)
- **Four Boxes Docs:** [howtos/boxes-filesystem-example.md](https://forge.meskill.farm/iamruinous/ruinagents/src/tag/v5.0.0-alpha.1/howtos/boxes-filesystem-example.md)

---

**Contact:** Questions → create issue in ruinagents or ask in session.
