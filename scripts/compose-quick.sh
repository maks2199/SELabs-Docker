#!/usr/bin/env bash
set -euo pipefail
docker compose up -d --build
echo "Orders API -> http://localhost:8083/health"
echo "Orders API -> http://localhost:8083/orders"
