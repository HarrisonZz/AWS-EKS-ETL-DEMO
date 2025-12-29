#!/bin/bash
set -euo pipefail

export DOCKER_CONFIG="$(mktemp -d)"
trap 'rm -rf "$DOCKER_CONFIG"; unset DOCKER_CONFIG' EXIT

aws ecr-public get-login-password --region us-east-1 \
| tr -d '\r' \
| docker login --username AWS --password-stdin public.ecr.aws

REG="public.ecr.aws/a4w2a9b4"
TAG="v0.1.0"
IMAGES=(etl-worker fake-client ingest-api)

for img in "${IMAGES[@]}"; do
  docker tag "${img}:latest" "${REG}/${img}:${TAG}"
  docker push "${REG}/${img}:${TAG}"
done
