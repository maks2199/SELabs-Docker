#!/usr/bin/env bash
# Optional: requires Docker Scout plugin
set -euo pipefail
docker scout quickview docker-lab/orders-api:optimized || echo "Docker Scout not available; skipping."
