# Ollama - Local LLM inference with AMD ROCm GPU acceleration
#
# Provides local language model inference using the Radeon 8060S GPU.
# Models are automatically downloaded on service start.
#
# NOTE: Uses nixpkgs-master for ROCm 7.1.1 which properly supports
# Strix Halo (gfx1151). The unstable branch has ROCm 7.0.2 which crashes.
{
  pkgs,
  flake,
  ...
}: let
  # Import ollama-rocm from nixpkgs-master which has ROCm 7.1.1
  pkgs-master = import flake.inputs.nixpkgs-master {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in {
  services.ollama = {
    enable = true;

    # Use Vulkan backend - ROCm 7.1.1 crashes on gfx1151 (Strix Halo)
    # TODO: Switch back to ollama-rocm once ROCm 7.2+ is available in nixpkgs
    # package = pkgs-master.ollama-rocm;
    package = pkgs-master.ollama-vulkan;

    # Strix Halo (gfx1151) - force gfx1100 compatibility mode
    # Native gfx1151 support in ROCm 7.1.1 still has issues with llama.cpp
    rocmOverrideGfx = "11.0.0";

    # Listen on localhost only - Caddy proxies if needed
    host = "127.0.0.1";
    port = 11434;

    # Models to download automatically on service start
    loadModels = [
      "phi3:mini" # Microsoft Phi-3 Mini - efficient 3.8B param model
      "nomic-embed-text" # Nomic text embeddings for RAG/vector search
    ];

    # Allow cross-origin requests for web UIs
    environmentVariables = {
      OLLAMA_ORIGINS = "*";
      # Strix Halo (gfx1151) ROCm workarounds - required until ROCm 7.2+
      # See: https://github.com/ROCm/ROCm/issues/5534
      HSA_ENABLE_SDMA = "0"; # Disable SDMA - causes memory corruption on unified memory
      AMD_SERIALIZE_KERNEL = "1"; # Prevent race conditions in early gfx1151 drivers
      HIP_VISIBLE_DEVICES = "0"; # Ensure correct iGPU binding
    };

    # Don't open firewall - localhost only
    openFirewall = false;
  };
}
