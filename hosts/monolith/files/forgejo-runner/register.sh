#!/usr/bin/env bash
set -euo pipefail

# Forgejo Runner Registration Script
# Run this once to register the runner, then start the forgejo-runner container

TOKEN_FILE="/run/agenix/monolith_forgejo_runner_token"
DATA_DIR="/data/docker/forgejo-runner/data"
FORGEJO_URL="http://forgejo:3000"
RUNNER_NAME="monolith-runner"
LABELS="ubuntu-latest:docker://node:20-bookworm,docker:docker://docker:dind"

# Check if already registered
if [ -f "$DATA_DIR/.runner" ]; then
    echo "Runner already registered. Delete $DATA_DIR/.runner to re-register."
    exit 0
fi

# Check token file exists
if [ ! -f "$TOKEN_FILE" ]; then
    echo "Error: Token file not found at $TOKEN_FILE"
    echo "Make sure agenix secrets are deployed."
    exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

echo "Registering Forgejo runner..."
echo "  Instance: $FORGEJO_URL"
echo "  Name: $RUNNER_NAME"
echo "  Labels: $LABELS"

# Run registration in a temporary container on the same networks
docker run --rm -it \
    --network servicenet \
    -v "$DATA_DIR:/data" \
    -e DOCKER_HOST=tcp://forgejo-dind:2375 \
    code.forgejo.org/forgejo/runner:6.0.0 \
    forgejo-runner register \
    --no-interactive \
    --instance "$FORGEJO_URL" \
    --token "$TOKEN" \
    --name "$RUNNER_NAME" \
    --labels "$LABELS"

echo ""
echo "Registration complete!"
echo "Now restart the forgejo-runner container:"
echo "  systemctl restart docker-forgejo-runner"
