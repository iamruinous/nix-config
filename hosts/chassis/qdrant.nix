# Qdrant - Vector Search Engine for semantic code search
#
# Provides local vector storage for grepai and other embedding-based tools.
# Uses the native NixOS module with sensible defaults.
#
# Ports:
#   - 6333: HTTP API + Web UI (http://localhost:6333/dashboard)
#   - 6334: gRPC API (used by grepai)
#
# Data stored in: /var/lib/qdrant/
{...}: {
  services.qdrant = {
    enable = true;

    settings = {
      # Listen on localhost only (no external access needed)
      service = {
        host = "127.0.0.1";
        http_port = 6333;
        grpc_port = 6334;
        enable_cors = true;
      };

      # Disable telemetry for privacy
      telemetry_disabled = true;

      # Storage optimization for workstation use
      storage = {
        # Use on-disk payload to reduce memory usage
        on_disk_payload = true;

        # HNSW index settings for balanced performance
        hnsw_index = {
          # Keep index in memory for fast searches
          on_disk = false;
        };
      };
    };
  };
}
