# weaviate

Weaviate is an open-source vector database that stores both objects and vectors.

## Overview

Weaviate allows for the combination of vector search with structured filtering, with the fault tolerance and scalability of a cloud-native database. It can be used standalone or as part of a larger AI/ML pipeline.

## Purpose

Provides a native Weaviate server binary for running vector database workloads without Docker containers.

## Key Features

- Vector + keyword search (hybrid search)
- Generative search (RAG)
- Multi-tenancy support
- Built-in vectorizer modules
- GraphQL and REST APIs
- Horizontal scalability
- HNSW indexing for fast similarity search

## Installation

This package is available to all hosts in this flake:

```nix
environment.systemPackages = with pkgs; [
  weaviate
];
```

## Usage

### Basic Server Start

```sh
# Start with default settings
weaviate --host 0.0.0.0 --port 8080 --scheme http

# With persistence directory
PERSISTENCE_DATA_PATH=/var/lib/weaviate weaviate --host 0.0.0.0 --port 8080
```

### Environment Variables

Key environment variables for configuration:

| Variable | Description | Default |
|----------|-------------|---------|
| `PERSISTENCE_DATA_PATH` | Data storage directory | `./data` |
| `QUERY_DEFAULTS_LIMIT` | Default query result limit | `10` |
| `AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED` | Allow anonymous access | `true` |
| `DEFAULT_VECTORIZER_MODULE` | Default vectorizer | `none` |
| `ENABLE_MODULES` | Comma-separated module list | - |
| `CLUSTER_HOSTNAME` | Node hostname for clustering | - |

### With Vectorizer Modules

```sh
# Enable text2vec-transformers module
ENABLE_MODULES=text2vec-transformers \
  TRANSFORMERS_INFERENCE_API=http://localhost:8000 \
  weaviate --host 0.0.0.0 --port 8080
```

### With Authentication

```sh
# Enable API key authentication
AUTHENTICATION_APIKEY_ENABLED=true \
  AUTHENTICATION_APIKEY_ALLOWED_KEYS=my-secret-key \
  AUTHENTICATION_APIKEY_USERS=admin \
  weaviate --host 0.0.0.0 --port 8080
```

## Technical Details

- **Language**: Go
- **Version**: 1.35.3
- **License**: BSD-3-Clause
- **Platform Support**: Linux x86_64

## Requirements

- Sufficient RAM for vector operations (minimum 2GB recommended)
- Disk space for persistence (varies by data volume)
- Optional: GPU for accelerated vectorization (via external modules)

## Companion Tools

- **weaviate-cli** - Command line interface for managing Weaviate instances (also packaged in this flake)

## Upstream

- **Repository**: https://github.com/weaviate/weaviate
- **Documentation**: https://weaviate.io/developers/weaviate
- **License**: BSD-3-Clause

## Notes

- This package provides the pre-built binary from official releases
- For production use, configure proper authentication and persistence
- Vectorizer modules may require additional services (e.g., inference APIs)
