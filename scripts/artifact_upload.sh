#!/usr/bin/env bash
set -euo pipefail

# ====== 你需要先設定的參數 ======
: "${PROJECT_ID:?Please export PROJECT_ID (e.g. my-gcp-project)}"
: "${LOCATION:=asia-northeast1}"          # 例如: asia-east1 / us-central1
: "${REPO:=etl-demo-apps}"          # Artifact Registry 的 repo 名稱
TAG="v0.1.0"
IMAGES=(etl-worker fake-client ingest-api)

# ====== Docker login 用的暫存 config（跟你原本一樣，避免污染 ~/.docker）======
export DOCKER_CONFIG="$(mktemp -d)"
trap 'rm -rf "$DOCKER_CONFIG"; unset DOCKER_CONFIG' EXIT

# ====== 前置檢查 ======
command -v gcloud >/dev/null 2>&1 || { echo "ERROR: gcloud not found"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "ERROR: docker not found"; exit 1; }

REG_HOST="${LOCATION}-docker.pkg.dev"
REG="${REG_HOST}/${PROJECT_ID}/${REPO}"


gcloud --quiet auth print-access-token \
  | docker login -u oauth2accesstoken --password-stdin "https://${REG_HOST}"

# ====== tag + push ======
for img in "${IMAGES[@]}"; do
  docker tag "${img}:latest" "${REG}/${img}:${TAG}"
  docker push "${REG}/${img}:${TAG}"
done