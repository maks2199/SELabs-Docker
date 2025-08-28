#!/usr/bin/env bash
set -euo pipefail
docker build -f Dockerfile -t docker-lab/orders-api:optimized .
docker images | grep docker-lab/orders-api | awk '{print $1, $2, $7}'
