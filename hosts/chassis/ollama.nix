# Ollama - Local LLM inference with AMD ROCm GPU acceleration
#
# Provides local language model inference using the Radeon 8060S GPU.
# Models are automatically downloaded on service start.
{pkgs, ...}: {
  services.ollama = {
    enable = true;

    # Use ROCm package for AMD GPU acceleration (Radeon 8060S)
    package = pkgs.ollama-rocm;

    # Strix Halo (gfx1151) needs override - gfx1100 kernels work better
    # Without this, ollama detects GPU but offloads 0 layers (CPU-only)
    rocmOverrideGfx = "11.0.0";

    # Listen on all interfaces for local network access
    host = "0.0.0.0";
    port = 11434;

    # Models to download automatically on service start
    loadModels = [
      "phi3:mini" # Microsoft Phi-3 Mini - efficient 3.8B param model
      "nomic-embed-text" # Nomic text embeddings for RAG/vector search
    ];

    # Allow cross-origin requests for web UIs
    environmentVariables = {
      OLLAMA_ORIGINS = "*";
    };

    # Open firewall for local network access
    openFirewall = true;
  };
}
