#!/usr/bin/env bash
set -euo pipefail
docker build -f Dockerfile.naive -t docker-lab/orders-api:naive .
docker images | grep docker-lab/orders-api | awk '{print $1, $2, $7}'
