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

    # Use ROCm package from nixpkgs-master (ROCm 7.1.1 with gfx1151 support)
    package = pkgs-master.ollama-rocm;

    # Strix Halo (gfx1151) - ROCm 7.1.1 has native support, no override needed
    # rocmOverrideGfx = "11.0.0"; # Only needed for ROCm < 7.1

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
    };

    # Don't open firewall - localhost only
    openFirewall = false;
  };
}
