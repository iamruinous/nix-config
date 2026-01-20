# nix-config Documentation - Agent Context

This directory is curated by **LIBBY** (documentation voice) with domain expertise from **NIXEY** (infrastructure SME).

---

## About This Documentation

**Hidden gem:** This isn't just another dotfiles repo with Nix sprinkled on top. It's a declarative infrastructure platform managing 24 hosts across NixOS, macOS, and Raspberry Pis—with encrypted secrets, container orchestration, and skill-based automation. The patterns here scale from a single laptop to a home datacenter.

---

## Dual Curation Model

| Curator | Responsibility | Voice |
|---------|----------------|-------|
| **LIBBY** | Structure, discoverability, cross-references | Warm, comprehensive, guide-like |
| **NIXEY** | Infrastructure accuracy, Nix patterns, deployment wisdom | Precise, declarative, pragmatic |

**The insight:** LIBBY makes this documentation navigable. NIXEY makes it correct. When NIXEY says "use `--internal` for datanet", there's a security reason.

---

## Documentation Map

### Getting Started

| Document | What You'll Learn | Read If... |
|----------|-------------------|------------|
| [index.md](index.md) | Project overview, host inventory | You're new to this repo |
| [README.md](README.md) | Existing doc index | You want to see what's documented |
| [../AGENTS.md](../AGENTS.md) | Full project context for agents | You're an AI agent |
| [../llms.txt](../llms.txt) | Token-efficient overview | You need quick context |

### Infrastructure

| Document | What You'll Learn | Read If... |
|----------|-------------------|------------|
| [NETWORKS.md](NETWORKS.md) | VLANs, DNS domains, container networks | You're configuring networking |
| [../hosts/README.md](../hosts/README.md) | All 24 hosts with specs | You need to find a host |
| [../secrets/README.md](../secrets/README.md) | Agenix encryption patterns | You're working with secrets |
| [../packages/README.md](../packages/README.md) | Custom Nix packages | You need a package |

### Deep Dives

| Document | What You'll Learn | Read If... |
|----------|-------------------|------------|
| [ai-cli-sync-reference.md](ai-cli-sync-reference.md) | AI CLI synchronization | You're setting up AI tools |
| [tmux-theming-research.md](tmux-theming-research.md) | Tmux theming research | You're customizing tmux |

### Plans & Migrations

| Document | What You'll Learn | Read If... |
|----------|-------------------|------------|
| [migrations/](migrations/) | Migration guides | You're upgrading something |
| [plans/](plans/) | Implementation plans | You're planning a change |

---

## For AI Agents Working Here

### Key Context

- **NIXEY is the SME**: All infrastructure decisions should align with NIXEY's patterns
- **Skills catalog**: Rich set of skills for secrets, DNS, containers, packaging
- **Multi-host**: Changes can affect 24 different hosts—verify scope first
- **Secrets are encrypted**: Use `agenix-helper unlock` before editing

### Verification Before Completion

1. `just remote-dry-build <target>` passes
2. No unencrypted secrets in commit
3. Container images pinned (no `:latest`)
4. DNS records created if needed

### Delegation Pattern

```markdown
1. TASK: [Specific goal]
2. EXPECTED OUTCOME: [Success criteria]
3. REQUIRED SKILLS: See AGENTS.md skills catalog
4. REQUIRED TOOLS: Read, Edit, Bash
5. MUST DO:
   - Verify with dry-build before deploying
   - Keep secrets encrypted (agenix)
   - Apply LIBBY voice in docs
   - Use alejandra for Nix formatting
6. MUST NOT DO:
   - Commit unencrypted secrets
   - Use `:latest` container tags
   - Deploy without dry-build verification
7. CONTEXT:
   - SME: NIXEY (infrastructure)
   - Curator: LIBBY (documentation)
   - 24 hosts across NixOS, macOS, Raspberry Pi
```

---

## Related

- [NIXEY SME](https://agents.ruinous.ai/smes/nixey/) — Full infrastructure expertise
- [Root AGENTS.md](../AGENTS.md) — Project-level context with skills
- [Global Context](https://agents.ruinous.ai/llms.txt) — Ecosystem-wide protocols
