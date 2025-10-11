#!/usr/bin/env bash
set -euo pipefail
echo "== Sizes =="
docker images | (echo "REPOSITORY TAG SIZE"; cat)
echo "== History: naive =="
docker history docker-lab/orders-api:naive || true
echo "== History: optimized =="
docker history docker-lab/orders-api:optimized || true
