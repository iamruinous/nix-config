# Zenith LLM Upgrade: vLLM → llama.cpp

## Context

### Original Request
Upgrade zenith's LLM infrastructure from vLLM (Qwen2.5-Coder-7B, 32K context) to llama.cpp (Qwen2.5-Coder-32B, 100K context) to support OpenCode's context requirements.

### Interview Summary
**Key Discussions**:
- Model choice: Qwen2.5-Coder-32B-Instruct at Q4_K_M quantization (~24GB)
- Framework: llama.cpp server mode (better unified memory handling, stable on Strix Halo)
- Context: 100K tokens (comfortable fit in 128GB unified memory)
- Tool calling: llama.cpp supports OpenAI-style function calling with `--jinja` flag

**Research Findings**:
- llama.cpp requires `--jinja` flag for tool calling, `-fa` for flash attention
- Qwen2.5 models use Hermes 2 Pro format handler (natively supported)
- Memory estimate: ~50GB total (24GB weights + 26GB KV cache at 100K)
- ROCm on Strix Halo needs `HSA_OVERRIDE_GFX_VERSION=11.0.0`

### Gap Analysis (Addressed)
- Model storage: `/data/docker/llama-cpp/models`
- Open WebUI: Update to use llama.cpp as sole backend
- Rollback: Comment out vLLM/Ollama configs (don't delete)

---

## Work Objectives

### Core Objective
Replace vLLM with llama.cpp server on zenith to provide 100K token context for OpenCode coding workflows with full tool calling support.

### Concrete Deliverables
- llama.cpp Docker container running Qwen2.5-Coder-32B-Instruct Q4_K_M
- OpenAI-compatible API at port 8000 with tool calling enabled
- Open WebUI updated to use llama.cpp backend
- vLLM and Ollama commented out (preserved for rollback)

### Definition of Done
- [ ] `curl http://zenith:8000/v1/models` returns Qwen2.5-Coder-32B model
- [ ] Tool calling works: API request with `tools` array returns `tool_calls` response
- [ ] Open WebUI loads and can chat with llama.cpp backend
- [ ] `just remote-dry-build zenith` passes

### Must Have
- 100K token context support
- OpenAI-compatible `/v1/chat/completions` endpoint
- Tool calling via `--jinja` flag
- ROCm GPU acceleration on Strix Halo

### Must NOT Have (Guardrails)
- Do NOT delete vLLM/Ollama configs (comment out only)
- Do NOT add LoRA support (future phase)
- Do NOT optimize for multi-user (single OpenCode use case)
- Do NOT change other containers or services

---

## Verification Strategy (MANDATORY)

### Test Decision
- **Infrastructure exists**: YES (curl, docker available)
- **User wants tests**: Manual verification (no automated test framework for infra)
- **QA approach**: Manual verification with curl and Open WebUI

### Manual QA Procedures

**For API verification:**
```bash
# Check model is loaded
curl http://zenith:8000/v1/models

# Test basic completion
curl http://zenith:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5-coder-32b","messages":[{"role":"user","content":"Hello"}]}'

# Test tool calling
curl http://zenith:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model":"qwen2.5-coder-32b",
    "messages":[{"role":"user","content":"What time is it?"}],
    "tools":[{"type":"function","function":{"name":"get_time","description":"Get current time"}}]
  }'
```

---

## Task Flow

```
Task 1 (Add llama-cpp-init + llama-cpp containers)
    ↓
Task 2 (Comment out vLLM/Ollama)
    ↓
Task 3 (Update Open WebUI)
    ↓
Task 4 (Update Caddy routes if needed)
    ↓
Task 5 (Deploy and verify)
```

## Parallelization

| Task | Depends On | Reason |
|------|------------|--------|
| 1 | None | Can start immediately |
| 2 | 1 | Need llama-cpp defined first |
| 3 | 1 | Need llama-cpp container name |
| 4 | 1 | Need to know endpoint |
| 5 | 1, 2, 3, 4 | All config changes must be complete |

---

## TODOs

- [x] 1. Add llama-cpp-init and llama-cpp containers to containers.nix

  **What to do**:
  - Add `llama-cpp-init` container (one-shot) that downloads GGUF model if not present
  - Add `llama-cpp` container for the server with `dependsOn = ["llama-cpp-init"]`
  - Configure ROCm GPU passthrough (same as vLLM)
  - Set environment variables for Strix Halo compatibility
  - Configure 100K context with `--jinja` for tool calling

  **Must NOT do**:
  - Delete existing vLLM container (comment out in task 2)
  - Change network configuration
  - Use non-Q4_K_M quantization

  **Parallelizable**: NO (first task)

  **References**:
  
  **Pattern References**:
  - `hosts/zenith/containers.nix:390-443` - vLLM container definition (GPU passthrough pattern)
  - `hosts/zenith/containers.nix:115-134` - Ollama container (ROCm environment vars)
  - `hosts/zenith/containers.nix:511-540` - ollama-pull-models pattern (similar init concept)
  
  **Model Download**:
  - Source: `bartowski/Qwen2.5-Coder-32B-Instruct-GGUF`
  - File: `Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf` (~24GB)
  - HuggingFace URL: `https://huggingface.co/bartowski/Qwen2.5-Coder-32B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf`
  - Storage: `/data/docker/llama-cpp/models/`
  
  **Init Container Design**:
  ```nix
  llama-cpp-init = {
    image = "curlimages/curl:latest";  # Lightweight image with curl
    volumes = ["/data/docker/llama-cpp/models:/models"];
    cmd = [
      "sh" "-c"
      ''
        if [ ! -f /models/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf ]; then
          echo "Downloading model..."
          curl -L -o /models/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf \
            "https://huggingface.co/bartowski/Qwen2.5-Coder-32B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf"
        else
          echo "Model already exists, skipping download"
        fi
      ''
    ];
  };
  ```
  
  **Docker Image for Server**:
  - `ghcr.io/ggerganov/llama.cpp:server-rocm` - Official ROCm build
  - Alternative: Build from source if needed
  
  **llama.cpp Server Flags**:
  ```
  --jinja              # REQUIRED for tool calling
  -fa                  # Flash attention
  -m /models/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf
  -c 100000            # 100K context
  --host 0.0.0.0
  --port 8000
  -ngl 99              # Offload all layers to GPU
  ```
  
  **ROCm Environment (from vLLM)**:
  - `HSA_OVERRIDE_GFX_VERSION=11.0.0`
  - `HSA_ENABLE_SDMA=0`
  - `HIP_VISIBLE_DEVICES=0`

  **Acceptance Criteria**:
  - [ ] `llama-cpp-init` container definition added (downloads model if missing)
  - [ ] `llama-cpp` container definition added with `dependsOn = ["llama-cpp-init"]`
  - [ ] GPU passthrough configured (--device=/dev/kfd, --device=/dev/dri)
  - [ ] Environment variables set for Strix Halo
  - [ ] Volume mount for models directory shared between init and server
  - [ ] `nix-instantiate --eval` passes (syntax check)

  **Commit**: YES (groups with 2, 3, 4)
  - Message: `feat(zenith): add llama.cpp with init container for 100K context LLM`
  - Files: `hosts/zenith/containers.nix`
  - Pre-commit: `just remote-dry-build zenith`

---

- [x] 2. Comment out vLLM and Ollama containers

  **What to do**:
  - Comment out entire `vllm` container block (lines 384-443)
  - Comment out entire `ollama` container block (lines 115-134)
  - Comment out `ollama-pull-models` systemd service (lines 511-540)
  - Add comment explaining these are preserved for rollback

  **Must NOT do**:
  - Delete the configurations
  - Comment out Open WebUI (updating in task 3)

  **Parallelizable**: NO (depends on task 1)

  **References**:
  - `hosts/zenith/containers.nix:384-443` - vLLM container to comment
  - `hosts/zenith/containers.nix:115-134` - Ollama container to comment
  - `hosts/zenith/containers.nix:511-540` - ollama-pull-models service to comment

  **Acceptance Criteria**:
  - [ ] vLLM container block commented with `# DISABLED: Using llama.cpp instead`
  - [ ] Ollama container block commented
  - [ ] ollama-pull-models service commented
  - [ ] `nix-instantiate --eval` passes (no syntax errors from comments)

  **Commit**: NO (groups with task 1)

---

- [x] 3. Update Open WebUI to use llama.cpp backend

  **What to do**:
  - Change `dependsOn` from `["ollama" "vllm"]` to `["llama-cpp"]`
  - Update `OPENAI_API_BASE_URL` from `http://vllm:8000/v1` to `http://llama-cpp:8000/v1`
  - Remove or update `OLLAMA_BASE_URL` (may need to keep pointing to llama-cpp or remove)

  **Must NOT do**:
  - Change any other Open WebUI settings
  - Disable Open WebUI

  **Parallelizable**: NO (depends on task 1 for container name)

  **References**:
  - `hosts/zenith/containers.nix:136-146` - Open WebUI container definition

  **Acceptance Criteria**:
  - [ ] `dependsOn` updated to reference llama-cpp
  - [ ] `OPENAI_API_BASE_URL` points to llama-cpp:8000
  - [ ] No references to vllm or ollama remain in open-webui config

  **Commit**: NO (groups with task 1)

---

- [x] 4. Verify and update Caddy routes if needed

  **What to do**:
  - Check if any Caddy routes point to vllm or ollama
  - Update routes to point to llama-cpp if needed
  - Verify ai.x.meskill.farm route configuration

  **Must NOT do**:
  - Change routes for unrelated services
  - Modify Caddy secrets

  **Parallelizable**: NO (depends on task 1)

  **References**:
  - `hosts/zenith/caddy.nix` - Caddy configuration
  - Look for routes containing "vllm", "ollama", "8000"

  **Acceptance Criteria**:
  - [ ] All LLM-related Caddy routes point to llama-cpp container
  - [ ] No broken routes referencing disabled containers

  **Commit**: YES (if changes needed)
  - Message: `fix(zenith): update Caddy routes for llama.cpp`
  - Files: `hosts/zenith/caddy.nix`

---

- [ ] 5. Deploy and verify

  **What to do**:
  - Run `just remote-dry-build zenith` to verify config
  - Deploy with `just remote-rebuild zenith`
  - Wait for init container to download model (~24GB, may take 10-30 min depending on network)
  - Verify llama-cpp container starts and loads model
  - Test API endpoints
  - Test Open WebUI access

  **Must NOT do**:
  - Deploy without dry-build verification
  - Skip API verification
  - Interrupt model download

  **Parallelizable**: NO (final step)

  **References**:
  - Verification commands in "Verification Strategy" section above

  **Acceptance Criteria**:
  - [ ] `just remote-dry-build zenith` passes
  - [ ] `just remote-rebuild zenith` completes successfully
  - [ ] `docker logs llama-cpp-init` shows "Model already exists" or successful download
  - [ ] `docker logs llama-cpp` shows model loaded
  - [ ] `curl http://zenith:8000/v1/models` returns model info
  - [ ] Tool calling test returns `tool_calls` in response
  - [ ] Open WebUI accessible at ai.x.meskill.farm

  **Commit**: NO (deployment, not code change)

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1, 2, 3 | `feat(zenith): replace vLLM with llama.cpp for 100K context` | hosts/zenith/containers.nix | `just remote-dry-build zenith` |
| 4 (if needed) | `fix(zenith): update Caddy routes for llama.cpp` | hosts/zenith/caddy.nix | `just remote-dry-build zenith` |

---

## Success Criteria

### Verification Commands
```bash
# Model loaded
curl http://zenith:8000/v1/models
# Expected: JSON with model name

# Basic completion
curl http://zenith:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5-coder-32b","messages":[{"role":"user","content":"Hello"}]}'
# Expected: completion response

# Tool calling
curl http://zenith:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Get the time"}],"tools":[{"type":"function","function":{"name":"get_time"}}]}'
# Expected: response with tool_calls array
```

### Final Checklist
- [ ] llama.cpp container running with Qwen2.5-Coder-32B
- [ ] 100K context configured
- [ ] Tool calling working (--jinja enabled)
- [ ] Open WebUI functional
- [ ] vLLM/Ollama commented out (not deleted)
- [ ] No other services affected

---

## Future Reference: Phase 2 - Cognitive Clone Node

When adding the second MS-S1 MAX for cognitive clone:

| Attribute | Recommendation |
|-----------|----------------|
| **Model** | Qwen2.5-14B-Instruct-1M (4-bit GGUF) |
| **Framework** | llama.cpp (server mode) |
| **Context Target** | 256K tokens |
| **Purpose** | Long-context memory, planning |

**Two-Node Routing Pattern**:
```
User Request → Router
  ├── Planning/Memory → Cognitive Clone (Node 2)
  └── Code changes → Coding Node (Zenith)
```

See `.sisyphus/drafts/zenith-llm-upgrade.md` for full cognitive clone research.
