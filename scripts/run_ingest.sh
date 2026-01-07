#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

# --- 讀 .env ---
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "❌ .env not found at: $ENV_FILE"
  exit 1
fi

: "${GCS_BUCKET:?missing GCS_BUCKET in .env}"
: "${GOOGLE_APPLICATION_CREDENTIALS:?missing GOOGLE_APPLICATION_CREDENTIALS in .env}"

CONTAINER_NAME="ingest-api-container"
IMAGE_NAME="ingest-api:latest"

CLIENT_CONTAINER_NAME="fake-client-container"
CLIENT_IMAGE="fake-client:latest"

HOST_PORT="${HOST_PORT:-8000}"
CONTAINER_PORT="8000"

# --- 清理舊容器 ---
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
docker rm -f "$CLIENT_CONTAINER_NAME" >/dev/null 2>&1 || true

# --- key 檔 mount ---
KEY_HOST_PATH="$(realpath "$GOOGLE_APPLICATION_CREDENTIALS")"
KEY_CONT_PATH="/tmp/sa-key.json"

NET="etl-net"
docker network create "$NET" >/dev/null 2>&1 || true

echo "🚀 Starting ingest-api (GCS_BUCKET=${GCS_BUCKET})..."
docker run -d \
  -p "${HOST_PORT}:${CONTAINER_PORT}" \
  -e GCS_BUCKET="${GCS_BUCKET}" \
  -e GOOGLE_APPLICATION_CREDENTIALS="${KEY_CONT_PATH}" \
  -v "${KEY_HOST_PATH}:${KEY_CONT_PATH}:ro" \
  --name "${CONTAINER_NAME}" \
  --network "$NET" \
  "${IMAGE_NAME}"

sleep 2

docker logs "$CONTAINER_NAME" | head -n 5 || true

echo "⏳ Wait API..."
sleep 3
curl -fsS "http://localhost:${HOST_PORT}/health" >/dev/null || echo "⚠️ health check failed"

echo "🌊 Start fake-client..."
docker run \
  --name "${CLIENT_CONTAINER_NAME}" \
  --network "$NET" \
  -e API_URL="http://${CONTAINER_NAME}:${CONTAINER_PORT}/metrics" \
  "${CLIENT_IMAGE}"
