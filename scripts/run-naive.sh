#!/usr/bin/env bash
set -euo pipefail
mkdir -p ./data
docker run --rm -p 8081:8080 -v "$(pwd)/data:/data" docker-lab/orders-api:naive
