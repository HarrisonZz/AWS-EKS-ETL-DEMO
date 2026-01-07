#!/usr/bin/env bash
set -euo pipefail

# --- 0) 定位 .env（用腳本路徑，不吃你在哪個資料夾跑）---
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"   # repo root/.env

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "❌ .env not found: $ENV_FILE"
  exit 1
fi

# --- 1) 必要環境變數（新 ETL job 用 BigQuery SQL）---
: "${BQ_PROJECT:?missing BQ_PROJECT in .env}"
: "${BQ_DATASET:?missing BQ_DATASET in .env}"
: "${BQ_TARGET_TABLE:?missing BQ_TARGET_TABLE in .env}"      # 例如 device_metrics_agg
: "${BQ_EXTERNAL_TABLE:?missing BQ_EXTERNAL_TABLE in .env}"  # 例如 raw_external

# 預設跑「昨天 UTC」，也可透過參數傳入：./run_etl_bq.sh 2026-01-07
PROCESS_DATE="${1:-$(date -u -d 'yesterday' +%Y-%m-%d 2>/dev/null || python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc).date() - timedelta(days=1)).isoformat())
PY
)}"

IMAGE_NAME="etl-job:latest"          # ⚠️ 新 job 建議改個 image 名稱，避免跟舊 duckdb worker 混淆
CONTAINER_NAME="etl-job-runner"

echo "🔧 Config"
echo "   - PROCESS_DATE     : $PROCESS_DATE"
echo "   - BQ_PROJECT       : $BQ_PROJECT"
echo "   - BQ_DATASET       : $BQ_DATASET"
echo "   - BQ_EXTERNAL_TABLE: $BQ_EXTERNAL_TABLE"
echo "   - BQ_TARGET_TABLE  : $BQ_TARGET_TABLE"
echo "   - BQ_LOCATION      : ${BQ_LOCATION:-US}"

# --- 2) (可選) 本機要用 SA key 的話才需要 mount；上 GKE 用 Workload Identity 不需要 ---
if [ -n "${ETL_GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then

  # 1. 處理路徑 (支援絕對路徑與相對路徑)
  if [[ "$ETL_GOOGLE_APPLICATION_CREDENTIALS" = /* ]]; then
      KEY_PATH="$ETL_GOOGLE_APPLICATION_CREDENTIALS"
  else
      # 假設 .env 裡的相對路徑是相對於專案根目錄
      KEY_PATH="${SCRIPT_DIR}/${ETL_GOOGLE_APPLICATION_CREDENTIALS}"
  fi
  
  # 2. 檢查檔案是否存在
  if [ ! -f "$KEY_PATH" ]; then
    echo "❌ Credential file not found: $KEY_PATH"
    echo "   (Checked from env var: ETL_GOOGLE_APPLICATION_CREDENTIALS)"
    exit 1
  fi
  
  # 3. 取得絕對路徑 (給 Docker -v 掛載用)
  REAL_KEY_PATH="$(realpath "$KEY_PATH")"
  
  # 4. 設定容器內部路徑
  CRED_PATH_CONT="/tmp/sa-key.json"
  
  # ⚠️ 關鍵：
  # Host 端讀取 ETL 專用 Key
  # Container 端設定為標準 GOOGLE_APPLICATION_CREDENTIALS，讓 Python 自動抓到
  EXTRA_DOCKER_ARGS+=( -e "GOOGLE_APPLICATION_CREDENTIALS=$CRED_PATH_CONT" )
  EXTRA_DOCKER_ARGS+=( -v "${REAL_KEY_PATH}:${CRED_PATH_CONT}:ro" )
  
  echo "🔑 Using Credentials: $ETL_GOOGLE_APPLICATION_CREDENTIALS"
fi

# --- 3) 跑 ETL job（BigQuery MERGE）---
docker run --rm \
  --name "$CONTAINER_NAME" \
  -e "PROCESS_DATE=$PROCESS_DATE" \
  -e "BQ_PROJECT=$BQ_PROJECT" \
  -e "BQ_DATASET=$BQ_DATASET" \
  -e "BQ_EXTERNAL_TABLE=$BQ_EXTERNAL_TABLE" \
  -e "BQ_TARGET_TABLE=$BQ_TARGET_TABLE" \
  -e "BQ_LOCATION=${BQ_LOCATION:-US}" \
  "${EXTRA_DOCKER_ARGS[@]}" \
  "$IMAGE_NAME"

echo "🏁 ETL done."
