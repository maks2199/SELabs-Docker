#!/usr/bin/env bash
set -euo pipefail
docker rm -f orders-api 2>/dev/null || true
docker compose down -v 2>/dev/null || true
echo "Cleaned."
